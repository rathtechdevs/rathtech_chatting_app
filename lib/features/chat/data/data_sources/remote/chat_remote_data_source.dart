import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/encryption/models/encrypted_payload.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/logger/app_logger.dart';

abstract interface class ChatRemoteDataSource {
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

  Stream<Map<String, dynamic>> watchIncomingMessages(String pairId);

  Future<void> markDelivered(String messageId);

  Future<void> removeChannel(String pairId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  ChatRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;
  final Map<String, RealtimeChannel> _channels = {};

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
  Stream<Map<String, dynamic>> watchIncomingMessages(String pairId) {
    if (_channels.containsKey(pairId)) {
      _channels[pairId]!.unsubscribe();
    }

    late RealtimeChannel channel;
    final controller = StreamController<Map<String, dynamic>>();

    channel = _client
        .channel('messages_$pairId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'pair_id',
            value: pairId,
          ),
          callback: (payload) {
            if (!controller.isClosed) {
              controller.add(payload.newRecord);
            }
          },
        )
        .subscribe();

    _channels[pairId] = channel;

    controller.onCancel = () async {
      await channel.unsubscribe();
      _channels.remove(pairId);
      await controller.close();
    };

    return controller.stream;
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
  Future<void> removeChannel(String pairId) async {
    final channel = _channels.remove(pairId);
    if (channel != null) {
      await channel.unsubscribe();
    }
  }
}
