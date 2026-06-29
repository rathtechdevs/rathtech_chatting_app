import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/encryption/encryption_service.dart';
import '../../../../core/encryption/models/encrypted_payload.dart';
import '../../../../core/encryption/remote/key_bundle_remote_data_source.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/media/media_cache_service.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/offline/outbox_queue_data_source.dart';
import '../../../../core/storage/app_database.dart';
import '../../../../features/media/data/data_sources/media_remote_data_source.dart';
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
    required this.mediaRemote,
    required this.mediaCache,
    required this.outboxQueue,
    required this.connectivity,
    required this.ownUserId,
  });

  final ChatRemoteDataSource remote;
  final ChatLocalDataSource local;
  final EncryptionService encryption;
  final KeyBundleRemoteDataSource keyBundleRemote;
  final MediaRemoteDataSource mediaRemote;
  final MediaCacheService mediaCache;
  final OutboxQueueDataSource outboxQueue;
  final ConnectivityService connectivity;
  final String ownUserId;

  static const int _maxOutboxAttempts = 10;

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
          final localId = _generateUuid();
          final now = DateTime.now().toUtc();

          // Store locally first — message appears immediately in the UI.
          await local.upsertMessage(MessageDto.toCompanion(
            id: localId,
            pairId: params.pairId,
            senderId: params.senderId,
            contentType: 'text',
            status: 'pending',
            createdAt: now,
            decryptedText: params.text,
          ));

          final isOnline = await connectivity.isOnline;

          if (!isOnline) {
            // Queue for delivery when connectivity restores.
            await outboxQueue.enqueue(OutboxQueueCompanion.insert(
              id: localId,
              pairId: params.pairId,
              encryptedPayload: Uint8List.fromList(
                utf8.encode(jsonEncode(payload.toJson())),
              ),
              messageType: 'text',
              createdAt: now,
              nextRetryAt: now,
            ));

            return Right(Message(
              id: localId,
              pairId: params.pairId,
              senderId: params.senderId,
              contentType: 'text',
              text: params.text,
              status: MessageStatus.pending,
              createdAt: now,
            ));
          }

          // Online — send immediately.
          final row = await remote.insertMessage(
            id: localId,
            pairId: params.pairId,
            senderId: params.senderId,
            payload: payload,
          );

          await local.updateStatus(localId, 'sent');

          final sentAt = DateTime.tryParse(row['sent_at'] as String? ?? '') ?? now;
          return Right(Message(
            id: localId,
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
          final id = row['id'] as String;
          final senderId = row['sender_id'] as String;
          final contentType = row['message_type'] as String? ?? 'text';
          final sentAt = DateTime.parse(row['sent_at'] as String);

          if (contentType == 'text') {
            final payload = _payloadFromRow(row);
            final decryptResult = await encryption.decrypt(
              pairId: params.pairId,
              payload: payload,
            );
            final text = decryptResult.getOrElse((_) => '[Decryption failed]');

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
          } else {
            // Media message — store metadata without re-downloading.
            // If already cached locally (from Realtime), the upsert
            // uses Value.absent() for paths so the cached version is preserved.
            final durationMs = row['media_duration_ms'] as int?;
            final storagePath = row['media_storage_path'] as String?;

            await local.upsertMessage(MessageDto.toCompanion(
              id: id,
              pairId: params.pairId,
              senderId: senderId,
              contentType: contentType,
              status: 'delivered',
              createdAt: sentAt,
              decryptedText: durationMs?.toString(),
              mediaStorageUrl: storagePath,
              // mediaLocalPath intentionally absent → preserves cached value
            ));

            messages.add(Message(
              id: id,
              pairId: params.pairId,
              senderId: senderId,
              contentType: contentType,
              mediaDurationMs: durationMs,
              mediaStorageUrl: storagePath,
              status: MessageStatus.delivered,
              createdAt: sentAt,
            ));
          }
        } catch (e, stack) {
          AppLogger.error('loadMoreMessages: failed to process row', e, stack);
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

    // Channel (re-)subscribe → gap fill + outbox flush.
    _subs['subscribe_$pairId'] =
        remote.channelSubscribeEvents(pairId).listen((_) async {
      await _fillGap(pairId);
      await _flushOutbox(pairId);
    });

    // New messages (INSERT)
    _subs['new_$pairId'] = remote.newMessages(pairId).listen(
      (row) async {
        final senderId = row['sender_id'] as String;
        if (senderId == ownUserId) return; // Already stored locally on send.
        try {
          final contentType = row['message_type'] as String? ?? 'text';
          final id = row['id'] as String;
          final sentAt = DateTime.parse(row['sent_at'] as String);

          if (contentType == 'text') {
            final payload = _payloadFromRow(row);
            final decryptResult = await encryption.decrypt(
              pairId: pairId,
              payload: payload,
            );
            final text = decryptResult.getOrElse((_) => '[Decryption failed]');

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
          } else {
            await _processIncomingMediaMessage(pairId: pairId, row: row);
          }
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
            // Re-decrypt the edited ciphertext (text messages only).
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
    await _subs.remove('subscribe_$pairId')?.cancel();
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

  // ── M6: Media messages ────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Message>> sendMediaMessage(
    SendMediaParams params,
  ) async {
    try {
      await _ensureSession(params.pairId, params.partnerId);

      // Read and (for images) compress the media file.
      Uint8List mediaBytes = await File(params.localFilePath).readAsBytes();
      if (params.contentType == 'image') {
        try {
          final compressed = await FlutterImageCompress.compressWithList(
            mediaBytes,
            quality: 80,
            minWidth: 1080,
          );
          mediaBytes = compressed;
        } catch (e) {
          AppLogger.warning('Image compression failed, using original: $e');
        }
      }

      // AES-256-GCM encrypt the media bytes.
      final encryptMediaResult = await encryption.encryptMedia(mediaBytes);
      return await encryptMediaResult.fold(
        Left.new,
        (encrypted) async {
          // Encode key + IV as a dot-separated base64 string and encrypt
          // it using the Signal Double Ratchet, so the partner can retrieve
          // the media key without it ever being stored in plaintext.
          final keyString =
              '${base64.encode(encrypted.key)}.${base64.encode(encrypted.iv)}';
          final payloadResult = await encryption.encrypt(
            pairId: params.pairId,
            plaintext: keyString,
          );

          return payloadResult.fold(
            Left.new,
            (payload) async {
              // Pre-generate a UUID so the storage path and message ID match.
              final localId = _generateUuid();
              final storagePath = '${params.pairId}/$localId.bin';

              // Upload first — if it fails, no message row is inserted.
              await mediaRemote.upload(
                storagePath: storagePath,
                bytes: encrypted.encryptedData,
              );

              // Insert the message row with the pre-generated ID.
              final row = await remote.insertMediaMessage(
                id: localId,
                pairId: params.pairId,
                senderId: params.senderId,
                contentType: params.contentType,
                payload: payload,
                storagePath: storagePath,
                durationMs: params.durationMs,
              );

              final sentAt = DateTime.parse(row['sent_at'] as String);

              // Store locally with the original file as the local path
              // (sender already has the file; no need to decrypt it back).
              await local.upsertMessage(MessageDto.toCompanion(
                id: localId,
                pairId: params.pairId,
                senderId: params.senderId,
                contentType: params.contentType,
                status: 'sent',
                createdAt: sentAt,
                decryptedText: params.durationMs?.toString(),
                mediaLocalPath: params.localFilePath,
                mediaStorageUrl: storagePath,
              ));

              return Right(Message(
                id: localId,
                pairId: params.pairId,
                senderId: params.senderId,
                contentType: params.contentType,
                mediaDurationMs: params.durationMs,
                mediaLocalPath: params.localFilePath,
                mediaStorageUrl: storagePath,
                status: MessageStatus.sent,
                createdAt: sentAt,
              ));
            },
          );
        },
      );
    } on ServerException catch (e) {
      AppLogger.error('sendMediaMessage server error', e);
      return Left(ServerFailure.server(e.message));
    } catch (e, stack) {
      AppLogger.error('sendMediaMessage unexpected error', e, stack);
      return const Left(UnknownFailure());
    }
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    final keys = _subs.keys.toList();
    for (final key in keys) {
      await _subs.remove(key)?.cancel();
    }
    final pairIds = keys
        .map((k) => k.split('_').skip(1).join('_'))
        .toSet();
    for (final pairId in pairIds) {
      await remote.removeChannel(pairId);
    }
  }

  // ── Offline: gap fill ─────────────────────────────────────────────────────

  Future<void> _fillGap(String pairId) async {
    try {
      final latest = await local.getLatestMessage(pairId);
      if (latest == null) return; // No local messages — nothing to fill.

      final rows = await remote.fetchMessagesSince(
        pairId: pairId,
        since: latest.createdAt,
        limit: 100,
      );

      for (final row in rows) {
        try {
          final senderId = row['sender_id'] as String;
          if (senderId == ownUserId) continue; // Own messages already stored.

          final contentType = row['message_type'] as String? ?? 'text';
          final id = row['id'] as String;
          final sentAt = DateTime.parse(row['sent_at'] as String);

          if (contentType == 'text') {
            final payload = _payloadFromRow(row);
            final decryptResult = await encryption.decrypt(
              pairId: pairId,
              payload: payload,
            );
            final text = decryptResult.getOrElse((_) => '[Decryption failed]');

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
          } else {
            await _processIncomingMediaMessage(pairId: pairId, row: row);
          }
        } catch (e, stack) {
          AppLogger.error('_fillGap: failed to process row', e, stack);
        }
      }
    } catch (e, stack) {
      AppLogger.error('_fillGap failed for $pairId', e, stack);
    }
  }

  // ── Offline: outbox flush ─────────────────────────────────────────────────

  Future<void> _flushOutbox(String pairId) async {
    final now = DateTime.now().toUtc();
    final items = await outboxQueue.getPendingDue(now);

    for (final item in items) {
      if (item.pairId != pairId) continue;

      // If the message was already confirmed (e.g., via a prior flush attempt
      // that partially succeeded), skip re-sending to avoid duplicates.
      final existing = await local.getMessageById(item.id);
      if (existing != null &&
          existing.status != 'pending' &&
          existing.status != 'failed') {
        await outboxQueue.remove(item.id);
        continue;
      }

      try {
        final payloadJson =
            jsonDecode(utf8.decode(item.encryptedPayload)) as Map<String, dynamic>;
        final payload = EncryptedPayload.fromJson(payloadJson);

        final row = await remote.insertMessage(
          id: item.id,
          pairId: item.pairId,
          senderId: ownUserId,
          payload: payload,
        );

        final sentAt =
            DateTime.tryParse(row['sent_at'] as String? ?? '') ?? now;
        await local.upsertMessage(MessageDto.toCompanion(
          id: item.id,
          pairId: item.pairId,
          senderId: ownUserId,
          contentType: item.messageType,
          status: 'sent',
          createdAt: sentAt,
        ));

        await outboxQueue.remove(item.id);
      } on ServerException catch (e) {
        AppLogger.error('_flushOutbox: server error for ${item.id}', e);

        final newCount = item.attemptCount + 1;
        if (newCount >= _maxOutboxAttempts) {
          await outboxQueue.markFailed(item.id);
          await local.updateStatus(item.id, 'failed');
        } else {
          final nextRetry = now.add(_retryDelay(newCount));
          await outboxQueue.updateRetry(
            id: item.id,
            newAttemptCount: newCount,
            nextRetryAt: nextRetry,
          );
        }
      } catch (e, stack) {
        AppLogger.error(
            '_flushOutbox: unexpected error for ${item.id}', e, stack);
      }
    }
  }

  static Duration _retryDelay(int attemptCount) {
    return switch (attemptCount) {
      0 => Duration.zero,
      1 => const Duration(seconds: 5),
      2 => const Duration(seconds: 30),
      _ => const Duration(minutes: 5),
    };
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

  Future<void> _processIncomingMediaMessage({
    required String pairId,
    required Map<String, dynamic> row,
  }) async {
    final id = row['id'] as String;
    final senderId = row['sender_id'] as String;
    final contentType = row['message_type'] as String;
    final sentAt = DateTime.parse(row['sent_at'] as String);
    final storagePath = row['media_storage_path'] as String? ?? '';
    final durationMs = row['media_duration_ms'] as int?;

    if (storagePath.isEmpty) {
      AppLogger.warning('Received media message $id with no storage path');
      return;
    }

    // Decrypt the media key string via Signal.
    final payload = _payloadFromRow(row);
    final decryptResult = await encryption.decrypt(
      pairId: pairId,
      payload: payload,
    );
    if (decryptResult.isLeft()) {
      AppLogger.error('Failed to decrypt media key for message $id');
      return;
    }
    final keyString = decryptResult.getOrElse((_) => '');

    final keyParts = keyString.split('.');
    if (keyParts.length != 2) {
      AppLogger.error('Invalid media key format for message $id');
      return;
    }

    try {
      final key = Uint8List.fromList(base64.decode(keyParts[0]));
      final iv = Uint8List.fromList(base64.decode(keyParts[1]));

      final encryptedBytes = await mediaRemote.download(storagePath);

      final decryptMediaResult = await encryption.decryptMedia(
        encryptedData: encryptedBytes,
        key: key,
        iv: iv,
      );

      final plainBytes = decryptMediaResult.getOrElse((_) => Uint8List(0));
      if (plainBytes.isEmpty) {
        AppLogger.error('Media decryption returned empty bytes for $id');
        return;
      }

      final localPath = await mediaCache.save(
        messageId: id,
        contentType: contentType,
        bytes: plainBytes,
      );

      await local.upsertMessage(MessageDto.toCompanion(
        id: id,
        pairId: pairId,
        senderId: senderId,
        contentType: contentType,
        status: 'delivered',
        createdAt: sentAt,
        decryptedText: durationMs?.toString(),
        mediaLocalPath: localPath,
        mediaStorageUrl: storagePath,
      ));

      await remote.markDelivered(id);
    } catch (e, stack) {
      AppLogger.error('Failed to download/decrypt media $id', e, stack);
      // Store without local path so a placeholder is shown.
      await local.upsertMessage(MessageDto.toCompanion(
        id: id,
        pairId: pairId,
        senderId: senderId,
        contentType: contentType,
        status: 'delivered',
        createdAt: sentAt,
        decryptedText: durationMs?.toString(),
        mediaStorageUrl: storagePath,
      ));
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

  // RFC 4122 version-4 UUID generated from cryptographic random bytes.
  static String _generateUuid() {
    final rng = Random.secure();
    final b = List<int>.generate(16, (_) => rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
