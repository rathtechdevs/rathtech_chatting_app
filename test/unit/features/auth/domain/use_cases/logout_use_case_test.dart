import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:rathtech_chatting_app/features/auth/domain/use_cases/logout_use_case.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository mockRepo;
  late LogoutUseCase sut;

  setUp(() {
    mockRepo = _MockAuthRepository();
    sut = LogoutUseCase(mockRepo);
  });

  group('LogoutUseCase', () {
    test('returns Right(null) when repository succeeds', () async {
      when(() => mockRepo.logout()).thenAnswer((_) async => const Right(null));

      final result = await sut.execute();

      expect(result, const Right<Failure, void>(null));
      verify(() => mockRepo.logout()).called(1);
    });

    test('returns Left(failure) when repository returns failure', () async {
      const failure = ServerFailure.noConnection();
      when(() => mockRepo.logout())
          .thenAnswer((_) async => const Left(failure));

      final result = await sut.execute();

      expect(result, const Left<Failure, void>(failure));
    });
  });
}
