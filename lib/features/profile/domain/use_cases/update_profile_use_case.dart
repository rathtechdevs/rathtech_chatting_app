import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';
import '../value_objects/display_name.dart';

class UpdateProfileParams {
  const UpdateProfileParams({required this.displayName});
  final DisplayName displayName;
}

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<Failure, UserProfile>> execute(
    UpdateProfileParams params,
  ) => _repository.updateProfile(displayName: params.displayName.value);
}
