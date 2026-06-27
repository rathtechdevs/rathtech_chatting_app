import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/network/supabase_client_provider.dart';
import '../../core/storage/secure_storage_provider.dart';
import 'data/data_sources/remote/auth_remote_data_source.dart';
import 'data/data_sources/secure/auth_secure_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/entities/auth_session.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/use_cases/logout_use_case.dart';
import 'domain/use_cases/request_magic_link_use_case.dart';
import 'domain/use_cases/request_otp_use_case.dart';
import 'domain/use_cases/verify_otp_use_case.dart';

// ── Data sources ──────────────────────────────────────────────────────────────

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final authSecureDataSourceProvider = Provider<AuthSecureDataSource>((ref) {
  return AuthSecureDataSourceImpl(ref.watch(secureStorageProvider));
});

// ── Repository ────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    secureDataSource: ref.watch(authSecureDataSourceProvider),
  );
});

// ── Use cases ─────────────────────────────────────────────────────────────────

final requestOtpUseCaseProvider = Provider<RequestOtpUseCase>((ref) {
  return RequestOtpUseCase(ref.watch(authRepositoryProvider));
});

final verifyOtpUseCaseProvider = Provider<VerifyOtpUseCase>((ref) {
  return VerifyOtpUseCase(ref.watch(authRepositoryProvider));
});

final requestMagicLinkUseCaseProvider = Provider<RequestMagicLinkUseCase>(
  (ref) => RequestMagicLinkUseCase(ref.watch(authRepositoryProvider)),
);

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

// ── Auth state stream ─────────────────────────────────────────────────────────

final authStateProvider = StreamProvider<AppAuthState>((ref) {
  return ref.watch(authRepositoryProvider).watchAuthState();
});

// ── Current user (nullable) ───────────────────────────────────────────────────

final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.id;
});
