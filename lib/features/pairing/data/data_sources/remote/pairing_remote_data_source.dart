import 'dart:async';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/error/exceptions.dart';
import '../../../../../core/logger/app_logger.dart';

abstract interface class PairingRemoteDataSource {
  Future<Map<String, dynamic>> generateInviteCode({
    required String userId,
    required String code,
    required DateTime expiresAt,
  });

  Future<Map<String, dynamic>> acceptInviteCode(String code);

  Future<Map<String, dynamic>?> getCurrentPair(String userId);

  Stream<Map<String, dynamic>?> watchPairStatus(String userId);
}

class PairingRemoteDataSourceImpl implements PairingRemoteDataSource {
  PairingRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static final _rng = Random.secure();

  static String _generateCode(int length) => String.fromCharCodes(
        Iterable.generate(
          length,
          (_) => _chars.codeUnitAt(_rng.nextInt(_chars.length)),
        ),
      );

  @override
  Future<Map<String, dynamic>> generateInviteCode({
    required String userId,
    required String code,
    required DateTime expiresAt,
  }) async {
    try {
      final row = await _client
          .from('pair_invite_codes')
          .insert({
            'code': code,
            'creator_id': userId,
            'expires_at': expiresAt.toIso8601String(),
          })
          .select()
          .single();
      return row;
    } on PostgrestException catch (e) {
      AppLogger.error('generateInviteCode failed', e);
      throw ServerException(
          message: e.message, statusCode: int.tryParse(e.code ?? ''));
    }
  }

  @override
  Future<Map<String, dynamic>> acceptInviteCode(String code) async {
    try {
      final response = await _client.functions.invoke(
        'accept-invite-code',
        body: {'code': code.toUpperCase()},
      );
      if (response.status != 200) {
        final errorData = response.data as Map<String, dynamic>?;
        final message = errorData?['error'] as String? ?? 'Invite code error';
        throw ServerException(message: message, statusCode: response.status);
      }
      return response.data as Map<String, dynamic>;
    } on ServerException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('acceptInviteCode failed', e, stack);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>?> getCurrentPair(String userId) async {
    try {
      final rows = await _client
          .from('pairs')
          .select()
          .or('user_a_id.eq.$userId,user_b_id.eq.$userId')
          .limit(1);
      return rows.isEmpty ? null : rows.first;
    } on PostgrestException catch (e) {
      AppLogger.error('getCurrentPair failed', e);
      throw ServerException(
          message: e.message, statusCode: int.tryParse(e.code ?? ''));
    }
  }

  @override
  Stream<Map<String, dynamic>?> watchPairStatus(String userId) {
    final controller = StreamController<Map<String, dynamic>?>();

    Future<void> seed() async {
      try {
        final current = await getCurrentPair(userId);
        if (!controller.isClosed) controller.add(current);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    final channel = _client
        .channel('pair_status_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'pairs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_a_id',
            value: userId,
          ),
          callback: (payload) async {
            final row = payload.newRecord;
            if (!controller.isClosed) controller.add(row);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'pairs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_b_id',
            value: userId,
          ),
          callback: (payload) async {
            final row = payload.newRecord;
            if (!controller.isClosed) controller.add(row);
          },
        )
        .subscribe();

    seed();

    controller.onCancel = () async {
      await _client.removeChannel(channel);
      await controller.close();
    };

    return controller.stream;
  }

  // Exposes a fresh 8-char code for the data source layer.
  static String freshCode() => _generateCode(8);
}
