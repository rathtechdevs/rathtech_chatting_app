import '../entities/app_lock_settings.dart';
import '../repositories/app_lock_repository.dart';

class GetAppLockSettingsUseCase {
  const GetAppLockSettingsUseCase(this._repository);
  final AppLockRepository _repository;

  AppLockSettings execute() => _repository.getSettings();
}
