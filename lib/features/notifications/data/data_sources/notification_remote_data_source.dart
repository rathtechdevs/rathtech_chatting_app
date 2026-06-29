import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';

abstract interface class NotificationRemoteDataSource {
  Future<void> saveToken({required String userId, required String token});
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  const NotificationRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<void> saveToken({
    required String userId,
    required String token,
  }) async {
    try {
      await _client
          .from('user_profiles')
          .update({'fcm_token': token})
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
