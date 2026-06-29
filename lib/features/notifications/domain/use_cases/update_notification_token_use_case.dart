import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

/// Persists a refreshed FCM token for the given user.
class UpdateNotificationTokenUseCase {
  const UpdateNotificationTokenUseCase(this._repository);

  final NotificationRepository _repository;

  Future<Either<Failure, void>> execute({
    required String userId,
    required String token,
  }) =>
      _repository.registerToken(userId: userId, token: token);
}
