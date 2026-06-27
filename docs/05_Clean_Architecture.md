# 05 — Clean Architecture

## Purpose
Define the Clean Architecture rules, layer boundaries, dependency rules, and enforcement mechanisms for SecureChat. This document is the law for code structure.

---

## 1. Clean Architecture Layers

```
┌──────────────────────────────────────────────────────┐
│                  Presentation Layer                   │
│   Screens | ViewModels | Widgets | Providers          │
│   Depends on: Domain Layer only                       │
└──────────────────────────────┬───────────────────────┘
                               │ calls use cases
                               ▼
┌──────────────────────────────────────────────────────┐
│                    Domain Layer                       │
│   Use Cases | Entities | Repository Interfaces        │
│   Depends on: NOTHING (pure Dart)                    │
└──────────────────────────────┬───────────────────────┘
                               │ implements interfaces
                               ▼
┌──────────────────────────────────────────────────────┐
│                      Data Layer                       │
│   Repositories | Data Sources | DTOs | Mappers        │
│   Depends on: Domain Layer (interfaces) only          │
└──────────────────────────────────────────────────────┘
```

### The Dependency Rule (ABSOLUTE)
> Code dependencies SHALL only point inward. Outer layers depend on inner layers. Inner layers NEVER depend on outer layers.

- **Presentation** may import from **Domain**
- **Data** may import from **Domain** (to implement interfaces)
- **Domain** may NOT import from **Presentation** or **Data**
- No layer may import from a sibling feature's layer directly (use dependency injection)

---

## 2. Layer Responsibilities

### 2.1 Domain Layer (The Core)

**Location:** `lib/features/<feature>/domain/`

**Contains:**
- **Entities** — Plain Dart classes with no framework dependencies. The true business objects.
- **Repository Interfaces** (abstract classes) — Contracts that define what operations exist.
- **Use Cases** — Single-responsibility classes that execute one business operation.
- **Value Objects** — Validated wrappers for primitive values (Email, Phone, MessageText).
- **Failures** — Domain-specific failure types.

**Rules:**
- Zero Flutter imports (`import 'package:flutter/...'` is FORBIDDEN)
- Zero Supabase imports
- Zero Drift imports
- Uses only: `dart:core`, `fpdart` (for Either/Option), other domain entities
- All use cases return `Either<Failure, T>`

**Example Entity:**
```
Message
  id: MessageId
  pairId: PairId
  senderId: UserId
  content: MessageContent   ← Value object (validated)
  status: MessageStatus     ← Enum
  sentAt: DateTime
  editedAt: DateTime?
  expiresAt: DateTime?
```

**Example Use Case Signature:**
```
class SendMessageUseCase {
  Future<Either<Failure, Message>> execute(SendMessageParams params)
}
```

### 2.2 Data Layer

**Location:** `lib/features/<feature>/data/`

**Contains:**
- **Repository Implementations** — Concrete implementations of domain interfaces
- **Remote Data Sources** — Supabase API calls (all in one file per feature)
- **Local Data Sources** — Drift database queries
- **Secure Data Sources** — flutter_secure_storage operations
- **DTOs (Data Transfer Objects)** — JSON-serializable models matching API/DB shapes
- **Mappers** — Convert DTO ↔ Entity

**Rules:**
- Implements domain repository interfaces
- NEVER exposes DTOs to domain or presentation (always map to entities)
- Catches data source exceptions and converts to domain Failures
- Handles retry and caching logic

**Example Repository Implementation:**
```
class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource _remote;
  final MessageLocalDataSource _local;

  Future<Either<Failure, Message>> sendMessage(params) async {
    try {
      final dto = await _remote.insertMessage(params);
      final entity = MessageMapper.fromDto(dto);
      await _local.insertMessage(entity);
      return Right(entity);
    } on SupabaseException catch (e) {
      return Left(ServerFailure(e.message));
    } on DriftException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
```

### 2.3 Presentation Layer

**Location:** `lib/features/<feature>/presentation/`

**Contains:**
- **Screens** — Full-screen widgets (named `*Screen` or `*Page`)
- **ViewModels** (Riverpod Notifiers) — State management, calls use cases
- **Widgets** — Reusable UI components specific to this feature
- **State** — Immutable state classes for each ViewModel

**Rules:**
- Screens contain ZERO business logic
- ViewModels call use cases ONLY — no direct repository or data source access
- ViewModels expose immutable state objects
- No `async`/`await` in build() methods
- No `setState()` except inside StatefulWidget for purely local UI state (e.g., keyboard focus)

**Example ViewModel (Riverpod AsyncNotifier):**
```
class ChatViewModel extends AsyncNotifier<ChatState> {
  Future<void> sendMessage(String text) async {
    state = const AsyncLoading();
    final result = await ref.read(sendMessageUseCaseProvider).execute(
      SendMessageParams(text: text, pairId: currentPairId),
    );
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (message) => AsyncData(state.value!.copyWith(
        messages: [message, ...state.value!.messages],
      )),
    );
  }
}
```

---

## 3. Feature Folder Structure

Every feature follows this identical structure:

