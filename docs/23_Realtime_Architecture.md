# 23 — Realtime Architecture

## Purpose
Define how Supabase Realtime is used — channel types, subscriptions, presence management, reconnection handling, and performance considerations.

---

## 1. Realtime Overview

Supabase Realtime uses WebSockets (Phoenix protocol) to stream database changes and broadcast custom events to connected clients.

**Three channel modes used:**

| Mode | Purpose | Used For |
|---|---|---|
| `postgres_changes` | Stream DB row changes (INSERT, UPDATE, DELETE) | New messages, message updates, pair changes |
| `broadcast` | Ephemeral custom events (not persisted) | Typing indicators |
| `presence` | Track which users are online in a channel | Partner online status |

---

## 2. Channel Naming Convention

All channels are namespaced by pair_id to enforce isolation:

```
messages:{pair_id}         ← Message INSERT/UPDATE/DELETE events
receipts:{pair_id}         ← Message receipt events
reactions:{pair_id}        ← Reaction INSERT/DELETE events
typing:{pair_id}           ← Typing broadcast events
presence:{pair_id}         ← Partner presence tracking
pairs:{user_id}            ← Pair status changes (accept, dissolve)
```

---

## 3. Subscription Lifecycle

### 3.1 Subscribe on Chat Screen Open

```dart
class RealtimeDataSource {
  final SupabaseClient _client;
  final Map<String, RealtimeChannel> _channels = {};

  void subscribeToChat(String pairId) {
    final channelKey = 'chat_$pairId';
    if (_channels.containsKey(channelKey)) return; // Already subscribed

    final channel = _client.channel('messages:$pairId')
      ..onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: FilterType.eq,
            column: 'pair_id',
            value: pairId,
          ),
          callback: _onMessageInsert,
        )
      ..onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: FilterType.eq,
            column: 'pair_id',
            value: pairId,
          ),
          callback: _onMessageUpdate,
        )
      ..subscribe((status) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _triggerGapFill(pairId);
        }
      });

    _channels[channelKey] = channel;
  }

  void unsubscribeFromChat(String pairId) {
    final channel = _channels.remove('chat_$pairId');
    channel?.unsubscribe();
  }
}
```

### 3.2 Unsubscribe on Chat Screen Dispose

```dart
// In ChatViewModel
@override
void dispose() {
  _realtimeDataSource.unsubscribeFromChat(pairId);
  super.dispose();
}
```

Using `ref.onDispose` in Riverpod:
```dart
ref.onDispose(() {
  ref.read(realtimeDataSourceProvider).unsubscribeFromChat(arg);
});
```

---

## 4. Message Stream

### 4.1 New Message Handling

```dart
void _onMessageInsert(PostgresChangePayload payload) async {
  final dto = MessageDto.fromJson(payload.newRecord);

  // Don't process own messages (already in local DB from optimistic insert)
  if (dto.senderId == _currentUserId) {
    // Just update the status of the optimistic message
    await _local.updateMessageStatus(dto.id, MessageStatus.delivered);
    return;
  }

  // Decrypt incoming message
  final decrypted = await _encryption.decrypt(Uint8List.fromList(dto.ciphertext));
  if (decrypted.isLeft()) {
    AppLogger.error('Failed to decrypt incoming message: ${dto.id}');
    return;
  }

  // Insert decrypted message to local DB
  final message = MessageMapper.fromDto(
    dto,
    decryptedContent: decrypted.getOrElse(() => ''),
    reactions: [],
  );
  await _local.insertMessage(message);

  // Send read receipt if chat is active
  if (_isChatActive) {
    await _sendReadReceipt(dto.id);
  }
}
```

### 4.2 Message Update Handling

```dart
void _onMessageUpdate(PostgresChangePayload payload) async {
  final dto = MessageDto.fromJson(payload.newRecord);

  if (dto.deletedAt != null) {
    // Message deleted
    await _local.markMessageDeleted(dto.id);
    return;
  }

  if (dto.editedAt != null) {
    // Message edited — decrypt new ciphertext
    final decrypted = await _encryption.decrypt(
      Uint8List.fromList(dto.ciphertext),
    );
    if (decrypted.isRight()) {
      await _local.updateMessageContent(dto.id, decrypted.getOrElse(() => ''));
      await _local.updateMessageEditedAt(dto.id, dto.editedAt!);
    }
    return;
  }
}
```

