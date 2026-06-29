import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../viewmodels/settings_notifier.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsNotifications)),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text(AppStrings.settingsMuteNotifications),
            value: settings.muteNotifications,
            onChanged: notifier.setMuteNotifications,
          ),
          SwitchListTile(
            title: const Text(AppStrings.settingsShowNotificationPreview),
            value: settings.showNotificationPreview,
            onChanged: settings.muteNotifications
                ? null
                : notifier.setShowNotificationPreview,
          ),
        ],
      ),
    );
  }
}