```
lib/features/<feature_name>/
├── domain/
│   ├── entities/
│   │   └── <entity>.dart
│   ├── repositories/
│   │   └── <feature>_repository.dart        ← abstract class
│   ├── use_cases/
│   │   ├── <action>_use_case.dart
│   │   └── params/
│   │       └── <action>_params.dart
│   ├── value_objects/
│   │   └── <value>.dart
│   └── failures/
│       └── <feature>_failures.dart
│
├── data/
│   ├── repositories/
│   │   └── <feature>_repository_impl.dart
│   ├── data_sources/
│   │   ├── remote/
│   │   │   └── <feature>_remote_data_source.dart
│   │   └── local/
│   │       └── <feature>_local_data_source.dart
│   ├── dtos/
│   │   └── <entity>_dto.dart
│   └── mappers/
│       └── <entity>_mapper.dart
│
└── presentation/
    ├── screens/
    │   └── <feature>_screen.dart
    ├── viewmodels/
    │   ├── <feature>_view_model.dart
    │   └── <feature>_state.dart
    └── widgets/
        └── <component>_widget.dart
```

---

## 4. Dependency Injection (Riverpod)

All dependencies are wired via Riverpod providers in a dedicated providers file per feature.

```
lib/features/<feature>/
└── providers.dart       ← All Riverpod providers for this feature
```

**Provider registration order (innermost first):**

```
// Data Sources
final remoteDataSourceProvider = Provider<FeatureRemoteDataSource>((ref) {
  return FeatureRemoteDataSourceImpl(ref.read(supabaseClientProvider));
});

// Repositories
final repositoryProvider = Provider<FeatureRepository>((ref) {
  return FeatureRepositoryImpl(
    remote: ref.read(remoteDataSourceProvider),
    local: ref.read(localDataSourceProvider),
  );
});

// Use Cases
final useCaseProvider = Provider<FeatureUseCase>((ref) {
  return FeatureUseCase(ref.read(repositoryProvider));
});

// ViewModels
final viewModelProvider = AsyncNotifierProvider<FeatureViewModel, FeatureState>(
  FeatureViewModel.new,
);
```

**Rule:** Providers are the ONLY mechanism for dependency resolution. No service locator, no `get_it`, no manual instantiation in constructors.

---

## 5. Value Objects

Value objects enforce business rules at the type system level.

```
class MessageText {
  final String value;

  MessageText._(this.value);

  static Either<ValidationFailure, MessageText> create(String input) {
    if (input.trim().isEmpty) {
      return Left(ValidationFailure('Message cannot be empty'));
    }
    if (input.length > 4000) {
      return Left(ValidationFailure('Message exceeds maximum length'));
    }
    return Right(MessageText._(input.trim()));
  }
}
```

**All domain primitives that have validation rules MUST be value objects.**

| Value Object | Rules |
|---|---|
| `DisplayName` | 1–30 chars, not empty |
| `PhoneNumber` | Valid E.164 format |
| `EmailAddress` | Valid RFC 5322 format |
| `MessageText` | 1–4000 chars, not only whitespace |
| `PairCode` | Exactly 8 alphanumeric chars |
| `PinCode` | Exactly 6 digits |

---

## 6. Either Pattern

All use cases and repositories return `Either<Failure, T>` from the `fpdart` package.

```
// In domain
abstract class MessageRepository {
  Future<Either<Failure, Message>> sendMessage(SendMessageParams params);
  Stream<Either<Failure, List<Message>>> watchMessages(PairId pairId);
}

// In presentation
final result = await sendMessageUseCase.execute(params);
result.fold(
  (failure) => _handleFailure(failure),
  (message) => _onMessageSent(message),
);
```

**Failure hierarchy:**
```
Failure (abstract)
├── ServerFailure         ← Supabase API / network errors
├── CacheFailure          ← SQLite / local storage errors
├── AuthFailure           ← Authentication errors
├── ValidationFailure     ← Domain validation errors
├── EncryptionFailure     ← Signal Protocol errors
├── PermissionFailure     ← Camera, microphone, notification permissions
└── UnknownFailure        ← Catch-all for unexpected errors
```

---

## 7. Architecture Enforcement Checklist

Before every PR, verify:

- [ ] Domain layer has zero Flutter/Supabase/Drift imports
- [ ] All use cases return `Either<Failure, T>`
- [ ] All repository implementations catch exceptions and return `Left(Failure)`
- [ ] No business logic exists in Screen widgets
- [ ] ViewModels only call use cases (not repositories directly)
- [ ] No DTO leaks to domain or presentation layer
- [ ] All dependencies injected via Riverpod providers
- [ ] Value objects used for all validated primitives
- [ ] New features follow the exact folder structure defined above

---

## 8. Anti-Patterns (FORBIDDEN)

| Anti-Pattern | Why Forbidden |
|---|---|
| `Supabase.instance.client` in a Screen | Bypasses repository layer, breaks testability |
| `throw Exception(...)` in use case | Must return `Left(Failure(...))` |
| DTO used as entity in domain | DTOs are API models; entities are business models |
| `print()` for debugging | Use AppLogger; print() produces no-op in release anyway |
| Hardcoded string in widget | All strings in `AppStrings` constants |
| `ref.read(repositoryProvider)` in Screen | Screens only read ViewModel providers |
| `setState()` for business data | Business state belongs in Riverpod |
| Cross-feature direct imports | Features communicate via shared domain entities only |
