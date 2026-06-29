import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../domain/repositories/notification_repository.dart';
import '../data_sources/notification_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl({
    required NotificationService service,
    required NotificationRemoteDataSource remoteDataSource,
  })  : _service = service,
        _remoteDataSource = remoteDataSource;

  final NotificationService _service;
  final NotificationRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, bool>> requestPermission() async {
    try {
      final granted = await _service.requestPermission();
      return Right(granted);
    } catch (e) {
      return const Left(PermissionFailure.notifications());
    }
  }

  @override
  Future<Either<Failure, void>> registerToken({
    required String userId,
    required String token,
  }) async {
    try {
      await _remoteDataSource.saveToken(userId: userId, token: token);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure.server(e.message));
    } catch (e) {
      return const Left(ServerFailure.unknown());
    }
  }

  @override
  Stream<String> get onTokenRefresh => _service.onTokenRefresh;

  @override
  Stream<RemoteMessage> get onForegroundMessage =>
      _service.onForegroundMessage;

  @override
  Stream<RemoteMessage> get onNotificationTap => _service.onNotificationTap;

  @override
  Future<RemoteMessage?> getInitialMessage() => _service.getInitialMessage();
}
