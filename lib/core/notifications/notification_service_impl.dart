import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_channel.dart';
import 'notification_service.dart';

// Top-level background message handler — must be a top-level function and
// annotated so the Dart VM preserves it when tree-shaking.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage _) async {
  // FCM automatically displays the notification banner for notification
  // messages when the app is in the background or terminated.
  // Data-only messages can be processed here if needed in a future iteration.
}

class NotificationServiceImpl implements NotificationService {
  NotificationServiceImpl({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  static const _androidDetails = AndroidNotificationDetails(
    NotificationChannel.messageChannelId,
    NotificationChannel.messageChannelName,
    channelDescription: NotificationChannel.messageChannelDesc,
    importance: Importance.high,
    priority: Priority.high,
  );

  // Use platform defaults for iOS — presentAlert/Badge/Sound default to true.
  static const _iosDetails = DarwinNotificationDetails();

  static const _notificationDetails = NotificationDetails(
    android: _androidDetails,
    iOS: _iosDetails,
  );

  @override
  Future<void> initialize() async {
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            NotificationChannel.messageChannelId,
            NotificationChannel.messageChannelName,
            description: NotificationChannel.messageChannelDesc,
            importance: Importance.high,
          ),
        );

    // Suppress FCM foreground banners — we show them via local notifications
    // so we have full control over the channel and content.
    // Suppress FCM foreground banners — shown via flutter_local_notifications instead.
    await _messaging.setForegroundNotificationPresentationOptions();
  }

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<RemoteMessage> get onForegroundMessage => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get onNotificationTap =>
      FirebaseMessaging.onMessageOpenedApp;

  @override
  Future<RemoteMessage?> getInitialMessage() =>
      _messaging.getInitialMessage();

  @override
  Future<void> showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      message.messageId?.hashCode ?? notification.hashCode,
      notification.title ?? 'SecureChat',
      notification.body ?? 'New message',
      _notificationDetails,
    );
  }
}
