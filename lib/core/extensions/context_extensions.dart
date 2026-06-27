import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  // ── Theme shortcuts ──────────────────────────────────────────────────────
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // ── Media query shortcuts ─────────────────────────────────────────────────
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  double get bottomPadding => padding.bottom;
  bool get isKeyboardVisible => MediaQuery.viewInsetsOf(this).bottom > 0;
  bool get reduceMotion => MediaQuery.of(this).disableAnimations;

  // ── Navigation ────────────────────────────────────────────────────────────
  void hideKeyboard() => FocusScope.of(this).unfocus();

  // ── SnackBar ──────────────────────────────────────────────────────────────
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? colorScheme.error : null,
        ),
      );
  }
}
