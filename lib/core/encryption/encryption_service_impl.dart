import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:fpdart/fpdart.dart';

import '../error/failures.dart';
import '../logger/app_logger.dart';
import 'double_ratchet_state.dart';
import 'encryption_service.dart';
import 'key_storage_service.dart';
import 'models/encrypted_payload.dart';
import 'models/key_bundle.dart';
import 'remote/key_bundle_remote_data_source.dart';

class EncryptionServiceImpl implements EncryptionService {
  EncryptionServiceImpl({
    required KeyStorageService keyStorage,
    required KeyBundleRemoteDataSource remoteDataSource,
    required String ownUserId,
  })  : _keyStorage = keyStorage,
        _remote = remoteDataSource,
        _ownUserId = ownUserId;

  final KeyStorageService _keyStorage;
  final KeyBundleRemoteDataSource _remote;
  final String _ownUserId;

  // In-memory session cache; also persisted per ratchet step.
  final Map<String, DoubleRatchetState> _sessions = {};

  // Caps the number of stored skipped message keys per session.
  static const int _maxSkippedKeys = 1000;

  static final _x25519 = X25519();
  static final _ed25519 = Ed25519();
  static final _aesCbc = AesCbc.with256bits(macAlgorithm: Hmac.sha256());
  static final _hmacSha256 = Hmac.sha256();

  // ── Public API ──────────────────────────────────────────────────────────────

  @override
  bool hasSession(String pairId) => _sessions.containsKey(pairId);

  @override
  Future<Either<Failure, void>> initializeSession({
    required String pairId,
    required KeyBundle partnerBundle,
  }) async {
    try {
      // Load own identity seed
      final seedResult = await _keyStorage.getIdentityKeyPair();
      if (seedResult.isLeft()) return seedResult.map((_) {});
      final seed = seedResult.getOrElse((_) => Uint8List(0));

      // Derive own identity public key to include in X3DH header
      final ownIkKp = await _x25519.newKeyPairFromSeed(seed.sublist(0, 32));
      final ownIkPub = await ownIkKp.extractPublicKey();

      // Decode partner's public keys
      final partnerIkPub = SimplePublicKey(
        base64.decode(partnerBundle.identityKey),
        type: KeyPairType.x25519,
      );
      final partnerIkSigningPub = SimplePublicKey(
        base64.decode(partnerBundle.identitySigningKey),
        type: KeyPairType.ed25519,
      );
      final partnerSpkPub = SimplePublicKey(
        base64.decode(partnerBundle.signedPreKey),
        type: KeyPairType.x25519,
      );

      // Verify SPK signature
      final sigOk = await _ed25519.verify(
        partnerSpkPub.bytes,
        signature: Signature(
          base64.decode(partnerBundle.signedPreKeySignature),
          publicKey: partnerIkSigningPub,
        ),
      );
      if (!sigOk) {
        return const Left(EncryptionFailure.decryptionFailed());
      }

      // Generate ephemeral key
      final ekSeed = _randomBytes(32);
      final ekKp = await _x25519.newKeyPairFromSeed(ekSeed);
      final ekPub = await ekKp.extractPublicKey();

      // DH1 = DH(IK_A, SPK_B) — seed is the Curve25519 scalar for IK_A
      final dh1 = await _dh(seed.sublist(0, 32), partnerSpkPub);
      // DH2 = DH(EK_A, IK_B)
      final dh2 = await _dh(ekSeed, partnerIkPub);
      // DH3 = DH(EK_A, SPK_B)
      final dh3 = await _dh(ekSeed, partnerSpkPub);

      Uint8List dhConcat;
      int? otpId;

      if (partnerBundle.oneTimePreKey != null) {
        final partnerOtpPub = SimplePublicKey(
          base64.decode(partnerBundle.oneTimePreKey!),
          type: KeyPairType.x25519,
        );
        // DH4 = DH(EK_A, OPK_B)
        final dh4 = await _dh(ekSeed, partnerOtpPub);
        dhConcat = _concat([dh1, dh2, dh3, dh4]);
        otpId = partnerBundle.oneTimePreKeyId;

        // Mark OPK consumed on server
        if (otpId != null) {
          await _remote.markOneTimePreKeyConsumed(
            userId: partnerBundle.userId,
            preKeyId: otpId,
          );
        }
      } else {
        dhConcat = _concat([dh1, dh2, dh3]);
      }

      final masterSecret = await _hkdfExpand(dhConcat);

      // Initialise Double Ratchet as sender
      // First DH ratchet step: generate our ratchet key and advance root key
      final ratchetSeed = _randomBytes(32);
      final ratchetKp = await _x25519.newKeyPairFromSeed(ratchetSeed);
      final ratchetPub = await ratchetKp.extractPublicKey();

      final (rk, cks) = await _kdfRk(
        masterSecret.sublist(0, 32),
        await _dh(ratchetSeed, partnerSpkPub),
      );

      final state = DoubleRatchetState(
        dhKeyPairPrivate: Uint8List.fromList(ratchetSeed),
        dhPublicKey: Uint8List.fromList(ratchetPub.bytes),
        remoteDhPublicKey: Uint8List.fromList(partnerSpkPub.bytes),
        rootKey: rk,
        sendingChainKey: cks,
      );

      _sessions[pairId] = state;
      await _persistSession(pairId, state);

      // Store X3DH header so first encrypt() can include it
      _pendingX3dhHeaders[pairId] = _X3dhHeader(
        identityKey: base64.encode(ownIkPub.bytes),
        ephemeralKey: base64.encode(ekPub.bytes),
        signedPreKeyId: partnerBundle.signedPreKeyId,
        oneTimePreKeyId: otpId,
      );

      return const Right(null);
    } catch (e, stack) {
      AppLogger.error('initializeSession failed', e, stack);
      return const Left(EncryptionFailure.sessionNotInitialized());
    }
  }

