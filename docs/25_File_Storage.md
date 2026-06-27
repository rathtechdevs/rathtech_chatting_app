# 25 — File Storage

## Purpose
Define how media files are stored, encrypted, uploaded, downloaded, and cached in SecureChat using Supabase Storage and local app storage.

---

## 1. Storage Architecture

```
User Device                              Supabase Storage
─────────────                            ─────────────────
Pick/capture media
    │
    ▼
Compress media
    │
    ▼
Generate AES key + IV
    │
    ▼
Encrypt media → ciphertext bytes
    │
    ▼                                    Bucket: chat-media
Upload ciphertext ─────────────────────► pair_id/message_id/blob
    │                                    (Encrypted bytes only)
    ▼
Encrypt (key + IV + storage_path)
  via Signal Protocol
    │
    ▼
Send Signal message to server ──────────► messages.ciphertext
                                          (Contains encrypted key)
```

```
Receive message                         Supabase Storage
───────────────                         ─────────────────
Receive Signal message
    │
    ▼
Decrypt → { key, IV, storage_path }
    │
    ▼                                   Bucket: chat-media
Download encrypted blob ◄───────────── pair_id/message_id/blob
    │
    ▼
Decrypt with key + IV → plaintext bytes
    │
    ▼
Cache decrypted file in app-private dir
    │
    ▼
Display in UI
```

---

## 2. Supabase Storage Buckets

### 2.1 `avatars` Bucket

| Property | Value |
|---|---|
| **Access** | Public read |
| **Write** | Authenticated users only |
| **Max file size** | 5MB |
| **Allowed types** | `image/jpeg`, `image/png`, `image/webp` |
| **Path structure** | `{user_id}/avatar.{ext}` |

**RLS Policy:**
```sql
-- Anyone can read avatars (they are not sensitive)
CREATE POLICY "avatars_public_read"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Users can only write to their own avatar path
CREATE POLICY "avatars_owner_write"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
```

### 2.2 `chat-media` Bucket

| Property | Value |
|---|---|
| **Access** | Private (JWT required) |
| **Max file size** | 50MB |
| **Allowed types** | All (encrypted blobs have no meaningful MIME type) |
| **Path structure** | `{pair_id}/{message_id}` |
| **Encryption** | AES-256-GCM client-side before upload |

**RLS Policy:**
```sql
-- Only pair members can read/write to their pair folder
CREATE POLICY "chat_media_pair_access"
ON storage.objects FOR ALL
USING (
  bucket_id = 'chat-media' AND
  (storage.foldername(name))[1] IN (
    SELECT id::text FROM pairs
    WHERE user_a_id = auth.uid() OR user_b_id = auth.uid()
  )
);
```

---

## 3. Media Upload Flow

### 3.1 Image Upload

```dart
class MediaRepositoryImpl implements MediaRepository {
  @override
  Future<Either<Failure, MediaUploadResult>> uploadImage(
    File imageFile,
    String pairId,
  ) async {
    try {
      // Step 1: Compress
      final compressed = await _compressImage(imageFile);

      // Step 2: Generate encryption key and IV
      final key = _crypto.generateRandomBytes(32);  // AES-256 key
      final iv = _crypto.generateRandomBytes(12);   // GCM IV

      // Step 3: Encrypt
      final encrypted = _crypto.aesGcmEncrypt(
        key: key,
        iv: iv,
        plaintext: await compressed.readAsBytes(),
      );

      // Step 4: Upload encrypted blob
      final messageId = const Uuid().v4();
      final storagePath = '$pairId/$messageId';

      await _supabase.storage
          .from('chat-media')
          .uploadBinary(
            storagePath,
            encrypted,
            fileOptions: const FileOptions(upsert: false),
          );

      // Step 5: Return key material + path for inclusion in message
      return Right(MediaUploadResult(
        storagePath: storagePath,
        encryptionKey: key,
        iv: iv,
        width: compressed.width,
        height: compressed.height,
        mimeType: 'image/jpeg',
      ));
    } on StorageException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
```

### 3.2 Image Compression

```dart
Future<CompressedImage> _compressImage(File file) async {
  final result = await FlutterImageCompress.compressWithFile(
    file.absolute.path,
    quality: 85,
    minWidth: 1280,
    minHeight: 1280,
    keepExif: false,
  );

  if (result == null || result.length > 2 * 1024 * 1024) {
    // Re-compress at lower quality if still > 2MB
    final result2 = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: 60,
      minWidth: 800,
      minHeight: 800,
    );
    return CompressedImage(bytes: result2!, ...);
  }

  return CompressedImage(bytes: result, ...);
}
```

