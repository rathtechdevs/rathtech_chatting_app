import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/profile_repository.dart';

class UploadAvatarParams {
  const UploadAvatarParams({
    required this.userId,
    required this.localFilePath,
  });
  final String userId;
  final String localFilePath;
}

class UploadAvatarUseCase {
  const UploadAvatarUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<Failure, String>> execute(UploadAvatarParams params) =>
      _repository.uploadAvatar(
        userId: params.userId,
        localFilePath: params.localFilePath,
      );
}
