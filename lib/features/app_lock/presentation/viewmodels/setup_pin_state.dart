sealed class SetupPinState {
  const SetupPinState();
}

final class SetupPinEntering extends SetupPinState {
  const SetupPinEntering({this.pin = ''});
  final String pin;
}

final class SetupPinConfirming extends SetupPinState {
  const SetupPinConfirming({
    required this.firstPin,
    this.confirmPin = '',
    this.error,
  });

  final String firstPin;
  final String confirmPin;
  final String? error;

  SetupPinConfirming copyWith({
    String? confirmPin,
    String? error,
    bool clearError = false,
  }) {
    return SetupPinConfirming(
      firstPin: firstPin,
      confirmPin: confirmPin ?? this.confirmPin,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final class SetupPinSaving extends SetupPinState {
  const SetupPinSaving();
}

final class SetupPinDone extends SetupPinState {
  const SetupPinDone();
}
