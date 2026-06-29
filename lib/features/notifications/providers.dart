import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/supabase_client_provider.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/notifications/notification_service_impl.dart';
import '../auth/providers.dart';
import 'data/data_sources/notification_remote_data_source.dart';
import 'data/repositories/notification_repository_impl.dart';
import 'domain/repositories/notification_repository.dart';
import 'domain/use_cases/initialize_notifications_use_case.dart';
import 'domain/use_cases/update_notification_token_use_case.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationServiceImpl(
    messaging: FirebaseMessaging.instance,
    localNotifications: FlutterLocalNotificationsPlugin(),
  );
});

// ── Data sources ──────────────────────────────────────────────────────────────

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

// ── Repository ────────────────────────────────────────────────────────────────

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    service: ref.watch(notificationServiceProvider),
    remoteDataSource: ref.watch(notificationRemoteDataSourceProvider),
  );
});

// ── Use cases ─────────────────────────────────────────────────────────────────

final initializeNotificationsUseCaseProvider =
    Provider<InitializeNotificationsUseCase>((ref) {
  return InitializeNotificationsUseCase(
    ref.watch(notificationRepositoryProvider),
    ref.watch(notificationServiceProvider),
  );
});

final updateNotificationTokenUseCaseProvider =
    Provider<UpdateNotificationTokenUseCase>((ref) {
  return UpdateNotificationTokenUseCase(
    ref.watch(notificationRepositoryProvider),
  );
});

// ── Lifecycle notifier ────────────────────────────────────────────────────────
//
// Watches the authenticated user and, when one is present:
//   1. Initialises local notifications and FCM.
//   2. Registers the FCM token with Supabase.
//   3. Refreshes the token whenever FCM rotates it.
//   4. Forwards foreground messages to the local notification system.

final notificationLifecycleProvider =
    AsyncNotifierProvider<_NotificationLifecycleNotifier, void>(
  _NotificationLifecycleNotifier.new,
);

class _NotificationLifecycleNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return;

    final service = ref.read(notificationServiceProvider);
    final repo = ref.read(notificationRepositoryProvider);

    await service.initialize();

    // Register token — failures are logged but do not surface to the UI.
    await ref
        .read(initializeNotificationsUseCaseProvider)
        .execute(userId)
        .then(
          (result) => result.fold(
            (failure) => null, // permission denied or server error — non-fatal
            (_) => null,
          ),
        );

    // Re-register whenever FCM rotates the token.
    final tokenSub = repo.onTokenRefresh.listen((token) {
      ref
          .read(updateNotificationTokenUseCaseProvider)
          .execute(userId: userId, token: token);
    });
    ref.onDispose(tokenSub.cancel);

    // Show local notification banner for foreground messages.
    final msgSub = repo.onForegroundMessage.listen((message) {
      service.showLocalNotification(message);
    });
    ref.onDispose(msgSub.cancel);
  }
}
