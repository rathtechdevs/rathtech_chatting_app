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
          RadioGroup<ThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (v) => notifier.setThemeMode(v!),
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text(AppStrings.settingsThemeSystem),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(AppStrings.settingsThemeLight),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(AppStrings.settingsThemeDark),
                  value: ThemeMode.dark,
                ),
              ],
            ),
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
          RadioGroup<int>(
            groupValue: settings.disappearingMessageHours,
            onChanged: (v) => notifier.setDisappearingMessageHours(v!),
            child: const Column(
              children: [
                RadioListTile<int>(
                  title: Text(AppStrings.settingsOff),
                  value: 0,
                ),
                RadioListTile<int>(
                  title: Text(AppStrings.settings24h),
                  value: 24,
                ),
                RadioListTile<int>(
                  title: Text(AppStrings.settings7d),
                  value: 168,
                ),
                RadioListTile<int>(
                  title: Text(AppStrings.settings30d),
                  value: 720,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
