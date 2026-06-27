import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../../core/constants/storage_keys.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/logger/app_logger.dart';
import '../../dtos/session_dto.dart';

abstract class AuthSecureDataSource {
  Future<void> saveSession(SessionDto dto);

  Future<SessionDto?> getSession();

  Future<void> deleteSession();

  Future<void> deleteAll();
}

class AuthSecureDataSourceImpl implements AuthSecureDataSource {
  const AuthSecureDataSourceImpl(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveSession(SessionDto dto) async {
    try {
      await _storage.write(key: StorageKeys.accessToken, value: dto.accessToken);
      await _storage.write(
        key: StorageKeys.refreshToken,
        value: dto.refreshToken,
      );
      await _storage.write(key: StorageKeys.userId, value: dto.userId);
    } catch (e, stack) {
      AppLogger.error('saveSession failed', e, stack);
      throw const CacheException(message: 'Failed to persist session.');
    }
  }

  @override
  Future<SessionDto?> getSession() async {
    try {
      final access = await _storage.read(key: StorageKeys.accessToken);
      final refresh = await _storage.read(key: StorageKeys.refreshToken);
      final userId = await _storage.read(key: StorageKeys.userId);

      if (access == null || refresh == null || userId == null) return null;

      return SessionDto(
        accessToken: access,
        refreshToken: refresh,
        expiresAt: 0,
        userId: userId,
      );
    } catch (e, stack) {
      AppLogger.error('getSession failed', e, stack);
      return null;
    }
  }

  @override
  Future<void> deleteSession() async {
    try {
      await _storage.delete(key: StorageKeys.accessToken);
      await _storage.delete(key: StorageKeys.refreshToken);
      await _storage.delete(key: StorageKeys.userId);
    } catch (e, stack) {
      AppLogger.error('deleteSession failed', e, stack);
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e, stack) {
      AppLogger.error('deleteAll failed', e, stack);
    }
  }
}
