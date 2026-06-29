import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/notifications/providers.dart';
import 'providers.dart';
import 'router.dart';

class SecureChatApp extends ConsumerWidget {
  const SecureChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Keep the notification lifecycle active for the lifetime of the app.
    // Watching (not just reading) ensures Riverpod rebuilds when userId changes.
    ref.watch(notificationLifecycleProvider);

    return MaterialApp.router(
      title: 'SecureChat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
