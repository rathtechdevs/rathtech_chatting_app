import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:rathtech_chatting_app/core/error/exceptions.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/app_lock/data/data_sources/app_lock_local_data_source.dart';
import 'package:rathtech_chatting_app/features/app_lock/data/data_sources/biometric_data_source.dart';
import 'package:rathtech_chatting_app/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:rathtech_chatting_app/features/app_lock/domain/entities/app_lock_settings.dart';

class _MockLocalDataSource extends Mock implements AppLockLocalDataSource {}

class _MockBiometricDataSource extends Mock implements BiometricDataSource {}

class _FakeAppLockSettings extends Fake implements AppLockSettings {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeAppLockSettings());
  });
  late AppLockRepositoryImpl sut;
  late _MockLocalDataSource mockLocal;
  late _MockBiometricDataSource mockBiometric;

  setUp(() {
    mockLocal = _MockLocalDataSource();
    mockBiometric = _MockBiometricDataSource();
    sut = AppLockRepositoryImpl(
      localDataSource: mockLocal,
      biometricDataSource: mockBiometric,
    );
  });

  group('getSettings', () {
    test('delegates to local data source', () {
      when(() => mockLocal.readSettings())
          .thenReturn(AppLockSettings.disabled);

      final result = sut.getSettings();

      expect(result, AppLockSettings.disabled);
      verify(() => mockLocal.readSettings()).called(1);
    });
  });

  group('saveSettings', () {
    test('returns Right on success', () async {
      when(() => mockLocal.saveSettings(AppLockSettings.disabled))
          .thenAnswer((_) async {});

      final result = await sut.saveSettings(AppLockSettings.disabled);

      expect(result, const Right<Failure, void>(null));
    });

    test('returns Left(CacheFailure) when local throws CacheException',
        () async {
      when(() => mockLocal.saveSettings(any()))
          .thenThrow(const CacheException(message: 'Disk full'));

      final result = await sut.saveSettings(AppLockSettings.disabled);

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => null), isA<CacheFailure>());
    });
  });

  group('verifyPin', () {
    test('returns Right(true) when PIN matches', () async {
      when(() => mockLocal.verifyPin('123456')).thenAnswer((_) async => true);

      final result = await sut.verifyPin('123456');

      expect(result, const Right<Failure, bool>(true));
    });

    test('returns Right(false) when PIN does not match', () async {
      when(() => mockLocal.verifyPin('000000')).thenAnswer((_) async => false);

      final result = await sut.verifyPin('000000');

      expect(result, const Right<Failure, bool>(false));
    });
  });

  group('authenticateWithBiometric', () {
    test('returns Left(PermissionFailure) when biometric unavailable',
        () async {
      when(() => mockBiometric.isAvailable()).thenAnswer((_) async => false);

      final result = await sut.authenticateWithBiometric();

      expect(result.isLeft(), isTrue);
      expect(
        result.fold((f) => f, (_) => null),
        isA<PermissionFailure>(),
      );
    });

    test('returns Right(true) on successful biometric auth', () async {
      when(() => mockBiometric.isAvailable()).thenAnswer((_) async => true);
      when(() => mockBiometric.authenticate(any()))
          .thenAnswer((_) async => true);

      final result = await sut.authenticateWithBiometric();

      expect(result, const Right<Failure, bool>(true));
    });

    test('returns Right(false) when user cancels biometric', () async {
      when(() => mockBiometric.isAvailable()).thenAnswer((_) async => true);
      when(() => mockBiometric.authenticate(any()))
          .thenAnswer((_) async => false);

      final result = await sut.authenticateWithBiometric();

      expect(result, const Right<Failure, bool>(false));
    });
  });

  group('hasPin', () {
    test('delegates to local data source', () async {
      when(() => mockLocal.hasPin()).thenAnswer((_) async => true);

      final result = await sut.hasPin();

      expect(result, isTrue);
    });
  });
}
