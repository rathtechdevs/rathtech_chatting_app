import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/error/exceptions.dart' as app_exceptions;
import '../../../../../core/logger/app_logger.dart';

abstract class ProfileRemoteDataSource {
  Future<Map<String, dynamic>> createProfile({
    required String userId,
    required String displayName,
    DateTime? dateOfBirth,
  });

  Future<Map<String, dynamic>?> getProfile(String userId);

  Future<bool> hasProfile(String userId);

  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String displayName,
  });

  /// Compresses, uploads to the avatars bucket, updates user_profiles.avatar_url,
  /// and returns the public avatar URL.
  Future<String> uploadAvatar({
    required String userId,
    required String localFilePath,
  });

  Stream<Map<String, dynamic>?> watchProfile(String userId);

  Future<void> upsertPresence({
    required String userId,
    required bool isOnline,
  });

  Stream<Map<String, dynamic>?> watchPresence(String userId);
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
      throw app_exceptions.ServerException(message: e.message);
    } catch (e, stack) {
      AppLogger.error('createProfile failed', e, stack);
      throw const app_exceptions.ServerException(
          message: 'Failed to create profile.');
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
      throw app_exceptions.ServerException(message: e.message);
    } catch (e, stack) {
      AppLogger.error('getProfile failed', e, stack);
      throw const app_exceptions.ServerException(
          message: 'Failed to fetch profile.');
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

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String displayName,
  }) async {
    try {
      final result = await _client
          .from('user_profiles')
          .update({'display_name': displayName})
          .eq('id', userId)
          .select()
          .single();
      return result;
    } on PostgrestException catch (e) {
      AppLogger.error('updateProfile DB error', e);
      throw app_exceptions.ServerException(message: e.message);
    } catch (e, stack) {
      AppLogger.error('updateProfile failed', e, stack);
      throw const app_exceptions.ServerException(
          message: 'Failed to update profile.');
    }
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required String localFilePath,
  }) async {
    try {
      final originalBytes = await File(localFilePath).readAsBytes();

      Uint8List imageBytes;
      try {
        imageBytes = await FlutterImageCompress.compressWithList(
          originalBytes,
          quality: 80,
          minWidth: 256,
          minHeight: 256,
        );
      } catch (_) {
        imageBytes = originalBytes;
      }

      final objectPath = '$userId.jpg';
      await _client.storage.from('avatars').uploadBinary(
            objectPath,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl =
          _client.storage.from('avatars').getPublicUrl(objectPath);

      await _client
          .from('user_profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', userId);

      return publicUrl;
    } on PostgrestException catch (e) {
      AppLogger.error('uploadAvatar DB error', e);
      throw app_exceptions.ServerException(message: e.message);
    } catch (e, stack) {
      AppLogger.error('uploadAvatar failed', e, stack);
      throw const app_exceptions.ServerException(
          message: 'Failed to upload avatar.');
    }
  }

  @override
  Stream<Map<String, dynamic>?> watchProfile(String userId) {
    return _client
        .from('user_profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  @override
  Future<void> upsertPresence({
    required String userId,
    required bool isOnline,
  }) async {
    try {
      await _client.from('user_presence').upsert({
        'user_id': userId,
        'is_online': isOnline,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      AppLogger.error('upsertPresence DB error', e);
      throw app_exceptions.ServerException(message: e.message);
    } catch (e, stack) {
      AppLogger.error('upsertPresence failed', e, stack);
      throw const app_exceptions.ServerException(
          message: 'Failed to update presence.');
    }
  }

  @override
  Stream<Map<String, dynamic>?> watchPresence(String userId) {
    return _client
        .from('user_presence')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((rows) => rows.isEmpty ? null : rows.first);
  }
}
