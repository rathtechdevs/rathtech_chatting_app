import '../../domain/entities/pair_invite_code.dart';

sealed class GenerateInviteState {
  const GenerateInviteState();
}

class GenerateInviteInitial extends GenerateInviteState {
  const GenerateInviteInitial();
}

class GenerateInviteLoading extends GenerateInviteState {
  const GenerateInviteLoading();
}

class GenerateInviteReady extends GenerateInviteState {
  const GenerateInviteReady(this.inviteCode);
  final PairInviteCode inviteCode;
}

class GenerateInviteExpired extends GenerateInviteState {
  const GenerateInviteExpired();
}

class GenerateInviteError extends GenerateInviteState {
  const GenerateInviteError(this.message);
  final String message;
}
