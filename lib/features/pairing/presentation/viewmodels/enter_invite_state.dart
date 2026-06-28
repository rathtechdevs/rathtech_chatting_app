import '../../domain/entities/pair.dart';

sealed class EnterInviteState {
  const EnterInviteState();
}

class EnterInviteInitial extends EnterInviteState {
  const EnterInviteInitial();
}

class EnterInviteLoading extends EnterInviteState {
  const EnterInviteLoading();
}

class EnterInviteSuccess extends EnterInviteState {
  const EnterInviteSuccess(this.pair);
  final Pair pair;
}

class EnterInviteError extends EnterInviteState {
  const EnterInviteError(this.message);
  final String message;
}
