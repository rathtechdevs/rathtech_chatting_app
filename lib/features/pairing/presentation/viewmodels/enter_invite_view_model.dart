import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_message_mapper.dart';
import '../../../auth/providers.dart';
import '../../providers.dart';
import 'enter_invite_state.dart';

class EnterInviteViewModel extends Notifier<EnterInviteState> {
  @override
  EnterInviteState build() => const EnterInviteInitial();

  Future<void> submit(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.length != 8) {
      state = const EnterInviteError('Please enter the full 8-character code.');
      return;
    }

    state = const EnterInviteLoading();

    final acceptResult =
        await ref.read(acceptInviteCodeUseCaseProvider).execute(code);

    await acceptResult.fold(
      (failure) async {
        state = EnterInviteError(FailureMessageMapper.toMessage(failure));
      },
      (pair) async {
        final ownUserId = ref.read(currentUserIdProvider) ?? '';

        // User B (accepter) initializes the Signal Protocol session with User A.
        await ref.read(initializePairSessionUseCaseProvider).execute(
              pairId: pair.id,
              partnerUserId: pair.partnerIdFor(ownUserId),
            );

        // pairStatusProvider will emit the new pair via Realtime, triggering
        // the router redirect to chat for both users automatically.
        state = EnterInviteSuccess(pair);
      },
    );
  }

  void reset() => state = const EnterInviteInitial();
}
