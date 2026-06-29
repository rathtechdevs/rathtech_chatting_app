import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/features/app_lock/domain/entities/app_lock_settings.dart';
import 'package:rathtech_chatting_app/features/app_lock/domain/entities/auto_lock_duration.dart';
import 'package:rathtech_chatting_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:rathtech_chatting_app/features/app_lock/domain/use_cases/get_app_lock_settings_use_case.dart';

class _MockAppLockRepository extends Mock implements AppLockRepository {}

void main() {
  late _MockAppLockRepository mockRepo;
  late GetAppLockSettingsUseCase sut;

  setUp(() {
    mockRepo = _MockAppLockRepository();
    sut = GetAppLockSettingsUseCase(mockRepo);
  });

  group('GetAppLockSettingsUseCase', () {
    test('returns AppLockSettings.disabled when lock is off', () {
      when(() => mockRepo.getSettings()).thenReturn(AppLockSettings.disabled);

      final result = sut.execute();

      expect(result, AppLockSettings.disabled);
      verify(() => mockRepo.getSettings()).called(1);
    });

    test('returns enabled settings when lock is on', () {
      const settings = AppLockSettings(
        isEnabled: true,
        isBiometricEnabled: false,
        autoLockDuration: AutoLockDuration.after5min,
      );
      when(() => mockRepo.getSettings()).thenReturn(settings);

      final result = sut.execute();

      expect(result.isEnabled, isTrue);
    });
  });
}
