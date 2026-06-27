# 28 — Performance Strategy

## Purpose
Define performance targets, measurement approach, and optimization techniques for SecureChat at the Flutter, Supabase, and SQLite layers.

---

## 1. Performance Targets (Recap)

| Metric | Target |
|---|---|
| App cold start | < 2 seconds |
| UI frame rate | 60fps (< 2% jank) |
| Message send latency | < 500ms (P95, 4G) |
| Message list initial load | < 300ms |
| SQLite queries | < 50ms |
| Memory (idle) | < 150MB |
| Memory (active chat) | < 250MB |
| Battery (background) | < 1%/hr |

---

## 2. Flutter Performance

### 2.1 Widget Rebuild Minimization

**Rule:** Every widget that doesn't depend on changing state must be `const`.

```dart
// ✅ Good — const constructor, no rebuild on parent rebuild
const MessageStatusIcon(status: MessageStatus.sent);

// ❌ Bad — recreated every parent rebuild
MessageStatusIcon(status: MessageStatus.sent);
```

**Rule:** Use `BlocSelector` / `select` in Riverpod to rebuild only on relevant state changes.

```dart
// ✅ Good — only rebuilds when isTyping changes, not on every chat state update
final isTyping = ref.watch(
  chatViewModelProvider(pairId).select((s) => s.valueOrNull?.isTyping ?? false),
);

// ❌ Bad — rebuilds on every ChatState change
final state = ref.watch(chatViewModelProvider(pairId));
final isTyping = state.valueOrNull?.isTyping ?? false;
```

### 2.2 Message List Optimization

```dart
// ✅ Good — builder with explicit item key for correct diffing
ListView.builder(
  itemCount: messages.length,
  itemBuilder: (context, index) {
    final message = messages[index];
    return KeyedSubtree(
      key: ValueKey(message.id),
      child: MessageBubble(message: message, ...),
    );
  },
)

// ❌ Bad — all items built at once
ListView(
  children: messages.map((m) => MessageBubble(message: m)).toList(),
)
```

**`cacheExtent`:** Set `ListView.builder(cacheExtent: 500)` to pre-render 500px above/below viewport. Reduces jank when scrolling quickly.

### 2.3 Image Loading

```dart
// ✅ Good — cached network image with placeholder and error widget
CachedNetworkImage(
  imageUrl: avatarUrl,
  placeholder: (ctx, url) => const CircularProgressIndicator(),
  errorWidget: (ctx, url, err) => const DefaultAvatarWidget(),
  memCacheWidth: 96,   // Limit in-memory image dimensions
  memCacheHeight: 96,
)

// ❌ Bad — loads full resolution image for a 48dp avatar
Image.network(avatarUrl)
```

### 2.4 RepaintBoundary

Wrap animated or frequently-changing widgets in `RepaintBoundary`:

```dart
RepaintBoundary(
  child: TypingIndicator(isTyping: isTyping),
)

RepaintBoundary(
  child: MessageStatusIcon(status: status),
)
```

### 2.5 Hero Animation Performance

Image viewer Hero animations must not cause jank. Use:
```dart
Hero(
  tag: 'image_${message.id}',
  transitionOnUserGestures: true,  // Smooth on swipe dismiss
  child: Image.file(cachedFile, fit: BoxFit.cover),
)
```

---

## 3. SQLite Performance

### 3.1 Indexing

All frequently queried columns are indexed (defined in DB schema doc):

```sql
CREATE INDEX idx_messages_pair_id_sent_at ON messages(pair_id, sent_at DESC);
-- Covers: SELECT * FROM messages WHERE pair_id = ? ORDER BY sent_at DESC LIMIT 50
```

### 3.2 Pagination Query

```dart
// Drift query — uses index efficiently
Future<List<Message>> getMessages(String pairId, {int offset = 0}) {
  return (select(localMessages)
    ..where((m) => m.pairId.equals(pairId))
    ..where((m) => m.isDeleted.equals(false))
    ..orderBy([(m) => OrderingTerm.desc(m.sentAt)])
    ..limit(50, offset: offset))
  .get();
}
```

### 3.3 Full-Text Search

FTS5 virtual table for message search:

```sql
CREATE VIRTUAL TABLE messages_fts USING fts5(
  content,
  content='local_messages',
  content_rowid='rowid'
);

-- Trigger to keep FTS in sync
CREATE TRIGGER messages_fts_ai AFTER INSERT ON local_messages BEGIN
  INSERT INTO messages_fts(rowid, content) VALUES (new.rowid, new.content);
END;
```

FTS5 queries run in < 10ms for typical message counts.

### 3.4 Database WAL Mode

