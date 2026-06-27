# 17 — Theme System

## Purpose
Define the complete theme system — color tokens, typography, component themes, light/dark modes, and custom chat themes.

---

## 1. Theme Architecture

```
AppTheme
├── AppTheme.light    ← ThemeData for light mode
├── AppTheme.dark     ← ThemeData for dark mode
└── AppTheme.forChatBackground(customColor)  ← Chat-specific overrides
```

All theme data is centralized in `lib/core/theme/app_theme.dart`.

---

## 2. Brand Color

```dart
// lib/core/theme/app_colors.dart
abstract class AppColors {
  static const brandPrimary = Color(0xFF7C5CBF);   // Warm purple
  static const brandSecondary = Color(0xFFE8D5FB);  // Light lavender

  // Semantics (light mode)
  static const errorLight = Color(0xFFBA1A1A);
  static const successLight = Color(0xFF2E7D32);
  static const warningLight = Color(0xFFF57C00);

  // Semantics (dark mode)
  static const errorDark = Color(0xFFFFB4AB);
  static const successDark = Color(0xFF81C784);
  static const warningDark = Color(0xFFFFB74D);

  // Message specific
  static const outgoingBubbleLight = Color(0xFFEDE7F6);
  static const outgoingBubbleDark = Color(0xFF4A148C);
  static const incomingBubbleLight = Color(0xFFF5F5F5);
  static const incomingBubbleDark = Color(0xFF2C2C2C);
}
```

---

## 3. Light Theme

```dart
static ThemeData get light => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.brandPrimary,
    brightness: Brightness.light,
  ),
  textTheme: _buildTextTheme(Brightness.light),
  appBarTheme: _buildAppBarTheme(Brightness.light),
  inputDecorationTheme: _buildInputTheme(Brightness.light),
  elevatedButtonTheme: _buildElevatedButtonTheme(),
  filledButtonTheme: _buildFilledButtonTheme(),
  bottomSheetTheme: _buildBottomSheetTheme(),
  dividerTheme: const DividerThemeData(space: 0, thickness: 0.5),
  listTileTheme: const ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  ),
);
```

---

## 4. Dark Theme

```dart
static ThemeData get dark => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.brandPrimary,
    brightness: Brightness.dark,
  ),
  textTheme: _buildTextTheme(Brightness.dark),
  appBarTheme: _buildAppBarTheme(Brightness.dark),
  inputDecorationTheme: _buildInputTheme(Brightness.dark),
  // ... same structure, derived colors automatically adjusted
);
```

---

## 5. Typography

```dart
static TextTheme _buildTextTheme(Brightness brightness) {
  final baseColor = brightness == Brightness.light
      ? const Color(0xFF1A1A2E)
      : const Color(0xFFE8E8E8);

  return TextTheme(
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: baseColor,
      letterSpacing: -0.5,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: baseColor,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: baseColor,
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: baseColor,
      height: 1.4,
    ),
    bodyMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: baseColor.withOpacity(0.65),
    ),
    labelLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: baseColor,
      letterSpacing: 0.1,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: baseColor.withOpacity(0.5),
      letterSpacing: 0.2,
    ),
  );
}
```

---

## 6. AppBar Theme

```dart
static AppBarTheme _buildAppBarTheme(Brightness brightness) {
  return AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 1,
    centerTitle: false,
    backgroundColor: brightness == Brightness.light
        ? Colors.white
        : const Color(0xFF1A1A2E),
    foregroundColor: brightness == Brightness.light
        ? const Color(0xFF1A1A2E)
        : Colors.white,
    titleTextStyle: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: brightness == Brightness.light
          ? const Color(0xFF1A1A2E)
          : Colors.white,
    ),
    iconTheme: IconThemeData(
      color: AppColors.brandPrimary,
      size: 24,
    ),
  );
}
```

---

## 7. Input Decoration Theme

```dart
static InputDecorationTheme _buildInputTheme(Brightness brightness) {
  return InputDecorationTheme(
    filled: true,
    fillColor: brightness == Brightness.light
        ? const Color(0xFFF5F0FF)
        : const Color(0xFF2C2C40),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: AppColors.brandPrimary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    hintStyle: TextStyle(
      color: brightness == Brightness.light
          ? const Color(0xFF888888)
          : const Color(0xFF888888),
    ),
  );
}
```

---

## 8. Button Themes

```dart
static FilledButtonThemeData _buildFilledButtonTheme() {
  return FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  );
}
```

---

## 9. Chat Background Themes

Users can choose from curated backgrounds. Stored in `SharedPreferences`.

```dart
enum ChatBackground {
  defaultLight(name: 'Default', color: Color(0xFFFAFAFA)),
  warmPeach(name: 'Warm Peach', color: Color(0xFFFFF3E0)),
  softRose(name: 'Soft Rose', color: Color(0xFFFCE4EC)),
  lavender(name: 'Lavender', color: Color(0xFFF3E5F5)),
  mintGreen(name: 'Mint', color: Color(0xFFE8F5E9)),
  oceanBlue(name: 'Ocean', color: Color(0xFFE3F2FD)),
  nightMode(name: 'Night', color: Color(0xFF121212)),
  custom(name: 'Custom', color: Colors.transparent);

  const ChatBackground({required this.name, required this.color});
  final String name;
  final Color color;
}
```

Custom background: user picks image from gallery, stored in app documents directory.

---

## 10. Theme Provider (Riverpod)

```dart
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Load from SharedPreferences
    return ThemeMode.system;
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    // Save to SharedPreferences
  }
}

final chatBackgroundProvider =
    NotifierProvider<ChatBackgroundNotifier, ChatBackground>(
  ChatBackgroundNotifier.new,
);
```

---

## 11. Theme Constants File

```dart
// lib/core/constants/app_strings.dart
abstract class AppStrings {
  // Auth
  static const appName = 'SecureChat';
  static const loginTitle = 'Welcome back';
  static const loginSubtitle = 'Your private space awaits';
  static const phoneTabLabel = 'Phone';
  static const emailTabLabel = 'Email';
  static const sendOtpButton = 'Send Code';
  static const sendMagicLinkButton = 'Send Magic Link';
  static const verifyOtpTitle = 'Enter the code';
  static const otpSentSubtitle = 'We sent a 6-digit code to';
  static const resendOtpButton = 'Resend Code';

  // Chat
  static const messageHint = 'Message...';
  static const sendMessage = 'Send message';
  static const typingIndicator = 'typing...';
  static const todayLabel = 'Today';
  static const yesterdayLabel = 'Yesterday';
  static const messageDeleted = 'Message deleted';
  static const messageEdited = 'Edited';
  static const offlineBanner = "You're offline";

  // Errors
  static const serverError = 'Something went wrong. Please try again.';
  static const noConnectionError = 'No internet connection';
  static const navigationError = 'Navigation error. Please restart the app.';

  // ... all other strings
}
```
