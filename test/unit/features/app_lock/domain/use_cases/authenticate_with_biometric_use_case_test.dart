import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:rathtech_chatting_app/features/app_lock/domain/use_cases/authenticate_with_biometric_use_case.dart';

class _MockAppLockRepository extends Mock implements AppLockRepository {}

void main() {
  late _MockAppLockRepository mockRepo;
  late AuthenticateWithBiometricUseCase sut;

  setUp(() {
    mockRepo = _MockAppLockRepository();
    sut = AuthenticateWithBiometricUseCase(mockRepo);
  });

  group('AuthenticateWithBiometricUseCase', () {
    test('returns Right(true) when biometric authentication succeeds', () async {
      when(() => mockRepo.authenticateWithBiometric())
          .thenAnswer((_) async => const Right(true));

      final result = await sut.execute();

      expect(result, const Right<Failure, bool>(true));
      verify(() => mockRepo.authenticateWithBiometric()).called(1);
    });

    test('returns Right(false) when user cancels or fails biometric prompt',
        () async {
      when(() => mockRepo.authenticateWithBiometric())
          .thenAnswer((_) async => const Right(false));

      final result = await sut.execute();

      expect(result, const Right<Failure, bool>(false));
    });

    test('returns Left(failure) when biometric hardware error occurs', () async {
      const failure = CacheFailure('biometric hardware unavailable');
      when(() => mockRepo.authenticateWithBiometric())
          .thenAnswer((_) async => const Left(failure));

      final result = await sut.execute();

      expect(result, const Left<Failure, bool>(failure));
    });
  });
}
