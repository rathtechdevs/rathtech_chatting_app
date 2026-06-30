import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/logger/app_logger.dart';
import 'core/notifications/notification_service_impl.dart';
import 'core/storage/shared_prefs_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeFirebase();
  await _initializeSupabase();

  // supabase_flutter v2 restores the session from SharedPreferences automatically
  // inside Supabase.initialize above. No manual restoration is needed.

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const SecureChatApp(),
    ),
  );
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Must be registered before WidgetsFlutterBinding is settled so the
    // background isolate can call Firebase without re-initialising.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    AppLogger.info('Firebase initialized');
  } catch (e) {
    // Firebase is not configured yet — run `flutterfire configure` and replace
    // lib/firebase_options.dart to enable push notifications.
    AppLogger.warning('Firebase not configured, push notifications disabled', e);
  }
}

Future<void> _initializeSupabase() async {
  if (!AppConfig.hasSupabaseCredentials) {
    AppLogger.warning(
      'Supabase credentials not provided. '
      'Run with: --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key>',
    );
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );

  AppLogger.info('Supabase initialized');
}
