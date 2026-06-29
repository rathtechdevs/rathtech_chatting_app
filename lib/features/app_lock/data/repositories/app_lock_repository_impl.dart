import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_lock_settings.dart';
import '../../domain/repositories/app_lock_repository.dart';
import '../data_sources/app_lock_local_data_source.dart';
import '../data_sources/biometric_data_source.dart';

class AppLockRepositoryImpl implements AppLockRepository {
  const AppLockRepositoryImpl({
    required AppLockLocalDataSource localDataSource,
    required BiometricDataSource biometricDataSource,
  })  : _local = localDataSource,
        _biometric = biometricDataSource;

  final AppLockLocalDataSource _local;
  final BiometricDataSource _biometric;

  @override
  AppLockSettings getSettings() => _local.readSettings();

  @override
  Future<Either<Failure, void>> saveSettings(AppLockSettings settings) async {
    try {
      await _local.saveSettings(settings);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> setupPin(String pin) async {
    try {
      await _local.setupPin(pin);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPin(String pin) async {
    try {
      final result = await _local.verifyPin(pin);
      return Right(result);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> clearPin() async {
    try {
      await _local.clearPin();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<bool> hasPin() => _local.hasPin();

  @override
  Future<Either<Failure, bool>> authenticateWithBiometric() async {
    try {
      final available = await _biometric.isAvailable();
      if (!available) {
        return const Left(PermissionFailure.biometric());
      }
      final success = await _biometric.authenticate(
        'Authenticate to access SecureChat',
      );
      return Right(success);
    } catch (e) {
      return const Left(ServerFailure.unknown());
    }
  }

  @override
  Future<bool> isBiometricAvailable() => _biometric.isAvailable();
}
