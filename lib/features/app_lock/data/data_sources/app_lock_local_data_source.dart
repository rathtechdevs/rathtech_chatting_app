import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/app_lock_settings.dart';
import '../../domain/entities/auto_lock_duration.dart';

class AppLockLocalDataSource {
  const AppLockLocalDataSource(this._prefs, this._secureStorage);

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  AppLockSettings readSettings() {
    final lockType = _prefs.getString(StorageKeys.lockType);
    if (lockType == null) return AppLockSettings.disabled;
    final minutes = _prefs.getInt(StorageKeys.lockTimeoutMinutes) ?? 0;
    return AppLockSettings(
      isEnabled: true,
      isBiometricEnabled: lockType == 'biometric',
      autoLockDuration: AutoLockDuration.fromMinutes(minutes),
    );
  }

  Future<void> saveSettings(AppLockSettings settings) async {
    try {
      if (!settings.isEnabled) {
        await _prefs.remove(StorageKeys.lockType);
      } else {
        await _prefs.setString(
          StorageKeys.lockType,
          settings.isBiometricEnabled ? 'biometric' : 'pin',
        );
        await _prefs.setInt(
          StorageKeys.lockTimeoutMinutes,
          settings.autoLockDuration.minutes,
        );
      }
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  Future<void> setupPin(String pin) async {
    try {
      final random = Random.secure();
      final salt = List<int>.generate(16, (_) => random.nextInt(256));
      final saltHex = _toHex(salt);
      final hashResult =
          await Sha256().hash([...salt, ...utf8.encode(pin)]);
      final hashHex = _toHex(hashResult.bytes);
      await _secureStorage.write(key: StorageKeys.pinHash, value: hashHex);
      await _secureStorage.write(key: StorageKeys.pinSalt, value: saltHex);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  Future<bool> verifyPin(String pin) async {
    try {
      final storedHash =
          await _secureStorage.read(key: StorageKeys.pinHash);
      final storedSalt =
          await _secureStorage.read(key: StorageKeys.pinSalt);
      if (storedHash == null || storedSalt == null) return false;
      final salt = _fromHex(storedSalt);
      final hashResult =
          await Sha256().hash([...salt, ...utf8.encode(pin)]);
      return _toHex(hashResult.bytes) == storedHash;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearPin() async {
    try {
      await _secureStorage.delete(key: StorageKeys.pinHash);
      await _secureStorage.delete(key: StorageKeys.pinSalt);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  Future<bool> hasPin() async {
    final hash = await _secureStorage.read(key: StorageKeys.pinHash);
    return hash != null;
  }

  void recordBackgroundTimestamp() {
    _prefs.setInt(
      StorageKeys.lockBackgroundTs,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  int readBackgroundTimestamp() =>
      _prefs.getInt(StorageKeys.lockBackgroundTs) ?? 0;

  String _toHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  List<int> _fromHex(String hex) => [
        for (int i = 0; i < hex.length; i += 2)
          int.parse(hex.substring(i, i + 2), radix: 16),
      ];
}
