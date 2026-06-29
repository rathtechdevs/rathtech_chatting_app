import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/notifications/notification_service.dart';
import '../repositories/notification_repository.dart';

/// Requests permission, retrieves the FCM token, and saves it to Supabase.
/// Returns Right(false) when the user denies permission (not an error).
class InitializeNotificationsUseCase {
  const InitializeNotificationsUseCase(this._repository, this._service);

  final NotificationRepository _repository;
  final NotificationService _service;

  Future<Either<Failure, bool>> execute(String userId) async {
    final permResult = await _repository.requestPermission();

    return permResult.fold(
      Left.new,
      (granted) async {
        if (!granted) return const Right(false);

        final token = await _service.getToken();
        if (token == null) return const Right(false);

        final saveResult = await _repository.registerToken(
          userId: userId,
          token: token,
        );

        return saveResult.fold(Left.new, (_) => const Right(true));
      },
    );
  }
}
