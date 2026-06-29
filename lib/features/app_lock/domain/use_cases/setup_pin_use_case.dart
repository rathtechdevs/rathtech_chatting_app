import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/app_lock_repository.dart';

class SetupPinUseCase {
  const SetupPinUseCase(this._repository);
  final AppLockRepository _repository;

  Future<Either<Failure, void>> execute(String pin) {
    if (pin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pin)) {
      return Future.value(
        const Left(ValidationFailure('PIN must be exactly 6 digits.')),
      );
    }
    return _repository.setupPin(pin);
  }
}
