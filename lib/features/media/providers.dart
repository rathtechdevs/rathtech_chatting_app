import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/media/media_cache_service.dart';
import '../../core/network/supabase_client_provider.dart';
import 'data/data_sources/media_remote_data_source.dart';

final mediaRemoteDataSourceProvider = Provider<MediaRemoteDataSource>((ref) {
  return MediaRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final mediaCacheServiceProvider = Provider<MediaCacheService>((ref) {
  return MediaCacheService();
});

// Shared audio player — only one voice message plays at a time.
final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});

// Tracks which message ID is currently playing (null = nothing playing).
final currentlyPlayingMessageIdProvider = StateProvider<String?>((ref) => null);