### 3.3 Voice Upload

```dart
Future<Either<Failure, MediaUploadResult>> uploadVoice(
  File audioFile,
  String pairId,
) async {
  // No compression for voice — already small and codec-optimized
  final bytes = await audioFile.readAsBytes();
  final duration = await _getAudioDuration(audioFile);
  final waveform = await _generateWaveform(audioFile);

  final key = _crypto.generateRandomBytes(32);
  final iv = _crypto.generateRandomBytes(12);
  final encrypted = _crypto.aesGcmEncrypt(key: key, iv: iv, plaintext: bytes);

  final messageId = const Uuid().v4();
  final storagePath = '$pairId/$messageId';

  await _supabase.storage
      .from('chat-media')
      .uploadBinary(storagePath, encrypted);

  return Right(MediaUploadResult(
    storagePath: storagePath,
    encryptionKey: key,
    iv: iv,
    duration: duration,
    waveformData: waveform,
    mimeType: 'audio/m4a',
  ));
}
```

---

## 4. Media Download Flow

```dart
Future<Either<Failure, File>> downloadMedia(
  String storagePath,
  String messageId,
  Uint8List encryptionKey,
  Uint8List iv,
) async {
  try {
    // Check local cache first
    final cached = await _cache.get(messageId);
    if (cached != null && await cached.exists()) {
      return Right(cached);
    }

    // Download encrypted blob from Supabase Storage
    final encryptedBytes = await _supabase.storage
        .from('chat-media')
        .download(storagePath);

    // Decrypt
    final decrypted = _crypto.aesGcmDecrypt(
      key: encryptionKey,
      iv: iv,
      ciphertext: encryptedBytes,
    );

    // Save to app-private cache directory
    final file = await _cache.save(messageId, decrypted);
    return Right(file);
  } on StorageException catch (e) {
    return Left(ServerFailure(e.message));
  } on DecryptionException catch (e) {
    return Left(EncryptionFailure(e.message));
  }
}
```

---

## 5. Local Media Cache

### 5.1 Cache Directory

```dart
// All cached media stored in app-private directory
final cacheDir = await getApplicationDocumentsDirectory();
final mediaCacheDir = Directory('${cacheDir.path}/media_cache');
await mediaCacheDir.create(recursive: true);
```

**Path structure:** `{appDocuments}/media_cache/{message_id}.{ext}`

### 5.2 Cache Policy (V1)

- Files cached indefinitely until account deletion or manual clear
- No automatic LRU eviction in V1 (future enhancement)
- Cache cleared on logout and account deletion

### 5.3 Cache Entry Check

```dart
Future<File?> get(String messageId) async {
  final extensions = ['jpg', 'mp4', 'aac', 'm4a'];
  for (final ext in extensions) {
    final file = File('$_cacheDirPath/$messageId.$ext');
    if (await file.exists()) return file;
  }
  return null;
}
```

---

## 6. Media Security

| Concern | Defense |
|---|---|
| Server reads media | AES-256-GCM encryption before upload; server sees only ciphertext |
| Key disclosure | Media key encrypted within Signal Protocol message |
| Cache access | App-private directory only; no external storage |
| Filename inference | Storage paths use `pair_id/message_id` — no filename reveals content type |
| Link expiry | Supabase signed URLs with 1-hour expiry (not used — we download binary directly) |

---

## 7. Avatar Upload (Unencrypted)

Avatar images are not encrypted — they are visible to both pair members and are used for display.

```dart
Future<Either<Failure, String>> uploadAvatar(File imageFile) async {
  try {
    // Compress
    final compressed = await _compressImage(imageFile);

    final userId = _supabase.auth.currentUser!.id;
    final path = '$userId/avatar.jpg';

    // Upload (unencrypted)
    await _supabase.storage
        .from('avatars')
        .uploadBinary(
          path,
          compressed.bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
    return Right(publicUrl);
  } on StorageException catch (e) {
    return Left(ServerFailure(e.message));
  }
}
```

---

## 8. Media Limits

| Type | Max Size | Compression |
|---|---|---|
| Image | 10MB original; 2MB after compression | JPEG 85% quality |
| Voice message | 5 minutes → ~5MB | None (already compressed) |
| Video (V2) | 50MB | H.264 compression |
| Avatar | 5MB original; 200KB after compression | JPEG 80% |
