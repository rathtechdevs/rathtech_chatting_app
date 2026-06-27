# 33 — Development Guidelines

## Purpose
Define all coding standards, naming conventions, git workflow, commit strategy, branch strategy, code review checklist, and daily development practices for SecureChat.

---

## 1. Dart / Flutter Code Standards

### 1.1 File Organization

```dart
// Order within every .dart file:
// 1. Dart core imports
import 'dart:async';
import 'dart:typed_data';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Third-party packages (alphabetical)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 4. Project imports (feature-internal first, then cross-feature)
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/auth/domain/entities/auth_session.dart';

// 5. Relative imports (only within same feature/layer)
import '../entities/message.dart';
import 'message_dto.dart';
```

### 1.2 Naming Conventions

| Item | Convention | Example |
|---|---|---|
| Files | `snake_case.dart` | `send_message_use_case.dart` |
| Classes | `PascalCase` | `SendMessageUseCase` |
| Methods/functions | `camelCase` | `sendMessage()` |
| Variables | `camelCase` | `currentPairId` |
| Private members | `_camelCase` | `_supabaseClient` |
| Constants (in abstract class) | `camelCase` | `AppStrings.sendMessage` |
| Providers | `camelCase + Provider` | `chatViewModelProvider` |
| Enums | `PascalCase` | `MessageStatus` |
| Enum values | `camelCase` | `MessageStatus.delivered` |
| Type aliases | `PascalCase` | `MessageId = String` |

### 1.3 Class Length

- Maximum 300 lines per class
- If a class exceeds 300 lines, split into smaller classes
- Exception: Generated code (`.g.dart` files)

### 1.4 Method Length

- Maximum 30 lines per method
- If a method exceeds 30 lines, extract helper methods

### 1.5 `const` Usage

Use `const` everywhere possible:
- All widget constructors that don't depend on runtime data
- All `Color`, `EdgeInsets`, `TextStyle` literals
- All string literals in const contexts

```dart
// ✅ Good
const MessageBubble(message: fakeMessage);
const EdgeInsets.symmetric(horizontal: 16);
const Color(0xFF7C5CBF);

// ❌ Bad
MessageBubble(message: fakeMessage);
EdgeInsets.symmetric(horizontal: 16);
Color(0xFF7C5CBF);
```

### 1.6 Avoid `dynamic`

Never use `dynamic` unless absolutely required (e.g., JSON parsing boundary):

```dart
// ✅ Good
Map<String, dynamic> json; // Only at JSON boundary

// ❌ Bad
dynamic result = someFunction();
List<dynamic> items = [...];
```

### 1.7 Prefer Early Returns

```dart
// ✅ Good
Future<Either<Failure, Message>> sendMessage(params) async {
  if (!_connectivity.isOnline) {
    return _queueOffline(params);
  }
  final encrypted = await _encrypt(params.text);
  if (encrypted.isLeft()) return encrypted.map((_) => throw StateError(''));
  // ... continue
}

// ❌ Bad
Future<Either<Failure, Message>> sendMessage(params) async {
  if (_connectivity.isOnline) {
    final encrypted = await _encrypt(params.text);
    if (encrypted.isRight()) {
      // ... 20 more lines of nesting
    }
  }
}
```

### 1.8 Avoid Nested Ternaries

```dart
// ✅ Good
String label;
if (status == MessageStatus.read) {
  label = 'Read';
} else if (status == MessageStatus.delivered) {
  label = 'Delivered';
} else {
  label = 'Sent';
}

// ✅ Also good (switch expression)
final label = switch (status) {
  MessageStatus.read => 'Read',
  MessageStatus.delivered => 'Delivered',
  _ => 'Sent',
};

// ❌ Bad
final label = status == MessageStatus.read ? 'Read' : status == MessageStatus.delivered ? 'Delivered' : 'Sent';
```

---

## 2. Architecture Rules

### 2.1 Absolute Rules (Never Break)

1. Domain layer has zero Flutter/Supabase/Drift imports
2. All use cases return `Either<Failure, T>`
3. All repository implementations catch exceptions and return `Left(Failure)`
4. No business logic in Screen widgets
5. ViewModels only call use cases
6. No DTO leaks to domain or presentation
7. No hardcoded strings — all strings in `AppStrings`
8. No `print()` — use `AppLogger`
9. No `!` (null-assertion) without a comment explaining why it cannot be null
10. Sensitive data only in `flutter_secure_storage`

### 2.2 Dependency Injection

```dart
// ✅ Good — DI via Riverpod provider
final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.read(messageRepositoryProvider));
});

// ❌ Bad — manual instantiation in widget
final useCase = SendMessageUseCase(MessageRepositoryImpl(...));

// ❌ Bad — static accessor
final useCase = ServiceLocator.get<SendMessageUseCase>();
```

### 2.3 Sealed Classes

