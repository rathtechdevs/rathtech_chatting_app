import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/encryption/encryption_service.dart';
import 'package:rathtech_chatting_app/core/encryption/models/encrypted_payload.dart';
import 'package:rathtech_chatting_app/core/encryption/models/key_bundle.dart';
import 'package:rathtech_chatting_app/core/encryption/remote/key_bundle_remote_data_source.dart';
import 'package:rathtech_chatting_app/core/error/exceptions.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/core/media/media_cache_service.dart';
import 'package:rathtech_chatting_app/core/network/connectivity_service.dart';
import 'package:rathtech_chatting_app/core/offline/outbox_queue_data_source.dart';
import 'package:rathtech_chatting_app/core/storage/app_database.dart';
import 'package:rathtech_chatting_app/features/chat/data/data_sources/local/chat_local_data_source.dart';
import 'package:rathtech_chatting_app/features/chat/data/data_sources/remote/chat_remote_data_source.dart';
import 'package:rathtech_chatting_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:rathtech_chatting_app/features/chat/domain/entities/message.dart';
import 'package:rathtech_chatting_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:rathtech_chatting_app/features/media/data/data_sources/media_remote_data_source.dart';

class _MockChatRemoteDataSource extends Mock implements ChatRemoteDataSource {}

class _MockChatLocalDataSource extends Mock implements ChatLocalDataSource {}

class _MockEncryptionService extends Mock implements EncryptionService {}

class _MockKeyBundleRemoteDataSource extends Mock
    implements KeyBundleRemoteDataSource {}

class _MockMediaRemoteDataSource extends Mock implements MediaRemoteDataSource {}

class _MockMediaCacheService extends Mock implements MediaCacheService {}

class _MockConnectivityService extends Mock implements ConnectivityService {}

class _MockOutboxQueueDataSource extends Mock
    implements OutboxQueueDataSource {}

class _FakeEncryptedPayload extends Fake implements EncryptedPayload {}

class _FakeLocalMessagesCompanion extends Fake implements LocalMessagesCompanion {}

class _FakeOutboxQueueCompanion extends Fake implements OutboxQueueCompanion {}

class _FakeKeyBundle extends Fake implements KeyBundle {}

class _FakeSendMessageParams extends Fake implements SendMessageParams {}

class _FakeSendMediaParams extends Fake implements SendMediaParams {}

