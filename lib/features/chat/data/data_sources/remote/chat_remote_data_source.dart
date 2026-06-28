import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/encryption/models/encrypted_payload.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/logger/app_logger.dart';

// ── Typedef ────────────────────────────────────────────────────────────────────

typedef ReactionEvent = ({Map<String, dynamic> record, bool isAdded});

// ── Interface ─────────────────────────────────────────────────────────────────

abstract interface class ChatRemoteDataSource {
  // ── CRUD ───────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> insertMessage({
    required String pairId,
    required String senderId,
    required EncryptedPayload payload,
  });

  Future<List<Map<String, dynamic>>> fetchMessagesBefore({
    required String pairId,
    required DateTime before,
    required int limit,
  });

  Future<void> markDelivered(String messageId);
  Future<void> markAllRead({required String pairId, required String readerId});

  Future<void> editMessage({
    required String messageId,
    required EncryptedPayload payload,
  });

  Future<void> deleteMessage(String messageId);

  Future<void> reactToMessage({
    required String messageId,
    required String userId,
    required String emoji,
  });

  Future<void> removeReaction({
    required String messageId,
    required String userId,
  });

  // ── Realtime (single channel per pair) ────────────────────────────────────

  void startListening(String pairId);

  /// INSERT events on `messages` for this pair.
  Stream<Map<String, dynamic>> newMessages(String pairId);

  /// UPDATE events on `messages` for this pair (status, edit, delete).
  Stream<Map<String, dynamic>> messageUpdates(String pairId);

  /// INSERT/DELETE events on `message_reactions` for this pair.
  Stream<ReactionEvent> reactionEvents(String pairId);

  /// Broadcast typing state from the partner.
  Stream<bool> typingEvents(String pairId);

  Future<void> sendTyping(String pairId, {required bool isTyping});

  Future<void> removeChannel(String pairId);
}

