import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/encryption/providers.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/network/supabase_client_provider.dart';
import '../../core/offline/outbox_queue_data_source.dart';
import '../../core/storage/app_database.dart';
import '../auth/providers.dart';
import '../media/providers.dart';
import '../pairing/providers.dart';
import '../profile/domain/entities/user_presence.dart';
import '../profile/domain/entities/user_profile.dart';
import '../profile/providers.dart' as profile_providers;
import 'data/data_sources/local/chat_local_data_source.dart';
import 'data/data_sources/remote/chat_remote_data_source.dart';
import 'data/repositories/chat_repository_impl.dart';
import 'domain/repositories/chat_repository.dart';
import 'domain/use_cases/delete_message_use_case.dart';
import 'domain/use_cases/edit_message_use_case.dart';
import 'domain/use_cases/load_more_messages_use_case.dart';
import 'domain/use_cases/mark_all_read_use_case.dart';
import 'domain/use_cases/react_to_message_use_case.dart';
import 'domain/use_cases/send_media_message_use_case.dart';
import 'domain/use_cases/send_message_use_case.dart';
import 'domain/use_cases/watch_messages_use_case.dart';
import 'presentation/viewmodels/chat_state.dart';
import 'presentation/viewmodels/chat_view_model.dart';

// ── Pair / user helpers (non-nullable after router pair-gate) ─────────────────

final chatOwnUserIdProvider = Provider<String>((ref) {
  return ref.watch(currentUserIdProvider) ?? '';
});

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

final outboxQueueDataSourceProvider = Provider<OutboxQueueDataSource>((ref) {
  return OutboxQueueDataSourceImpl(ref.watch(appDatabaseProvider));
});

// ── Repository ────────────────────────────────────────────────────────────────

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final impl = ChatRepositoryImpl(
    remote: ref.watch(chatRemoteDataSourceProvider),
    local: ref.watch(chatLocalDataSourceProvider),
    encryption: ref.watch(encryptionServiceProvider),
    keyBundleRemote: ref.watch(keyBundleRemoteDataSourceProvider),
    mediaRemote: ref.watch(mediaRemoteDataSourceProvider),
    mediaCache: ref.watch(mediaCacheServiceProvider),
    outboxQueue: ref.watch(outboxQueueDataSourceProvider),
    connectivity: ref.watch(connectivityProvider),
    ownUserId: ref.watch(chatOwnUserIdProvider),
  );
  ref.onDispose(impl.dispose);
  return impl;
});

// ── Offline state ─────────────────────────────────────────────────────────────

/// Count of messages pending delivery in the outbox for the current pair.
final outboxPendingCountProvider = StreamProvider<int>((ref) {
  final pairId = ref.watch(chatPairIdProvider);
  if (pairId.isEmpty) return Stream.value(0);
  return ref.watch(outboxQueueDataSourceProvider).watchPendingCount(pairId);
});

// ── Use cases — M4 ───────────────────────────────────────────────────────────

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(chatRepositoryProvider));
});

final watchMessagesUseCaseProvider = Provider<WatchMessagesUseCase>((ref) {
  return WatchMessagesUseCase(ref.watch(chatRepositoryProvider));
});

final loadMoreMessagesUseCaseProvider = Provider<LoadMoreMessagesUseCase>(
  (ref) => LoadMoreMessagesUseCase(ref.watch(chatRepositoryProvider)),
);

// ── Use cases — M5 ───────────────────────────────────────────────────────────

final editMessageUseCaseProvider = Provider<EditMessageUseCase>((ref) {
  return EditMessageUseCase(ref.watch(chatRepositoryProvider));
});

final deleteMessageUseCaseProvider = Provider<DeleteMessageUseCase>((ref) {
  return DeleteMessageUseCase(ref.watch(chatRepositoryProvider));
});

final reactToMessageUseCaseProvider = Provider<ReactToMessageUseCase>((ref) {
  return ReactToMessageUseCase(ref.watch(chatRepositoryProvider));
});

final markAllReadUseCaseProvider = Provider<MarkAllReadUseCase>((ref) {
  return MarkAllReadUseCase(ref.watch(chatRepositoryProvider));
});

// ── Use cases — M6 ───────────────────────────────────────────────────────────

final sendMediaMessageUseCaseProvider = Provider<SendMediaMessageUseCase>(
  (ref) => SendMediaMessageUseCase(ref.watch(chatRepositoryProvider)),
);

// ── Partner profile & presence (scoped to the current chat partner) ───────────

final chatPartnerProfileProvider = StreamProvider<UserProfile?>((ref) {
  final partnerId = ref.watch(chatPartnerIdProvider);
  if (partnerId.isEmpty) return const Stream.empty();
  return ref
      .read(profile_providers.profileRepositoryProvider)
      .watchPartnerProfile(partnerId);
});

final chatPartnerPresenceProvider = StreamProvider<UserPresence?>((ref) {
  final partnerId = ref.watch(chatPartnerIdProvider);
  if (partnerId.isEmpty) return const Stream.empty();
  return ref
      .read(profile_providers.profileRepositoryProvider)
      .watchPartnerPresence(partnerId);
});

// ── View model ────────────────────────────────────────────────────────────────

final chatViewModelProvider = NotifierProvider<ChatViewModel, ChatState>(
  ChatViewModel.new,
);
