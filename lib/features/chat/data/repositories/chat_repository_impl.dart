import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../../core/encryption/encryption_service.dart';
import '../../../../core/encryption/models/encrypted_payload.dart';
import '../../../../core/encryption/remote/key_bundle_remote_data_source.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/storage/app_database.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/reaction.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/use_cases/edit_message_use_case.dart';
import '../../domain/use_cases/react_to_message_use_case.dart';
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

  // Subscriptions keyed by '<type>_<pairId>' to allow multiple per pair.
  final Map<String, StreamSubscription<dynamic>> _subs = {};

  // ── M4: Core messaging ────────────────────────────────────────────────────

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

          return Right(Message(
            id: id,
            pairId: params.pairId,
            senderId: params.senderId,
            contentType: 'text',
            text: params.text,
            status: MessageStatus.sent,
            createdAt: sentAt,
          ));
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
          (rows) =>
              Right(rows.reversed.map(MessageDto.fromLocalMessage).toList()),
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
    if (_subs.containsKey('new_$pairId')) return;

    remote.startListening(pairId);

    // New messages (INSERT)
    _subs['new_$pairId'] = remote.newMessages(pairId).listen(
      (row) async {
        final senderId = row['sender_id'] as String;
        if (senderId == ownUserId) return; // Already stored locally on send.
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
          AppLogger.error('Realtime: failed to process new message', e, stack);
        }
      },
      onError: (Object e, StackTrace s) {
        AppLogger.error('Realtime newMessages error for $pairId', e, s);
      },
    );

    // Status / edit / delete updates (UPDATE)
    _subs['update_$pairId'] = remote.messageUpdates(pairId).listen(
      (row) async {
        try {
          final id = row['id'] as String;
          final status = row['status'] as String? ?? 'sent';
          final isDeleted = status == 'deleted';
          final editedAt = row['edited_at'];

          if (isDeleted) {
            // Mark deleted locally.
            await local.upsertMessage(MessageDto.toCompanion(
              id: id,
              pairId: pairId,
              senderId: row['sender_id'] as String? ?? '',
              contentType: row['message_type'] as String? ?? 'text',
              status: 'delivered',
              createdAt: DateTime.parse(row['sent_at'] as String),
              isDeleted: true,
            ));
          } else if (editedAt != null) {
            // Re-decrypt the edited ciphertext.
            try {
              final payload = _payloadFromRow(row);
              final decryptResult = await encryption.decrypt(
                pairId: pairId,
                payload: payload,
              );
              final newText =
                  decryptResult.getOrElse((_) => '[Decryption failed]');
              await local.updateDecryptedText(id, newText);
            } catch (e, stack) {
              AppLogger.error(
                  'Realtime: failed to decrypt edited message', e, stack);
            }
          } else {
            // Status-only update (delivered/read) — update sender's local record.
            await local.updateStatus(id, status);
          }
        } catch (e, stack) {
          AppLogger.error('Realtime: failed to process message update', e, stack);
        }
      },
      onError: (Object e, StackTrace s) {
        AppLogger.error('Realtime messageUpdates error for $pairId', e, s);
      },
    );

    // Reaction events
    _subs['reaction_$pairId'] =
        remote.reactionEvents(pairId).listen((event) async {
      try {
        final record = event.record;
        final messageId = record['message_id'] as String? ?? '';
        final userId = record['user_id'] as String? ?? '';

        if (event.isAdded) {
          final id = record['id'] as String? ?? '';
          final emoji = record['emoji'] as String? ?? '';
          final createdAt = record['created_at'] as String?;

          await local.upsertReaction(LocalReactionsCompanion.insert(
            id: id,
            messageId: messageId,
            userId: userId,
            emoji: emoji,
            createdAt: createdAt != null
                ? DateTime.parse(createdAt)
                : DateTime.now(),
          ));
        } else {
          await local.deleteReaction(
            messageId: messageId,
            userId: userId,
          );
        }
      } catch (e, stack) {
        AppLogger.error('Realtime: failed to process reaction event', e, stack);
      }
    });
  }

  @override
  Future<void> stopRealtimeListener(String pairId) async {
    await _subs.remove('new_$pairId')?.cancel();
    await _subs.remove('update_$pairId')?.cancel();
    await _subs.remove('reaction_$pairId')?.cancel();
    await _subs.remove('typing_$pairId')?.cancel();
    await remote.removeChannel(pairId);
  }

  // ── M5: Message features ──────────────────────────────────────────────────

  @override
  Future<Either<Failure, Message>> editMessage(
    EditMessageParams params,
  ) async {
    try {
      final encryptResult = await encryption.encrypt(
        pairId: params.pairId,
        plaintext: params.newText,
      );

      return encryptResult.fold(
        Left.new,
        (payload) async {
          await remote.editMessage(
            messageId: params.messageId,
            payload: payload,
          );
          await local.updateDecryptedText(params.messageId, params.newText);

          // Return an updated message; the Drift stream will emit the updated row
          // but we return immediately so the ViewModel can track the edit.
          return Right(Message(
            id: params.messageId,
            pairId: params.pairId,
            senderId: ownUserId,
            contentType: 'text',
            text: params.newText,
            status: MessageStatus.sent,
            createdAt: params.originalCreatedAt,
          ));
        },
      );
    } on ServerException catch (e) {
      AppLogger.error('editMessage server error', e);
      return Left(ServerFailure.server(e.message));
    } catch (e, stack) {
      AppLogger.error('editMessage unexpected error', e, stack);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String messageId) async {
    try {
      await remote.deleteMessage(messageId);
      // Local update will arrive via the Realtime UPDATE subscription.
      return const Right(null);
    } on ServerException catch (e) {
      AppLogger.error('deleteMessage server error', e);
      return Left(ServerFailure.server(e.message));
    } catch (e, stack) {
      AppLogger.error('deleteMessage unexpected error', e, stack);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> reactToMessage(
    ReactToMessageParams params,
  ) async {
    try {
      await remote.reactToMessage(
        messageId: params.messageId,
        userId: ownUserId,
        emoji: params.emoji,
      );
      return const Right(null);
    } on ServerException catch (e) {
      AppLogger.error('reactToMessage server error', e);
      return Left(ServerFailure.server(e.message));
    } catch (e, stack) {
      AppLogger.error('reactToMessage unexpected error', e, stack);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> removeReaction({
    required String messageId,
    required String pairId,
  }) async {
    try {
      await remote.removeReaction(
        messageId: messageId,
        userId: ownUserId,
      );
      return const Right(null);
    } on ServerException catch (e) {
      AppLogger.error('removeReaction server error', e);
      return Left(ServerFailure.server(e.message));
    } catch (e, stack) {
      AppLogger.error('removeReaction unexpected error', e, stack);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> markAllRead(String pairId) async {
    try {
      await remote.markAllRead(pairId: pairId, readerId: ownUserId);
      // Also update local DB so the UI reflects read status immediately.
      await (_updateLocalStatusBatch(pairId));
      return const Right(null);
    } catch (e, stack) {
      AppLogger.error('markAllRead unexpected error', e, stack);
      return const Left(UnknownFailure());
    }
  }

  @override
  Stream<Map<String, List<Reaction>>> watchReactions(String pairId) {
    return local.watchReactions(pairId).map((rows) {
      final result = <String, List<Reaction>>{};
      for (final row in rows) {
        result.putIfAbsent(row.messageId, () => []).add(Reaction(
              id: row.id,
              messageId: row.messageId,
              userId: row.userId,
              emoji: row.emoji,
              createdAt: row.createdAt,
            ));
      }
      return result;
    });
  }

  @override
  Future<void> sendTyping(String pairId, {required bool isTyping}) =>
      remote.sendTyping(pairId, isTyping: isTyping);

  @override
  Stream<bool> watchTyping(String pairId) => remote.typingEvents(pairId);

  // ── Dispose ───────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    final keys = _subs.keys.toList();
    for (final key in keys) {
      await _subs.remove(key)?.cancel();
    }
    // Remove all channels — extract unique pairIds from keys.
    final pairIds = keys
        .map((k) => k.split('_').skip(1).join('_'))
        .toSet();
    for (final pairId in pairIds) {
      await remote.removeChannel(pairId);
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

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

  // Marks all partner messages in local DB as 'read' (best-effort, no rethrow).
  Future<void> _updateLocalStatusBatch(String pairId) async {
    try {
      final rows = await local.getMessagesBefore(
        pairId: pairId,
        before: DateTime.now().add(const Duration(hours: 1)),
        limit: 200,
      );
      for (final row in rows) {
        if (row.senderId != ownUserId &&
            (row.status == 'sent' || row.status == 'delivered')) {
          await local.updateStatus(row.id, 'read');
        }
      }
    } catch (e, stack) {
      AppLogger.error('_updateLocalStatusBatch failed', e, stack);
    }
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
