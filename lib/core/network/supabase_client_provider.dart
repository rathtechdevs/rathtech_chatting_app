import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// The Supabase client is initialized in main.dart before ProviderScope is created.
// This provider simply exposes the already-initialized singleton.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
