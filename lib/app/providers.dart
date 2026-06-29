import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/presentation/viewmodels/settings_notifier.dart';

// Derives theme mode from the settings notifier so it persists across launches.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsNotifierProvider).themeMode;
});
