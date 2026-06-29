import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:rathtech_chatting_app/features/app_lock/domain/use_cases/check_biometric_availability_use_case.dart';

class _MockAppLockRepository extends Mock implements AppLockRepository {}

void main() {
  late _MockAppLockRepository mockRepo;
  late CheckBiometricAvailabilityUseCase sut;

  setUp(() {
    mockRepo = _MockAppLockRepository();
    sut = CheckBiometricAvailabilityUseCase(mockRepo);
  });

  group('CheckBiometricAvailabilityUseCase', () {
    test('returns true when device supports biometrics', () async {
      when(() => mockRepo.isBiometricAvailable()).thenAnswer((_) async => true);

      final result = await sut.execute();

      expect(result, isTrue);
      verify(() => mockRepo.isBiometricAvailable()).called(1);
    });

    test('returns false when device has no biometric hardware', () async {
      when(() => mockRepo.isBiometricAvailable())
          .thenAnswer((_) async => false);

      final result = await sut.execute();

      expect(result, isFalse);
    });
  });
}
