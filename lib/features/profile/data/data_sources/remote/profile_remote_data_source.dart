import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/error/exceptions.dart';
import '../../../../../core/logger/app_logger.dart';

abstract class ProfileRemoteDataSource {
  Future<Map<String, dynamic>> createProfile({
    required String userId,
    required String displayName,
    DateTime? dateOfBirth,
  });

  Future<Map<String, dynamic>?> getProfile(String userId);

  Future<bool> hasProfile(String userId);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> createProfile({
    required String userId,
    required String displayName,
    DateTime? dateOfBirth,
  }) async {
    try {
      final payload = <String, dynamic>{
        'id': userId,
        'display_name': displayName,
        if (dateOfBirth != null)
          'date_of_birth':
              '${dateOfBirth.year.toString().padLeft(4, '0')}-'
              '${dateOfBirth.month.toString().padLeft(2, '0')}-'
              '${dateOfBirth.day.toString().padLeft(2, '0')}',
      };
      final result = await _client
          .from('user_profiles')
          .insert(payload)
          .select()
          .single();
      return result;
    } on PostgrestException catch (e) {
      AppLogger.error('createProfile DB error', e);
      throw ServerException(message: e.message);
    } catch (e, stack) {
      AppLogger.error('createProfile failed', e, stack);
      throw const ServerException(message: 'Failed to create profile.');
    }
  }

  @override
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      return await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
    } on PostgrestException catch (e) {
      AppLogger.error('getProfile DB error', e);
      throw ServerException(message: e.message);
    } catch (e, stack) {
      AppLogger.error('getProfile failed', e, stack);
      throw const ServerException(message: 'Failed to fetch profile.');
    }
  }

  @override
  Future<bool> hasProfile(String userId) async {
    try {
      final result = await _client
          .from('user_profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      return result != null;
    } catch (e, stack) {
      AppLogger.error('hasProfile failed', e, stack);
      return false;
    }
  }
}
