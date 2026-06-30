import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/encryption/providers.dart';
import '../../../../core/error/failure_message_mapper.dart';
import '../../../profile/domain/use_cases/create_profile_use_case.dart';
import '../../../profile/domain/value_objects/display_name.dart';
import '../../../profile/providers.dart';
import '../../providers.dart';
import 'setup_profile_state.dart';

class SetupProfileViewModel extends Notifier<SetupProfileState> {
  @override
  SetupProfileState build() => const SetupProfileInitial();

  Future<void> createProfile({
    required String rawDisplayName,
    DateTime? dateOfBirth,
  }) async {
    final nameResult = DisplayName.create(rawDisplayName);

    await nameResult.fold(
      (failure) async =>
          state = SetupProfileError(FailureMessageMapper.toMessage(failure)),
      (displayName) async {
        state = const SetupProfileLoading();

        if (dateOfBirth != null) {
          final age =
              DateTime.now().difference(dateOfBirth).inDays ~/ 365;
          if (age < 18) {
            state = const SetupProfileError(
              'You must be 18 or older to use SecureChat.',
            );
            return;
          }
        }

        final profileResult = await ref
            .read(createProfileUseCaseProvider)
            .execute(
              CreateProfileParams(
                displayName: displayName,
                dateOfBirth: dateOfBirth,
              ),
            );

        if (profileResult.isLeft()) {
          state = profileResult.fold(
            (failure) => SetupProfileError(
              FailureMessageMapper.toMessage(failure),
            ),
            (_) => const SetupProfileSuccess(),
          );
          return;
        }

        // Generate and publish Signal Protocol keys after profile creation.
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          final keyResult = await ref
              .read(keyGenerationServiceProvider)
              .generateAndPublishKeys(userId);

          if (keyResult.isLeft()) {
            state = keyResult.fold(
              (failure) => SetupProfileError(
                FailureMessageMapper.toMessage(failure),
              ),
              (_) => const SetupProfileSuccess(),
            );
            return;
          }
        }

        // Restart watchAuthState so it re-checks hasProfile and emits
        // AppAuthState.authenticated, allowing GoRouter to redirect to /pair.
        ref.invalidate(authStateProvider);
        state = const SetupProfileSuccess();
      },
    );
  }
}

final setupProfileViewModelProvider =
    NotifierProvider<SetupProfileViewModel, SetupProfileState>(
  SetupProfileViewModel.new,
);
