import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/storage/shared_prefs_provider.dart';
import 'app_lock_status.dart';

class AppLockNotifier extends Notifier<AppLockStatus> {
  @override
  AppLockStatus build() {
    final lockType =
        ref.read(sharedPrefsProvider).getString(StorageKeys.lockType);
    return lockType != null ? AppLockStatus.locked : AppLockStatus.disabled;
  }

  void lock() {
    if (state != AppLockStatus.disabled) state = AppLockStatus.locked;
  }

  void unlock() {
    if (state == AppLockStatus.locked) state = AppLockStatus.unlocked;
  }

  void enable() => state = AppLockStatus.locked;
  void disable() => state = AppLockStatus.disabled;
}
