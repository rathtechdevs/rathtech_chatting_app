sealed class SetupProfileState {
  const SetupProfileState();
}

final class SetupProfileInitial extends SetupProfileState {
  const SetupProfileInitial();
}

final class SetupProfileLoading extends SetupProfileState {
  const SetupProfileLoading();
}

final class SetupProfileSuccess extends SetupProfileState {
  const SetupProfileSuccess();
}

final class SetupProfileError extends SetupProfileState {
  const SetupProfileError(this.message);

  final String message;
}