// ── Implementation ────────────────────────────────────────────────────────────

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  ChatRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  // One RealtimeChannel per pair.
  final Map<String, RealtimeChannel> _channels = {};

  // Per-pair StreamControllers stored directly in class-level maps so the
  // linter can confirm they are closed in removeChannel / dispose.
  final Map<String, StreamController<Map<String, dynamic>>> _newMsgCtrls = {};
  final Map<String, StreamController<Map<String, dynamic>>> _updateCtrls = {};
  final Map<String, StreamController<ReactionEvent>> _reactionCtrls = {};
  final Map<String, StreamController<bool>> _typingCtrls = {};

  // ── CRUD ─────────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> insertMessage({
    required String pairId,
    required String senderId,
    required EncryptedPayload payload,
  }) async {
    try {
      final rows = await _client.from('messages').insert({
        'pair_id': pairId,
        'sender_id': senderId,
        'message_type': 'text',
        'ciphertext': payload.ciphertext,
        'signal_header': payload.header,
        'message_index': payload.messageIndex,
        'signal_type': payload.messageType,
      }).select();
      return rows.first;
    } on PostgrestException catch (e) {
      AppLogger.error('insertMessage failed', e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? ''),
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMessagesBefore({
    required String pairId,
    required DateTime before,
    required int limit,
  }) async {
    try {
      final rows = await _client
          .from('messages')
          .select()
          .eq('pair_id', pairId)
          .lt('sent_at', before.toIso8601String())
          .order('sent_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(rows);
    } on PostgrestException catch (e) {
      AppLogger.error('fetchMessagesBefore failed', e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? ''),
      );
    }
  }

  @override
  Future<void> markDelivered(String messageId) async {
    try {
      await _client
          .from('messages')
          .update({'status': 'delivered'})
          .eq('id', messageId);
    } on PostgrestException catch (e) {
      AppLogger.error('markDelivered failed', e);
    }
  }

  @override
  Future<void> markAllRead({
    required String pairId,
    required String readerId,
  }) async {
    try {
      await _client
          .from('messages')
          .update({'status': 'read'})
          .eq('pair_id', pairId)
          .neq('sender_id', readerId)
          .inFilter('status', ['sent', 'delivered']);
    } on PostgrestException catch (e) {
      AppLogger.error('markAllRead failed', e);
    }
  }

  @override
  Future<void> editMessage({
    required String messageId,
    required EncryptedPayload payload,
  }) async {
    try {
      await _client.from('messages').update({
        'ciphertext': payload.ciphertext,
        'signal_header': payload.header,
        'message_index': payload.messageIndex,
        'signal_type': payload.messageType,
        'edited_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', messageId);
    } on PostgrestException catch (e) {
      AppLogger.error('editMessage failed', e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? ''),
      );
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      await _client.from('messages').update({
        'status': 'deleted',
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', messageId);
    } on PostgrestException catch (e) {
      AppLogger.error('deleteMessage failed', e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? ''),
      );
    }
  }

  @override
  Future<void> reactToMessage({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      await _client.from('message_reactions').upsert({
        'message_id': messageId,
        'user_id': userId,
        'emoji': emoji,
      }, onConflict: 'message_id,user_id');
    } on PostgrestException catch (e) {
      AppLogger.error('reactToMessage failed', e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? ''),
      );
    }
  }

  @override
  Future<void> removeReaction({
    required String messageId,
    required String userId,
  }) async {
    try {
      await _client
          .from('message_reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      AppLogger.error('removeReaction failed', e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? ''),
      );
    }
  }

  // ── Realtime ──────────────────────────────────────────────────────────────

  @override
  void startListening(String pairId) {
    if (_channels.containsKey(pairId)) return;

    // Local vars are captured by channel callbacks AND by onCancel (which
    // calls .close()). The linter sees .close() and does not flag these as
    // unclosed sinks. They are also stored in the class-level maps so that
    // removeChannel() can close them if onCancel never fires (e.g., no subscriber).
    final newMsgCtrl = StreamController<Map<String, dynamic>>();
    newMsgCtrl.onCancel = () async {
      if (!newMsgCtrl.isClosed) await newMsgCtrl.close();
    };
    _newMsgCtrls[pairId] = newMsgCtrl;

    final updateCtrl = StreamController<Map<String, dynamic>>();
    updateCtrl.onCancel = () async {
      if (!updateCtrl.isClosed) await updateCtrl.close();
    };
    _updateCtrls[pairId] = updateCtrl;

    final reactionCtrl = StreamController<ReactionEvent>();
    reactionCtrl.onCancel = () async {
      if (!reactionCtrl.isClosed) await reactionCtrl.close();
    };
    _reactionCtrls[pairId] = reactionCtrl;

    final typingCtrl = StreamController<bool>();
    typingCtrl.onCancel = () async {
      if (!typingCtrl.isClosed) await typingCtrl.close();
    };
    _typingCtrls[pairId] = typingCtrl;

    _channels[pairId] = _client
        .channel('chat_$pairId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'pair_id',
            value: pairId,
          ),
          callback: (p) {
            if (!newMsgCtrl.isClosed) newMsgCtrl.add(p.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'pair_id',
            value: pairId,
          ),
          callback: (p) {
            if (!updateCtrl.isClosed) updateCtrl.add(p.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'message_reactions',
          callback: (p) {
            if (!reactionCtrl.isClosed) {
              reactionCtrl.add((record: p.newRecord, isAdded: true));
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'message_reactions',
          callback: (p) {
            if (!reactionCtrl.isClosed) {
              reactionCtrl.add((record: p.oldRecord, isAdded: false));
            }
          },
        )
        .onBroadcast(
          event: 'typing',
          callback: (p) {
            final isTyping = (p['typing'] as bool?) ?? false;
            if (!typingCtrl.isClosed) typingCtrl.add(isTyping);
          },
        )
        .subscribe();
  }

  @override
  Stream<Map<String, dynamic>> newMessages(String pairId) =>
      _newMsgCtrls[pairId]?.stream ?? const Stream.empty();

  @override
  Stream<Map<String, dynamic>> messageUpdates(String pairId) =>
      _updateCtrls[pairId]?.stream ?? const Stream.empty();

  @override
  Stream<ReactionEvent> reactionEvents(String pairId) =>
      _reactionCtrls[pairId]?.stream ?? const Stream.empty();

  @override
  Stream<bool> typingEvents(String pairId) =>
      _typingCtrls[pairId]?.stream ?? const Stream.empty();

  @override
  Future<void> sendTyping(String pairId, {required bool isTyping}) async {
    try {
      await _channels[pairId]?.sendBroadcastMessage(
        event: 'typing',
        payload: {'typing': isTyping},
      );
    } catch (e) {
      AppLogger.error('sendTyping failed', e);
    }
  }

  @override
  Future<void> removeChannel(String pairId) async {
    await _channels.remove(pairId)?.unsubscribe();
    await _newMsgCtrls.remove(pairId)?.close();
    await _updateCtrls.remove(pairId)?.close();
    await _reactionCtrls.remove(pairId)?.close();
    await _typingCtrls.remove(pairId)?.close();
  }
}
