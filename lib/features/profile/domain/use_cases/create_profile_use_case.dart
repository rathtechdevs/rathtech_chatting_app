import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_case/use_case.dart';
import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';
import '../value_objects/display_name.dart';

class CreateProfileParams {
  const CreateProfileParams({required this.displayName, this.dateOfBirth});

  final DisplayName displayName;
  final DateTime? dateOfBirth;
}

class CreateProfileUseCase extends UseCase<UserProfile, CreateProfileParams> {
  CreateProfileUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, UserProfile>> execute(
    CreateProfileParams params,
  ) => _repository.createProfile(
    displayName: params.displayName,
    dateOfBirth: params.dateOfBirth,
  );
}
