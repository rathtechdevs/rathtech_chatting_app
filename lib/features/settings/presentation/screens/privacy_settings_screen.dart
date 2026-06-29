import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../viewmodels/settings_notifier.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsPrivacy)),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text(AppStrings.settingsReadReceipts),
            subtitle: const Text('Let your partner know when you read messages'),
            value: settings.readReceipts,
            onChanged: notifier.setReadReceipts,
          ),
          SwitchListTile(
            title: const Text(AppStrings.settingsTypingIndicator),
            subtitle:
                const Text('Let your partner know when you are typing'),
            value: settings.typingIndicator,
            onChanged: notifier.setTypingIndicator,
          ),
        ],
      ),
    );
  }
}
