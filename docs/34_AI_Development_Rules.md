# 34 — AI Development Rules

## Purpose
Permanent mandatory rulebook for all AI-assisted code generation in SecureChat. Every rule applies to every implementation without exception.

---

## THE GOLDEN RULE

**Every line of code generated must be production-ready.**

There is no "placeholder", "prototype", "good enough for now", or "will fix later". Code either meets all rules below, or it is not written.

---

## RULE 1: ARCHITECTURE COMPLIANCE

**Before writing any code, identify which layer it belongs to.**

```
Is it business logic?          → Domain layer (no Flutter, no Supabase)
Is it data access?             → Data layer (repositories, data sources)
Is it UI?                      → Presentation layer (screens, viewmodels, widgets)
Is it shared infrastructure?   → Core layer (errors, logger, constants, theme)
```

**Violations that trigger immediate rejection:**
- Any Supabase import in domain layer
- Any Flutter Widget import in domain layer
- Any business logic in a Screen widget
- Any direct data source call from a ViewModel
- Any DTO exposed outside the data layer

---

## RULE 2: COMPLETE IMPLEMENTATION ONLY

**Never generate partial code.**

Every class, method, and function must be fully implemented:
- No `// TODO: implement this`
- No `throw UnimplementedError()`
- No `...` as a placeholder
- No empty catch blocks
- No empty method bodies

If a full implementation requires more context, ask for the context — do not generate a stub.

---

## RULE 3: EITHER PATTERN MANDATORY

**Every use case and every repository method returns `Either<Failure, T>`.**

```dart
// ✅ CORRECT
Future<Either<Failure, Message>> sendMessage(params) async { ... }
Stream<Either<Failure, List<Message>>> watchMessages(pairId) { ... }

// ❌ WRONG — throws exceptions to presentation
Future<Message> sendMessage(params) async { ... }

// ❌ WRONG — returns null on failure
Future<Message?> sendMessage(params) async { ... }
```

---

## RULE 4: NO HARDCODED STRINGS

**Every string shown to users lives in `AppStrings`.**

```dart
// ✅ CORRECT
Text(AppStrings.sendMessage)
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(AppStrings.serverError)),
);

// ❌ WRONG
Text('Send message')
SnackBar(content: Text('Something went wrong'))
```

---

## RULE 5: NO LOGGING OF SENSITIVE DATA

**`AppLogger` must never be called with:**
- Message content (plaintext or ciphertext)
- Authentication tokens (access_token, refresh_token)
- Private key material
- User passwords or PINs
- Partner information in identifiable detail

```dart
// ✅ CORRECT
AppLogger.error('Message send failed', e, stack);
AppLogger.info('OTP requested for phone ending in ${phone.value.substring(phone.value.length - 4)}');

// ❌ WRONG
AppLogger.debug('Sending message: $plaintextMessage');
AppLogger.info('Token: $accessToken');
```

---

## RULE 6: NO NULL ASSERTION WITHOUT JUSTIFICATION

**The `!` operator is banned without an explaining comment.**

```dart
// ✅ CORRECT — reason documented
// currentUser is non-null here because this code is only reached
// after auth guard passes (GoRouter redirect ensures authentication)
final userId = supabase.auth.currentUser!.id;

// ❌ WRONG — no justification
final userId = supabase.auth.currentUser!.id;
```

---

## RULE 7: CONST EVERYWHERE

**Every widget constructor that doesn't use runtime data must be `const`.**

This is checked by `flutter analyze` with `prefer_const_constructors` lint rule. AI must generate `const` constructors proactively, not wait for the linter to flag it.

---

## RULE 8: VALUE OBJECTS FOR ALL VALIDATED INPUTS

**Any input that has validation rules must be a Value Object before reaching domain logic.**

```dart
// ✅ CORRECT — validated at boundary
final phoneOrFailure = PhoneNumber.create(rawInput);
final result = await phoneOrFailure.fold(
  (failure) async => Left(failure),
  (phone) => requestOtpUseCase.execute(phone),
);

// ❌ WRONG — raw string passed to use case
final result = await requestOtpUseCase.execute(rawInput);
```

Value objects: `PhoneNumber`, `EmailAddress`, `OtpCode`, `MessageText`, `PairCode`, `DisplayName`.

---

## RULE 9: PROVIDER NAMING MANDATORY

**All Riverpod providers must follow the naming convention:**

```dart
// Data sources
final messageRemoteDataSourceProvider = Provider<MessageRemoteDataSource>(...);

// Repositories
final messageRepositoryProvider = Provider<MessageRepository>(...);

// Use cases
final sendMessageUseCaseProvider = Provider<SendMessageUseCase>(...);

// ViewModels
final chatViewModelProvider = AsyncNotifierProvider<ChatViewModel, ChatState>(...);

// Streams
final messageListProvider = StreamProvider.family<List<Message>, String>(...);
```

