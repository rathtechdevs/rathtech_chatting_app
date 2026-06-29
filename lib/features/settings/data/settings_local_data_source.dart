import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/storage_keys.dart';
import '../domain/entities/user_settings.dart';

class SettingsLocalDataSource {
  const SettingsLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  UserSettings read() {
    final themeModeIndex =
        _prefs.getInt(StorageKeys.settingsThemeMode) ?? ThemeMode.system.index;
    return UserSettings(
      themeMode: ThemeMode.values[themeModeIndex.clamp(0, 2)],
      muteNotifications:
          _prefs.getBool(StorageKeys.settingsMuteNotifications) ?? false,
      showNotificationPreview:
          _prefs.getBool(StorageKeys.settingsShowNotificationPreview) ?? true,
      readReceipts: _prefs.getBool(StorageKeys.settingsReadReceipts) ?? true,
      typingIndicator:
          _prefs.getBool(StorageKeys.settingsTypingIndicator) ?? true,
      disappearingMessageHours:
          _prefs.getInt(StorageKeys.settingsDisappearingMessageHours) ?? 0,
    );
  }

  Future<void> save(UserSettings settings) async {
    await Future.wait([
      _prefs.setInt(StorageKeys.settingsThemeMode, settings.themeMode.index),
      _prefs.setBool(
          StorageKeys.settingsMuteNotifications, settings.muteNotifications),
      _prefs.setBool(StorageKeys.settingsShowNotificationPreview,
          settings.showNotificationPreview),
      _prefs.setBool(StorageKeys.settingsReadReceipts, settings.readReceipts),
      _prefs.setBool(
          StorageKeys.settingsTypingIndicator, settings.typingIndicator),
      _prefs.setInt(StorageKeys.settingsDisappearingMessageHours,
          settings.disappearingMessageHours),
    ]);
  }
}
