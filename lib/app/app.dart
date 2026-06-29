import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/app_lock/presentation/screens/app_lock_screen.dart';
import '../features/app_lock/presentation/viewmodels/app_lock_status.dart';
import '../features/app_lock/providers.dart' as app_lock;
import '../features/notifications/providers.dart';
import '../features/profile/providers.dart' as profile_providers;
import 'providers.dart';
import 'router.dart';

class SecureChatApp extends ConsumerWidget {
  const SecureChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final appLockStatus = ref.watch(app_lock.appLockStatusProvider);

    // Keep background services active for the lifetime of the app.
    ref.watch(notificationLifecycleProvider);
    ref.watch(profile_providers.presenceLifecycleProvider);
    ref.watch(app_lock.appLockLifecycleProvider);

    return MaterialApp.router(
      title: 'SecureChat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        if (appLockStatus == AppLockStatus.locked) {
          return const AppLockScreen();
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
