import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/supabase_client_provider.dart';
import '../auth/providers.dart';
import 'data/data_sources/remote/profile_remote_data_source.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'domain/entities/user_presence.dart';
import 'domain/entities/user_profile.dart';
import 'domain/repositories/profile_repository.dart';
import 'domain/use_cases/create_profile_use_case.dart';
import 'domain/use_cases/get_own_profile_use_case.dart';
import 'domain/use_cases/get_partner_profile_use_case.dart';
import 'domain/use_cases/update_profile_use_case.dart';
import 'domain/use_cases/upload_avatar_use_case.dart';
import 'domain/use_cases/upsert_presence_use_case.dart';
import 'domain/use_cases/watch_partner_presence_use_case.dart';
import 'presentation/viewmodels/profile_state.dart';
import 'presentation/viewmodels/profile_view_model.dart';

// ── Data sources ──────────────────────────────────────────────────────────────

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>(
  (ref) => ProfileRemoteDataSourceImpl(ref.watch(supabaseClientProvider)),
);

// ── Repository ────────────────────────────────────────────────────────────────

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    remoteDataSource: ref.watch(profileRemoteDataSourceProvider),
    client: ref.watch(supabaseClientProvider),
  );
});

// ── Use cases ─────────────────────────────────────────────────────────────────

final createProfileUseCaseProvider = Provider<CreateProfileUseCase>((ref) {
  return CreateProfileUseCase(ref.watch(profileRepositoryProvider));
});

final getOwnProfileUseCaseProvider = Provider<GetOwnProfileUseCase>((ref) {
  return GetOwnProfileUseCase(ref.watch(profileRepositoryProvider));
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.watch(profileRepositoryProvider));
});

final uploadAvatarUseCaseProvider = Provider<UploadAvatarUseCase>((ref) {
  return UploadAvatarUseCase(ref.watch(profileRepositoryProvider));
});

final getPartnerProfileUseCaseProvider =
    Provider<GetPartnerProfileUseCase>((ref) {
  return GetPartnerProfileUseCase(ref.watch(profileRepositoryProvider));
});

final upsertPresenceUseCaseProvider = Provider<UpsertPresenceUseCase>((ref) {
  return UpsertPresenceUseCase(ref.watch(profileRepositoryProvider));
});

final watchPartnerPresenceUseCaseProvider =
    Provider<WatchPartnerPresenceUseCase>((ref) {
  return WatchPartnerPresenceUseCase(ref.watch(profileRepositoryProvider));
});

// ── Streams (called from chat feature providers) ──────────────────────────────

final partnerProfileStreamProvider =
    StreamProvider.family<UserProfile?, String>((ref, partnerId) {
  if (partnerId.isEmpty) return const Stream.empty();
  return ref.watch(profileRepositoryProvider).watchPartnerProfile(partnerId);
});

final partnerPresenceStreamProvider =
    StreamProvider.family<UserPresence?, String>((ref, partnerId) {
  if (partnerId.isEmpty) return const Stream.empty();
  return ref
      .watch(watchPartnerPresenceUseCaseProvider)
      .execute(partnerId);
});

// ── View model ────────────────────────────────────────────────────────────────

final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);

// ── Presence lifecycle ────────────────────────────────────────────────────────
//
// Keeps the authenticated user's presence up to date as the app moves between
// foreground and background states.

final presenceLifecycleProvider =
    AsyncNotifierProvider<_PresenceLifecycleNotifier, void>(
  _PresenceLifecycleNotifier.new,
);

class _PresenceLifecycleNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return;

    void update({required bool isOnline}) {
      ref
          .read(upsertPresenceUseCaseProvider)
          .execute(userId: userId, isOnline: isOnline);
    }

    final listener = AppLifecycleListener(
      onResume: () => update(isOnline: true),
      onPause: () => update(isOnline: false),
      onDetach: () => update(isOnline: false),
      onHide: () => update(isOnline: false),
    );
    ref.onDispose(listener.dispose);

    await ref
        .read(upsertPresenceUseCaseProvider)
        .execute(userId: userId, isOnline: true);
  }
}
