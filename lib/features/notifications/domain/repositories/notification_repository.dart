import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';

abstract interface class NotificationRepository {
  Future<Either<Failure, bool>> requestPermission();
  Future<Either<Failure, void>> registerToken({
    required String userId,
    required String token,
  });
  Stream<String> get onTokenRefresh;
  Stream<RemoteMessage> get onForegroundMessage;
  Stream<RemoteMessage> get onNotificationTap;
  Future<RemoteMessage?> getInitialMessage();
}
