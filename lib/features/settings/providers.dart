import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/shared_prefs_provider.dart';
import 'data/settings_local_data_source.dart';
import 'presentation/viewmodels/settings_notifier.dart';

export 'domain/entities/user_settings.dart' show UserSettings;
export 'presentation/viewmodels/settings_notifier.dart'
    show SettingsNotifier, settingsNotifierProvider;

final settingsLocalDataSourceProvider =
    Provider<SettingsLocalDataSource>((ref) {
  return SettingsLocalDataSource(ref.read(sharedPrefsProvider));
});

// Convenience derived providers for features that need individual settings.
final readReceiptsSettingProvider = Provider<bool>((ref) {
  return ref.watch(settingsNotifierProvider).readReceipts;
});

final typingIndicatorSettingProvider = Provider<bool>((ref) {
  return ref.watch(settingsNotifierProvider).typingIndicator;
});
