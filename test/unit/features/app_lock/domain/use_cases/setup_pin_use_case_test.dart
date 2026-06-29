import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:rathtech_chatting_app/features/app_lock/domain/use_cases/setup_pin_use_case.dart';

class _MockAppLockRepository extends Mock implements AppLockRepository {}

void main() {
  late SetupPinUseCase sut;
  late _MockAppLockRepository mockRepo;

  setUp(() {
    mockRepo = _MockAppLockRepository();
    sut = SetupPinUseCase(mockRepo);
  });

  group('SetupPinUseCase', () {
    test('returns Right(null) for valid 6-digit PIN', () async {
      when(() => mockRepo.setupPin('123456'))
          .thenAnswer((_) async => const Right(null));

      final result = await sut.execute('123456');

      expect(result.isRight(), isTrue);
      verify(() => mockRepo.setupPin('123456')).called(1);
    });

    test('returns Left(ValidationFailure) for PIN shorter than 6 digits',
        () async {
      final result = await sut.execute('1234');

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
      verifyNever(() => mockRepo.setupPin(any()));
    });

    test('returns Left(ValidationFailure) for PIN longer than 6 digits',
        () async {
      final result = await sut.execute('1234567');

      expect(result.isLeft(), isTrue);
      verifyNever(() => mockRepo.setupPin(any()));
    });

    test('returns Left(ValidationFailure) for PIN with non-digits', () async {
      final result = await sut.execute('12345a');

      expect(result.isLeft(), isTrue);
      verifyNever(() => mockRepo.setupPin(any()));
    });

    test('returns Left when repository throws', () async {
      when(() => mockRepo.setupPin('000000'))
          .thenAnswer((_) async => const Left(CacheFailure('Storage error')));

      final result = await sut.execute('000000');

      expect(result.isLeft(), isTrue);
    });
  });
}
