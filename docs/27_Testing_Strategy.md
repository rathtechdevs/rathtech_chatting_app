# 27 — Testing Strategy

## Purpose
Define the complete testing approach — test types, coverage targets, tools, mocking strategy, and test-writing conventions for SecureChat.

---

## 1. Testing Pyramid

```
        ┌─────────────────┐
        │  Integration    │  ← 10% of tests; most expensive; test critical flows
        │  Tests          │
        ├─────────────────┤
        │  Widget Tests   │  ← 30% of tests; test UI rendering and interaction
        │                 │
        ├─────────────────┤
        │  Unit Tests     │  ← 60% of tests; fast, isolated, test business logic
        │                 │
        └─────────────────┘
```

---

## 2. Coverage Targets

| Layer | Coverage Target |
|---|---|
| Domain use cases | 100% |
| Domain value objects | 100% |
| Repository implementations | 90% |
| Data sources | 80% |
| ViewModels | 85% |
| Screens (widget tests) | 70% |
| Core utilities | 90% |

---

## 3. Unit Tests

### 3.1 Use Case Tests

```dart
// test/unit/features/auth/domain/use_cases/verify_otp_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late VerifyOtpUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = VerifyOtpUseCase(mockRepository);
  });

  group('VerifyOtpUseCase', () {
    final validParams = VerifyOtpParams(
      phone: PhoneNumber.create('+919876543210').getOrElse(() => throw StateError('')),
      code: OtpCode.create('123456').getOrElse(() => throw StateError('')),
    );

    test('returns Right(AuthSession) when OTP is valid', () async {
      when(() => mockRepository.verifyPhoneOtp(any()))
          .thenAnswer((_) async => Right(fakeAuthSession));

      final result = await useCase.execute(validParams);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => throw StateError('')), equals(fakeAuthSession));
    });

    test('returns Left(AuthFailure) when OTP is invalid', () async {
      when(() => mockRepository.verifyPhoneOtp(any()))
          .thenAnswer((_) async => Left(const AuthFailure.invalidCredentials()));

      final result = await useCase.execute(validParams);

      expect(result.isLeft(), true);
      expect(result.fold((f) => f, (_) => null), isA<AuthFailure>());
    });

    test('calls repository exactly once', () async {
      when(() => mockRepository.verifyPhoneOtp(any()))
          .thenAnswer((_) async => Right(fakeAuthSession));

      await useCase.execute(validParams);

      verify(() => mockRepository.verifyPhoneOtp(any())).called(1);
    });
  });
}
```

### 3.2 Value Object Tests

```dart
// test/unit/features/auth/domain/value_objects/phone_number_test.dart
void main() {
  group('PhoneNumber', () {
    test('creates valid E.164 phone number', () {
      final result = PhoneNumber.create('+919876543210');
      expect(result.isRight(), true);
      expect(result.getOrElse(() => throw StateError('')).value, '+919876543210');
    });

    test('trims whitespace before validation', () {
      final result = PhoneNumber.create('  +919876543210  ');
      expect(result.isRight(), true);
    });

    test('rejects phone without country code', () {
      final result = PhoneNumber.create('9876543210');
      expect(result.isLeft(), true);
      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
    });

    test('rejects empty input', () {
      final result = PhoneNumber.create('');
      expect(result.isLeft(), true);
    });

    test('rejects too-short number', () {
      final result = PhoneNumber.create('+1');
      expect(result.isLeft(), true);
    });
  });
}
```

### 3.3 Repository Tests

```dart
// test/unit/features/chat/data/repositories/message_repository_impl_test.dart
void main() {
  late MessageRepositoryImpl repository;
  late MockMessageRemoteDataSource mockRemote;
  late MockMessageLocalDataSource mockLocal;
  late MockEncryptionService mockEncryption;
  late MockConnectivityService mockConnectivity;

  setUp(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(SendMessageParams(
      text: MessageText.create('hello').getOrElse(() => throw StateError('')),
      pairId: 'pair-id',
    ));

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
    test('encrypts message before sending', () async {
      when(mockConnectivity.isOnline).thenReturn(true);
      when(() => mockEncryption.encrypt(any()))
          .thenAnswer((_) async => Right(Uint8List(10)));
      when(() => mockRemote.insertMessage(
            pairId: any(named: 'pairId'),
            ciphertext: any(named: 'ciphertext'),
            messageType: any(named: 'messageType'),
          )).thenAnswer((_) async => fakeMessageDto);
      when(() => mockLocal.insertMessage(any())).thenAnswer((_) async {});
      when(() => mockLocal.updateMessage(any())).thenAnswer((_) async {});

      await repository.sendMessage(fakeSendParams);

      verify(() => mockEncryption.encrypt(any())).called(1);
    });

    test('adds to outbox when offline', () async {
      when(mockConnectivity.isOnline).thenReturn(false);
      when(() => mockEncryption.encrypt(any()))
          .thenAnswer((_) async => Right(Uint8List(10)));
      when(() => mockLocal.insertMessage(any())).thenAnswer((_) async {});
      when(() => mockLocal.addToOutbox(any(), any())).thenAnswer((_) async {});

      final result = await repository.sendMessage(fakeSendParams);

      verify(() => mockLocal.addToOutbox(any(), any())).called(1);
      verifyNever(() => mockRemote.insertMessage(
            pairId: any(named: 'pairId'),
            ciphertext: any(named: 'ciphertext'),
            messageType: any(named: 'messageType'),
          ));
      expect(result.getOrElse(() => throw StateError('')).status,
          MessageStatus.queued);
    });
  });
}
```

