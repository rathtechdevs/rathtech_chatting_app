import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/profile/domain/entities/user_profile.dart';
import 'package:rathtech_chatting_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:rathtech_chatting_app/features/profile/domain/use_cases/get_partner_profile_use_case.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late _MockProfileRepository mockRepo;
  late GetPartnerProfileUseCase sut;

  const tPartnerId = 'partner-uid';
  final tProfile = UserProfile(
    id: tPartnerId,
    displayName: 'Bob',
    createdAt: DateTime(2024),
  );

  setUp(() {
    mockRepo = _MockProfileRepository();
    sut = GetPartnerProfileUseCase(mockRepo);
  });

  group('GetPartnerProfileUseCase', () {
    test('returns Right(profile) when partner found', () async {
      when(() => mockRepo.getPartnerProfile(any()))
          .thenAnswer((_) async => Right(tProfile));

      final result = await sut.execute(tPartnerId);

      expect(result, Right<Failure, UserProfile?>(tProfile));
      verify(() => mockRepo.getPartnerProfile(tPartnerId)).called(1);
    });

    test('returns Right(null) when partner has no profile', () async {
      when(() => mockRepo.getPartnerProfile(any()))
          .thenAnswer((_) async => const Right(null));

      final result = await sut.execute(tPartnerId);

      expect(result, const Right<Failure, UserProfile?>(null));
    });

    test('returns Left(failure) when repository fails', () async {
      const failure = ServerFailure.noConnection();
      when(() => mockRepo.getPartnerProfile(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await sut.execute(tPartnerId);

      expect(result.isLeft(), isTrue);
    });
  });
}
