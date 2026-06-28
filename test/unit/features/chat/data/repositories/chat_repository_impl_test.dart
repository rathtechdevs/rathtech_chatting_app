import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/encryption/encryption_service.dart';
import 'package:rathtech_chatting_app/core/encryption/models/encrypted_payload.dart';
import 'package:rathtech_chatting_app/core/encryption/models/key_bundle.dart';
import 'package:rathtech_chatting_app/core/encryption/remote/key_bundle_remote_data_source.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/core/storage/app_database.dart';
import 'package:rathtech_chatting_app/features/chat/data/data_sources/local/chat_local_data_source.dart';
import 'package:rathtech_chatting_app/features/chat/data/data_sources/remote/chat_remote_data_source.dart';
import 'package:rathtech_chatting_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:rathtech_chatting_app/features/chat/domain/entities/message.dart';
import 'package:rathtech_chatting_app/features/chat/domain/repositories/chat_repository.dart';

class _MockChatRemoteDataSource extends Mock implements ChatRemoteDataSource {}

class _MockChatLocalDataSource extends Mock implements ChatLocalDataSource {}

class _MockEncryptionService extends Mock implements EncryptionService {}

class _MockKeyBundleRemoteDataSource extends Mock
    implements KeyBundleRemoteDataSource {}

class _FakeEncryptedPayload extends Fake implements EncryptedPayload {}

class _FakeLocalMessagesCompanion extends Fake implements LocalMessagesCompanion {}

class _FakeKeyBundle extends Fake implements KeyBundle {}

class _FakeSendMessageParams extends Fake implements SendMessageParams {}