Use sealed classes for entities with variants:

```dart
// ✅ Good — exhaustive switch on sealed class
sealed class MessageContent { ... }
class TextContent extends MessageContent { ... }
class ImageContent extends MessageContent { ... }

Widget build(MessageContent content) => switch (content) {
  TextContent c => TextWidget(c.text),
  ImageContent c => ImageWidget(c.storageUrl),
};
// Compiler enforces all variants are handled

// ❌ Bad — if/else chain that misses variants
if (content is TextContent) { ... }
else if (content is ImageContent) { ... }
// Missing VoiceContent? Runtime crash.
```

---

## 3. Git Workflow

### 3.1 Branch Strategy

```
main                   ← Production-ready code only; tagged on release
└── dev                ← Integration branch; all features merged here first
    ├── feat/M0-foundation
    ├── feat/M1-authentication
    ├── feat/M2-encryption-core
    ├── feat/M3-pairing
    ├── feat/M4-core-messaging
    └── fix/bug-description
```

**Branch naming:**
- Features: `feat/M{n}-{short-description}`
- Bug fixes: `fix/{short-description}`
- Chores: `chore/{description}`

### 3.2 Commit Convention (Conventional Commits)

```
<type>(<scope>): <short imperative description>

[optional body: what and why, not how]

[optional footer: Closes #issue, breaking changes]
```

**Types:** `feat`, `fix`, `refactor`, `test`, `chore`, `docs`, `style`, `perf`

**Scopes:** `auth`, `chat`, `pairing`, `encryption`, `media`, `notification`, `profile`, `settings`, `app-lock`, `core`, `router`, `theme`

**Examples:**
```
feat(auth): add phone OTP registration flow
fix(chat): prevent duplicate messages on rapid send
refactor(encryption): extract key storage into dedicated service
test(auth): add unit tests for VerifyOtpUseCase
chore(deps): upgrade supabase_flutter to 2.5.0
docs(encryption): update X3DH flow diagram
perf(chat): add message list scroll caching
```

**Rules:**
- Subject line max 72 characters
- Imperative mood ("add" not "added" / "adds")
- No trailing period
- Body explains WHY, not WHAT

### 3.3 PR Process

1. Create branch from `dev`
2. Implement feature
3. Run `flutter analyze` — must pass
4. Run `flutter test` — must pass
5. Create PR to `dev` (not `main`)
6. Self-review using Code Review Checklist below
7. Merge (squash merge preferred for clean history)
8. Delete branch after merge

### 3.4 Merge to Main

`dev` → `main` only when:
- All milestone features are complete
- All tests pass
- Performance targets met
- Manual testing complete

---

## 4. Code Review Checklist

Before approving any PR:

**Architecture:**
- [ ] Domain layer has no Flutter/Supabase/Drift imports
- [ ] Use cases return `Either<Failure, T>`
- [ ] Repository catches all exceptions
- [ ] No DTO exposed outside data layer
- [ ] No business logic in widgets

**Code Quality:**
- [ ] No `print()` statements
- [ ] No hardcoded strings
- [ ] No `!` without comment
- [ ] No `dynamic` type (except JSON boundary)
- [ ] `const` used where applicable
- [ ] Methods ≤ 30 lines
- [ ] Classes ≤ 300 lines

**Tests:**
- [ ] New use cases have unit tests
- [ ] New repositories have tests
- [ ] New value objects have validation tests

**Security:**
- [ ] No secrets in code
- [ ] No sensitive data logged
- [ ] RLS policies updated if schema changed

**Documentation:**
- [ ] Code comments added only where WHY is non-obvious
- [ ] If architecture changed, relevant doc updated

---

## 5. Daily Development Checklist

Before committing:
- [ ] `flutter analyze` — zero warnings
- [ ] `flutter test` relevant feature tests pass
- [ ] No `print()` statements
- [ ] No TODOs in committed code (note issues instead)
- [ ] Commit message follows Conventional Commits

Before marking a feature as "done":
- [ ] Happy path works
- [ ] Error path works (try triggering failures)
- [ ] Offline scenario works
- [ ] Dark mode verified
- [ ] Unit tests written and passing

---

## 6. pubspec.yaml Conventions

```yaml
dependencies:
  package_name: ^1.2.3     # ✅ Caret constraint (allows patch + minor updates)
  package_name: 1.2.3      # ❌ Pinned exact version (only if known incompatibility)
  package_name: ">=1.2.0"  # ❌ Open range (too permissive)
```

Always run `flutter pub upgrade --major-versions` to check for updates before each milestone.

---

## 7. Sensitive Files — Never Commit

Add to `.gitignore`:
```
# Secrets
*.jks
*.p12
*.pem
key.properties
google-services.json    ← Use template + CI/CD secret injection
GoogleService-Info.plist ← Same
.env
*.env.*
supabase/.env
```
