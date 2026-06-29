import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/app_lock_repository.dart';

class VerifyPinUseCase {
  const VerifyPinUseCase(this._repository);
  final AppLockRepository _repository;

  Future<Either<Failure, bool>> execute(String pin) =>
      _repository.verifyPin(pin);
}
