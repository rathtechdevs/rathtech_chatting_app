import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_lock_settings.dart';

abstract interface class AppLockRepository {
  AppLockSettings getSettings();
  Future<Either<Failure, void>> saveSettings(AppLockSettings settings);
  Future<Either<Failure, void>> setupPin(String pin);
  Future<Either<Failure, bool>> verifyPin(String pin);
  Future<Either<Failure, void>> clearPin();
  Future<bool> hasPin();
  Future<Either<Failure, bool>> authenticateWithBiometric();
  Future<bool> isBiometricAvailable();
}
