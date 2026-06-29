import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_lock_settings.dart';
import '../repositories/app_lock_repository.dart';

class SaveAppLockSettingsUseCase {
  const SaveAppLockSettingsUseCase(this._repository);
  final AppLockRepository _repository;

  Future<Either<Failure, void>> execute(AppLockSettings settings) =>
      _repository.saveSettings(settings);
}
