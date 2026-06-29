import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:rathtech_chatting_app/features/app_lock/domain/use_cases/verify_pin_use_case.dart';

class _MockAppLockRepository extends Mock implements AppLockRepository {}

void main() {
  late VerifyPinUseCase sut;
  late _MockAppLockRepository mockRepo;

  setUp(() {
    mockRepo = _MockAppLockRepository();
    sut = VerifyPinUseCase(mockRepo);
  });

  group('VerifyPinUseCase', () {
    test('returns Right(true) when PIN is correct', () async {
      when(() => mockRepo.verifyPin('123456'))
          .thenAnswer((_) async => const Right(true));

      final result = await sut.execute('123456');

      expect(result, const Right<Failure, bool>(true));
    });

    test('returns Right(false) when PIN is wrong', () async {
      when(() => mockRepo.verifyPin('999999'))
          .thenAnswer((_) async => const Right(false));

      final result = await sut.execute('999999');

      expect(result, const Right<Failure, bool>(false));
    });

    test('returns Left when repository fails', () async {
      when(() => mockRepo.verifyPin('000000'))
          .thenAnswer((_) async => const Left(CacheFailure('Storage error')));

      final result = await sut.execute('000000');

      expect(result.isLeft(), isTrue);
    });
  });
}