  // Holds X3DH headers pending inclusion in the first outgoing message per pairId.
  final Map<String, _X3dhHeader> _pendingX3dhHeaders = {};

  @override
  Future<Either<Failure, EncryptedPayload>> encrypt({
    required String pairId,
    required String plaintext,
  }) async {
    try {
      final state = await _loadSession(pairId);
      if (state == null) {
        return const Left(EncryptionFailure.sessionNotInitialized());
      }
      if (state.sendingChainKey == null) {
        return const Left(EncryptionFailure.sessionNotInitialized());
      }

      // Advance sending chain key
      final mk = await _chainKdfMessageKey(state.sendingChainKey!);
      final nextCks = await _chainKdfChainKey(state.sendingChainKey!);

      // Encrypt plaintext — store nonce prepended so decryption can recover it
      final secretKey = await _aesCbc.newSecretKeyFromBytes(mk);
      final secretBox = await _aesCbc.encrypt(
        utf8.encode(plaintext),
        secretKey: secretKey,
      );
      final storedCiphertext = base64.encode([
        ...secretBox.nonce,
        ...secretBox.cipherText,
        ...secretBox.mac.bytes,
      ]);

      final isPrekey = _pendingX3dhHeaders.containsKey(pairId);
      final String headerJson;
      if (isPrekey) {
        final x3dhHeader = _pendingX3dhHeaders.remove(pairId)!;
        headerJson = jsonEncode({
          'type': 'prekey',
          'identity_key': x3dhHeader.identityKey,
          'ephemeral_key': x3dhHeader.ephemeralKey,
          'signed_prekey_id': x3dhHeader.signedPreKeyId,
          if (x3dhHeader.oneTimePreKeyId != null)
            'one_time_prekey_id': x3dhHeader.oneTimePreKeyId,
          'dh_public': base64.encode(state.dhPublicKey),
          'prev_chain_count': state.previousChainCount,
        });
      } else {
        headerJson = jsonEncode({
          'type': 'signal',
          'dh_public': base64.encode(state.dhPublicKey),
          'prev_chain_count': state.previousChainCount,
        });
      }

      final updatedState = state.copyWith(
        sendingChainKey: nextCks,
        sendCount: state.sendCount + 1,
      );
      _sessions[pairId] = updatedState;
      await _persistSession(pairId, updatedState);

      return Right(EncryptedPayload(
        ciphertext: storedCiphertext,
        header: base64.encode(utf8.encode(headerJson)),
        messageIndex: state.sendCount,
        messageType: isPrekey ? 'prekey' : 'signal',
      ));
    } catch (e, stack) {
      AppLogger.error('encrypt failed', e, stack);
      return const Left(EncryptionFailure.sessionNotInitialized());
    }
  }