---

## 5. Typing Indicator

### 5.1 Subscribe

```dart
void subscribeToTyping(String pairId) {
  _client.channel('typing:$pairId')
    ..onBroadcast(
        event: 'typing',
        callback: (payload) {
          final userId = payload['user_id'] as String;
          final isTyping = payload['is_typing'] as bool;
          if (userId != _currentUserId) {
            _typingStreamController.add(isTyping);
          }
        },
      )
    ..subscribe();
}
```

### 5.2 Send Typing Events

```dart
void sendTypingEvent(String pairId, bool isTyping) {
  _client.channel('typing:$pairId').sendBroadcastMessage(
    event: 'typing',
    payload: {
      'user_id': _currentUserId,
      'is_typing': isTyping,
    },
  );
}
```

### 5.3 Debounce in ViewModel

```dart
Timer? _typingTimer;

void onTextChanged(String text) {
  if (text.isNotEmpty) {
    _sendTypingEvent(true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _sendTypingEvent(false);
    });
  } else {
    _typingTimer?.cancel();
    _sendTypingEvent(false);
  }
}
```

---

## 6. Presence (Partner Online Status)

```dart
void subscribeToPresence(String pairId) {
  final channel = _client.channel('presence:$pairId');

  channel
    ..onPresenceSync(callback: (payload) {
      // Check if partner is in presences
      final presences = channel.presenceState();
      final partnerPresent = presences.values
          .expand((list) => list)
          .any((p) => p['user_id'] != _currentUserId);
      _partnerOnlineController.add(partnerPresent);
    })
    ..onPresenceJoin(callback: (payload) {
      if (payload.newPresences.any((p) => p['user_id'] != _currentUserId)) {
        _partnerOnlineController.add(true);
      }
    })
    ..onPresenceLeave(callback: (payload) {
      if (payload.leftPresences.any((p) => p['user_id'] != _currentUserId)) {
        _partnerOnlineController.add(false);
        _updateLastSeen(); // Update user_presence table
      }
    })
    ..subscribe((status) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        // Track own presence
        channel.track({'user_id': _currentUserId, 'online_at': DateTime.now().toIso8601String()});
      }
    });
}
```

---

## 7. Pair Status Subscription (for pairing flow)

```dart
void subscribeToPairAcceptance(String creatorUserId) {
  _client.channel('pairs:$creatorUserId')
    ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'pairs',
        filter: PostgresChangeFilter(
          type: FilterType.eq,
          column: 'user_a_id',
          value: creatorUserId,
        ),
        callback: (payload) {
          final pairId = payload.newRecord['id'] as String;
          _pairAcceptedStreamController.add(pairId);
        },
      )
    ..subscribe();
}
```

---

## 8. Realtime Performance

### 8.1 Connection Management

| App State | Channels |
|---|---|
| Foreground + chat open | messages, receipts, reactions, typing, presence |
| Foreground + other screen | None (autoDispose removes chat channels) |
| Background | All channels disconnected |
| Terminated | No connection |

### 8.2 Channel Limit

Supabase free tier: 200 concurrent channels. SecureChat per-user uses at most 5 channels. No issue.

### 8.3 Bandwidth

| Event Type | Frequency | Payload Size |
|---|---|---|
| New message | User-driven | ~1–5 KB (ciphertext) |
| Message update | Rare | ~1 KB |
| Typing event | ~1/300ms while typing | ~50 bytes |
| Presence ping | ~30s heartbeat | ~100 bytes |

Typing events are the most frequent. Debounced to once per 300ms keystroke activity.

---

## 9. Realtime Security

- **Channel isolation:** Channel name includes `pair_id` — clients cannot subscribe to other pairs' channels
- **RLS on postgres_changes:** Supabase enforces RLS on all Realtime events — even if a client subscribes to a channel, they only receive events for rows they have SELECT access to
- **No sensitive data in broadcast:** Typing events contain only `user_id` and `is_typing` — no content
- **Presence data:** Contains only `user_id` and online timestamp — no sensitive data
