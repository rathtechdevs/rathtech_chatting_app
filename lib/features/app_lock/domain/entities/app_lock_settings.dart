import 'auto_lock_duration.dart';

class AppLockSettings {
  const AppLockSettings({
    required this.isEnabled,
    required this.isBiometricEnabled,
    required this.autoLockDuration,
  });

  final bool isEnabled;
  final bool isBiometricEnabled;
  final AutoLockDuration autoLockDuration;

  static const disabled = AppLockSettings(
    isEnabled: false,
    isBiometricEnabled: false,
    autoLockDuration: AutoLockDuration.immediately,
  );

  AppLockSettings copyWith({
    bool? isEnabled,
    bool? isBiometricEnabled,
    AutoLockDuration? autoLockDuration,
  }) {
    return AppLockSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      autoLockDuration: autoLockDuration ?? this.autoLockDuration,
    );
  }
}