  @override
  Future<Either<Failure, String>> decrypt({
    required String pairId,
    required EncryptedPayload payload,
  }) async {
    try {
      final headerJson =
          utf8.decode(base64.decode(payload.header));
      final header =
          jsonDecode(headerJson) as Map<String, dynamic>;

      if (payload.messageType == 'prekey') {
        final initResult = await _initSessionAsReceiver(pairId, header);
        if (initResult.isLeft()) return initResult.map((_) => '');
      }

      var state = await _loadSession(pairId);
      if (state == null) {
        return const Left(EncryptionFailure.sessionNotInitialized());
      }

      final headerDhPub = Uint8List.fromList(
          base64.decode(header['dh_public'] as String));
      final headerMsgIndex = payload.messageIndex;
      final headerPn = header['prev_chain_count'] as int;

      // Check if this is a new DH ratchet step
      if (!_bytesEqual(headerDhPub, state.remoteDhPublicKey)) {
        state = await _skipMessageKeys(
          state,
          headerPn,
          pairId,
        );
        state = await _dhRatchetStep(state, headerDhPub);
      }

      // Skip any messages before this one
      if (headerMsgIndex > state.receiveCount) {
        state = await _skipUpTo(state, headerMsgIndex, pairId);
      }

      // Check skipped keys first
      final skipKey = '${base64.encode(headerDhPub)}:$headerMsgIndex';
      Uint8List mk;
      if (state.skippedMessageKeys.containsKey(skipKey)) {
        mk = state.skippedMessageKeys[skipKey]!;
        final updated = Map<String, Uint8List>.from(state.skippedMessageKeys)
          ..remove(skipKey);
        state = state.copyWith(skippedMessageKeys: updated);
      } else {
        if (state.receivingChainKey == null) {
          return const Left(EncryptionFailure.decryptionFailed());
        }
        mk = await _chainKdfMessageKey(state.receivingChainKey!);
        final nextCkr = await _chainKdfChainKey(state.receivingChainKey!);
        state = state.copyWith(
          receivingChainKey: nextCkr,
          receiveCount: state.receiveCount + 1,
        );
      }

      // Decrypt — format: nonce(16) + ciphertext + mac(32)
      final fullBytes = base64.decode(payload.ciphertext);
      const cbcNonceLen = 16; // AES-CBC IV = one AES block
      const macLen = 32;      // HMAC-SHA256 output
      final nonce = fullBytes.sublist(0, cbcNonceLen);
      final cipherText =
          fullBytes.sublist(cbcNonceLen, fullBytes.length - macLen);
      final mac = Mac(fullBytes.sublist(fullBytes.length - macLen));

      final secretKey = await _aesCbc.newSecretKeyFromBytes(mk);
      final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);

      final plainBytes = await _aesCbc.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      _sessions[pairId] = state;
      await _persistSession(pairId, state);

      return Right(utf8.decode(plainBytes));
    } catch (e, stack) {
      AppLogger.error('decrypt failed', e, stack);
      return const Left(EncryptionFailure.decryptionFailed());
    }
  }

  @override
  Future<Either<Failure, ({Uint8List encryptedData, Uint8List key, Uint8List iv})>>
      encryptMedia(Uint8List data) async {
    try {
      final aesGcm = AesGcm.with256bits();
      final mediaKey = await aesGcm.newSecretKey();
      final mediaKeyBytes = Uint8List.fromList(await mediaKey.extractBytes());
      final nonce = aesGcm.newNonce();
      final secretBox =
          await aesGcm.encrypt(data, secretKey: mediaKey, nonce: nonce);
      final encrypted = Uint8List.fromList([
        ...secretBox.nonce,
        ...secretBox.cipherText,
        ...secretBox.mac.bytes,
      ]);
      return Right((
        encryptedData: encrypted,
        key: mediaKeyBytes,
        iv: Uint8List.fromList(nonce),
      ));
    } catch (e, stack) {
      AppLogger.error('encryptMedia failed', e, stack);
      return const Left(EncryptionFailure.keyGenerationFailed());
    }
  }

  @override
  Future<Either<Failure, Uint8List>> decryptMedia({
    required Uint8List encryptedData,
    required Uint8List key,
    required Uint8List iv,
  }) async {
    try {
      final aesGcm = AesGcm.with256bits();
      final nonceLen = aesGcm.nonceLength;
      const macLen = 16;
      final cipherText = encryptedData.sublist(
          nonceLen, encryptedData.length - macLen);
      final mac =
          Mac(encryptedData.sublist(encryptedData.length - macLen));
      final secretBox = SecretBox(cipherText, nonce: iv, mac: mac);
      final secretKey = await aesGcm.newSecretKeyFromBytes(key);
      final plain = await aesGcm.decrypt(secretBox, secretKey: secretKey);
      return Right(Uint8List.fromList(plain));
    } catch (e, stack) {
      AppLogger.error('decryptMedia failed', e, stack);
      return const Left(EncryptionFailure.decryptionFailed());
    }
  }

  // ── Session init as receiver ────────────────────────────────────────────────

  Future<Either<Failure, void>> _initSessionAsReceiver(
      String pairId, Map<String, dynamic> header) async {
    try {
      final seedResult = await _keyStorage.getIdentityKeyPair();
      if (seedResult.isLeft()) return seedResult.map((_) {});
      final seed = seedResult.getOrElse((_) => Uint8List(0));

      final bundleResult =
          await _keyStorage.getOwnPublicKeyBundle(_ownUserId);
      if (bundleResult.isLeft()) return bundleResult.map((_) {});
      final ownBundle = bundleResult.getOrElse((_) => throw Exception());
      final spkId = ownBundle.signedPreKeyId;

      final senderIkPub = SimplePublicKey(
        base64.decode(header['identity_key'] as String),
        type: KeyPairType.x25519,
      );
      final senderEkPub = SimplePublicKey(
        base64.decode(header['ephemeral_key'] as String),
        type: KeyPairType.x25519,
      );

      // We need SPK private bytes — read them from KeyStorageService.
      // KeyStorageServiceImpl stores SPK at `signal_signed_prekey_pair_{id}`.
      // We expose this via a new method on the interface below.
      final spkPrivResult = await _keyStorage.getSignedPreKeyPrivateBytes(spkId);
      if (spkPrivResult.isLeft()) return spkPrivResult.map((_) {});
      final spkPrivSeed = spkPrivResult.getOrElse((_) => Uint8List(0));

      // DH1 = DH(SPK_B, IK_A)
      final dh1 = await _dh(spkPrivSeed, senderIkPub);
      // DH2 = DH(IK_B, EK_A)
      final dh2 = await _dh(seed.sublist(0, 32), senderEkPub);
      // DH3 = DH(SPK_B, EK_A)
      final dh3 = await _dh(spkPrivSeed, senderEkPub);

      Uint8List dhConcat;
      final otpId = header['one_time_prekey_id'] as int?;
      if (otpId != null) {
        final otpPrivResult =
            await _keyStorage.consumeOneTimePreKeyById(otpId);
        if (otpPrivResult.isLeft()) {
          return otpPrivResult.map((_) {});
        }
        final otpPrivSeed = otpPrivResult.getOrElse((_) => null);
        if (otpPrivSeed != null) {
          // DH4 = DH(OPK_B, EK_A)
          final dh4 = await _dh(otpPrivSeed, senderEkPub);
          dhConcat = _concat([dh1, dh2, dh3, dh4]);
        } else {
          dhConcat = _concat([dh1, dh2, dh3]);
        }
      } else {
        dhConcat = _concat([dh1, dh2, dh3]);
      }

      final masterSecret = await _hkdfExpand(dhConcat);

      // Initialise Double Ratchet as receiver
      // Sender's first ratchet public key is in the message header
      final senderRatchetPub = SimplePublicKey(
        base64.decode(header['dh_public'] as String),
        type: KeyPairType.x25519,
      );

      final ratchetSeed = _randomBytes(32);
      final ratchetKp = await _x25519.newKeyPairFromSeed(ratchetSeed);
      final ratchetPub = await ratchetKp.extractPublicKey();

      // Derive receiving chain from master secret
      final (rk0, ckr) = await _kdfRk(
        masterSecret.sublist(0, 32),
        await _dh(spkPrivSeed, senderRatchetPub),
      );

      // Derive our own sending chain (DH ratchet step with our new key)
      final (rk, cks) = await _kdfRk(
        rk0,
        await _dh(ratchetSeed, senderRatchetPub),
      );

      final state = DoubleRatchetState(
        dhKeyPairPrivate: ratchetSeed,
        dhPublicKey: Uint8List.fromList(ratchetPub.bytes),
        remoteDhPublicKey: Uint8List.fromList(senderRatchetPub.bytes),
        rootKey: rk,
        sendingChainKey: cks,
        receivingChainKey: ckr,
      );

      _sessions[pairId] = state;
      await _persistSession(pairId, state);
      return const Right(null);
    } catch (e, stack) {
      AppLogger.error('_initSessionAsReceiver failed', e, stack);
      return const Left(EncryptionFailure.sessionNotInitialized());
    }
  }

  // ── Double Ratchet helpers ──────────────────────────────────────────────────

  Future<DoubleRatchetState> _dhRatchetStep(
      DoubleRatchetState state, Uint8List newRemotePub) async {
    final remotePub = SimplePublicKey(newRemotePub, type: KeyPairType.x25519);

    // Skip remaining messages on old receiving chain
    final (rk1, ckr) = await _kdfRk(
      state.rootKey,
      await _dh(state.dhKeyPairPrivate, remotePub),
    );

    // Generate new DH key pair for our next sending chain
    final newRatchetSeed = _randomBytes(32);
    final newRatchetKp = await _x25519.newKeyPairFromSeed(newRatchetSeed);
    final newRatchetPub = await newRatchetKp.extractPublicKey();

    final (rk2, cks) = await _kdfRk(
      rk1,
      await _dh(newRatchetSeed, remotePub),
    );

    return state.copyWith(
      dhKeyPairPrivate: newRatchetSeed,
      dhPublicKey: Uint8List.fromList(newRatchetPub.bytes),
      remoteDhPublicKey: newRemotePub,
      rootKey: rk2,
      sendingChainKey: cks,
      receivingChainKey: ckr,
      sendCount: 0,
      receiveCount: 0,
      previousChainCount: state.sendCount,
    );
  }

  Future<DoubleRatchetState> _skipMessageKeys(
      DoubleRatchetState state, int until, String pairId) async {
    if (state.receivingChainKey == null) return state;
    var s = state;
    while (s.receiveCount < until &&
        s.skippedMessageKeys.length < _maxSkippedKeys) {
      final mk = await _chainKdfMessageKey(s.receivingChainKey!);
      final nextCkr = await _chainKdfChainKey(s.receivingChainKey!);
      final key =
          '${base64.encode(s.remoteDhPublicKey)}:${s.receiveCount}';
      final updated = Map<String, Uint8List>.from(s.skippedMessageKeys)
        ..[key] = mk;
      s = s.copyWith(
        receivingChainKey: nextCkr,
        receiveCount: s.receiveCount + 1,
        skippedMessageKeys: updated,
      );
    }
    return s;
  }

  Future<DoubleRatchetState> _skipUpTo(
      DoubleRatchetState state, int msgIndex, String pairId) async {
    return _skipMessageKeys(state, msgIndex, pairId);
  }

  // ── Crypto primitives ───────────────────────────────────────────────────────

  // X25519 DH — returns 32-byte shared secret
  Future<Uint8List> _dh(Uint8List privateSeed, SimplePublicKey remotePub) async {
    final kp = await _x25519.newKeyPairFromSeed(privateSeed);
    final shared = await _x25519.sharedSecretKey(
      keyPair: kp,
      remotePublicKey: remotePub,
    );
    return Uint8List.fromList(await shared.extractBytes());
  }

  // HKDF-expand 64 bytes from DH material
  Future<Uint8List> _hkdfExpand(Uint8List dhMaterial) async {
    final hkdf64 = Hkdf(hmac: Hmac.sha256(), outputLength: 64);
    final result = await hkdf64.deriveKey(
      secretKey: SecretKey(dhMaterial),
      nonce: List.filled(32, 0),
      info: utf8.encode('SecureChat-X3DH-v1'),
    );
    return Uint8List.fromList(await result.extractBytes());
  }

  // KDF_RK: returns (new_root_key, new_chain_key)
  Future<(Uint8List, Uint8List)> _kdfRk(
      Uint8List rootKey, Uint8List dhOutput) async {
    final hkdf64 = Hkdf(hmac: Hmac.sha256(), outputLength: 64);
    final derived = await hkdf64.deriveKey(
      secretKey: SecretKey(dhOutput),
      nonce: rootKey,
      info: utf8.encode('SecureChat-RatchetRK-v1'),
    );
    final bytes = Uint8List.fromList(await derived.extractBytes());
    return (bytes.sublist(0, 32), bytes.sublist(32));
  }

  // Chain key → message key: HMAC-SHA256(CK, [0x01])
  Future<Uint8List> _chainKdfMessageKey(Uint8List chainKey) async {
    final mac = await _hmacSha256.calculateMac([0x01],
        secretKey: SecretKey(chainKey));
    return Uint8List.fromList(mac.bytes);
  }

  // Chain key → next chain key: HMAC-SHA256(CK, [0x02])
  Future<Uint8List> _chainKdfChainKey(Uint8List chainKey) async {
    final mac = await _hmacSha256.calculateMac([0x02],
        secretKey: SecretKey(chainKey));
    return Uint8List.fromList(mac.bytes);
  }

  Uint8List _concat(List<Uint8List> parts) =>
      Uint8List.fromList(parts.expand((b) => b).toList());

  bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
        List<int>.generate(length, (_) => rng.nextInt(256)));
  }

  // ── Session persistence ─────────────────────────────────────────────────────

  Future<DoubleRatchetState?> _loadSession(String pairId) async {
    if (_sessions.containsKey(pairId)) return _sessions[pairId];
    final result = await _keyStorage.getSessionState(pairId);
    return result.fold(
      (_) => null,
      (bytes) {
        if (bytes == null) return null;
        final state = DoubleRatchetState.fromBytes(bytes);
        _sessions[pairId] = state;
        return state;
      },
    );
  }

  Future<void> _persistSession(
      String pairId, DoubleRatchetState state) async {
    await _keyStorage.saveSessionState(pairId, state.toBytes());
  }
}

// ── Internal models ─────────────────────────────────────────────────────────

class _X3dhHeader {
  const _X3dhHeader({
    required this.identityKey,
    required this.ephemeralKey,
    required this.signedPreKeyId,
    this.oneTimePreKeyId,
  });

  final String identityKey;
  final String ephemeralKey;
  final int signedPreKeyId;
  final int? oneTimePreKeyId;
}
