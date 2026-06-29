import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class GetOwnProfileUseCase {
  const GetOwnProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<Failure, UserProfile?>> execute() =>
      _repository.getOwnProfile();
}
