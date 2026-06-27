# 20 — Data Models

## Purpose
Define all domain entities, DTOs, and value objects — their fields, validation rules, and mapping contracts.

---

## 1. Domain Entities

Domain entities are pure Dart classes with no framework dependencies. They represent business concepts.

### 1.1 `Message`

```dart
class Message {
  final String id;
  final String pairId;
  final String senderId;
  final MessageType type;
  final MessageContent content;
  final MessageStatus status;
  final DateTime sentAt;
  final DateTime? editedAt;
  final DateTime? expiresAt;
  final bool isDeleted;
  final List<MessageReaction> reactions;
  final bool isRead;

  bool get isOutgoing; // Compare senderId with current user ID
  bool get canEdit;    // isOutgoing && !isDeleted && sentAt within 15 min
  bool get canDelete;  // isOutgoing && !isDeleted
}
```

### 1.2 `MessageContent` (sealed class)

```dart
sealed class MessageContent {
  const MessageContent();
}

class TextContent extends MessageContent {
  final String text;
  const TextContent(this.text);
}

class ImageContent extends MessageContent {
  final String storageUrl;          // Encrypted blob URL
  final String? localCachedPath;    // Decrypted local path
  final int? width;
  final int? height;
  final String mimeType;
  const ImageContent({...});
}

class VoiceContent extends MessageContent {
  final String storageUrl;
  final String? localCachedPath;
  final Duration duration;
  final List<double> waveformData;  // Normalized 0.0–1.0
  const VoiceContent({...});
}

class SystemContent extends MessageContent {
  final String text;
  const SystemContent(this.text);
}
```

### 1.3 `MessageStatus` (enum)

```dart
enum MessageStatus {
  pending,    // Created locally, not yet sent
  sending,    // In flight to server
  sent,       // Server received
  delivered,  // Partner device received
  read,       // Partner opened chat
  failed,     // Send failed
  queued,     // Offline, in outbox queue
}
```

### 1.4 `MessageType` (enum)

```dart
enum MessageType {
  text,
  image,
  voice,
  video,
  system,
}
```

### 1.5 `MessageReaction`

```dart
class MessageReaction {
  final String id;
  final String messageId;
  final String userId;
  final String emoji;
  final DateTime createdAt;
}
```

### 1.6 `Pair`

```dart
class Pair {
  final String id;
  final String userAId;
  final String userBId;
  final DisappearingDuration disappearingDuration;
  final DateTime createdAt;

  String partnerIdFor(String userId) =>
      userId == userAId ? userBId : userAId;
}

enum DisappearingDuration {
  off,
  oneHour,
  twentyFourHours,
  sevenDays,
  thirtyDays;

  Duration? get duration => switch (this) {
    off => null,
    oneHour => const Duration(hours: 1),
    twentyFourHours => const Duration(hours: 24),
    sevenDays => const Duration(days: 7),
    thirtyDays => const Duration(days: 30),
  };
}
```

### 1.7 `UserProfile`

```dart
class UserProfile {
  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;
}
```

### 1.8 `AppSettings`

```dart
class AppSettings {
  final bool showLastSeen;
  final bool readReceiptsEnabled;
  final bool typingIndicatorEnabled;
  final String notificationSound;
  final DateTime? notificationMutedUntil;
  final ChatBackground chatBackground;
  final AppLockConfig appLockConfig;

  bool get isNotificationMuted =>
      notificationMutedUntil != null &&
      notificationMutedUntil!.isAfter(DateTime.now());
}
```

### 1.9 `AppLockConfig`

```dart
class AppLockConfig {
  final bool isEnabled;
  final LockType type;
  final LockTimeout timeout;
}

enum LockType { biometric, pin, none }

enum LockTimeout {
  immediately,
  oneMinute,
  fiveMinutes,
  fifteenMinutes,
  never;

  Duration? get duration => switch (this) {
    immediately => Duration.zero,
    oneMinute => const Duration(minutes: 1),
    fiveMinutes => const Duration(minutes: 5),
    fifteenMinutes => const Duration(minutes: 15),
    never => null,
  };
}
```

### 1.10 `PartnerPresence`

```dart
class PartnerPresence {
  final String userId;
  final bool isOnline;
  final DateTime lastSeen;
}
```

---

## 2. Value Objects

### 2.1 `PhoneNumber`

```dart
class PhoneNumber {
  final String value; // E.164 format: +919876543210

  PhoneNumber._(this.value);

  static Either<ValidationFailure, PhoneNumber> create(String input) {
    final cleaned = input.trim();
    final regex = RegExp(r'^\+[1-9]\d{6,14}$');
    if (!regex.hasMatch(cleaned)) {
      return Left(ValidationFailure('Enter a valid phone number with country code'));
    }
    return Right(PhoneNumber._(cleaned));
  }
}
```

