# 21 — Repository Pattern

## Purpose
Define the repository pattern implementation — abstract interfaces, concrete implementations, data source composition, error handling, caching strategy, and testing approach.

---

## 1. Repository Principles

1. **One repository per domain aggregate** (not per table)
2. **Repositories return domain entities** — never DTOs, never raw JSON
3. **Repositories handle all errors** — convert exceptions to `Either<Failure, T>`
4. **Repositories decide data source priority** — remote vs local vs cache
5. **Repositories are the only callers of data sources**
6. **Use cases depend on repository interfaces** — never implementations

---

## 2. Base Use Case

```dart
// lib/core/use_case/use_case.dart
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> execute(Params params);
}

abstract class UseCaseNoParams<Type> {
  Future<Either<Failure, Type>> execute();
}

abstract class StreamUseCase<Type, Params> {
  Stream<Either<Failure, Type>> execute(Params params);
}

class NoParams {
  const NoParams();
}
```

---

## 3. Repository Interfaces

### 3.1 `MessageRepository`

```dart
// lib/features/chat/domain/repositories/message_repository.dart
abstract class MessageRepository {
  // Send a message (encrypt → upload → store locally)
  Future<Either<Failure, Message>> sendMessage(SendMessageParams params);

  // Edit an existing message
  Future<Either<Failure, Message>> editMessage(EditMessageParams params);

  // Delete a message (both sides)
  Future<Either<Failure, void>> deleteMessage(String messageId);

  // Load a page of messages (oldest first in page, newest pages first)
  Future<Either<Failure, List<Message>>> getMessages(
    String pairId, {
    int limit = 50,
    int offset = 0,
  });

  // Real-time stream of messages (local DB as source of truth)
  Stream<Either<Failure, List<Message>>> watchMessages(String pairId);

  // Mark message as read
  Future<Either<Failure, void>> markAsRead(String messageId);

  // Add reaction to message
  Future<Either<Failure, void>> addReaction(String messageId, String emoji);

  // Remove reaction from message
  Future<Either<Failure, void>> removeReaction(String messageId);

  // Search messages locally
  Future<Either<Failure, List<Message>>> searchMessages(String query, String pairId);

  // Flush offline queue
  Future<Either<Failure, int>> flushOutboxQueue();
}
```

### 3.2 `AuthRepository`

```dart
abstract class AuthRepository {
  Future<Either<AuthFailure, void>> requestPhoneOtp(PhoneNumber phone);
  Future<Either<AuthFailure, AuthSession>> verifyPhoneOtp(VerifyOtpParams params);
  Future<Either<AuthFailure, void>> requestEmailMagicLink(EmailAddress email);
  Future<Either<AuthFailure, AuthSession?>> getStoredSession();
  Future<Either<AuthFailure, void>> refreshSession();
  Future<Either<AuthFailure, void>> logout();
  Stream<AuthState> watchAuthState();
}
```

### 3.3 `PairingRepository`

```dart
abstract class PairingRepository {
  Future<Either<Failure, PairCode>> generateInviteCode();
  Future<Either<Failure, Pair>> acceptInviteCode(PairCode code);
  Future<Either<Failure, Pair?>> getCurrentPair();
  Stream<Either<Failure, Pair?>> watchPairStatus();
  Future<Either<Failure, void>> dissolvePair();
}
```

### 3.4 `ProfileRepository`

```dart
abstract class ProfileRepository {
  Future<Either<Failure, UserProfile>> createProfile(CreateProfileParams params);
  Future<Either<Failure, UserProfile>> updateProfile(UpdateProfileParams params);
  Future<Either<Failure, UserProfile>> getMyProfile();
  Future<Either<Failure, UserProfile>> getPartnerProfile(String partnerId);
  Future<Either<Failure, String>> uploadAvatar(File imageFile);
  Stream<Either<Failure, UserProfile>> watchPartnerProfile(String partnerId);
}
```

### 3.5 `MediaRepository`

```dart
abstract class MediaRepository {
  Future<Either<Failure, MediaUploadResult>> uploadImage(File imageFile, String pairId);
  Future<Either<Failure, MediaUploadResult>> uploadVoice(File audioFile, String pairId);
  Future<Either<Failure, File>> downloadMedia(String storageUrl, String messageId);
  Future<Either<Failure, void>> deleteMedia(String storageUrl);
}
```

