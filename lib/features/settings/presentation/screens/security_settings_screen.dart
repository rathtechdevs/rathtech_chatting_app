import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../app_lock/domain/entities/auto_lock_duration.dart';
import '../../../app_lock/presentation/viewmodels/app_lock_status.dart';
import '../../../app_lock/providers.dart' as app_lock;

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockStatus = ref.watch(app_lock.appLockStatusProvider);
    final lockSettings = ref.watch(app_lock.appLockSettingsProvider);
    final isLockEnabled = lockStatus != AppLockStatus.disabled;
    final biometricAsync = ref.watch(app_lock.biometricAvailableProvider);
    final theme = Theme.of(context);

    Future<void> disableLock() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(AppStrings.appLockDisable),
          content: const Text('App lock will be removed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppStrings.appLockDisable,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await ref.read(app_lock.disableAppLockUseCaseProvider).execute();
      ref.read(app_lock.appLockStatusProvider.notifier).disable();
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsSecurity)),
      body: ListView(
        children: [
          // ── App Lock header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              AppStrings.appLockTitle,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          // Enable toggle
          SwitchListTile(
            title: Text(
              isLockEnabled
                  ? AppStrings.appLockDisable
                  : AppStrings.appLockEnablePin,
            ),
            value: isLockEnabled,
            onChanged: (enable) {
              if (enable) {
                context.push(AppRoutes.appLock);
              } else {
                disableLock();
              }
            },
          ),

          // Lock-enabled-only options
          if (isLockEnabled) ...[
            ListTile(
              title: const Text('Change PIN'),
              leading: const Icon(Icons.pin_rounded),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.appLock),
            ),
            ListTile(
              title: const Text(AppStrings.appLockAutoLock),
              leading: const Icon(Icons.timer_rounded),
              subtitle: Text(_durationLabel(lockSettings.autoLockDuration)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showAutoLockDialog(context, ref, lockSettings.autoLockDuration),
            ),
            biometricAsync.when(
              data: (available) => available
                  ? SwitchListTile(
                      title: const Text(AppStrings.appLockEnableBiometric),
                      secondary: const Icon(Icons.fingerprint_rounded),
                      value: lockSettings.isBiometricEnabled,
                      onChanged: (enabled) async {
                        final updated = lockSettings.copyWith(
                          isBiometricEnabled: enabled,
                        );
                        await ref
                            .read(app_lock.saveAppLockSettingsUseCaseProvider)
                            .execute(updated);
                      },
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }

  String _durationLabel(AutoLockDuration d) => switch (d) {
        AutoLockDuration.immediately => AppStrings.appLockImmediately,
        AutoLockDuration.after1min => AppStrings.appLockAfter1min,
        AutoLockDuration.after5min => AppStrings.appLockAfter5min,
        AutoLockDuration.after15min => AppStrings.appLockAfter15min,
      };

  Future<void> _showAutoLockDialog(
    BuildContext context,
    WidgetRef ref,
    AutoLockDuration current,
  ) async {
    final selected = await showDialog<AutoLockDuration>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text(AppStrings.appLockAutoLock),
        children: AutoLockDuration.values.map((d) {
          return RadioListTile<AutoLockDuration>(
            title: Text(_durationLabel(d)),
            value: d,
            groupValue: current,
            onChanged: (v) => Navigator.pop(context, v),
          );
        }).toList(),
      ),
    );
    if (selected == null) return;
    final lockSettings = ref.read(app_lock.appLockSettingsProvider);
    await ref
        .read(app_lock.saveAppLockSettingsUseCaseProvider)
        .execute(lockSettings.copyWith(autoLockDuration: selected));
  }
}