---

## 4. Widget Tests

```dart
// test/widget/features/chat/widgets/message_bubble_test.dart
void main() {
  testWidgets('TextMessageBubble displays message content', (tester) async {
    final message = fakeTextMessage.copyWith(
      content: const TextContent('Hello, world!'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isOutgoing: true,
            onLongPress: () {},
          ),
        ),
      ),
    );

    expect(find.text('Hello, world!'), findsOneWidget);
  });

  testWidgets('shows deleted message placeholder', (tester) async {
    final message = fakeTextMessage.copyWith(isDeleted: true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isOutgoing: true,
            onLongPress: () {},
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.messageDeleted), findsOneWidget);
    expect(find.text('Hello, world!'), findsNothing);
  });

  testWidgets('triggers onLongPress when long-pressed', (tester) async {
    bool longPressTriggered = false;
    final message = fakeTextMessage;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isOutgoing: true,
            onLongPress: () => longPressTriggered = true,
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(MessageBubble));
    expect(longPressTriggered, true);
  });
}
```

---

## 5. Integration Tests

```dart
// test/integration/send_message_flow_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User can send a text message', (tester) async {
    // Launch app with test Supabase instance
    await tester.pumpWidget(ProviderScope(
      overrides: [
        supabaseClientProvider.overrideWithValue(testSupabaseClient),
        // ... other test overrides
      ],
      child: const App(),
    ));
    await tester.pumpAndSettle();

    // Navigate to chat (assumes auth and pair are pre-seeded)
    expect(find.byType(ChatScreen), findsOneWidget);

    // Type a message
    final inputField = find.byType(TextField).last;
    await tester.tap(inputField);
    await tester.enterText(inputField, 'Hello from integration test!');
    await tester.pumpAndSettle();

    // Tap send
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify message appears
    expect(find.text('Hello from integration test!'), findsOneWidget);
  });
}
```

---

## 6. Test Utilities

### 6.1 Fake Data Factories

```dart
// test/helpers/fake_data.dart
abstract class FakeData {
  static Message fakeTextMessage({
    String? id,
    String? content,
    MessageStatus? status,
  }) => Message(
    id: id ?? 'msg-${DateTime.now().millisecondsSinceEpoch}',
    pairId: 'pair-id',
    senderId: 'user-id',
    type: MessageType.text,
    content: TextContent(content ?? 'Test message'),
    status: status ?? MessageStatus.sent,
    sentAt: DateTime.now(),
    reactions: [],
    isRead: false,
    isDeleted: false,
  );

  static UserProfile fakeProfile() => const UserProfile(
    id: 'profile-id',
    userId: 'user-id',
    displayName: 'Test User',
    createdAt: ...
  );
}
```

### 6.2 Mock Generation

Using `mocktail` for mocking:

```dart
// test/helpers/mocks.dart
class MockAuthRepository extends Mock implements AuthRepository {}
class MockMessageRepository extends Mock implements MessageRepository {}
class MockEncryptionService extends Mock implements EncryptionService {}
class MockConnectivityService extends Mock implements ConnectivityService {}
class MockMessageRemoteDataSource extends Mock implements MessageRemoteDataSource {}
class MockMessageLocalDataSource extends Mock implements MessageLocalDataSource {}
```

---

## 7. Running Tests

```bash
# All tests
flutter test

# Unit tests only
flutter test test/unit/

# Widget tests only
flutter test test/widget/

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Integration tests (requires running device)
flutter test integration_test/

# Specific test file
flutter test test/unit/features/auth/domain/use_cases/verify_otp_use_case_test.dart
```

---

## 8. CI Test Requirements

Every PR must pass:
- [ ] `flutter analyze` — zero warnings
- [ ] All unit tests (`flutter test test/unit/`)
- [ ] All widget tests (`flutter test test/widget/`)
- [ ] Coverage report showing no regression from established baseline

Integration tests run on schedule (nightly), not on every PR.

---

## 9. Test Naming Convention

```
group('ClassName', () {
  group('methodName', () {
    test('returns X when Y', ...);
    test('throws Z when W', ...);
    test('calls dependency N times', ...);
  });
});
```

- Test names describe observable behavior, not implementation
- "returns Right" / "returns Left" for Either results
- "calls once" / "never calls" for verifying interactions
