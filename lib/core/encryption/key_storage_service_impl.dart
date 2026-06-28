import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';

import '../constants/storage_keys.dart';
import '../error/exceptions.dart';
import '../error/failures.dart';
import '../logger/app_logger.dart';
import 'key_storage_service.dart';
import 'models/key_bundle.dart';

class KeyStorageServiceImpl implements KeyStorageService {
  const KeyStorageServiceImpl(this._storage);

  final FlutterSecureStorage _storage;

  // ── Identity key ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> saveIdentityKeyPair(
      Uint8List seedBytes) async {
    try {
      await _storage.write(
        key: StorageKeys.identityKeyPair,
        value: base64.encode(seedBytes),
      );
      return const Right(null);
    } on StorageException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e, stack) {
      AppLogger.error('saveIdentityKeyPair failed', e, stack);
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Uint8List>> getIdentityKeyPair() async {
    try {
      final value = await _storage.read(key: StorageKeys.identityKeyPair);
      if (value == null) {
        return const Left(EncryptionFailure.keyGenerationFailed());
      }
      return Right(Uint8List.fromList(base64.decode(value)));
    } catch (e, stack) {
      AppLogger.error('getIdentityKeyPair failed', e, stack);
      return const Left(CacheFailure());
    }
  }

  // ── Signed prekey ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> saveSignedPreKey({
    required int id,
    required Uint8List privateKeyBytes,
    required Uint8List signatureBytes,
  }) async {
    try {
      await Future.wait([
        _storage.write(
          key: '${StorageKeys.signedPreKeyPair}_$id',
          value: base64.encode(privateKeyBytes),
        ),
        _storage.write(
          key: '${StorageKeys.signedPreKeySignature}_$id',
          value: base64.encode(signatureBytes),
        ),
        _storage.write(
          key: StorageKeys.signedPreKeyId,
          value: id.toString(),
        ),
      ]);
      return const Right(null);
    } catch (e, stack) {
      AppLogger.error('saveSignedPreKey failed', e, stack);
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Uint8List>> getSignedPreKeyPrivateBytes(int id) async {
    try {
      final value =
          await _storage.read(key: '${StorageKeys.signedPreKeyPair}_$id');
      if (value == null) {
        return const Left(EncryptionFailure.keyGenerationFailed());
      }
      return Right(Uint8List.fromList(base64.decode(value)));
    } catch (e, stack) {
      AppLogger.error('getSignedPreKeyPrivateBytes failed', e, stack);
      return const Left(CacheFailure());
    }
  }

  // ── Own public key bundle ────────────────────────────────────────────────────

  @override
  Future<Either<Failure, KeyBundle>> getOwnPublicKeyBundle(
      String userId) async {
    try {
      final seedValue =
          await _storage.read(key: StorageKeys.identityKeyPair);
      if (seedValue == null) {
        return const Left(EncryptionFailure.keyGenerationFailed());
      }
      final seed = Uint8List.fromList(base64.decode(seedValue));

      final spkIdValue =
          await _storage.read(key: StorageKeys.signedPreKeyId);
      if (spkIdValue == null) {
        return const Left(EncryptionFailure.keyGenerationFailed());
      }
      final spkId = int.parse(spkIdValue);

      final spkPrivValue =
          await _storage.read(key: '${StorageKeys.signedPreKeyPair}_$spkId');
      final spkSigValue = await _storage.read(
          key: '${StorageKeys.signedPreKeySignature}_$spkId');
      if (spkPrivValue == null || spkSigValue == null) {
        return const Left(EncryptionFailure.keyGenerationFailed());
      }

      // Derive public keys from seed (same derivation used during generation)
      final x25519 = X25519();
      final ed25519 = Ed25519();

      final identityX25519Kp =
          await x25519.newKeyPairFromSeed(seed.sublist(0, 32));
      final identityEd25519Kp =
          await ed25519.newKeyPairFromSeed(seed.sublist(0, 32));

      final identityX25519Pub = await identityX25519Kp.extractPublicKey();
      final identityEd25519Pub = await identityEd25519Kp.extractPublicKey();

      final spkPrivBytes =
          Uint8List.fromList(base64.decode(spkPrivValue));
      final spkKp = await x25519.newKeyPairFromSeed(spkPrivBytes);
      final spkPub = await spkKp.extractPublicKey();

      return Right(KeyBundle(
        userId: userId,
        identityKey: base64.encode(identityX25519Pub.bytes),
        identitySigningKey: base64.encode(identityEd25519Pub.bytes),
        signedPreKey: base64.encode(spkPub.bytes),
        signedPreKeySignature: spkSigValue,
        signedPreKeyId: spkId,
      ));
    } catch (e, stack) {
      AppLogger.error('getOwnPublicKeyBundle failed', e, stack);
      return const Left(CacheFailure());
    }
  }

  // ── One-time prekeys ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> saveOneTimePreKeys(
      List<OtpRecord> preKeys) async {
    try {
      final existing = await _readOtpList();
      final updated = [...existing, ...preKeys.map(_otpToJson)];
      await _storage.write(
        key: StorageKeys.oneTimePreKeys,
        value: jsonEncode(updated),
      );
      return const Right(null);
    } catch (e, stack) {
      AppLogger.error('saveOneTimePreKeys failed', e, stack);
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Uint8List?>> consumeOneTimePreKeyById(int id) async {
    try {
      final list = await _readOtpList();
      final index = list.indexWhere((e) => e['id'] as int == id);
      if (index == -1) return const Right(null);

      final entry = list[index];
      list.removeAt(index);

      await _storage.write(
        key: StorageKeys.oneTimePreKeys,
        value: jsonEncode(list),
      );
      return Right(
          Uint8List.fromList(base64.decode(entry['pk'] as String)));
    } catch (e, stack) {
      AppLogger.error('consumeOneTimePreKeyById failed', e, stack);
      return const Left(CacheFailure());
    }
  }

  // ── Session state ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> saveSessionState(
      String pairId, Uint8List stateBytes) async {
    try {
      await _storage.write(
        key: '${StorageKeys.sessionStatePrefix}$pairId',
        value: base64.encode(stateBytes),
      );
      return const Right(null);
    } catch (e, stack) {
      AppLogger.error('saveSessionState failed', e, stack);
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Uint8List?>> getSessionState(String pairId) async {
    try {
      final value = await _storage.read(
          key: '${StorageKeys.sessionStatePrefix}$pairId');
      return Right(
          value != null ? Uint8List.fromList(base64.decode(value)) : null);
    } catch (e, stack) {
      AppLogger.error('getSessionState failed', e, stack);
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteSession(String pairId) async {
    try {
      await _storage.delete(
          key: '${StorageKeys.sessionStatePrefix}$pairId');
      return const Right(null);
    } catch (e, stack) {
      AppLogger.error('deleteSession failed', e, stack);
      return const Left(CacheFailure());
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _readOtpList() async {
    final raw = await _storage.read(key: StorageKeys.oneTimePreKeys);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Map<String, dynamic> _otpToJson(OtpRecord r) => {
        'id': r.id,
        'pk': base64.encode(r.privateKeyBytes),
      };
}
