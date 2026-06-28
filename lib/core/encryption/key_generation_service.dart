import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';

import '../constants/storage_keys.dart';
import '../error/exceptions.dart';
import '../error/failures.dart';
import '../logger/app_logger.dart';
import 'key_storage_service.dart';
import 'remote/key_bundle_remote_data_source.dart';

abstract class KeyGenerationService {
  /// Generates and publishes all Signal Protocol keys for [userId].
  /// Called exactly once after profile creation.
  Future<Either<Failure, void>> generateAndPublishKeys(String userId);

  /// Returns true if identity key material exists in secure storage.
  Future<bool> hasKeys();
}

class KeyGenerationServiceImpl implements KeyGenerationService {
  const KeyGenerationServiceImpl({
    required KeyStorageService keyStorage,
    required KeyBundleRemoteDataSource remoteDataSource,
    required FlutterSecureStorage secureStorage,
  })  : _keyStorage = keyStorage,
        _remote = remoteDataSource,
        _secureStorage = secureStorage;

  final KeyStorageService _keyStorage;
  final KeyBundleRemoteDataSource _remote;
  final FlutterSecureStorage _secureStorage;

  static const int _otpCount = 100;

  @override
  Future<bool> hasKeys() async {
    final value =
        await _secureStorage.read(key: StorageKeys.identityKeyPair);
    return value != null;
  }

  @override
  Future<Either<Failure, void>> generateAndPublishKeys(
      String userId) async {
    try {
      AppLogger.info('KeyGenerationService: generating keys for $userId');

      final x25519 = X25519();
      final ed25519 = Ed25519();

      // ── 1. Identity key ───────────────────────────────────────────────────
      final seed = _randomBytes(32);
      final identityX25519Kp = await x25519.newKeyPairFromSeed(seed);
      final identityEd25519Kp = await ed25519.newKeyPairFromSeed(seed);
      final identityX25519Pub = await identityX25519Kp.extractPublicKey();
      final identityEd25519Pub = await identityEd25519Kp.extractPublicKey();

      // ── 2. Signed prekey ──────────────────────────────────────────────────
      const spkId = 1;
      final spkSeed = _randomBytes(32);
      final spkKp = await x25519.newKeyPairFromSeed(spkSeed);
      final spkPub = await spkKp.extractPublicKey();

      final spkSignature = await ed25519.sign(
        spkPub.bytes,
        keyPair: identityEd25519Kp,
      );

      // ── 3. One-time prekeys ───────────────────────────────────────────────
      final otpRecords = <OtpRecord>[];
      final otpPublic = <({int id, String publicKey})>[];
      for (var i = 1; i <= _otpCount; i++) {
        final otpSeed = _randomBytes(32);
        final otpKp = await x25519.newKeyPairFromSeed(otpSeed);
        final otpPub = await otpKp.extractPublicKey();
        otpRecords.add((id: i, privateKeyBytes: Uint8List.fromList(otpSeed)));
        otpPublic.add((id: i, publicKey: base64.encode(otpPub.bytes)));
      }

      // ── 4. Persist private keys ───────────────────────────────────────────
      final saveId = await _keyStorage.saveIdentityKeyPair(
          Uint8List.fromList(seed));
      if (saveId.isLeft()) return saveId;

      final saveSpk = await _keyStorage.saveSignedPreKey(
        id: spkId,
        privateKeyBytes: Uint8List.fromList(spkSeed),
        signatureBytes: Uint8List.fromList(spkSignature.bytes),
      );
      if (saveSpk.isLeft()) return saveSpk;

      final saveOtp = await _keyStorage.saveOneTimePreKeys(otpRecords);
      if (saveOtp.isLeft()) return saveOtp;

      // ── 5. Publish public keys ────────────────────────────────────────────
      final registrationId = _randomInt31();
      await _remote.publishIdentityKey(
        userId: userId,
        identityKey: base64.encode(identityX25519Pub.bytes),
        identitySigningKey: base64.encode(identityEd25519Pub.bytes),
        registrationId: registrationId,
      );

      await _remote.publishSignedPreKey(
        userId: userId,
        preKeyId: spkId,
        publicKey: base64.encode(spkPub.bytes),
        signature: base64.encode(spkSignature.bytes),
      );

      await _remote.publishOneTimePreKeys(
        userId: userId,
        preKeys: otpPublic,
      );

      AppLogger.info('KeyGenerationService: keys published successfully');
      return const Right(null);
    } on ServerException catch (e) {
      AppLogger.error('generateAndPublishKeys server error', e);
      return Left(ServerFailure.server(e.message));
    } catch (e, stack) {
      AppLogger.error('generateAndPublishKeys unexpected error', e, stack);
      return const Left(EncryptionFailure.keyGenerationFailed());
    }
  }

  Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
        List<int>.generate(length, (_) => rng.nextInt(256)));
  }

  int _randomInt31() {
    final rng = Random.secure();
    return rng.nextInt(0x7FFFFFFF);
  }
}
