import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/providers.dart';

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    Future<void> signOut() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Sign out?'),
          content: const Text(
            'You will be signed out of SecureChat on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign out'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await ref.read(logoutUseCaseProvider).execute();
      // GoRouter redirect handles navigation to /login once auth state clears.
    }

    Future<void> deleteAccount() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(AppStrings.settingsDeleteAccountConfirmTitle),
          content: const Text(AppStrings.settingsDeleteAccountConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: const Text(AppStrings.delete),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      // Full account deletion (FEAT-020) is not yet implemented.
      // Sign out as a safe fallback — server-side data remains.
      await ref.read(logoutUseCaseProvider).execute();
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsAccount)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_rounded),
            title: const Text('My Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.myProfile),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Sign out'),
            onTap: signOut,
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever_rounded,
              color: theme.colorScheme.error,
            ),
            title: Text(
              AppStrings.settingsDeleteAccount,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: deleteAccount,
          ),
        ],
      ),
    );
  }
}
