# 13 — State Management

## Purpose
Define how Riverpod is used throughout SecureChat — provider types, naming conventions, state shapes, async patterns, and inter-provider dependencies.

---

## 1. Riverpod Philosophy

- **Every piece of state lives in a Riverpod provider** — no global variables, no singletons, no `setState` for business data
- **Providers are defined at feature level** — in `features/<feature>/providers.dart`
- **Compile-time safety** — using `@riverpod` code generation (riverpod_generator) wherever possible
- **Testable** — all providers can be overridden in tests via `ProviderContainer`
- **No BuildContext in providers** — providers are pure Dart; they don't depend on the widget tree

---

## 2. Provider Types Used

| Provider Type | When Used | Example |
|---|---|---|
| `Provider<T>` | Synchronous, non-changing values (services, repositories) | `supabaseClientProvider` |
| `FutureProvider<T>` | Async one-shot values | `currentPairProvider` |
| `StreamProvider<T>` | Ongoing async streams | `messageListProvider`, `authStateProvider` |
| `NotifierProvider<N, T>` | Sync state with mutation methods | `settingsProvider` |
| `AsyncNotifierProvider<N, T>` | Async state with mutation methods | `chatViewModelProvider` |
| `StateProvider<T>` | Simple local UI state | `messageInputProvider` |

---

## 3. Provider Naming Convention

```
// Naming pattern: <noun><Suffix>Provider
// Suffix rules:
//   No suffix = pure Provider (services, repos, use cases)
//   ViewModel = AsyncNotifierProvider for screens
//   State     = NotifierProvider for simple state
//   Stream    = StreamProvider

// Examples:
final supabaseClientProvider          // Provider<SupabaseClient>
final authRepositoryProvider          // Provider<AuthRepository>
final requestOtpUseCaseProvider       // Provider<RequestOtpUseCase>
final authStateProvider               // StreamProvider<AuthState>
final loginViewModelProvider          // AsyncNotifierProvider<LoginViewModel, LoginState>
final chatViewModelProvider           // AsyncNotifierProvider<ChatViewModel, ChatState>
final messageListProvider             // StreamProvider<List<Message>>
final settingsProvider                // NotifierProvider<SettingsNotifier, AppSettings>
final currentPairProvider             // FutureProvider<Pair?>
final isTypingProvider                // StreamProvider<bool>
```

---

## 4. Core Provider Definitions

### 4.1 Infrastructure Providers

```
// lib/core/providers/infrastructure_providers.dart

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.firstUnlock),
  );
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider).valueOrNull;
  return connectivity != null && connectivity != ConnectivityResult.none;
});
```

### 4.2 Auth Feature Providers

```
// lib/features/auth/providers.dart

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.read(supabaseClientProvider));
});

final authSecureDataSourceProvider = Provider<AuthSecureDataSource>((ref) {
  return AuthSecureDataSourceImpl(ref.read(secureStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.read(authRemoteDataSourceProvider),
    secure: ref.read(authSecureDataSourceProvider),
  );
});

final requestOtpUseCaseProvider = Provider<RequestOtpUseCase>((ref) {
  return RequestOtpUseCase(ref.read(authRepositoryProvider));
});

final verifyOtpUseCaseProvider = Provider<VerifyOtpUseCase>((ref) {
  return VerifyOtpUseCase(ref.read(authRepositoryProvider));
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authRepositoryProvider).watchAuthState();
});

final loginViewModelProvider =
    AsyncNotifierProvider<LoginViewModel, LoginState>(() => LoginViewModel());
```

### 4.3 Chat Feature Providers

```
// lib/features/chat/providers.dart

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepositoryImpl(
    remote: ref.read(messageRemoteDataSourceProvider),
    local: ref.read(messageLocalDataSourceProvider),
    encryption: ref.read(encryptionServiceProvider),
  );
});

// Stream of messages for current pair — auto-updates via Realtime
final messageListProvider = StreamProvider.autoDispose
    .family<List<Message>, PairId>((ref, pairId) {
  return ref.read(messageRepositoryProvider).watchMessages(pairId);
});

// Typing indicator stream
final isPartnerTypingProvider = StreamProvider.autoDispose
    .family<bool, PairId>((ref, pairId) {
  return ref.read(typingRepositoryProvider).watchPartnerTyping(pairId);
});

// Chat ViewModel
final chatViewModelProvider =
    AsyncNotifierProvider.autoDispose
        .family<ChatViewModel, ChatState, PairId>(ChatViewModel.new);
```

---

## 5. ViewModel Pattern

Every screen has a corresponding ViewModel (Riverpod AsyncNotifier or Notifier).

### 5.1 LoginViewModel

```
class LoginViewModel extends AsyncNotifier<LoginState> {
  @override
  Future<LoginState> build() async {
    return const LoginState.initial();
  }

  Future<void> requestOtp(String phone) async {
    state = const AsyncLoading();
    final phoneOrFailure = PhoneNumber.create(phone);
    final result = await phoneOrFailure.fold(
      (failure) async => Left(failure),
      (phone) => ref.read(requestOtpUseCaseProvider).execute(phone),
    );
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(LoginState.otpSent()),
    );
  }

  Future<void> verifyOtp(String phone, String code) async {
    state = const AsyncLoading();
    final result = await ref.read(verifyOtpUseCaseProvider).execute(
      VerifyOtpParams(phone: phone, code: code),
    );
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (session) => AsyncData(LoginState.success(session)),
    );
  }
}
```

