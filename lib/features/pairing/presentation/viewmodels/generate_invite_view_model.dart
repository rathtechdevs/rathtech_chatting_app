import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_message_mapper.dart';
import '../../providers.dart';
import 'generate_invite_state.dart';

class GenerateInviteViewModel extends Notifier<GenerateInviteState> {
  Timer? _expiryTimer;

  @override
  GenerateInviteState build() {
    ref.onDispose(() => _expiryTimer?.cancel());
    return const GenerateInviteInitial();
  }

  Future<void> generate() async {
    if (state is GenerateInviteLoading) return;
    state = const GenerateInviteLoading();

    final result = await ref.read(generateInviteCodeUseCaseProvider).execute();

    result.fold(
      (failure) => state = GenerateInviteError(
        FailureMessageMapper.toMessage(failure),
      ),
      (inviteCode) {
        state = GenerateInviteReady(inviteCode);
        _scheduleExpiryAt(inviteCode.expiresAt);
      },
    );
  }

  void _scheduleExpiryAt(DateTime expiresAt) {
    _expiryTimer?.cancel();
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) {
      state = const GenerateInviteExpired();
      return;
    }
    _expiryTimer = Timer(remaining, () {
      if (state is GenerateInviteReady) {
        state = const GenerateInviteExpired();
      }
    });
  }

  void reset() {
    _expiryTimer?.cancel();
    state = const GenerateInviteInitial();
  }
}
