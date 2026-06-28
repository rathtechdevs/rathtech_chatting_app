import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/encryption/providers.dart';
import '../../core/network/supabase_client_provider.dart';
import 'data/data_sources/remote/pairing_remote_data_source.dart';
import 'data/repositories/pairing_repository_impl.dart';
import 'domain/entities/pair.dart';
import 'domain/repositories/pairing_repository.dart';
import 'domain/use_cases/accept_invite_code_use_case.dart';
import 'domain/use_cases/generate_invite_code_use_case.dart';
import 'domain/use_cases/get_current_pair_use_case.dart';
import 'domain/use_cases/initialize_pair_session_use_case.dart';
import 'domain/use_cases/watch_pair_status_use_case.dart';
import 'presentation/viewmodels/enter_invite_state.dart';
import 'presentation/viewmodels/enter_invite_view_model.dart';
import 'presentation/viewmodels/generate_invite_state.dart';
import 'presentation/viewmodels/generate_invite_view_model.dart';

// ── Data sources ──────────────────────────────────────────────────────────────

final pairingRemoteDataSourceProvider =
    Provider<PairingRemoteDataSource>((ref) {
  return PairingRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

// ── Repository ────────────────────────────────────────────────────────────────

final pairingRepositoryProvider = Provider<PairingRepository>((ref) {
  return PairingRepositoryImpl(
    remoteDataSource: ref.watch(pairingRemoteDataSourceProvider),
    client: ref.watch(supabaseClientProvider),
  );
});

// ── Use cases ─────────────────────────────────────────────────────────────────

final generateInviteCodeUseCaseProvider =
    Provider<GenerateInviteCodeUseCase>((ref) {
  return GenerateInviteCodeUseCase(ref.watch(pairingRepositoryProvider));
});

final acceptInviteCodeUseCaseProvider =
    Provider<AcceptInviteCodeUseCase>((ref) {
  return AcceptInviteCodeUseCase(ref.watch(pairingRepositoryProvider));
});

final getCurrentPairUseCaseProvider = Provider<GetCurrentPairUseCase>((ref) {
  return GetCurrentPairUseCase(ref.watch(pairingRepositoryProvider));
});

final watchPairStatusUseCaseProvider = Provider<WatchPairStatusUseCase>((ref) {
  return WatchPairStatusUseCase(ref.watch(pairingRepositoryProvider));
});

final initializePairSessionUseCaseProvider =
    Provider<InitializePairSessionUseCase>((ref) {
  return InitializePairSessionUseCase(
    encryptionService: ref.watch(encryptionServiceProvider),
    keyBundleRemoteDataSource: ref.watch(keyBundleRemoteDataSourceProvider),
  );
});

// ── Pair status stream ────────────────────────────────────────────────────────

// Emits null when the current user is not paired, or the Pair when paired.
// Drives the router's pair-gate redirect.
final pairStatusProvider = StreamProvider<Pair?>((ref) {
  return ref.watch(pairingRepositoryProvider).watchPairStatus().map(
        (either) => either.fold((_) => null, (pair) => pair),
      );
});

// ── View models ───────────────────────────────────────────────────────────────

final generateInviteViewModelProvider =
    NotifierProvider<GenerateInviteViewModel, GenerateInviteState>(
  GenerateInviteViewModel.new,
);

final enterInviteViewModelProvider =
    NotifierProvider<EnterInviteViewModel, EnterInviteState>(
  EnterInviteViewModel.new,
);