---

## 4. Repository Implementations

### 4.1 `MessageRepositoryImpl`

```dart
class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource _remote;
  final MessageLocalDataSource _local;
  final EncryptionService _encryption;
  final ConnectivityService _connectivity;

  const MessageRepositoryImpl({
    required MessageRemoteDataSource remote,
    required MessageLocalDataSource local,
    required EncryptionService encryption,
    required ConnectivityService connectivity,
  }) : _remote = remote, _local = local,
       _encryption = encryption, _connectivity = connectivity;

  @override
  Future<Either<Failure, Message>> sendMessage(SendMessageParams params) async {
    // 1. Encrypt message
    final encryptResult = await _encryption.encrypt(params.text.value);
    if (encryptResult.isLeft()) {
      return encryptResult.map((_) => throw StateError('unreachable'));
    }
    final ciphertext = encryptResult.getOrElse(() => throw StateError(''));

    // 2. Create optimistic local message
    final optimisticMessage = Message.optimistic(
      pairId: params.pairId,
      content: TextContent(params.text.value),
      senderId: _currentUserId,
    );
    await _local.insertMessage(optimisticMessage);

    // 3. Check connectivity
    if (!_connectivity.isOnline) {
      await _local.addToOutbox(ciphertext, params.pairId);
      return Right(optimisticMessage.copyWith(status: MessageStatus.queued));
    }

    // 4. Send to remote
    try {
      final dto = await _remote.insertMessage(
        pairId: params.pairId,
        ciphertext: ciphertext,
        messageType: 'text',
      );
      final message = MessageMapper.fromDto(dto, decryptedContent: params.text.value, reactions: []);
      await _local.updateMessage(message);
      return Right(message);
    } on PostgrestException catch (e) {
      await _local.updateMessageStatus(optimisticMessage.id, MessageStatus.failed);
      return Left(ServerFailure(e.message));
    } on SocketException {
      await _local.addToOutbox(ciphertext, params.pairId);
      return Right(optimisticMessage.copyWith(status: MessageStatus.queued));
    }
  }

  @override
  Stream<Either<Failure, List<Message>>> watchMessages(String pairId) {
    return _local.watchMessages(pairId).map(
      (messages) => Right<Failure, List<Message>>(messages),
    ).handleError(
      (error) => Left<Failure, List<Message>>(CacheFailure(error.toString())),
    );
  }

  @override
  Future<Either<Failure, int>> flushOutboxQueue() async {
    try {
      final queued = await _local.getOutboxQueue();
      int sent = 0;
      for (final item in queued) {
        try {
          await _remote.insertMessage(
            pairId: item.pairId,
            ciphertext: item.ciphertext,
            messageType: item.messageType,
          );
          await _local.removeFromOutbox(item.id);
          await _local.updateMessageStatus(item.id, MessageStatus.sent);
          sent++;
        } catch (_) {
          // Individual failures don't abort the queue
        }
      }
      return Right(sent);
    } on DriftException catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
```

---

## 5. Data Sources

### 5.1 Remote Data Source Pattern

```dart
abstract class MessageRemoteDataSource {
  Future<MessageDto> insertMessage({
    required String pairId,
    required Uint8List ciphertext,
    required String messageType,
  });

  Future<List<MessageDto>> fetchMessages(String pairId, {int limit, int offset});
  Future<void> updateMessage(String id, Map<String, dynamic> updates);
  Future<void> deleteMessage(String id);
  Future<void> markAsRead(String messageId, String userId);
  Future<void> addReaction(String messageId, String userId, String emoji);
  Future<void> removeReaction(String messageId, String userId);
  Stream<MessageDto> watchNewMessages(String pairId);
}

class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  final SupabaseClient _client;

  const MessageRemoteDataSourceImpl(this._client);

  @override
  Future<MessageDto> insertMessage({...}) async {
    final response = await _client
        .from('messages')
        .insert({
          'pair_id': pairId,
          'sender_id': _client.auth.currentUser!.id,
          'message_type': messageType,
          'ciphertext': ciphertext,
        })
        .select()
        .single();
    return MessageDto.fromJson(response);
  }
}
```

