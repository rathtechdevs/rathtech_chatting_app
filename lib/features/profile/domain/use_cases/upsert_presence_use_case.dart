import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/profile_repository.dart';

class UpsertPresenceUseCase {
  const UpsertPresenceUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<Failure, void>> execute({
    required String userId,
    required bool isOnline,
  }) => _repository.upsertPresence(userId: userId, isOnline: isOnline);
}
