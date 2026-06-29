import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:rathtech_chatting_app/features/profile/domain/use_cases/upsert_presence_use_case.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late _MockProfileRepository mockRepo;
  late UpsertPresenceUseCase sut;

  const tUserId = 'uid-1';

  setUp(() {
    mockRepo = _MockProfileRepository();
    sut = UpsertPresenceUseCase(mockRepo);
  });

  group('UpsertPresenceUseCase', () {
    test('returns Right(null) when repository succeeds (online)', () async {
      when(() => mockRepo.upsertPresence(userId: any(named: 'userId'), isOnline: any(named: 'isOnline')))
          .thenAnswer((_) async => const Right(null));

      final result = await sut.execute(userId: tUserId, isOnline: true);

      expect(result, const Right<Failure, void>(null));
      verify(() => mockRepo.upsertPresence(userId: tUserId, isOnline: true)).called(1);
    });

    test('returns Right(null) when repository succeeds (offline)', () async {
      when(() => mockRepo.upsertPresence(userId: any(named: 'userId'), isOnline: any(named: 'isOnline')))
          .thenAnswer((_) async => const Right(null));

      final result = await sut.execute(userId: tUserId, isOnline: false);

      expect(result.isRight(), isTrue);
    });

    test('returns Left(failure) when repository fails', () async {
      const failure = ServerFailure.server('upsert error');
      when(() => mockRepo.upsertPresence(userId: any(named: 'userId'), isOnline: any(named: 'isOnline')))
          .thenAnswer((_) async => const Left(failure));

      final result = await sut.execute(userId: tUserId, isOnline: true);

      expect(result.isLeft(), isTrue);
    });
  });
}