### 5.2 ChatViewModel

```
class ChatViewModel extends FamilyAsyncNotifier<ChatState, PairId> {
  @override
  Future<ChatState> build(PairId pairId) async {
    // Watch real-time message stream
    ref.listen(messageListProvider(pairId), (prev, next) {
      if (next.hasValue) {
        state = AsyncData(state.valueOrNull?.copyWith(
          messages: next.value!,
        ) ?? ChatState.initial(next.value!));
      }
    });

    return ChatState.initial(await _loadInitialMessages(pairId));
  }

  Future<void> sendMessage(String text) async {
    final params = SendMessageParams(
      text: text,
      pairId: arg, // arg = pairId from family parameter
    );
    final result = await ref.read(sendMessageUseCaseProvider).execute(params);
    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (message) => null, // StreamProvider already updates messages
    );
  }

  Future<void> sendTypingIndicator(bool isTyping) async {
    await ref.read(typingUseCaseProvider).execute(
      TypingParams(pairId: arg, isTyping: isTyping),
    );
  }
}
```

---

## 6. State Classes

Every ViewModel has a corresponding immutable state class:

```
@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    required List<Message> messages,
    required bool isLoadingMore,
    required bool hasReachedEnd,
    required bool isOffline,
    required int queuedCount,
  }) = _ChatState;

  factory ChatState.initial(List<Message> messages) => ChatState(
    messages: messages,
    isLoadingMore: false,
    hasReachedEnd: false,
    isOffline: false,
    queuedCount: 0,
  );
}
```

**Rules for State Classes:**
- Immutable (use `freezed` or manual `copyWith`)
- No methods — state is pure data
- Named constructors for common initial states
- No nullable fields where possible — use empty list, empty string, or explicit enum values

---

## 7. Provider Scoping and Lifecycle

### `autoDispose`
Used for providers tied to specific screens. Automatically cleaned up when no widget is watching.

```
// Message list for a specific pair — disposed when chat screen is popped
final messageListProvider = StreamProvider.autoDispose
    .family<List<Message>, PairId>((ref, pairId) { ... });
```

### Keeping Providers Alive
For providers that must survive navigation (e.g., auth state, current pair):

```
final authStateProvider = StreamProvider<AuthState>((ref) {
  // No autoDispose — auth state must persist across all screens
  return ref.read(authRepositoryProvider).watchAuthState();
});
```

### `family`
Used when the same provider type is needed for different parameters:

```
// Different message lists for different pairs (though SecureChat has only one pair,
// family is used for correctness and testability)
final messageListProvider = StreamProvider.family<List<Message>, String>(
  (ref, pairId) => ...,
);
```

---

## 8. Error Handling in Providers

```
// In ViewModel
result.fold(
  (failure) {
    state = AsyncError(failure, StackTrace.current);
  },
  (data) {
    state = AsyncData(ChatState(...));
  },
);

// In Widget (Screen)
ref.listen(chatViewModelProvider(pairId), (previous, next) {
  next.whenOrNull(
    error: (failure, _) {
      if (failure is ServerFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.serverError)),
        );
      }
    },
  );
});
```

---

## 9. Provider Testing

All providers are testable by overriding dependencies:

```
final container = ProviderContainer(
  overrides: [
    authRepositoryProvider.overrideWithValue(MockAuthRepository()),
    supabaseClientProvider.overrideWithValue(mockClient),
  ],
);

test('login with invalid OTP returns AuthFailure', () async {
  final viewModel = container.read(loginViewModelProvider.notifier);
  await viewModel.verifyOtp('+919876543210', '000000');
  final state = container.read(loginViewModelProvider);
  expect(state.hasError, true);
  expect(state.error, isA<AuthFailure>());
});
```

---

## 10. Provider Dependency Graph

```
supabaseClientProvider ─────────────────────────────────────────────┐
secureStorageProvider ──────────────────────────────────────────────┤
appDatabaseProvider ────────────────────────────────────────────────┤
                                                                     │
authRemoteDataSourceProvider ← supabaseClientProvider               │
authSecureDataSourceProvider ← secureStorageProvider                │
authRepositoryProvider ← authRemoteDS + authSecureDS                │
requestOtpUseCaseProvider ← authRepositoryProvider                  │
verifyOtpUseCaseProvider ← authRepositoryProvider                   │
authStateProvider ← authRepositoryProvider (stream)                 │
loginViewModelProvider ← requestOtpUseCase + verifyOtpUseCase      │
                                                                     │
encryptionServiceProvider ← secureStorageProvider                   │
messageRemoteDataSourceProvider ← supabaseClientProvider            │
messageLocalDataSourceProvider ← appDatabaseProvider                │
messageRepositoryProvider ← remote + local + encryptionService      │
sendMessageUseCaseProvider ← messageRepositoryProvider              │
messageListProvider ← messageRepositoryProvider (stream)            │
chatViewModelProvider ← sendMessageUseCase + messageListProvider   │
```
