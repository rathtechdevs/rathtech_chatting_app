# 12 — Authentication

## Purpose
Define the complete authentication system — registration flows, session management, token storage, deep links, and the GoRouter auth guard.

---

## 1. Auth Strategies

| Method | Provider | When Used |
|---|---|---|
| Phone OTP | Supabase Auth + Twilio | Primary (most users) |
| Email Magic Link | Supabase Auth | Fallback / alternative |

Both methods create the same `Session` object — the app treats all authenticated users identically regardless of registration method.

---

## 2. Auth State Machine

```
States:
  AuthState.unknown      ← Initial (app started, checking storage)
  AuthState.unauthenticated  ← No valid session
  AuthState.authenticated    ← Valid session + user profile exists
  AuthState.registering      ← Valid session but no profile yet

Transitions:
  unknown         → unauthenticated     (no session in storage)
  unknown         → authenticated       (valid session found)
  unknown         → registering         (session but no profile)
  unauthenticated → registering         (OTP/link verified; no profile yet)
  registering     → authenticated       (profile created successfully)
  authenticated   → unauthenticated     (logout or token expiry)
```

---

## 3. Supabase Auth Integration

### 3.1 Initialization

```
// In main.dart, before runApp:
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  authOptions: const FlutterAuthClientOptions(
    autoRefreshToken: true,
    persistSession: false,   ← Manual persistence in SecureStorage
  ),
);
```

### 3.2 Session Persistence

Since `persistSession: false`, we manually manage sessions:

```
On auth success:
  final session = response.session!;
  await secureStorage.write(
    key: 'supabase_session',
    value: jsonEncode(session.toJson()),
  );

On app start:
  final raw = await secureStorage.read(key: 'supabase_session');
  if (raw != null) {
    final session = Session.fromJson(jsonDecode(raw));
    await supabase.auth.setSession(session.refreshToken!);
    // This auto-refreshes the access token
  }
```

### 3.3 Token Auto-Refresh

The Supabase client automatically refreshes the access token 60 seconds before expiry when `autoRefreshToken: true`. After refresh, we save the new session:

```
supabase.auth.onAuthStateChange.listen((event) {
  if (event.event == AuthChangeEvent.tokenRefreshed) {
    secureStorage.write(
      key: 'supabase_session',
      value: jsonEncode(event.session!.toJson()),
    );
  }
  if (event.event == AuthChangeEvent.signedOut) {
    secureStorage.delete(key: 'supabase_session');
  }
});
```

---

## 4. Phone OTP Flow

### 4.1 Send OTP

```
Feature: auth
Domain use case: RequestOtpUseCase

Input: PhoneNumber (validated value object)
Action: supabase.auth.signInWithOtp(phone: phone.value)
Output: Either<AuthFailure, void>
```

### 4.2 Verify OTP

```
Feature: auth
Domain use case: VerifyOtpUseCase

Input: PhoneNumber + OtpCode (validated value object)
Action: supabase.auth.verifyOTP(phone: ..., token: ..., type: OtpType.sms)
Output: Either<AuthFailure, Session>

On success:
  → Save session to secure storage
  → Check if user_profile exists
  → Emit AuthState.registering or AuthState.authenticated
```

---

## 5. Email Magic Link Flow

### 5.1 Send Magic Link

```
Feature: auth
Domain use case: RequestMagicLinkUseCase

Input: EmailAddress (validated value object)
Action: supabase.auth.signInWithOtp(
  email: email.value,
  emailRedirectTo: 'securechat://auth/callback',
)
Output: Either<AuthFailure, void>
```

### 5.2 Deep Link Handling

iOS `Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>securechat</string>
    </array>
  </dict>
</array>
```

Android `AndroidManifest.xml`:
```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="securechat" android:host="auth"/>
</intent-filter>
```

GoRouter handles the deep link:
```
GoRoute(
  path: '/auth/callback',
  redirect: (context, state) {
    final uri = state.uri;
    // Supabase client parses the session from the fragment
    supabase.auth.getSessionFromUrl(uri);
    return '/chat';
  },
)
```

---

## 6. Auth Repository Interface

```
abstract class AuthRepository {
  Future<Either<AuthFailure, void>> requestPhoneOtp(PhoneNumber phone);
  Future<Either<AuthFailure, Session>> verifyPhoneOtp(PhoneNumber phone, OtpCode code);
  Future<Either<AuthFailure, void>> requestEmailMagicLink(EmailAddress email);
  Future<Either<AuthFailure, Session?>> getStoredSession();
  Future<Either<AuthFailure, void>> logout();
  Stream<AuthState> watchAuthState();
}
```

---

## 7. Auth Providers (Riverpod)

```
// Watches Supabase auth state changes
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authRepositoryProvider).watchAuthState();
});

// Current session (nullable)
final currentSessionProvider = Provider<Session?>((ref) {
  return supabase.auth.currentSession;
});

// Current user ID (throws if not authenticated)
final currentUserIdProvider = Provider<String>((ref) {
  final session = ref.watch(currentSessionProvider);
  if (session == null) throw const AuthFailure.unauthorized();
  return session.user.id;
});
```

---

## 8. GoRouter Auth Guard

```
GoRouter(
  redirect: (context, state) {
    final authState = container.read(authStateProvider).valueOrNull;
    final isLoginRoute = state.matchedLocation.startsWith('/auth');

    if (authState == null || authState == AuthState.unknown) {
      return '/splash';
    }
    if (authState == AuthState.unauthenticated && !isLoginRoute) {
      return '/auth/login';
    }
    if (authState == AuthState.registering) {
      return '/auth/setup-profile';
    }
    if (authState == AuthState.authenticated) {
      final isPaired = container.read(pairStatusProvider).valueOrNull ?? false;
      if (!isPaired) return '/pair';
      if (isLoginRoute) return '/chat';
    }
    return null; // No redirect needed
  },
  refreshListenable: GoRouterRefreshStream(
    container.read(authStateProvider.stream),
  ),
)
```

---

## 9. Age Verification

At profile setup, user must enter date of birth. Validation:

```
class DateOfBirth {
  static Either<ValidationFailure, DateOfBirth> create(DateTime dob) {
    final age = DateTime.now().difference(dob).inDays ~/ 365;
    if (age < 18) {
      return Left(ValidationFailure('You must be 18 or older to use SecureChat'));
    }
    return Right(DateOfBirth._(dob));
  }
}
```

DOB stored in `user_profiles.date_of_birth`. Server-side CHECK can also be added.

---

## 10. Logout Flow

```
LogoutUseCase.execute():
  1. supabase.auth.signOut()               → revoke server session
  2. secureStorage.deleteAll()             → clear tokens, keys, settings
  3. localDatabase.deleteAll()             → clear SQLite
  4. Emit AuthState.unauthenticated
  5. GoRouter redirects to /auth/login
```

---

## 11. Error Handling

| Supabase AuthException | Mapped To | User Message |
|---|---|---|
| `invalid_credentials` | `AuthFailure.invalidCredentials()` | "Incorrect code. Try again." |
| `email_not_confirmed` | `AuthFailure.emailNotConfirmed()` | "Please check your email." |
| `over_request_rate_limit` | `AuthFailure.rateLimited()` | "Too many requests. Please wait." |
| `user_not_found` | `AuthFailure.userNotFound()` | "No account found. Please register." |
| Network error | `ServerFailure.noConnection()` | "No internet connection." |
