import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/app_lock/domain/entities/app_lock_settings.dart';
import 'package:rathtech_chatting_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:rathtech_chatting_app/features/app_lock/domain/use_cases/save_app_lock_settings_use_case.dart';

class _MockAppLockRepository extends Mock implements AppLockRepository {}

class _FakeAppLockSettings extends Fake implements AppLockSettings {}

void main() {
  late _MockAppLockRepository mockRepo;
  late SaveAppLockSettingsUseCase sut;

  setUpAll(() => registerFallbackValue(_FakeAppLockSettings()));

  setUp(() {
    mockRepo = _MockAppLockRepository();
    sut = SaveAppLockSettingsUseCase(mockRepo);
  });

  group('SaveAppLockSettingsUseCase', () {
    test('returns Right(null) when repository succeeds', () async {
      when(() => mockRepo.saveSettings(any()))
          .thenAnswer((_) async => const Right(null));

      final result = await sut.execute(AppLockSettings.disabled);

      expect(result, const Right<Failure, void>(null));
      verify(() => mockRepo.saveSettings(AppLockSettings.disabled)).called(1);
    });

    test('returns Left(CacheFailure) when repository fails', () async {
      const failure = CacheFailure('disk full');
      when(() => mockRepo.saveSettings(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await sut.execute(AppLockSettings.disabled);

      expect(result, const Left<Failure, void>(failure));
    });
  });
}
