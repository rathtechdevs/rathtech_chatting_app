import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_lock_settings.dart';
import '../repositories/app_lock_repository.dart';

class DisableAppLockUseCase {
  const DisableAppLockUseCase(this._repository);
  final AppLockRepository _repository;

  Future<Either<Failure, void>> execute() async {
    final saveResult =
        await _repository.saveSettings(AppLockSettings.disabled);
    if (saveResult.isLeft()) return saveResult;
    return _repository.clearPin();
  }
}
