import '../../domain/entities/user_profile.dart';

sealed class ProfileState {
  const ProfileState();
}

final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileReady extends ProfileState {
  const ProfileReady({
    required this.profile,
    this.isSaving = false,
    this.isUploadingAvatar = false,
    this.errorMessage,
  });

  final UserProfile profile;
  final bool isSaving;
  final bool isUploadingAvatar;
  final String? errorMessage;

  ProfileReady copyWith({
    UserProfile? profile,
    bool? isSaving,
    bool? isUploadingAvatar,
    String? errorMessage,
    bool clearError = false,
  }) => ProfileReady(
    profile: profile ?? this.profile,
    isSaving: isSaving ?? this.isSaving,
    isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

final class ProfileError extends ProfileState {
  const ProfileError(this.message);
  final String message;
}