### 2.2 `EmailAddress`

```dart
class EmailAddress {
  final String value;

  EmailAddress._(this.value);

  static Either<ValidationFailure, EmailAddress> create(String input) {
    final cleaned = input.trim().toLowerCase();
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(cleaned)) {
      return Left(ValidationFailure('Enter a valid email address'));
    }
    return Right(EmailAddress._(cleaned));
  }
}
```

### 2.3 `OtpCode`

```dart
class OtpCode {
  final String value;

  OtpCode._(this.value);

  static Either<ValidationFailure, OtpCode> create(String input) {
    final cleaned = input.trim();
    if (cleaned.length != 6 || !RegExp(r'^\d{6}$').hasMatch(cleaned)) {
      return Left(ValidationFailure('Enter the 6-digit code'));
    }
    return Right(OtpCode._(cleaned));
  }
}
```

### 2.4 `MessageText`

```dart
class MessageText {
  final String value;

  MessageText._(this.value);

  static Either<ValidationFailure, MessageText> create(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return Left(ValidationFailure('Message cannot be empty'));
    }
    if (trimmed.length > 4000) {
      return Left(ValidationFailure('Message is too long'));
    }
    return Right(MessageText._(trimmed));
  }
}
```

### 2.5 `PairCode`

```dart
class PairCode {
  final String value; // 8-char uppercase alphanumeric

  PairCode._(this.value);

  static Either<ValidationFailure, PairCode> create(String input) {
    final cleaned = input.trim().toUpperCase();
    if (cleaned.length != 8 || !RegExp(r'^[A-Z0-9]{8}$').hasMatch(cleaned)) {
      return Left(ValidationFailure('Enter a valid 8-character invite code'));
    }
    return Right(PairCode._(cleaned));
  }

  static PairCode generate() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No 0/O, 1/I ambiguity
    final random = Random.secure();
    final code = List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    return PairCode._(code);
  }
}
```

### 2.6 `DisplayName`

```dart
class DisplayName {
  final String value;

  DisplayName._(this.value);

  static Either<ValidationFailure, DisplayName> create(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return Left(ValidationFailure('Name cannot be empty'));
    }
    if (trimmed.length > 30) {
      return Left(ValidationFailure('Name must be 30 characters or less'));
    }
    return Right(DisplayName._(trimmed));
  }
}
```

---

## 3. DTOs (Data Transfer Objects)

DTOs match the shape of Supabase API responses. They are only used in the data layer.

### 3.1 `MessageDto`

```dart
class MessageDto {
  final String id;
  final String pairId;
  final String senderId;
  final String messageType;
  final List<int> ciphertext;      // Decoded from BYTEA
  final String status;
  final DateTime sentAt;
  final DateTime? editedAt;
  final DateTime? expiresAt;
  final DateTime? deletedAt;
  final List<ReactionDto>? reactions;

  factory MessageDto.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### 3.2 `UserProfileDto`

```dart
class UserProfileDto {
  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;

  factory UserProfileDto.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toInsertJson();
}
```

---

## 4. Mappers

Mappers convert between DTOs and domain entities. They live in `data/mappers/`.

### 4.1 `MessageMapper`

```dart
abstract class MessageMapper {
  static Message fromDto(MessageDto dto, {
    required String decryptedContent,
    required List<MessageReaction> reactions,
  }) {
    return Message(
      id: dto.id,
      pairId: dto.pairId,
      senderId: dto.senderId,
      type: MessageType.values.byName(dto.messageType),
      content: _parseContent(dto.messageType, decryptedContent),
      status: MessageStatus.values.byName(dto.status),
      sentAt: dto.sentAt,
      editedAt: dto.editedAt,
      expiresAt: dto.expiresAt,
      isDeleted: dto.deletedAt != null,
      reactions: reactions,
      isRead: false, // Computed separately
    );
  }

  static MessageContent _parseContent(String type, String content) {
    return switch (type) {
      'text' => TextContent(content),
      'image' => ImageContent.fromJson(jsonDecode(content)),
      'voice' => VoiceContent.fromJson(jsonDecode(content)),
      'system' => SystemContent(content),
      _ => throw UnknownMessageTypeException(type),
    };
  }
}
```

---

## 5. Use Case Params

Each use case that requires input takes a typed `Params` object:

```dart
class SendMessageParams {
  final MessageText text;
  final String pairId;
  const SendMessageParams({required this.text, required this.pairId});
}

class VerifyOtpParams {
  final PhoneNumber phone;
  final OtpCode code;
  const VerifyOtpParams({required this.phone, required this.code});
}

class AcceptInviteCodeParams {
  final PairCode code;
  const AcceptInviteCodeParams({required this.code});
}
```