### 5.2 Local Data Source Pattern

```dart
abstract class MessageLocalDataSource {
  Future<void> insertMessage(Message message);
  Future<void> updateMessage(Message message);
  Future<void> updateMessageStatus(String id, MessageStatus status);
  Future<List<Message>> getMessages(String pairId, {int limit, int offset});
  Stream<List<Message>> watchMessages(String pairId);
  Future<void> addToOutbox(Uint8List ciphertext, String pairId);
  Future<List<OutboxItem>> getOutboxQueue();
  Future<void> removeFromOutbox(String id);
  Future<void> deleteAllForPair(String pairId);
}
```

---

## 6. Error Conversion Pattern

Every data source method wraps exceptions at the boundary:

```dart
// In repository implementation:
try {
  final dto = await _remote.insertMessage(...);
  return Right(MessageMapper.fromDto(dto, ...));
} on PostgrestException catch (e) {
  return switch (e.statusCode) {
    '401' => Left(const AuthFailure.unauthorized()),
    '403' => Left(const AuthFailure.forbidden()),
    _ => Left(ServerFailure(e.message)),
  };
} on SocketException {
  return Left(const ServerFailure.noConnection());
} on TimeoutException {
  return Left(const ServerFailure.timeout());
} on DriftException catch (e) {
  return Left(CacheFailure(e.toString()));
} catch (e, stack) {
  AppLogger.error('Unexpected error in MessageRepository', e, stack);
  return Left(UnknownFailure(e.toString()));
}
```

---

## 7. Caching Strategy

| Data | Cache Strategy |
|---|---|
| Messages | Local SQLite is source of truth; Realtime keeps it updated |
| User Profile | Cached in SQLite; invalidated on `user_profiles` Realtime event |
| Pair | Cached in secure storage; reloaded on app start |
| Settings | Cached in SharedPreferences; synced to Supabase on change |
| Media | Cached in app documents directory; LRU eviction (future) |

---

## 8. Repository Testing

```dart
// test/unit/features/chat/data/repositories/message_repository_impl_test.dart

void main() {
  late MessageRepositoryImpl repository;
  late MockMessageRemoteDataSource mockRemote;
  late MockMessageLocalDataSource mockLocal;
  late MockEncryptionService mockEncryption;
  late MockConnectivityService mockConnectivity;

  setUp(() {
    mockRemote = MockMessageRemoteDataSource();
    mockLocal = MockMessageLocalDataSource();
    mockEncryption = MockEncryptionService();
    mockConnectivity = MockConnectivityService();

    repository = MessageRepositoryImpl(
      remote: mockRemote,
      local: mockLocal,
      encryption: mockEncryption,
      connectivity: mockConnectivity,
    );
  });

  group('sendMessage', () {
    test('returns Right(Message) on successful send', () async {
      when(mockConnectivity.isOnline).thenReturn(true);
      when(mockEncryption.encrypt(any)).thenAnswer(
        (_) async => Right(Uint8List(0)),
      );
      when(mockRemote.insertMessage(...)).thenAnswer(
        (_) async => fakeMessageDto,
      );

      final result = await repository.sendMessage(fakeSendParams);

      expect(result.isRight(), true);
    });

    test('queues message when offline', () async {
      when(mockConnectivity.isOnline).thenReturn(false);
      when(mockEncryption.encrypt(any)).thenAnswer(
        (_) async => Right(Uint8List(0)),
      );

      final result = await repository.sendMessage(fakeSendParams);

      verify(mockLocal.addToOutbox(any, any)).called(1);
      expect(result.getOrElse(() => null)?.status, MessageStatus.queued);
    });

    test('returns Left(ServerFailure) on network error', () async {
      when(mockConnectivity.isOnline).thenReturn(true);
      when(mockRemote.insertMessage(...)).thenThrow(
        const PostgrestException(message: 'Server error', statusCode: '500'),
      );

      final result = await repository.sendMessage(fakeSendParams);

      expect(result.isLeft(), true);
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    });
  });
}
```
