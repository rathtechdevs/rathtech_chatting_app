import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_message_mapper.dart';
import '../../../profile/domain/use_cases/create_profile_use_case.dart';
import '../../../profile/domain/value_objects/display_name.dart';
import '../../../profile/providers.dart';
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

        final result = await ref
            .read(createProfileUseCaseProvider)
            .execute(
              CreateProfileParams(
                displayName: displayName,
                dateOfBirth: dateOfBirth,
              ),
            );

        state = result.fold(
          (failure) => SetupProfileError(
            FailureMessageMapper.toMessage(failure),
          ),
          (_) => const SetupProfileSuccess(),
        );
      },
    );
  }
}

final setupProfileViewModelProvider =
    NotifierProvider<SetupProfileViewModel, SetupProfileState>(
  SetupProfileViewModel.new,
);
