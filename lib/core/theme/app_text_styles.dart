import 'package:flutter/material.dart';

extension AppTextStyles on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;

  TextStyle get displayLarge => textTheme.displayLarge!;
  TextStyle get displayMedium => textTheme.displayMedium!;
  TextStyle get displaySmall => textTheme.displaySmall!;

  TextStyle get headlineLarge => textTheme.headlineLarge!;
  TextStyle get headlineMedium => textTheme.headlineMedium!;
  TextStyle get headlineSmall => textTheme.headlineSmall!;

  TextStyle get titleLarge => textTheme.titleLarge!;
  TextStyle get titleMedium => textTheme.titleMedium!;
  TextStyle get titleSmall => textTheme.titleSmall!;

  TextStyle get bodyLarge => textTheme.bodyLarge!;
  TextStyle get bodyMedium => textTheme.bodyMedium!;
  TextStyle get bodySmall => textTheme.bodySmall!;

  TextStyle get labelLarge => textTheme.labelLarge!;
  TextStyle get labelMedium => textTheme.labelMedium!;
  TextStyle get labelSmall => textTheme.labelSmall!;

  // ── Semantic aliases ──────────────────────────────────────────────────────
  TextStyle get chatBubbleText => textTheme.bodyMedium!.copyWith(height: 1.4);
  TextStyle get messageMeta =>
      textTheme.labelSmall!.copyWith(fontSize: 11, height: 1.2);
  TextStyle get dateLabel =>
      textTheme.labelSmall!.copyWith(letterSpacing: 0.5);
  TextStyle get sectionTitle =>
      textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w600);
}