void main() {
  late _MockChatRemoteDataSource remote;
  late _MockChatLocalDataSource local;
  late _MockEncryptionService encryption;
  late _MockKeyBundleRemoteDataSource keyBundle;
  late ChatRepositoryImpl repository;

  const tPairId = 'pair-id';
  const tSenderId = 'user-a';
  const tPartnerId = 'user-b';
  const tText = 'Hello!';

  const tPayload = EncryptedPayload(
    ciphertext: 'ciphertext',
    header: 'header',
    messageIndex: 0,
    messageType: 'prekey',
  );

  final tRow = {
    'id': 'msg-server-id',
    'pair_id': tPairId,
    'sender_id': tSenderId,
    'message_type': 'text',
    'ciphertext': 'ciphertext',
    'signal_header': 'header',
    'message_index': 0,
    'signal_type': 'prekey',
    'status': 'sent',
    'sent_at': DateTime(2024).toIso8601String(),
  };

  setUp(() {
    remote = _MockChatRemoteDataSource();
    local = _MockChatLocalDataSource();
    encryption = _MockEncryptionService();
    keyBundle = _MockKeyBundleRemoteDataSource();

    registerFallbackValue(_FakeEncryptedPayload());
    registerFallbackValue(_FakeLocalMessagesCompanion());
    registerFallbackValue(_FakeKeyBundle());
    registerFallbackValue(_FakeSendMessageParams());

    repository = ChatRepositoryImpl(
      remote: remote,
      local: local,
      encryption: encryption,
      keyBundleRemote: keyBundle,
      ownUserId: tSenderId,
    );
  });

  group('sendMessage', () {
    const tParams = SendMessageParams(
      pairId: tPairId,
      senderId: tSenderId,
      partnerId: tPartnerId,
      text: tText,
    );

    test('encrypts, posts to server, stores locally, returns Right(Message)',
        () async {
      when(() => encryption.hasSession(tPairId)).thenReturn(true);
      when(() => encryption.encrypt(pairId: tPairId, plaintext: tText))
          .thenAnswer((_) async => const Right(tPayload));
      when(() => remote.insertMessage(
            pairId: tPairId,
            senderId: tSenderId,
            payload: any(named: 'payload'),
          )).thenAnswer((_) async => tRow);
      when(() => local.upsertMessage(any())).thenAnswer((_) async {});

      final result = await repository.sendMessage(tParams);

      expect(result.isRight(), isTrue);
      final msg = result.getOrElse((_) => throw Exception());
      expect(msg.pairId, tPairId);
      expect(msg.senderId, tSenderId);
      expect(msg.text, tText);
      expect(msg.status, MessageStatus.sent);

      verify(() => encryption.encrypt(pairId: tPairId, plaintext: tText))
          .called(1);
      verify(() => remote.insertMessage(
            pairId: tPairId,
            senderId: tSenderId,
            payload: any(named: 'payload'),
          )).called(1);
      verify(() => local.upsertMessage(any())).called(1);
    });

    test('initializes session via X3DH if hasSession returns false', () async {
      const tBundle = KeyBundle(
        userId: tPartnerId,
        identityKey: 'ik',
        identitySigningKey: 'isk',
        signedPreKey: 'spk',
        signedPreKeySignature: 'sig',
        signedPreKeyId: 1,
      );

      when(() => encryption.hasSession(tPairId)).thenReturn(false);
      when(() => keyBundle.fetchPartnerKeyBundle(tPartnerId))
          .thenAnswer((_) async => tBundle);
      when(() => encryption.initializeSession(
            pairId: tPairId,
            partnerBundle: any(named: 'partnerBundle'),
          )).thenAnswer((_) async => const Right(null));
      when(() => encryption.encrypt(pairId: tPairId, plaintext: tText))
          .thenAnswer((_) async => const Right(tPayload));
      when(() => remote.insertMessage(
            pairId: any(named: 'pairId'),
            senderId: any(named: 'senderId'),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async => tRow);
      when(() => local.upsertMessage(any())).thenAnswer((_) async {});

      final result = await repository.sendMessage(tParams);

      expect(result.isRight(), isTrue);
      verify(() => keyBundle.fetchPartnerKeyBundle(tPartnerId)).called(1);
      verify(() => encryption.initializeSession(
            pairId: tPairId,
            partnerBundle: any(named: 'partnerBundle'),
          )).called(1);
    });

    test('returns Left when encryption fails', () async {
      when(() => encryption.hasSession(tPairId)).thenReturn(true);
      when(() => encryption.encrypt(pairId: tPairId, plaintext: tText))
          .thenAnswer(
            (_) async => const Left(EncryptionFailure.decryptionFailed()),
          );

      final result = await repository.sendMessage(tParams);

      expect(result.isLeft(), isTrue);
      verifyNever(() => remote.insertMessage(
            pairId: any(named: 'pairId'),
            senderId: any(named: 'senderId'),
            payload: any(named: 'payload'),
          ));
    });
  });

  group('watchMessages', () {
    test('emits Right(reversed messages) from local data source', () async {
      final now = DateTime(2024);
      final tRows = [
        LocalMessage(
          id: 'msg-2',
          pairId: tPairId,
          senderId: tSenderId,
          contentType: 'text',
          decryptedText: 'Second',
          status: 'sent',
          createdAt: now.add(const Duration(minutes: 1)),
          updatedAt: now,
          isDeleted: false,
        ),
        LocalMessage(
          id: 'msg-1',
          pairId: tPairId,
          senderId: tPartnerId,
          contentType: 'text',
          decryptedText: 'First',
          status: 'delivered',
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
        ),
      ];

      // Local data source returns newest-first; repository reverses to oldest-first.
      when(() => local.watchMessages(tPairId, limit: any(named: 'limit')))
          .thenAnswer((_) => Stream.value(tRows));

      final result = await repository.watchMessages(tPairId).first;

      expect(result.isRight(), isTrue);
      final messages = result.getOrElse((_) => []);
      expect(messages.length, 2);
      // After reversal: oldest first
      expect(messages.first.id, 'msg-1');
      expect(messages.last.id, 'msg-2');
    });
  });
}
