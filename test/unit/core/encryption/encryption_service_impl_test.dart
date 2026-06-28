import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:rathtech_chatting_app/core/encryption/double_ratchet_state.dart';
import 'package:rathtech_chatting_app/core/encryption/encryption_service_impl.dart';
import 'package:rathtech_chatting_app/core/encryption/key_storage_service.dart';
import 'package:rathtech_chatting_app/core/encryption/models/encrypted_payload.dart';
import 'package:rathtech_chatting_app/core/encryption/models/key_bundle.dart';
import 'package:rathtech_chatting_app/core/encryption/remote/key_bundle_remote_data_source.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockKeyStorageService extends Mock implements KeyStorageService {}

class MockKeyBundleRemoteDataSource extends Mock
    implements KeyBundleRemoteDataSource {}

// ── Helper: generate a real key bundle for testing ────────────────────────────

Future<_TestKeyMaterial> _generateTestKeyMaterial(String userId) async {
  final x25519 = X25519();
  final ed25519 = Ed25519();

  final seed = Uint8List.fromList(List.generate(32, (i) => i + 1));
  final ikX25519 = await x25519.newKeyPairFromSeed(seed);
  final ikEd25519 = await ed25519.newKeyPairFromSeed(seed);
  final ikX25519Pub = await ikX25519.extractPublicKey();
  final ikEd25519Pub = await ikEd25519.extractPublicKey();

  final spkSeed = Uint8List.fromList(List.generate(32, (i) => i + 50));
  final spkKp = await x25519.newKeyPairFromSeed(spkSeed);
  final spkPub = await spkKp.extractPublicKey();
  final spkSig = await ed25519.sign(spkPub.bytes, keyPair: ikEd25519);

  final otpSeed = Uint8List.fromList(List.generate(32, (i) => i + 100));
  final otpKp = await x25519.newKeyPairFromSeed(otpSeed);
  final otpPub = await otpKp.extractPublicKey();

  return _TestKeyMaterial(
    userId: userId,
    identitySeed: seed,
    spkSeed: spkSeed,
    otpSeed: otpSeed,
    bundle: KeyBundle(
      userId: userId,
      identityKey: base64.encode(ikX25519Pub.bytes),
      identitySigningKey: base64.encode(ikEd25519Pub.bytes),
      signedPreKey: base64.encode(spkPub.bytes),
      signedPreKeySignature: base64.encode(spkSig.bytes),
      signedPreKeyId: 1,
      oneTimePreKey: base64.encode(otpPub.bytes),
      oneTimePreKeyId: 1,
    ),
  );
}

class _TestKeyMaterial {
  const _TestKeyMaterial({
    required this.userId,
    required this.identitySeed,
    required this.spkSeed,
    required this.otpSeed,
    required this.bundle,
  });

  final String userId;
  final Uint8List identitySeed;
  final Uint8List spkSeed;
  final Uint8List otpSeed;
  final KeyBundle bundle;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockKeyStorageService aliceStorage;
  late MockKeyStorageService bobStorage;
  late MockKeyBundleRemoteDataSource aliceRemote;
  late MockKeyBundleRemoteDataSource bobRemote;

  late _TestKeyMaterial aliceMaterial;
  late _TestKeyMaterial bobMaterial;

  late EncryptionServiceImpl aliceService;
  late EncryptionServiceImpl bobService;

