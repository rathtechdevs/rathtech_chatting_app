import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/app_lock_repository.dart';

class AuthenticateWithBiometricUseCase {
  const AuthenticateWithBiometricUseCase(this._repository);
  final AppLockRepository _repository;

  Future<Either<Failure, bool>> execute() =>
      _repository.authenticateWithBiometric();
}