**No unnamed providers. No anonymous providers in widget build methods.**

---

## RULE 10: TESTS ARE NOT OPTIONAL

**Every generated use case must come with its unit test.**

When generating a use case, also generate:
1. The test file at the correct test path
2. Test cases for: happy path, failure path, boundary conditions
3. Mock classes for all dependencies

If the tests cannot be generated in the same response, state explicitly what tests must be written and why.

---

## RULE 11: SUPABASE CALLS ARE DATA LAYER ONLY

**`supabase.from(...)`, `supabase.auth.*`, `supabase.storage.*` calls appear ONLY in data source files.**

Never in:
- Domain entities
- Use cases
- ViewModels
- Screen widgets
- Core providers (except the Supabase client provider itself)

---

## RULE 12: RLS MUST BE CONSIDERED

**Whenever a Supabase table operation is generated, the corresponding RLS policy must be stated or referenced.**

If generating an INSERT to a new table, also generate the RLS policy.  
If an operation would violate RLS, flag it before generating the code.

---

## RULE 13: DOCUMENTATION UPDATES

**If any implementation changes the architecture, adds a new pattern, or deviates from existing documentation, the relevant documentation file must be updated in the same change.**

This ensures the documentation remains the single source of truth.

---

## RULE 14: NO DUPLICATE LOGIC

**Before generating any function, search for existing implementations.**

If similar logic already exists:
- Reuse the existing implementation
- If slight variation is needed, extract a shared helper

Creating a second `encrypt()` method, a second `mapFailure()` helper, or a second `isOnline` check is forbidden.

---

## RULE 15: COMPLETE FEATURE = ALL LAYERS

**A feature is not "implemented" until all three layers exist:**
- Domain: entity, repository interface, use cases, value objects
- Data: repository impl, data sources, DTOs, mappers
- Presentation: screen, viewmodel, state, widgets, provider

Generating only the ViewModel and screen without the domain layer is incomplete implementation.

---

## RULE 16: ERROR PATHS ARE REQUIRED

**Every generated method must handle its error paths.**

```dart
// ✅ COMPLETE — both success and failure handled
final result = await sendMessageUseCase.execute(params);
result.fold(
  (failure) => _handleFailure(failure),
  (message) => _onSuccess(message),
);

// ❌ INCOMPLETE — failure path ignored
final result = await sendMessageUseCase.execute(params);
if (result.isRight()) {
  _onSuccess(result.getOrElse(() => throw StateError('')));
}
// What happens on failure? Silently ignored.
```

---

## RULE 17: AFFECTED FILES LIST

**Before generating any code, list all files that will be created or modified.**

```
Affected files:
- lib/features/chat/domain/use_cases/send_message_use_case.dart (CREATE)
- lib/features/chat/domain/use_cases/params/send_message_params.dart (CREATE)
- lib/features/chat/data/repositories/message_repository_impl.dart (MODIFY)
- lib/features/chat/providers.dart (MODIFY)
- test/unit/features/chat/domain/use_cases/send_message_use_case_test.dart (CREATE)
```

---

## RULE 18: NO PLACEHOLDER NAVIGATION

**Every navigation target must exist as a real screen.**

```dart
// ✅ CORRECT — actual screen exists
context.push(AppRoutes.settings);

// ❌ WRONG — placeholder
context.push('/todo-implement-this-screen');
```

---

## RULE 19: REALTIME CHANNELS MUST BE UNSUBSCRIBED

**Every Supabase Realtime channel subscribed in a widget or ViewModel must be unsubscribed in `dispose` or `ref.onDispose`.**

```dart
// ✅ CORRECT — cleanup guaranteed
ref.onDispose(() {
  _realtimeDataSource.unsubscribeFromChat(pairId);
});

// ❌ WRONG — channel leaks memory
@override
void initState() {
  _realtimeDataSource.subscribeToChat(pairId);
}
// No dispose — channel never closed
```

---

## RULE 20: SIGNAL PROTOCOL SESSION SAVED AFTER EVERY RATCHET

**After every encrypt() or decrypt() call, the Signal session state must be persisted.**

The Double Ratchet advances state with every message. If the session state is not saved, a crash between messages will corrupt the session.

```dart
// ✅ CORRECT
final ciphertext = _signalSession.encrypt(plaintext);
await _keyStorage.saveSessionState(pairId, _signalSession.serialize());
return ciphertext;

// ❌ WRONG — session state loss on crash
final ciphertext = _signalSession.encrypt(plaintext);
return ciphertext;
```

---

## ENFORCEMENT

These rules are enforced by:
1. Code review (every PR checked against this list)
2. `flutter analyze` with strict lint rules
3. Architecture tests (future: `dart_code_metrics`)
4. This document referenced in every AI session as the first context loaded
