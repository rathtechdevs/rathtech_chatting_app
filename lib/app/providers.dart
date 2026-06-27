import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Global theme mode — updated from settings screen (M10).
// Defaults to ThemeMode.system on first launch.
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});
