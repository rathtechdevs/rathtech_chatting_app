import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences is initialized once and injected via ProviderScope overrides.
// Never store sensitive data here — use flutter_secure_storage instead.
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPrefsProvider must be overridden in ProviderScope. '
    'Initialize SharedPreferences in main() and pass it via overrides.',
  );
});
