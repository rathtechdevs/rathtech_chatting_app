import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';
import '../value_objects/display_name.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserProfile>> createProfile({
    required DisplayName displayName,
    DateTime? dateOfBirth,
  });

  Future<Either<Failure, bool>> hasOwnProfile();

  Future<Either<Failure, UserProfile?>> getOwnProfile();
}
