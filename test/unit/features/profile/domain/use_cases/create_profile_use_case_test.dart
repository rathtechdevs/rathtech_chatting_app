import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/profile/domain/entities/user_profile.dart';
import 'package:rathtech_chatting_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:rathtech_chatting_app/features/profile/domain/use_cases/create_profile_use_case.dart';
import 'package:rathtech_chatting_app/features/profile/domain/value_objects/display_name.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _FakeDisplayName extends Fake implements DisplayName {}

DisplayName _name(String raw) =>
    DisplayName.create(raw).fold((_) => throw Exception('bad test data'), (n) => n);

void main() {
  late _MockProfileRepository mockRepo;
  late CreateProfileUseCase sut;

  final tName = _name('Alice');
  final tProfile = UserProfile(
    id: 'uid-1',
    displayName: 'Alice',
    createdAt: DateTime(2024),
  );

  setUpAll(() => registerFallbackValue(_FakeDisplayName()));

  setUp(() {
    mockRepo = _MockProfileRepository();
    sut = CreateProfileUseCase(mockRepo);
  });

  group('CreateProfileUseCase', () {
    test('returns Right(profile) on success', () async {
      when(() => mockRepo.createProfile(displayName: any(named: 'displayName')))
          .thenAnswer((_) async => Right(tProfile));

      final result = await sut.execute(CreateProfileParams(displayName: tName));

      expect(result, Right<Failure, UserProfile>(tProfile));
      verify(() => mockRepo.createProfile(displayName: tName)).called(1);
    });

    test('returns Left(ServerFailure) when repository fails', () async {
      const failure = ServerFailure.server('conflict');
      when(() => mockRepo.createProfile(displayName: any(named: 'displayName')))
          .thenAnswer((_) async => const Left(failure));

      final result = await sut.execute(CreateProfileParams(displayName: tName));

      expect(result.isLeft(), isTrue);
    });
  });
}
