import 'package:flutter/material.dart';

class UserSettings {
  const UserSettings({
    this.themeMode = ThemeMode.system,
    this.muteNotifications = false,
    this.showNotificationPreview = true,
    this.readReceipts = true,
    this.typingIndicator = true,
    this.disappearingMessageHours = 0,
  });

  final ThemeMode themeMode;
  final bool muteNotifications;
  final bool showNotificationPreview;
  final bool readReceipts;
  final bool typingIndicator;

  // 0 = off, 24 = 24 hours, 168 = 7 days, 720 = 30 days
  final int disappearingMessageHours;

  static const defaults = UserSettings();

  UserSettings copyWith({
    ThemeMode? themeMode,
    bool? muteNotifications,
    bool? showNotificationPreview,
    bool? readReceipts,
    bool? typingIndicator,
    int? disappearingMessageHours,
  }) {
    return UserSettings(
      themeMode: themeMode ?? this.themeMode,
      muteNotifications: muteNotifications ?? this.muteNotifications,
      showNotificationPreview:
          showNotificationPreview ?? this.showNotificationPreview,
      readReceipts: readReceipts ?? this.readReceipts,
      typingIndicator: typingIndicator ?? this.typingIndicator,
      disappearingMessageHours:
          disappearingMessageHours ?? this.disappearingMessageHours,
    );
  }
}
