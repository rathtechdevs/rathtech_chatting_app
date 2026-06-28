import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../../core/encryption/encryption_service.dart';
import '../../../../core/encryption/models/encrypted_payload.dart';
import '../../../../core/encryption/remote/key_bundle_remote_data_source.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logger/app_logger.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../data_sources/local/chat_local_data_source.dart';
import '../data_sources/remote/chat_remote_data_source.dart';
import '../dtos/message_dto.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required this.remote,
    required this.local,
    required this.encryption,
    required this.keyBundleRemote,
    required this.ownUserId,
  });

  final ChatRemoteDataSource remote;
  final ChatLocalDataSource local;
  final EncryptionService encryption;
  final KeyBundleRemoteDataSource keyBundleRemote;
  final String ownUserId;

  final Map<String, StreamSubscription<Map<String, dynamic>>> _realtimeSubs =
      {};

  @override
  Future<Either<Failure, Message>> sendMessage(
    SendMessageParams params,
  ) async {
    try {
      await _ensureSession(params.pairId, params.partnerId);

      final encryptResult = await encryption.encrypt(
        pairId: params.pairId,
        plaintext: params.text,
      );

      return encryptResult.fold(
        Left.new,
        (payload) async {
          final row = await remote.insertMessage(
            pairId: params.pairId,
            senderId: params.senderId,
            payload: payload,
          );

          final id = row['id'] as String;
          final sentAt = DateTime.parse(row['sent_at'] as String);
          final companion = MessageDto.toCompanion(
            id: id,
            pairId: params.pairId,
            senderId: params.senderId,
            contentType: 'text',
            status: 'sent',
            createdAt: sentAt,
            decryptedText: params.text,
          );
          await local.upsertMessage(companion);

          return Right(
            Message(
              id: id,
              pairId: params.pairId,
              senderId: params.senderId,
              contentType: 'text',
              text: params.text,
              status: MessageStatus.sent,
              createdAt: sentAt,
            ),
          );
        },
      );
    } on ServerException catch (e) {
      AppLogger.error('sendMessage server error', e);
      return Left(ServerFailure.server(e.message));
    } catch (e, stack) {
      AppLogger.error('sendMessage unexpected error', e, stack);
      return const Left(UnknownFailure());
    }
  }

  @override
  Stream<Either<Failure, List<Message>>> watchMessages(String pairId) {
    return local.watchMessages(pairId).map(
      (rows) => Right(rows.reversed.map(MessageDto.fromLocalMessage).toList()),
    );
  }

  @override
  Future<Either<Failure, List<Message>>> loadMoreMessages(
    LoadMoreParams params,
  ) async {
    try {
      final rows = await remote.fetchMessagesBefore(
        pairId: params.pairId,
        before: params.before,
        limit: params.limit,
      );

      final messages = <Message>[];

      for (final row in rows) {
        try {
          final payload = _payloadFromRow(row);
          final decryptResult = await encryption.decrypt(
            pairId: params.pairId,
            payload: payload,
          );
          final text = decryptResult.getOrElse((_) => '[Decryption failed]');
          final id = row['id'] as String;
          final senderId = row['sender_id'] as String;
          final sentAt = DateTime.parse(row['sent_at'] as String);

          await local.upsertMessage(MessageDto.toCompanion(
            id: id,
            pairId: params.pairId,
            senderId: senderId,
            contentType: 'text',
            status: 'delivered',
            createdAt: sentAt,
            decryptedText: text,
          ));

          messages.add(Message(
            id: id,
            pairId: params.pairId,
            senderId: senderId,
            contentType: 'text',
            text: text,
            status: MessageStatus.delivered,
            createdAt: sentAt,
          ));
        } catch (e, stack) {
          AppLogger.error('loadMoreMessages: failed to decrypt row', e, stack);
        }
      }

      return Right(messages.reversed.toList());
    } on ServerException catch (e) {
      return Left(ServerFailure.server(e.message));
    } catch (e, stack) {
      AppLogger.error('loadMoreMessages unexpected error', e, stack);
      return const Left(UnknownFailure());
    }
  }

  @override
  void startRealtimeListener(String pairId) {
    if (_realtimeSubs.containsKey(pairId)) return;

    _realtimeSubs[pairId] = remote.watchIncomingMessages(pairId).listen(
      (row) async {
        final senderId = row['sender_id'] as String;
        if (senderId == ownUserId) return; // Already stored locally when sent.

        try {
          final payload = _payloadFromRow(row);
          final decryptResult = await encryption.decrypt(
            pairId: pairId,
            payload: payload,
          );
          final text = decryptResult.getOrElse((_) => '[Decryption failed]');
          final id = row['id'] as String;
          final sentAt = DateTime.parse(row['sent_at'] as String);

          await local.upsertMessage(MessageDto.toCompanion(
            id: id,
            pairId: pairId,
            senderId: senderId,
            contentType: 'text',
            status: 'delivered',
            createdAt: sentAt,
            decryptedText: text,
          ));

          await remote.markDelivered(id);
        } catch (e, stack) {
          AppLogger.error('Realtime: failed to process incoming message', e, stack);
        }
      },
      onError: (Object e, StackTrace stack) {
        AppLogger.error('Realtime subscription error for $pairId', e, stack);
      },
    );
  }

  @override
  Future<void> stopRealtimeListener(String pairId) async {
    await _realtimeSubs.remove(pairId)?.cancel();
    await remote.removeChannel(pairId);
  }

  Future<void> dispose() async {
    for (final entry in _realtimeSubs.entries) {
      await entry.value.cancel();
      await remote.removeChannel(entry.key);
    }
    _realtimeSubs.clear();
  }

  // Ensures a Signal session exists for pairId; initializes via X3DH if needed.
  Future<void> _ensureSession(String pairId, String partnerId) async {
    if (encryption.hasSession(pairId)) return;

    final bundle = await keyBundleRemote.fetchPartnerKeyBundle(partnerId);
    final result = await encryption.initializeSession(
      pairId: pairId,
      partnerBundle: bundle,
    );
    result.fold(
      (f) => throw Exception(f.message),
      (_) {},
    );
  }

  static EncryptedPayload _payloadFromRow(Map<String, dynamic> row) {
    return EncryptedPayload(
      ciphertext: row['ciphertext'] as String,
      header: row['signal_header'] as String,
      messageIndex: row['message_index'] as int,
      messageType: row['signal_type'] as String,
    );
  }
}
