import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand ─────────────────────────────────────────────────────────────────
  static const brandPrimary = Color(0xFF7C5CBF);
  static const brandSecondary = Color(0xFF9B7FD4);
  static const brandTertiary = Color(0xFF5A3F9A);

  // ── Surface — Light ───────────────────────────────────────────────────────
  static const backgroundLight = Color(0xFFFAF9FF);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceVariantLight = Color(0xFFEDE8F5);
  static const onSurfaceLight = Color(0xFF1A1A2E);
  static const outlineLight = Color(0xFFCAC4D0);

  // ── Surface — Dark ────────────────────────────────────────────────────────
  static const backgroundDark = Color(0xFF0F0F1A);
  static const surfaceDark = Color(0xFF1E1E2E);
  static const surfaceVariantDark = Color(0xFF2D2D42);
  static const onSurfaceDark = Color(0xFFE6E0F0);
  static const outlineDark = Color(0xFF49454F);

  // ── Message bubbles — Light ───────────────────────────────────────────────
  static const sentBubbleLight = Color(0xFF7C5CBF);
  static const receivedBubbleLight = Color(0xFFF0EBF8);
  static const sentBubbleTextLight = Color(0xFFFFFFFF);
  static const receivedBubbleTextLight = Color(0xFF1A1A2E);

  // ── Message bubbles — Dark ────────────────────────────────────────────────
  static const sentBubbleDark = Color(0xFF9B7FD4);
  static const receivedBubbleDark = Color(0xFF2D2D42);
  static const sentBubbleTextDark = Color(0xFFFFFFFF);
  static const receivedBubbleTextDark = Color(0xFFE6E0F0);

  // ── Status ────────────────────────────────────────────────────────────────
  static const online = Color(0xFF4CAF50);
  static const offline = Color(0xFF9E9E9E);
  static const error = Color(0xFFB3261E);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF4CAF50);

  // ── Utility ───────────────────────────────────────────────────────────────
  static const transparent = Color(0x00000000);
  static const dividerLight = Color(0x1F000000);
  static const dividerDark = Color(0x1FFFFFFF);
  static const shimmerBaseLight = Color(0xFFE0E0E0);
  static const shimmerHighlightLight = Color(0xFFF5F5F5);
  static const shimmerBaseDark = Color(0xFF2D2D42);
  static const shimmerHighlightDark = Color(0xFF3D3D5C);
  static const overlayDark = Color(0x80000000);
}
