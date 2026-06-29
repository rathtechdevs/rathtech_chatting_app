import '../repositories/app_lock_repository.dart';

class CheckBiometricAvailabilityUseCase {
  const CheckBiometricAvailabilityUseCase(this._repository);
  final AppLockRepository _repository;

  Future<bool> execute() => _repository.isBiometricAvailable();
}
