import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../profile/presentation/viewmodels/profile_state.dart';
import '../../../profile/presentation/widgets/avatar_widget.dart';
import '../../../profile/providers.dart' as profile_providers;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profile_providers.profileViewModelProvider);
    final theme = Theme.of(context);

    final displayName = profileState is ProfileReady
        ? profileState.profile.displayName
        : '';
    final avatarUrl =
        profileState is ProfileReady ? profileState.profile.avatarUrl : null;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
      body: ListView(
        children: [
          // ── Profile banner ─────────────────────────────────────────────────
          InkWell(
            onTap: () => context.push(AppRoutes.myProfile),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  AvatarWidget(
                    avatarUrl: avatarUrl,
                    displayName: displayName,
                    radius: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName.isNotEmpty ? displayName : '—',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          'View profile',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // ── Section tiles ──────────────────────────────────────────────────
          _SettingsTile(
            icon: Icons.notifications_rounded,
            label: AppStrings.settingsNotifications,
            onTap: () => context.push(AppRoutes.notificationSettings),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_rounded,
            label: AppStrings.settingsPrivacy,
            onTap: () => context.push(AppRoutes.privacySettings),
          ),
          _SettingsTile(
            icon: Icons.shield_rounded,
            label: AppStrings.settingsSecurity,
            onTap: () => context.push(AppRoutes.securitySettings),
          ),
          _SettingsTile(
            icon: Icons.chat_bubble_rounded,
            label: AppStrings.settingsChat,
            onTap: () => context.push(AppRoutes.chatSettings),
          ),
          _SettingsTile(
            icon: Icons.manage_accounts_rounded,
            label: AppStrings.settingsAccount,
            onTap: () => context.push(AppRoutes.accountSettings),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
