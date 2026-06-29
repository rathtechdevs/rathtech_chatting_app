import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/constants/app_strings.dart';
import '../../core/storage/secure_storage_provider.dart';
import '../../core/storage/shared_prefs_provider.dart';
import 'data/data_sources/app_lock_local_data_source.dart';
import 'data/data_sources/biometric_data_source.dart';
import 'data/repositories/app_lock_repository_impl.dart';
import 'domain/entities/app_lock_settings.dart';
import 'domain/entities/auto_lock_duration.dart';
import 'domain/repositories/app_lock_repository.dart';
import 'domain/use_cases/authenticate_with_biometric_use_case.dart';
import 'domain/use_cases/check_biometric_availability_use_case.dart';
import 'domain/use_cases/disable_app_lock_use_case.dart';
import 'domain/use_cases/get_app_lock_settings_use_case.dart';
import 'domain/use_cases/save_app_lock_settings_use_case.dart';
import 'domain/use_cases/setup_pin_use_case.dart';
import 'domain/use_cases/verify_pin_use_case.dart';
import 'presentation/viewmodels/app_lock_notifier.dart';
import 'presentation/viewmodels/app_lock_status.dart';
import 'presentation/viewmodels/setup_pin_state.dart';

// ── Data sources ──────────────────────────────────────────────────────────────

final appLockLocalDataSourceProvider = Provider<AppLockLocalDataSource>((ref) {
  return AppLockLocalDataSource(
    ref.read(sharedPrefsProvider),
    ref.read(secureStorageProvider),
  );
});

final _localAuthProvider = Provider<LocalAuthentication>(
  (_) => LocalAuthentication(),
);

final _biometricDataSourceProvider = Provider<BiometricDataSource>((ref) {
  return BiometricDataSourceImpl(ref.read(_localAuthProvider));
});

// ── Repository ────────────────────────────────────────────────────────────────

final appLockRepositoryProvider = Provider<AppLockRepository>((ref) {
  return AppLockRepositoryImpl(
    localDataSource: ref.read(appLockLocalDataSourceProvider),
    biometricDataSource: ref.read(_biometricDataSourceProvider),
  );
});

// ── Use cases ─────────────────────────────────────────────────────────────────

final getAppLockSettingsUseCaseProvider =
    Provider<GetAppLockSettingsUseCase>((ref) {
  return GetAppLockSettingsUseCase(ref.read(appLockRepositoryProvider));
});

final saveAppLockSettingsUseCaseProvider =
    Provider<SaveAppLockSettingsUseCase>((ref) {
  return SaveAppLockSettingsUseCase(ref.read(appLockRepositoryProvider));
});

final setupPinUseCaseProvider = Provider<SetupPinUseCase>((ref) {
  return SetupPinUseCase(ref.read(appLockRepositoryProvider));
});

final verifyPinUseCaseProvider = Provider<VerifyPinUseCase>((ref) {
  return VerifyPinUseCase(ref.read(appLockRepositoryProvider));
});

final disableAppLockUseCaseProvider = Provider<DisableAppLockUseCase>((ref) {
  return DisableAppLockUseCase(ref.read(appLockRepositoryProvider));
});

final authenticateWithBiometricUseCaseProvider =
    Provider<AuthenticateWithBiometricUseCase>((ref) {
  return AuthenticateWithBiometricUseCase(ref.read(appLockRepositoryProvider));
});

final checkBiometricAvailabilityUseCaseProvider =
    Provider<CheckBiometricAvailabilityUseCase>((ref) {
  return CheckBiometricAvailabilityUseCase(ref.read(appLockRepositoryProvider));
});

// ── Settings convenience provider (sync read) ─────────────────────────────────

final appLockSettingsProvider = Provider<AppLockSettings>((ref) {
  return ref.read(appLockLocalDataSourceProvider).readSettings();
});

// ── App lock status ───────────────────────────────────────────────────────────

final appLockStatusProvider =
    NotifierProvider<AppLockNotifier, AppLockStatus>(AppLockNotifier.new);

// ── Setup PIN notifier ────────────────────────────────────────────────────────

class SetupPinNotifier extends Notifier<SetupPinState> {
  @override
  SetupPinState build() => const SetupPinEntering();

  void onDigit(String digit) {
    final s = state;
    if (s is SetupPinEntering) {
      if (s.pin.length >= 6) return;
      final newPin = s.pin + digit;
      if (newPin.length == 6) {
        state = SetupPinConfirming(firstPin: newPin);
      } else {
        state = SetupPinEntering(pin: newPin);
      }
    } else if (s is SetupPinConfirming) {
      if (s.confirmPin.length >= 6) return;
      final newConfirm = s.confirmPin + digit;
      state = s.copyWith(confirmPin: newConfirm, clearError: true);
      if (newConfirm.length == 6) {
        _finalize(s.firstPin, newConfirm);
      }
    }
  }

  void onBackspace() {
    final s = state;
    if (s is SetupPinEntering && s.pin.isNotEmpty) {
      state = SetupPinEntering(pin: s.pin.substring(0, s.pin.length - 1));
    } else if (s is SetupPinConfirming) {
      if (s.confirmPin.isNotEmpty) {
        state = s.copyWith(
          confirmPin: s.confirmPin.substring(0, s.confirmPin.length - 1),
        );
      } else {
        state = SetupPinEntering(pin: s.firstPin);
      }
    }
  }

  Future<void> _finalize(String firstPin, String confirmPin) async {
    if (firstPin != confirmPin) {
      state = SetupPinConfirming(
        firstPin: firstPin,
        error: AppStrings.appLockPinMismatch,
      );
      return;
    }
    state = const SetupPinSaving();

    final setupResult =
        await ref.read(setupPinUseCaseProvider).execute(firstPin);
    if (setupResult.isLeft()) {
      state = SetupPinConfirming(
        firstPin: firstPin,
        error: setupResult.fold((f) => f.message, (_) => ''),
      );
      return;
    }

    final currentSettings = ref.read(appLockSettingsProvider);
    await ref.read(saveAppLockSettingsUseCaseProvider).execute(
          currentSettings.copyWith(isEnabled: true, isBiometricEnabled: false),
        );

    ref.read(appLockStatusProvider.notifier).enable();
    ref.read(appLockStatusProvider.notifier).unlock();

    state = const SetupPinDone();
  }

  void reset() => state = const SetupPinEntering();
}

final setupPinNotifierProvider =
    NotifierProvider<SetupPinNotifier, SetupPinState>(SetupPinNotifier.new);

// ── App lock lifecycle ────────────────────────────────────────────────────────

class _AppLockLifecycleNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    final dataSource = ref.read(appLockLocalDataSourceProvider);

    final listener = AppLifecycleListener(
      onPause: dataSource.recordBackgroundTimestamp,
      onHide: dataSource.recordBackgroundTimestamp,
      onDetach: dataSource.recordBackgroundTimestamp,
      onResume: () {
        final settings = dataSource.readSettings();
        if (!settings.isEnabled) return;
        final bgTs = dataSource.readBackgroundTimestamp();
        final elapsed = DateTime.now().millisecondsSinceEpoch - bgTs;
        final thresholdMs = settings.autoLockDuration.minutes * 60 * 1000;
        if (settings.autoLockDuration == AutoLockDuration.immediately ||
            elapsed >= thresholdMs) {
          ref.read(appLockStatusProvider.notifier).lock();
        }
      },
    );

    ref.onDispose(listener.dispose);
  }
}

final appLockLifecycleProvider =
    AsyncNotifierProvider<_AppLockLifecycleNotifier, void>(
  _AppLockLifecycleNotifier.new,
);
