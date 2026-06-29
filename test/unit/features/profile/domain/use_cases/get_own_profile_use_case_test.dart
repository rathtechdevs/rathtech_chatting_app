import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/profile/domain/entities/user_profile.dart';
import 'package:rathtech_chatting_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:rathtech_chatting_app/features/profile/domain/use_cases/get_own_profile_use_case.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late _MockProfileRepository mockRepo;
  late GetOwnProfileUseCase sut;

  final tProfile = UserProfile(
    id: 'uid-1',
    displayName: 'Alice',
    createdAt: DateTime(2024),
  );

  setUp(() {
    mockRepo = _MockProfileRepository();
    sut = GetOwnProfileUseCase(mockRepo);
  });

  group('GetOwnProfileUseCase', () {
    test('returns Right(profile) when repository finds a profile', () async {
      when(() => mockRepo.getOwnProfile())
          .thenAnswer((_) async => Right(tProfile));

      final result = await sut.execute();

      expect(result, Right<Failure, UserProfile?>(tProfile));
      verify(() => mockRepo.getOwnProfile()).called(1);
    });

    test('returns Right(null) when no profile found', () async {
      when(() => mockRepo.getOwnProfile())
          .thenAnswer((_) async => const Right(null));

      final result = await sut.execute();

      expect(result, const Right<Failure, UserProfile?>(null));
    });

    test('returns Left(failure) when repository fails', () async {
      const failure = ServerFailure.server('query failed');
      when(() => mockRepo.getOwnProfile())
          .thenAnswer((_) async => const Left(failure));

      final result = await sut.execute();

      expect(result.isLeft(), isTrue);
    });
  });
}