  const pairId = 'pair-001';

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(const <OtpRecord>[]);
  });

  setUp(() async {
    aliceStorage = MockKeyStorageService();
    bobStorage = MockKeyStorageService();
    aliceRemote = MockKeyBundleRemoteDataSource();
    bobRemote = MockKeyBundleRemoteDataSource();

    aliceMaterial = await _generateTestKeyMaterial('alice-uid');
    bobMaterial = await _generateTestKeyMaterial('bob-uid');

    aliceService = EncryptionServiceImpl(
      keyStorage: aliceStorage,
      remoteDataSource: aliceRemote,
      ownUserId: 'alice-uid',
    );
    bobService = EncryptionServiceImpl(
      keyStorage: bobStorage,
      remoteDataSource: bobRemote,
      ownUserId: 'bob-uid',
    );

    // Alice's key storage stubs
    when(() => aliceStorage.getIdentityKeyPair())
        .thenAnswer((_) async => Right(aliceMaterial.identitySeed));
    when(() => aliceStorage.getOwnPublicKeyBundle(any()))
        .thenAnswer((_) async => Right(aliceMaterial.bundle));
    when(() => aliceStorage.saveSessionState(any(), any()))
        .thenAnswer((_) async => const Right(null));
    when(() => aliceStorage.getSessionState(any()))
        .thenAnswer((_) async => const Right(null));

    // Bob's key storage stubs
    when(() => bobStorage.getIdentityKeyPair())
        .thenAnswer((_) async => Right(bobMaterial.identitySeed));
    when(() => bobStorage.getOwnPublicKeyBundle(any()))
        .thenAnswer((_) async => Right(bobMaterial.bundle));
    when(() => bobStorage.getSignedPreKeyPrivateBytes(any()))
        .thenAnswer((_) async => Right(bobMaterial.spkSeed));
    when(() => bobStorage.consumeOneTimePreKeyById(any()))
        .thenAnswer((_) async => Right(bobMaterial.otpSeed));
    when(() => bobStorage.saveSessionState(any(), any()))
        .thenAnswer((_) async => const Right(null));
    when(() => bobStorage.getSessionState(any()))
        .thenAnswer((_) async => const Right(null));

    // Remote stubs — OPK consumption
    when(() => aliceRemote.markOneTimePreKeyConsumed(
          userId: any(named: 'userId'),
          preKeyId: any(named: 'preKeyId'),
        )).thenAnswer((_) async {});
  });

  group('X3DH session establishment', () {
    test('Alice can initialize a session with Bob\'s key bundle', () async {
      final result = await aliceService.initializeSession(
        pairId: pairId,
        partnerBundle: bobMaterial.bundle,
      );
      expect(result.isRight(), isTrue);
      expect(aliceService.hasSession(pairId), isTrue);
    });
  });

  group('encrypt / decrypt round-trip', () {
    late EncryptedPayload cipherPayload;

    setUp(() async {
      // Alice initializes the session
      await aliceService.initializeSession(
        pairId: pairId,
        partnerBundle: bobMaterial.bundle,
      );
    });

    test('first message (prekey type) round-trips correctly', () async {
      const plaintext = 'Hello, Bob!';

      final encResult = await aliceService.encrypt(
        pairId: pairId,
        plaintext: plaintext,
      );
      expect(encResult.isRight(), isTrue);
      cipherPayload = encResult.getOrElse((_) => throw Exception());
      expect(cipherPayload.messageType, equals('prekey'));

      // Bob decrypts — he receives the prekey message and initialises his session
      final decResult = await bobService.decrypt(
        pairId: pairId,
        payload: cipherPayload,
      );
      expect(decResult.isRight(), isTrue);
      expect(decResult.getOrElse((_) => ''), equals(plaintext));
      expect(bobService.hasSession(pairId), isTrue);
    });

    test('subsequent messages (signal type) round-trip correctly', () async {
      const first = 'First message';
      const second = 'Second message';
      const third = 'Third message';

      final e1 = await aliceService.encrypt(pairId: pairId, plaintext: first);
      final payload1 = e1.getOrElse((_) => throw Exception());
      expect(payload1.messageType, equals('prekey'));

      // Bob decrypts first (initialises his session)
      await bobService.decrypt(pairId: pairId, payload: payload1);

      // Stub Bob's getSessionState to return his persisted session
      final capturedState = verify(
        () => bobStorage.saveSessionState(pairId, captureAny()),
      ).captured.last as Uint8List;
      when(() => bobStorage.getSessionState(pairId))
          .thenAnswer((_) async => Right(capturedState));

      // Alice sends second message (signal type)
      final e2 = await aliceService.encrypt(pairId: pairId, plaintext: second);
      final payload2 = e2.getOrElse((_) => throw Exception());
      expect(payload2.messageType, equals('signal'));

      final d2 = await bobService.decrypt(pairId: pairId, payload: payload2);
      expect(d2.isRight(), isTrue);
      expect(d2.getOrElse((_) => ''), equals(second));

      // Third message
      final e3 = await aliceService.encrypt(pairId: pairId, plaintext: third);
      final payload3 = e3.getOrElse((_) => throw Exception());
      final d3 = await bobService.decrypt(pairId: pairId, payload: payload3);
      expect(d3.isRight(), isTrue);
      expect(d3.getOrElse((_) => ''), equals(third));
    });

    test('decrypting wrong ciphertext returns EncryptionFailure', () async {
      final e = await aliceService.encrypt(
          pairId: pairId, plaintext: 'secret');
      final payload = e.getOrElse((_) => throw Exception());
      await bobService.decrypt(pairId: pairId, payload: payload);

      // Tamper with ciphertext
      final tampered = EncryptedPayload(
        ciphertext: base64.encode(Uint8List(64)), // garbage
        header: payload.header,
        messageIndex: payload.messageIndex,
        messageType: payload.messageType,
      );

      final result = await bobService.decrypt(
        pairId: pairId,
        payload: tampered,
      );
      expect(result.isLeft(), isTrue);
    });
  });

  group('DoubleRatchetState serialization', () {
    test('round-trips through toBytes / fromBytes', () {
      final original = DoubleRatchetState(
        dhKeyPairPrivate: Uint8List.fromList(List.generate(32, (i) => i)),
        dhPublicKey: Uint8List.fromList(List.generate(32, (i) => i + 32)),
        remoteDhPublicKey:
            Uint8List.fromList(List.generate(32, (i) => i + 64)),
        rootKey: Uint8List.fromList(List.generate(32, (i) => i + 96)),
        sendingChainKey:
            Uint8List.fromList(List.generate(32, (i) => i + 128)),
        receivingChainKey:
            Uint8List.fromList(List.generate(32, (i) => i + 160)),
        sendCount: 5,
        receiveCount: 3,
        previousChainCount: 2,
      );

      final restored = DoubleRatchetState.fromBytes(original.toBytes());

      expect(restored.sendCount, equals(original.sendCount));
      expect(restored.receiveCount, equals(original.receiveCount));
      expect(restored.rootKey, equals(original.rootKey));
      expect(restored.sendingChainKey, equals(original.sendingChainKey));
    });
  });

  group('media encryption', () {
    test('encrypt then decrypt returns original bytes', () async {
      final original = Uint8List.fromList(
          List.generate(1024, (i) => i % 256));

      final encResult = await aliceService.encryptMedia(original);
      expect(encResult.isRight(), isTrue);
      final enc = encResult.getOrElse((_) => throw Exception());

      final decResult = await aliceService.decryptMedia(
        encryptedData: enc.encryptedData,
        key: enc.key,
        iv: enc.iv,
      );
      expect(decResult.isRight(), isTrue);
      expect(decResult.getOrElse((_) => Uint8List(0)), equals(original));
    });

    test('decrypting with wrong key returns failure', () async {
      final original = Uint8List.fromList(List.generate(64, (i) => i));
      final enc = (await aliceService.encryptMedia(original))
          .getOrElse((_) => throw Exception());

      final wrongKey = Uint8List.fromList(List.generate(32, (_) => 0));
      final result = await aliceService.decryptMedia(
        encryptedData: enc.encryptedData,
        key: wrongKey,
        iv: enc.iv,
      );
      expect(result.isLeft(), isTrue);
    });
  });
}
