import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/shared_prefs_provider.dart';
import '../../data/settings_local_data_source.dart';
import '../../domain/entities/user_settings.dart';

class SettingsNotifier extends Notifier<UserSettings> {
  SettingsLocalDataSource get _ds =>
      SettingsLocalDataSource(ref.read(sharedPrefsProvider));

  @override
  UserSettings build() => _ds.read();

  Future<void> _update(UserSettings settings) async {
    state = settings;
    await _ds.save(settings);
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _update(state.copyWith(themeMode: mode));

  Future<void> setMuteNotifications(bool value) =>
      _update(state.copyWith(muteNotifications: value));

  Future<void> setShowNotificationPreview(bool value) =>
      _update(state.copyWith(showNotificationPreview: value));

  Future<void> setReadReceipts(bool value) =>
      _update(state.copyWith(readReceipts: value));

  Future<void> setTypingIndicator(bool value) =>
      _update(state.copyWith(typingIndicator: value));

  Future<void> setDisappearingMessageHours(int hours) =>
      _update(state.copyWith(disappearingMessageHours: hours));
}

// Standalone provider so screens can import this file directly without
// the circular import that would arise from importing providers.dart here.
final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, UserSettings>(SettingsNotifier.new);
