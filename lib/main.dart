import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/logger/app_logger.dart';
import 'core/storage/shared_prefs_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeSupabase();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const SecureChatApp(),
    ),
  );
}

Future<void> _initializeSupabase() async {
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    AppLogger.warning(
      'Supabase credentials not provided. '
      'Run with: --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key>',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseKey,
  );

  AppLogger.info('Supabase initialized');
}
