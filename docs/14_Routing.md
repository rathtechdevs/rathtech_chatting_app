# 14 — Routing

## Purpose
Define the complete routing architecture using GoRouter — all routes, guards, redirects, deep links, and navigation patterns.

---

## 1. Route Hierarchy

```
/ (root)
├── /splash                          ← Determine auth state (no UI flash)
│
├── /auth
│   ├── /auth/login                  ← Phone/email choice
│   ├── /auth/otp-verification       ← OTP entry
│   ├── /auth/magic-link-sent        ← "Check your email" waiting screen
│   ├── /auth/callback               ← Deep link target (magic link return)
│   └── /auth/setup-profile          ← First-time profile creation
│
├── /pair
│   ├── /pair                        ← Choose: generate or enter code
│   ├── /pair/generate               ← Show invite code
│   └── /pair/enter                  ← Enter partner's code
│
├── /chat                            ← Main chat screen (home after paired)
│
├── /image-viewer                    ← Full-screen image viewer
├── /voice-player                    ← Full-screen voice message player
│
├── /profile
│   ├── /profile/my                  ← My profile (edit)
│   └── /profile/partner             ← Partner's profile (read-only)
│
├── /settings
│   ├── /settings                    ← Settings menu
│   ├── /settings/notifications      ← Notification preferences
│   ├── /settings/privacy            ← Privacy settings
│   ├── /settings/security           ← App lock, sessions
│   ├── /settings/chat               ← Background, font, disappearing
│   └── /settings/account            ← Export, delete account
│
├── /app-lock                        ← Lock screen overlay
└── /delete-account                  ← Delete account confirmation
```

---

## 2. Named Route Constants

```dart
// lib/core/constants/route_names.dart
abstract class AppRoutes {
  static const splash = '/splash';
  static const login = '/auth/login';
  static const otpVerification = '/auth/otp-verification';
  static const magicLinkSent = '/auth/magic-link-sent';
  static const authCallback = '/auth/callback';
  static const setupProfile = '/auth/setup-profile';
  static const pair = '/pair';
  static const generateInvite = '/pair/generate';
  static const enterInvite = '/pair/enter';
  static const chat = '/chat';
  static const imageViewer = '/image-viewer';
  static const myProfile = '/profile/my';
  static const partnerProfile = '/profile/partner';
  static const settings = '/settings';
  static const notificationSettings = '/settings/notifications';
  static const privacySettings = '/settings/privacy';
  static const securitySettings = '/settings/security';
  static const chatSettings = '/settings/chat';
  static const accountSettings = '/settings/account';
  static const appLock = '/app-lock';
  static const deleteAccount = '/delete-account';
}
```

---

## 3. GoRouter Configuration

```dart
// lib/app/router.dart

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authStateProvider.notifier);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authStateProvider.stream),
    ),
    redirect: _buildRedirect(ref),
    routes: _buildRoutes(),
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
});

String? _buildRedirect(ProviderRef ref) => (context, state) {
  final authState = ref.read(authStateProvider).valueOrNull ?? AuthState.unknown;
  final isAppLocked = ref.read(appLockStateProvider);
  final location = state.matchedLocation;

  // Handle app lock
  if (isAppLocked && location != AppRoutes.appLock) {
    return AppRoutes.appLock;
  }

  return switch (authState) {
    AuthState.unknown => AppRoutes.splash,
    AuthState.unauthenticated => _requiresAuth(location)
        ? AppRoutes.login
        : null,
    AuthState.registering => AppRoutes.setupProfile,
    AuthState.authenticated => _buildAuthenticatedRedirect(ref, location),
  };
};

String? _buildAuthenticatedRedirect(ProviderRef ref, String location) {
  final pair = ref.read(currentPairProvider).valueOrNull;

  if (pair == null) {
    // Not paired — send to pair screen
    if (!location.startsWith('/pair') && !location.startsWith('/auth')) {
      return AppRoutes.pair;
    }
    return null;
  }

  // Paired — if on auth or pair screens, redirect to chat
  if (location.startsWith('/auth') || location.startsWith('/pair')) {
    return AppRoutes.chat;
  }
  return null;
}
```

---

## 4. Route Definitions