void main() {
  late _MockChatRemoteDataSource remote;
  late _MockChatLocalDataSource local;
  late _MockEncryptionService encryption;
  late _MockKeyBundleRemoteDataSource keyBundle;
  late _MockMediaRemoteDataSource mediaRemote;
  late _MockMediaCacheService mediaCache;
  late _MockConnectivityService connectivity;
  late _MockOutboxQueueDataSource outbox;
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
    mediaRemote = _MockMediaRemoteDataSource();
    mediaCache = _MockMediaCacheService();
    connectivity = _MockConnectivityService();
    outbox = _MockOutboxQueueDataSource();

    registerFallbackValue(_FakeEncryptedPayload());
    registerFallbackValue(_FakeLocalMessagesCompanion());
    registerFallbackValue(_FakeOutboxQueueCompanion());
    registerFallbackValue(_FakeKeyBundle());
    registerFallbackValue(_FakeSendMessageParams());
    registerFallbackValue(_FakeSendMediaParams());
    registerFallbackValue(Uint8List(0));

    repository = ChatRepositoryImpl(
      remote: remote,
      local: local,
      encryption: encryption,
      keyBundleRemote: keyBundle,
      mediaRemote: mediaRemote,
      mediaCache: mediaCache,
      outboxQueue: outbox,
      connectivity: connectivity,
      ownUserId: tSenderId,
    );
  });

  group('sendMessage (online)', () {
    const tParams = SendMessageParams(
      pairId: tPairId,
      senderId: tSenderId,
      partnerId: tPartnerId,
      text: tText,
    );

    test('encrypts, posts to server, updates status to sent, returns Right(Message)',
        () async {
      when(() => encryption.hasSession(tPairId)).thenReturn(true);
      when(() => encryption.encrypt(pairId: tPairId, plaintext: tText))
          .thenAnswer((_) async => const Right(tPayload));
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(() => local.upsertMessage(any())).thenAnswer((_) async {});
      when(() => local.updateStatus(any(), any())).thenAnswer((_) async {});
      when(() => remote.insertMessage(
            id: any(named: 'id'),
            pairId: tPairId,
            senderId: tSenderId,
            payload: any(named: 'payload'),
          )).thenAnswer((_) async => tRow);

      final result = await repository.sendMessage(tParams);

      expect(result.isRight(), isTrue);
      final msg = result.getOrElse((_) => throw Exception());
      expect(msg.pairId, tPairId);
      expect(msg.senderId, tSenderId);
      expect(msg.text, tText);
      expect(msg.status, MessageStatus.sent);

      verify(() => local.upsertMessage(any())).called(1);
      verify(() => remote.insertMessage(
            id: any(named: 'id'),
            pairId: tPairId,
            senderId: tSenderId,
            payload: any(named: 'payload'),
          )).called(1);
      verify(() => local.updateStatus(any(), 'sent')).called(1);
      verifyNever(() => outbox.enqueue(any()));
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
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(() => local.upsertMessage(any())).thenAnswer((_) async {});
      when(() => local.updateStatus(any(), any())).thenAnswer((_) async {});
      when(() => remote.insertMessage(
            id: any(named: 'id'),
            pairId: any(named: 'pairId'),
            senderId: any(named: 'senderId'),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async => tRow);

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
            id: any(named: 'id'),
            pairId: any(named: 'pairId'),
            senderId: any(named: 'senderId'),
            payload: any(named: 'payload'),
          ));
    });
  });

  group('sendMessage (offline)', () {
    const tParams = SendMessageParams(
      pairId: tPairId,
      senderId: tSenderId,
      partnerId: tPartnerId,
      text: tText,
    );

    test(
        'stores locally with pending status, enqueues in outbox, '
        'returns Right(Message) with pending status', () async {
      when(() => encryption.hasSession(tPairId)).thenReturn(true);
      when(() => encryption.encrypt(pairId: tPairId, plaintext: tText))
          .thenAnswer((_) async => const Right(tPayload));
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      when(() => local.upsertMessage(any())).thenAnswer((_) async {});
      when(() => outbox.enqueue(any())).thenAnswer((_) async {});

      final result = await repository.sendMessage(tParams);

      expect(result.isRight(), isTrue);
      final msg = result.getOrElse((_) => throw Exception());
      expect(msg.status, MessageStatus.pending);
      expect(msg.text, tText);

      verify(() => local.upsertMessage(any())).called(1);
      verify(() => outbox.enqueue(any())).called(1);
      verifyNever(() => remote.insertMessage(
            id: any(named: 'id'),
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

  group('sendMediaMessage', () {
    late File tMediaFile;

    final tKey = Uint8List.fromList(List.generate(32, (i) => i));
    final tIv = Uint8List.fromList(List.generate(12, (i) => i + 100));
    final tEncryptedData = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);

    final tMediaRow = {
      'id': 'media-id',
      'pair_id': tPairId,
      'sender_id': tSenderId,
      'message_type': 'image',
      'ciphertext': 'ciphertext',
      'signal_header': 'header',
      'message_index': 0,
      'signal_type': 'prekey',
      'status': 'sent',
      'sent_at': DateTime(2024).toIso8601String(),
      'media_storage_path': '$tPairId/media-id.bin',
    };

    setUp(() async {
      tMediaFile = File(
        '${Directory.systemTemp.path}/test_m6_${DateTime.now().microsecondsSinceEpoch}.bin',
      );
      await tMediaFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);
    });

    tearDown(() async {
      if (tMediaFile.existsSync()) await tMediaFile.delete();
    });

    void stubEncryptMedia() {
      when(() => encryption.encryptMedia(any())).thenAnswer(
        (_) async => Right((
          encryptedData: tEncryptedData,
          key: tKey,
          iv: tIv,
        )),
      );
    }

    test(
        'encrypts media, uploads to storage, inserts message row, '
        'stores locally, returns Right(Message)', () async {
      when(() => encryption.hasSession(tPairId)).thenReturn(true);
      stubEncryptMedia();
      when(() => encryption.encrypt(
            pairId: tPairId,
            plaintext: any(named: 'plaintext'),
          )).thenAnswer((_) async => const Right(tPayload));
      when(() => mediaRemote.upload(
            storagePath: any(named: 'storagePath'),
            bytes: any(named: 'bytes'),
          )).thenAnswer((_) async {});
      when(() => remote.insertMediaMessage(
            id: any(named: 'id'),
            pairId: tPairId,
            senderId: tSenderId,
            contentType: 'image',
            payload: any(named: 'payload'),
            storagePath: any(named: 'storagePath'),
          )).thenAnswer((_) async => tMediaRow);
      when(() => local.upsertMessage(any())).thenAnswer((_) async {});

      final result = await repository.sendMediaMessage(SendMediaParams(
        pairId: tPairId,
        senderId: tSenderId,
        partnerId: tPartnerId,
        contentType: 'image',
        localFilePath: tMediaFile.path,
      ));

      expect(result.isRight(), isTrue);
      final msg = result.getOrElse((_) => throw Exception());
      expect(msg.contentType, 'image');
      expect(msg.status, MessageStatus.sent);
      expect(msg.mediaLocalPath, tMediaFile.path);

      verify(() => encryption.encryptMedia(any())).called(1);
      verify(() => mediaRemote.upload(
            storagePath: any(named: 'storagePath'),
            bytes: any(named: 'bytes'),
          )).called(1);
      verify(() => remote.insertMediaMessage(
            id: any(named: 'id'),
            pairId: tPairId,
            senderId: tSenderId,
            contentType: 'image',
            payload: any(named: 'payload'),
            storagePath: any(named: 'storagePath'),
          )).called(1);
      verify(() => local.upsertMessage(any())).called(1);
    });

    test('returns Left when media encryption fails', () async {
      when(() => encryption.hasSession(tPairId)).thenReturn(true);
      when(() => encryption.encryptMedia(any())).thenAnswer(
        (_) async => const Left(EncryptionFailure.decryptionFailed()),
      );

      final result = await repository.sendMediaMessage(SendMediaParams(
        pairId: tPairId,
        senderId: tSenderId,
        partnerId: tPartnerId,
        contentType: 'image',
        localFilePath: tMediaFile.path,
      ));

      expect(result.isLeft(), isTrue);
      verifyNever(() => mediaRemote.upload(
            storagePath: any(named: 'storagePath'),
            bytes: any(named: 'bytes'),
          ));
    });

    test('returns Left(ServerFailure) when storage upload throws', () async {
      when(() => encryption.hasSession(tPairId)).thenReturn(true);
      stubEncryptMedia();
      when(() => encryption.encrypt(
            pairId: tPairId,
            plaintext: any(named: 'plaintext'),
          )).thenAnswer((_) async => const Right(tPayload));
      when(() => mediaRemote.upload(
            storagePath: any(named: 'storagePath'),
            bytes: any(named: 'bytes'),
          )).thenThrow(const ServerException(message: 'upload failed'));

      final result = await repository.sendMediaMessage(SendMediaParams(
        pairId: tPairId,
        senderId: tSenderId,
        partnerId: tPartnerId,
        contentType: 'image',
        localFilePath: tMediaFile.path,
      ));

      expect(result.isLeft(), isTrue);
      verifyNever(() => remote.insertMediaMessage(
            id: any(named: 'id'),
            pairId: any(named: 'pairId'),
            senderId: any(named: 'senderId'),
            contentType: any(named: 'contentType'),
            payload: any(named: 'payload'),
            storagePath: any(named: 'storagePath'),
          ));
    });

    test('passes durationMs and returns voice message on success', () async {
      late File voiceFile;
      voiceFile = File(
        '${Directory.systemTemp.path}/test_voice_${DateTime.now().microsecondsSinceEpoch}.m4a',
      );
      await voiceFile.writeAsBytes([0x00, 0x00, 0x00, 0x20]);
      addTearDown(() async {
        if (voiceFile.existsSync()) await voiceFile.delete();
      });

      const tDurationMs = 5000;
      final tVoiceRow = {
        ...tMediaRow,
        'message_type': 'voice',
        'media_duration_ms': tDurationMs,
      };

      when(() => encryption.hasSession(tPairId)).thenReturn(true);
      stubEncryptMedia();
      when(() => encryption.encrypt(
            pairId: tPairId,
            plaintext: any(named: 'plaintext'),
          )).thenAnswer((_) async => const Right(tPayload));
      when(() => mediaRemote.upload(
            storagePath: any(named: 'storagePath'),
            bytes: any(named: 'bytes'),
          )).thenAnswer((_) async {});
      when(() => remote.insertMediaMessage(
            id: any(named: 'id'),
            pairId: tPairId,
            senderId: tSenderId,
            contentType: 'voice',
            payload: any(named: 'payload'),
            storagePath: any(named: 'storagePath'),
            durationMs: tDurationMs,
          )).thenAnswer((_) async => tVoiceRow);
      when(() => local.upsertMessage(any())).thenAnswer((_) async {});

      final result = await repository.sendMediaMessage(SendMediaParams(
        pairId: tPairId,
        senderId: tSenderId,
        partnerId: tPartnerId,
        contentType: 'voice',
        localFilePath: voiceFile.path,
        durationMs: tDurationMs,
      ));

      expect(result.isRight(), isTrue);
      final msg = result.getOrElse((_) => throw Exception());
      expect(msg.contentType, 'voice');
      expect(msg.mediaDurationMs, tDurationMs);

      verify(() => remote.insertMediaMessage(
            id: any(named: 'id'),
            pairId: tPairId,
            senderId: tSenderId,
            contentType: 'voice',
            payload: any(named: 'payload'),
            storagePath: any(named: 'storagePath'),
            durationMs: tDurationMs,
          )).called(1);
    });
  });
}
