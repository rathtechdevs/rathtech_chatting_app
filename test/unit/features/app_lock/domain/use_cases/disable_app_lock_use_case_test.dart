import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/app_lock/domain/entities/app_lock_settings.dart';
import 'package:rathtech_chatting_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:rathtech_chatting_app/features/app_lock/domain/use_cases/disable_app_lock_use_case.dart';

class _MockAppLockRepository extends Mock implements AppLockRepository {}

class _FakeAppLockSettings extends Fake implements AppLockSettings {}

void main() {
  late _MockAppLockRepository mockRepo;
  late DisableAppLockUseCase sut;

  setUpAll(() => registerFallbackValue(_FakeAppLockSettings()));

  setUp(() {
    mockRepo = _MockAppLockRepository();
    sut = DisableAppLockUseCase(mockRepo);
  });

  group('DisableAppLockUseCase', () {
    test('saves disabled settings then clears pin and returns Right(null)',
        () async {
      when(() => mockRepo.saveSettings(AppLockSettings.disabled))
          .thenAnswer((_) async => const Right(null));
      when(() => mockRepo.clearPin())
          .thenAnswer((_) async => const Right(null));

      final result = await sut.execute();

      expect(result, const Right<Failure, void>(null));
      verifyInOrder([
        () => mockRepo.saveSettings(AppLockSettings.disabled),
        () => mockRepo.clearPin(),
      ]);
    });

    test('returns Left(failure) and does NOT call clearPin if saveSettings fails',
        () async {
      const failure = CacheFailure('disk full');
      when(() => mockRepo.saveSettings(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await sut.execute();

      expect(result, const Left<Failure, void>(failure));
      verifyNever(() => mockRepo.clearPin());
    });
  });
}
