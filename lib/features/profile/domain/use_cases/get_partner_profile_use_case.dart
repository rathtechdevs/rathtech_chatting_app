import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class GetPartnerProfileUseCase {
  const GetPartnerProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<Failure, UserProfile?>> execute(String partnerId) =>
      _repository.getPartnerProfile(partnerId);
}
