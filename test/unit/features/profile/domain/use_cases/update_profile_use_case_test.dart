import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/profile/domain/entities/user_profile.dart';
import 'package:rathtech_chatting_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:rathtech_chatting_app/features/profile/domain/use_cases/update_profile_use_case.dart';
import 'package:rathtech_chatting_app/features/profile/domain/value_objects/display_name.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late UpdateProfileUseCase sut;
  late _MockProfileRepository mockRepo;

  final tDisplayName = DisplayName.create('Alice').getOrElse((_) => throw StateError(''));
  final tProfile = UserProfile(
    id: 'user-1',
    displayName: 'Alice',
    createdAt: DateTime(2024),
  );

  setUp(() {
    mockRepo = _MockProfileRepository();
    sut = UpdateProfileUseCase(mockRepo);
  });

  group('UpdateProfileUseCase', () {
    test('returns Right(UserProfile) on success', () async {
      when(() => mockRepo.updateProfile(displayName: 'Alice'))
          .thenAnswer((_) async => Right(tProfile));

      final result = await sut.execute(UpdateProfileParams(displayName: tDisplayName));

      expect(result, Right<Failure, UserProfile>(tProfile));
      verify(() => mockRepo.updateProfile(displayName: 'Alice')).called(1);
    });

    test('returns Left(ServerFailure) when repository fails', () async {
      when(() => mockRepo.updateProfile(displayName: 'Alice'))
          .thenAnswer((_) async => const Left(ServerFailure.server()));

      final result = await sut.execute(UpdateProfileParams(displayName: tDisplayName));

      expect(result.isLeft(), isTrue);
    });
  });
}