```dart
List<RouteBase> _buildRoutes() => [
  GoRoute(
    path: AppRoutes.splash,
    pageBuilder: (ctx, state) => const NoTransitionPage(child: SplashScreen()),
  ),

  // Auth routes
  GoRoute(
    path: AppRoutes.login,
    pageBuilder: (ctx, state) => const MaterialPage(child: LoginScreen()),
  ),
  GoRoute(
    path: AppRoutes.otpVerification,
    pageBuilder: (ctx, state) {
      final phone = state.extra as String;
      return MaterialPage(child: OtpVerificationScreen(phone: phone));
    },
  ),
  GoRoute(
    path: AppRoutes.setupProfile,
    pageBuilder: (ctx, state) => const MaterialPage(child: SetupProfileScreen()),
  ),
  GoRoute(
    path: AppRoutes.authCallback,
    redirect: (ctx, state) {
      // Supabase client handles session extraction from URI
      Supabase.instance.client.auth.getSessionFromUrl(state.uri);
      return AppRoutes.chat;
    },
  ),

  // Pair routes
  GoRoute(
    path: AppRoutes.pair,
    pageBuilder: (ctx, state) => const MaterialPage(child: PairScreen()),
    routes: [
      GoRoute(
        path: 'generate',
        pageBuilder: (ctx, state) =>
            const MaterialPage(child: GenerateInviteScreen()),
      ),
      GoRoute(
        path: 'enter',
        pageBuilder: (ctx, state) =>
            const MaterialPage(child: EnterInviteScreen()),
      ),
    ],
  ),

  // Chat
  GoRoute(
    path: AppRoutes.chat,
    pageBuilder: (ctx, state) => const MaterialPage(child: ChatScreen()),
  ),

  // Image viewer (full-screen, no app bar)
  GoRoute(
    path: AppRoutes.imageViewer,
    pageBuilder: (ctx, state) {
      final message = state.extra as Message;
      return MaterialPage(
        fullscreenDialog: true,
        child: ImageViewerScreen(message: message),
      );
    },
  ),

  // Profile routes
  GoRoute(
    path: AppRoutes.myProfile,
    pageBuilder: (ctx, state) => const MaterialPage(child: MyProfileScreen()),
  ),
  GoRoute(
    path: AppRoutes.partnerProfile,
    pageBuilder: (ctx, state) =>
        const MaterialPage(child: PartnerProfileScreen()),
  ),

  // Settings routes (nested)
  GoRoute(
    path: AppRoutes.settings,
    pageBuilder: (ctx, state) => const MaterialPage(child: SettingsScreen()),
    routes: [
      GoRoute(
        path: 'notifications',
        pageBuilder: (ctx, state) =>
            const MaterialPage(child: NotificationSettingsScreen()),
      ),
      GoRoute(
        path: 'privacy',
        pageBuilder: (ctx, state) =>
            const MaterialPage(child: PrivacySettingsScreen()),
      ),
      GoRoute(
        path: 'security',
        pageBuilder: (ctx, state) =>
            const MaterialPage(child: SecuritySettingsScreen()),
      ),
      GoRoute(
        path: 'chat',
        pageBuilder: (ctx, state) =>
            const MaterialPage(child: ChatSettingsScreen()),
      ),
      GoRoute(
        path: 'account',
        pageBuilder: (ctx, state) =>
            const MaterialPage(child: AccountSettingsScreen()),
      ),
    ],
  ),

  // App lock
  GoRoute(
    path: AppRoutes.appLock,
    pageBuilder: (ctx, state) => const NoTransitionPage(child: AppLockScreen()),
  ),

  // Delete account
  GoRoute(
    path: AppRoutes.deleteAccount,
    pageBuilder: (ctx, state) =>
        const MaterialPage(child: DeleteAccountScreen()),
  ),
];
```

---

## 5. Navigation Patterns

### 5.1 Standard Push

```dart
// In a widget
context.push(AppRoutes.settings);

// With extra data
context.push(AppRoutes.imageViewer, extra: message);
```

### 5.2 Replace (no back button)

```dart
// After login success — replace auth stack
context.go(AppRoutes.chat);
```

### 5.3 Pop (back)

```dart
context.pop();             // Go back one step
context.pop(result);       // Go back with a result
```

### 5.4 Named with parameters

All routes use path-based navigation (not named). Parameters passed via `extra` for complex objects, via path segments for IDs:

```dart
// Passing complex objects via extra
context.push(AppRoutes.imageViewer, extra: message);

// Reading in destination
final message = GoRouterState.of(context).extra as Message;
```

---

## 6. Page Transitions

```dart
// Standard: Material slide (default)
MaterialPage(child: SettingsScreen())

// Modal: slide up from bottom
MaterialPage(fullscreenDialog: true, child: ImageViewerScreen(...))

// No transition: for splash, lock screen
NoTransitionPage(child: SplashScreen())

// Custom fade for chat → image viewer
CustomTransitionPage(
  child: ImageViewerScreen(...),
  transitionsBuilder: (ctx, anim, secondAnim, child) =>
      FadeTransition(opacity: anim, child: child),
)
```

---

## 7. Deep Link Handling

| Deep Link | Handler | Action |
|---|---|---|
| `securechat://auth/callback?...` | `authCallback` route | Extract session from URL |
| `securechat://chat` | `chat` route | Open chat (if authenticated) |

Android intent filter and iOS URL scheme are both configured for `securechat://`.

---

## 8. Router Error Handling

```dart
errorBuilder: (context, state) {
  AppLogger.error('GoRouter error: ${state.error}');
  return Scaffold(
    body: Center(
      child: Text(AppStrings.navigationError),
    ),
  );
},
```

---

## 9. Auth-Required Routes

```dart
bool _requiresAuth(String location) {
  const publicRoutes = [
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.otpVerification,
    AppRoutes.magicLinkSent,
    AppRoutes.authCallback,
  ];
  return !publicRoutes.any(location.startsWith);
}
```