```dart
@DriftDatabase(tables: [...])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'secure_chat',
      native: const DriftNativeOptions(
        databaseSetup: (db) {
          // Enable WAL for better concurrent read/write performance
          db.execute('PRAGMA journal_mode=WAL');
          db.execute('PRAGMA foreign_keys=ON');
          db.execute('PRAGMA cache_size=-8000'); // 8MB cache
        },
      ),
    );
  }
}
```

---

## 4. Encryption Performance

Signal Protocol encryption adds overhead per message. Targets:
- Encrypt text message: < 20ms
- Decrypt text message: < 20ms
- Encrypt 2MB image: < 200ms (AES-GCM)

If encryption is slow (>50ms for text), run it in an isolate:

```dart
// Isolate for heavy encryption
Future<Uint8List> encryptInIsolate(EncryptParams params) {
  return compute(_encryptMessage, params);
}

Uint8List _encryptMessage(EncryptParams params) {
  // Signal Protocol encryption here (no Flutter SDK access needed)
  return encryptedBytes;
}
```

---

## 5. Memory Management

### 5.1 Image Cache Size

```dart
// In main.dart
PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024; // 100MB
PaintingBinding.instance.imageCache.maximumSize = 200; // Max 200 images
```

### 5.2 Riverpod AutoDispose

Always use `autoDispose` for screen-level providers to free memory when screens are popped:

```dart
final messageListProvider = StreamProvider.autoDispose
    .family<List<Message>, String>((ref, pairId) {
  // This is automatically cleaned up when chat screen is disposed
  return ref.read(messageRepositoryProvider).watchMessages(pairId);
});
```

### 5.3 Stream Subscription Cleanup

All StreamSubscriptions must be cancelled in `dispose()`:

```dart
// In a StatefulWidget
@override
void dispose() {
  _subscription?.cancel();
  _scrollController.dispose();
  super.dispose();
}
```

In Riverpod providers, use `ref.onDispose`:

```dart
final myStreamProvider = Provider.autoDispose((ref) {
  final subscription = myStream.listen(...);
  ref.onDispose(subscription.cancel);
  return something;
});
```

---

## 6. Network Performance

### 6.1 Parallel Requests

Where multiple independent API calls are needed, use `Future.wait`:

```dart
// ✅ Good — parallel requests
final [profile, pair, settings] = await Future.wait([
  _profileRepository.getMyProfile(),
  _pairingRepository.getCurrentPair(),
  _settingsRepository.getSettings(),
]);

// ❌ Bad — sequential requests (3x slower)
final profile = await _profileRepository.getMyProfile();
final pair = await _pairingRepository.getCurrentPair();
final settings = await _settingsRepository.getSettings();
```

### 6.2 Supabase Query Optimization

Use `select('specific, columns')` instead of `select('*')` for large tables:

```dart
// ✅ Good — only fetch needed columns
supabase.from('messages')
  .select('id, pair_id, sender_id, message_type, ciphertext, status, sent_at')
  .eq('pair_id', pairId)
  .limit(50);

// ❌ Bad — fetches all columns including heavy ones
supabase.from('messages').select().eq('pair_id', pairId).limit(50);
```

---

## 7. Performance Monitoring

### 7.1 Frame Rate Monitoring

```dart
// In debug/profile mode
WidgetsBinding.instance.addTimingsCallback((timings) {
  for (final timing in timings) {
    if (timing.totalSpan > const Duration(milliseconds: 16)) {
      AppLogger.warning('Slow frame: ${timing.totalSpan.inMilliseconds}ms');
    }
  }
});
```

### 7.2 Cold Start Measurement

```dart
// In main.dart
final startTime = DateTime.now();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ... setup
  AppLogger.info('App started in ${DateTime.now().difference(startTime).inMilliseconds}ms');
  runApp(const App());
}
```

### 7.3 Profiling Commands

```bash
# Profile build (nearest to release performance)
flutter run --profile

# Check frame rate in DevTools
flutter pub global run devtools

# Memory profiling
flutter run --profile
# → Open DevTools → Memory tab

# Startup analysis
flutter run --trace-startup --profile
```

---

## 8. Performance Checklist (Pre-Release)

- [ ] Cold start measured on mid-range Android device: ≤ 2s
- [ ] Scroll 200 messages list: no jank frames in DevTools
- [ ] Send message round-trip measured on 4G: ≤ 500ms
- [ ] Memory profiler shows no leaks after 10 navigation cycles
- [ ] All SQLite queries measured: ≤ 50ms
- [ ] Image viewer open/close: smooth 60fps Hero animation
- [ ] `flutter build apk --profile` → analyze APK size
- [ ] `flutter build ios --profile` → no Xcode Instruments warnings
