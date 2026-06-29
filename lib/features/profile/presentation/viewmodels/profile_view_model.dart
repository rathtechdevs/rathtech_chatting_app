import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/use_cases/update_profile_use_case.dart';
import '../../domain/use_cases/upload_avatar_use_case.dart';
import '../../domain/value_objects/display_name.dart';
import '../../providers.dart';
import 'profile_state.dart';

class ProfileViewModel extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    _load();
    return const ProfileInitial();
  }

  Future<void> _load() async {
    state = const ProfileLoading();
    final result =
        await ref.read(getOwnProfileUseCaseProvider).execute();
    state = result.fold(
      (failure) => ProfileError(failure.message),
      (profile) => profile != null
          ? ProfileReady(profile: profile)
          : const ProfileError('Profile not found.'),
    );
  }

  Future<void> updateDisplayName(String rawName) async {
    final ready = state;
    if (ready is! ProfileReady) return;

    final nameResult = DisplayName.create(rawName);
    final failure = nameResult.fold((f) => f, (_) => null);
    if (failure != null) {
      state = ready.copyWith(errorMessage: failure.message);
      return;
    }

    state = ready.copyWith(isSaving: true, clearError: true);

    final result = await ref
        .read(updateProfileUseCaseProvider)
        .execute(UpdateProfileParams(displayName: nameResult.getOrElse((_) => throw StateError(''))));

    state = result.fold(
      (f) => ready.copyWith(isSaving: false, errorMessage: f.message),
      (updated) => ProfileReady(profile: updated),
    );
  }

  Future<void> uploadAvatar(String userId, String localFilePath) async {
    final ready = state;
    if (ready is! ProfileReady) return;

    state = ready.copyWith(isUploadingAvatar: true, clearError: true);

    final result = await ref
        .read(uploadAvatarUseCaseProvider)
        .execute(UploadAvatarParams(userId: userId, localFilePath: localFilePath));

    state = result.fold(
      (f) => ready.copyWith(isUploadingAvatar: false, errorMessage: f.message),
      (url) => ProfileReady(
        profile: ready.profile.copyWith(avatarUrl: url),
      ),
    );
  }
}
