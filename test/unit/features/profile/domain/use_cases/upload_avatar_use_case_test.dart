import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:rathtech_chatting_app/features/profile/domain/use_cases/upload_avatar_use_case.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late UploadAvatarUseCase sut;
  late _MockProfileRepository mockRepo;

  const tUserId = 'user-1';
  const tLocalFilePath = '/tmp/avatar.jpg';
  const tAvatarUrl = 'https://example.com/avatars/user-1.jpg';

  setUp(() {
    mockRepo = _MockProfileRepository();
    sut = UploadAvatarUseCase(mockRepo);
  });

  group('UploadAvatarUseCase', () {
    test('returns Right(url) on successful upload', () async {
      when(
        () => mockRepo.uploadAvatar(
          userId: tUserId,
          localFilePath: tLocalFilePath,
        ),
      ).thenAnswer((_) async => const Right(tAvatarUrl));

      final result = await sut.execute(
        const UploadAvatarParams(
          userId: tUserId,
          localFilePath: tLocalFilePath,
        ),
      );

      expect(result, const Right<Failure, String>(tAvatarUrl));
    });

    test('returns Left(ServerFailure) when upload fails', () async {
      when(
        () => mockRepo.uploadAvatar(
          userId: tUserId,
          localFilePath: tLocalFilePath,
        ),
      ).thenAnswer((_) async => const Left(ServerFailure.server()));

      final result = await sut.execute(
        const UploadAvatarParams(
          userId: tUserId,
          localFilePath: tLocalFilePath,
        ),
      );

      expect(result.isLeft(), isTrue);
    });
  });
}
