import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/supabase_client_provider.dart';
import 'data/data_sources/remote/profile_remote_data_source.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'domain/repositories/profile_repository.dart';
import 'domain/use_cases/create_profile_use_case.dart';

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
