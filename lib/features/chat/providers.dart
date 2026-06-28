import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/encryption/providers.dart';
import '../../core/network/supabase_client_provider.dart';
import '../../core/storage/app_database.dart';
import '../auth/providers.dart';
import '../pairing/providers.dart';
import 'data/data_sources/local/chat_local_data_source.dart';
import 'data/data_sources/remote/chat_remote_data_source.dart';
import 'data/repositories/chat_repository_impl.dart';
import 'domain/repositories/chat_repository.dart';
import 'domain/use_cases/load_more_messages_use_case.dart';
import 'domain/use_cases/send_message_use_case.dart';
import 'domain/use_cases/watch_messages_use_case.dart';
import 'presentation/viewmodels/chat_state.dart';
import 'presentation/viewmodels/chat_view_model.dart';

// ── Pair / user helpers (non-nullable after router pair-gate) ─────────────────

// Router guarantees current user is authenticated when /chat is reachable.
final chatOwnUserIdProvider = Provider<String>((ref) {
  return ref.watch(currentUserIdProvider) ?? '';
});

// Router guarantees Pair is non-null when /chat is reachable.
final chatPairIdProvider = Provider<String>((ref) {
  return ref.watch(pairStatusProvider).valueOrNull?.id ?? '';
});

final chatPartnerIdProvider = Provider<String>((ref) {
  final pair = ref.watch(pairStatusProvider).valueOrNull;
  final ownId = ref.watch(chatOwnUserIdProvider);
  if (pair == null) return '';
  return pair.partnerIdFor(ownId);
});

// ── Data sources ──────────────────────────────────────────────────────────────

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final chatLocalDataSourceProvider = Provider<ChatLocalDataSource>((ref) {
  return ChatLocalDataSourceImpl(ref.watch(appDatabaseProvider));
});

// ── Repository ────────────────────────────────────────────────────────────────

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final impl = ChatRepositoryImpl(
    remote: ref.watch(chatRemoteDataSourceProvider),
    local: ref.watch(chatLocalDataSourceProvider),
    encryption: ref.watch(encryptionServiceProvider),
    keyBundleRemote: ref.watch(keyBundleRemoteDataSourceProvider),
    ownUserId: ref.watch(chatOwnUserIdProvider),
  );
  ref.onDispose(impl.dispose);
  return impl;
});

// ── Use cases ─────────────────────────────────────────────────────────────────

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(chatRepositoryProvider));
});

final watchMessagesUseCaseProvider = Provider<WatchMessagesUseCase>((ref) {
  return WatchMessagesUseCase(ref.watch(chatRepositoryProvider));
});

final loadMoreMessagesUseCaseProvider = Provider<LoadMoreMessagesUseCase>(
  (ref) => LoadMoreMessagesUseCase(ref.watch(chatRepositoryProvider)),
);

// ── View model ────────────────────────────────────────────────────────────────

final chatViewModelProvider = NotifierProvider<ChatViewModel, ChatState>(
  ChatViewModel.new,
);
