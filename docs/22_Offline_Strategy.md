# 22 — Offline Strategy

## Purpose
Define how SecureChat behaves without network connectivity — what works offline, how data is queued, how sync happens on reconnect, and conflict resolution.

---

## 1. Offline Principles

1. **Read-first offline** — All previously received messages are always accessible offline
2. **Write-queue offline** — Outgoing messages are encrypted and queued locally
3. **Optimistic UI** — Messages appear immediately with "queued" status; don't wait for network
4. **No data loss** — Messages never discarded, even after app restart
5. **Transparent sync** — User sees clear indicators of offline state and queue

---

## 2. Connectivity Detection

```dart
// lib/core/network/connectivity_service.dart
abstract class ConnectivityService {
  bool get isOnline;
  Stream<bool> get onlineStream;
}

class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity;

  @override
  bool get isOnline {
    // Cached from last connectivity check
    return _cachedIsOnline;
  }

  @override
  Stream<bool> get onlineStream {
    return _connectivity.onConnectivityChanged.map(
      (result) => result != ConnectivityResult.none,
    ).distinct();
  }
}
```

**Riverpod Provider:**
```dart
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityStreamProvider).valueOrNull ?? true;
});

final connectivityStreamProvider = StreamProvider<bool>((ref) {
  return ref.read(connectivityServiceProvider).onlineStream;
});
```

---

## 3. Outbox Queue

### Schema (Drift local SQLite)

```dart
class OutboxQueue extends Table {
  TextColumn get id => text()();               // Temporary local UUID
  TextColumn get pairId => text()();
  BlobColumn get ciphertext => blob()();       // Already encrypted
  TextColumn get messageType => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### Queue Flow

```
[User sends message offline]
    │
    ▼
MessageText validated → Signal Protocol encrypts → ciphertext
    │
    ▼
local_messages: INSERT (status = queued)
outbox_queue: INSERT (ciphertext, pairId, messageType)
    │
    ▼
UI shows message with "queued" icon
    │
    ▼
[Network comes back online]
    │
    ▼
ConnectivityService.onlineStream emits true
    │
    ▼
OutboxQueue.flush() called by ConnectivityObserver
    │
    ├── For each item in outbox:
    │       remote.insertMessage(ciphertext, pairId)
    │       local_messages.UPDATE status = sent
    │       outbox_queue.DELETE item
    │
    └── Report success count to ViewModel
```

### Retry Policy

| Attempt | Delay | Max |
|---|---|---|
| 1st | Immediate | — |
| 2nd | 5 seconds | — |
| 3rd | 30 seconds | — |
| 4th+ | 5 minutes | 10 total attempts |

After 10 failed attempts: message stays in "failed" state. User shown retry button.

---

## 4. Gap Fill on Reconnect

When app reconnects after being offline, it may have missed messages that arrived while disconnected (Realtime was not connected). We reconcile:

```dart
class GapFillService {
  Future<void> fillGap(String pairId) async {
    // Find the most recent local message timestamp
    final lastMessage = await _local.getLatestMessage(pairId);
    final since = lastMessage?.sentAt ?? DateTime(2024);

    // Fetch all server messages newer than our last local message
    final missed = await _remote.fetchMessagesSince(pairId, since);

    for (final dto in missed) {
      final alreadyExists = await _local.exists(dto.id);
      if (alreadyExists) continue;

      final decrypted = await _encryption.decrypt(dto.ciphertext);
      if (decrypted.isRight()) {
        await _local.insertMessage(
          MessageMapper.fromDto(dto, decryptedContent: decrypted.getOrElse(() => ''), reactions: []),
        );
      }
    }
  }
}
```

**Trigger:** `ConnectivityService.onlineStream` → reconnect event → `GapFillService.fillGap(pairId)`.

---

## 5. Realtime Reconnection

Supabase Realtime channel reconnects automatically. After reconnect:

1. Channel subscription re-established
2. GapFillService fills any missed messages
3. Outbox queue flushed

```dart
supabase.channel('messages:$pairId')
  .onPostgresChanges(...)
  .subscribe((status) {
    if (status == RealtimeSubscribeStatus.subscribed) {
      _gapFillService.fillGap(pairId);
      _outboxQueue.flush();
    }
  });
```

---

## 6. Offline Read Experience

### What Works Offline
- View all previously received messages (from local SQLite)
- View cached media (from app documents directory)
- Compose and queue new messages
- View partner profile (cached)
- Change settings (local + queued sync)

### What Requires Connection
- Send media (upload required)
- Receive new messages (Realtime)
- Login / OTP verification
- Profile update sync

---

## 7. Offline UI

```
┌─────────────────────────────────────────┐
│  ⚠️ You're offline · 3 messages queued  │  ← Amber banner (animated in)
├─────────────────────────────────────────┤
│  [Chat content — fully accessible]      │
│                                         │
│  "Hey I'll be late"     ⏳              │  ← Queued icon
│  "Miss you!"            ⏳              │  ← Queued icon
└─────────────────────────────────────────┘
```

**Offline Banner:**
- Background: `Colors.amber.shade100`
- Icon: `Icons.wifi_off`
- Text: "You're offline · {n} messages queued" (only if queue > 0)
- Animates in/out with `SizeTransition`

---

## 8. Signal Protocol and Offline

The Signal Protocol session state is stored locally. Encrypting messages for the outbox queue:

1. Session state is read from secure storage
2. Message encrypted against current session
3. Session state advanced (ratchet step) and saved back to secure storage
4. Ciphertext stored in outbox

When partner is also offline and the session has advanced significantly between reconnects, the Signal Protocol Double Ratchet handles out-of-order delivery automatically via its skipped-message-key store.

---

## 9. Conflict Resolution

Since SecureChat has exactly two users and messages are append-only:
- No write conflicts can occur (each user writes their own messages)
- Ordering conflicts: messages ordered by `sent_at` timestamp; concurrent sends from both users are ordered by timestamp + message ID for determinism
- Timestamp skew: server `sent_at` is set by Supabase (`DEFAULT NOW()`) — not client clock

There are no multi-user conflict scenarios to resolve.
