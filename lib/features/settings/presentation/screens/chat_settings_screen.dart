import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../viewmodels/settings_notifier.dart';

class ChatSettingsScreen extends ConsumerWidget {
  const ChatSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsChat)),
      body: ListView(
        children: [
          // ── Theme ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              AppStrings.settingsTheme,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          RadioListTile<ThemeMode>(
            title: const Text(AppStrings.settingsThemeSystem),
            value: ThemeMode.system,
            groupValue: settings.themeMode,
            onChanged: (v) => notifier.setThemeMode(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text(AppStrings.settingsThemeLight),
            value: ThemeMode.light,
            groupValue: settings.themeMode,
            onChanged: (v) => notifier.setThemeMode(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text(AppStrings.settingsThemeDark),
            value: ThemeMode.dark,
            groupValue: settings.themeMode,
            onChanged: (v) => notifier.setThemeMode(v!),
          ),
          const Divider(),

          // ── Disappearing messages ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              AppStrings.settingsDisappearingMessages,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          RadioListTile<int>(
            title: const Text(AppStrings.settingsOff),
            value: 0,
            groupValue: settings.disappearingMessageHours,
            onChanged: (v) => notifier.setDisappearingMessageHours(v!),
          ),
          RadioListTile<int>(
            title: const Text(AppStrings.settings24h),
            value: 24,
            groupValue: settings.disappearingMessageHours,
            onChanged: (v) => notifier.setDisappearingMessageHours(v!),
          ),
          RadioListTile<int>(
            title: const Text(AppStrings.settings7d),
            value: 168,
            groupValue: settings.disappearingMessageHours,
            onChanged: (v) => notifier.setDisappearingMessageHours(v!),
          ),
          RadioListTile<int>(
            title: const Text(AppStrings.settings30d),
            value: 720,
            groupValue: settings.disappearingMessageHours,
            onChanged: (v) => notifier.setDisappearingMessageHours(v!),
          ),
        ],
      ),
    );
  }
}
