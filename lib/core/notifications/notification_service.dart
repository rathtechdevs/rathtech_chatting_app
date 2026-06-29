import 'package:firebase_messaging/firebase_messaging.dart';

abstract interface class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
  Stream<RemoteMessage> get onForegroundMessage;
  Stream<RemoteMessage> get onNotificationTap;
  Future<RemoteMessage?> getInitialMessage();
  Future<void> showLocalNotification(RemoteMessage message);
}
