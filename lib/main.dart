import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/constants/storage_keys.dart';
import 'core/logger/app_logger.dart';
import 'core/notifications/notification_service_impl.dart';
import 'core/storage/shared_prefs_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeFirebase();
  await _initializeSupabase();

  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  await _restoreSession(secureStorage);

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

// Restores a persisted session from secure storage so that
// `supabase.auth.currentUser` is non-null before the first frame.
Future<void> _restoreSession(FlutterSecureStorage storage) async {
  try {
    final accessToken = await storage.read(key: StorageKeys.accessToken);
    final refreshToken = await storage.read(key: StorageKeys.refreshToken);

    if (accessToken == null || refreshToken == null) return;

    await Supabase.instance.client.auth.setSession(accessToken);
    AppLogger.info('Session restored from secure storage');
  } catch (e) {
    // Expired or invalid token — clear and force re-login.
    AppLogger.warning('Session restoration failed, clearing credentials', e);
    try {
      await storage.delete(key: StorageKeys.accessToken);
      await storage.delete(key: StorageKeys.refreshToken);
      await storage.delete(key: StorageKeys.userId);
    } catch (_) {
      // Best-effort cleanup; ignore secondary failure.
    }
  }
}
