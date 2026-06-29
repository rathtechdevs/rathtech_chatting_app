import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rathtech_chatting_app/core/constants/storage_keys.dart';
import 'package:rathtech_chatting_app/features/settings/data/settings_local_data_source.dart';
import 'package:rathtech_chatting_app/features/settings/domain/entities/user_settings.dart';

void main() {
  group('SettingsLocalDataSource', () {
    late SharedPreferences prefs;
    late SettingsLocalDataSource sut;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      sut = SettingsLocalDataSource(prefs);
    });

    group('read()', () {
      test('returns defaults when SharedPreferences is empty', () {
        final result = sut.read();

        expect(result.themeMode, ThemeMode.system);
        expect(result.muteNotifications, isFalse);
        expect(result.showNotificationPreview, isTrue);
        expect(result.readReceipts, isTrue);
        expect(result.typingIndicator, isTrue);
        expect(result.disappearingMessageHours, 0);
      });

      test('reads ThemeMode.dark when index 2 is stored', () async {
        await prefs.setInt(StorageKeys.settingsThemeMode, ThemeMode.dark.index);

        final result = sut.read();

        expect(result.themeMode, ThemeMode.dark);
      });

      test('reads ThemeMode.light when index 1 is stored', () async {
        await prefs.setInt(
            StorageKeys.settingsThemeMode, ThemeMode.light.index);

        final result = sut.read();

        expect(result.themeMode, ThemeMode.light);
      });

      test('clamps out-of-range themeMode index to 0 (system)', () async {
        await prefs.setInt(StorageKeys.settingsThemeMode, 99);

        final result = sut.read();

        expect(result.themeMode, ThemeMode.dark);
      });

      test('reads stored boolean settings correctly', () async {
        await prefs.setBool(StorageKeys.settingsMuteNotifications, true);
        await prefs.setBool(
            StorageKeys.settingsShowNotificationPreview, false);
        await prefs.setBool(StorageKeys.settingsReadReceipts, false);
        await prefs.setBool(StorageKeys.settingsTypingIndicator, false);

        final result = sut.read();

        expect(result.muteNotifications, isTrue);
        expect(result.showNotificationPreview, isFalse);
        expect(result.readReceipts, isFalse);
        expect(result.typingIndicator, isFalse);
      });

      test('reads stored disappearingMessageHours', () async {
        await prefs.setInt(
            StorageKeys.settingsDisappearingMessageHours, 24);

        final result = sut.read();

        expect(result.disappearingMessageHours, 24);
      });
    });

    group('save()', () {
      test('persists all settings fields', () async {
        const settings = UserSettings(
          themeMode: ThemeMode.dark,
          muteNotifications: true,
          showNotificationPreview: false,
          readReceipts: false,
          typingIndicator: false,
          disappearingMessageHours: 168,
        );

        await sut.save(settings);
        final result = sut.read();

        expect(result.themeMode, ThemeMode.dark);
        expect(result.muteNotifications, isTrue);
        expect(result.showNotificationPreview, isFalse);
        expect(result.readReceipts, isFalse);
        expect(result.typingIndicator, isFalse);
        expect(result.disappearingMessageHours, 168);
      });

      test('overwriting a previously saved value is reflected in read()',
          () async {
        await sut.save(const UserSettings(themeMode: ThemeMode.dark));
        await sut.save(const UserSettings(themeMode: ThemeMode.light));

        final result = sut.read();

        expect(result.themeMode, ThemeMode.light);
      });
    });
  });
}
