import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/supabase_client_provider.dart';
import '../storage/secure_storage_provider.dart';
import 'encryption_service.dart';
import 'encryption_service_impl.dart';
import 'key_generation_service.dart';
import 'key_storage_service.dart';
import 'key_storage_service_impl.dart';
import 'remote/key_bundle_remote_data_source.dart';

final keyBundleRemoteDataSourceProvider =
    Provider<KeyBundleRemoteDataSource>((ref) {
  return KeyBundleRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final keyStorageServiceProvider = Provider<KeyStorageService>((ref) {
  return KeyStorageServiceImpl(ref.watch(secureStorageProvider));
});

final keyGenerationServiceProvider = Provider<KeyGenerationService>((ref) {
  return KeyGenerationServiceImpl(
    keyStorage: ref.watch(keyStorageServiceProvider),
    remoteDataSource: ref.watch(keyBundleRemoteDataSourceProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
  return EncryptionServiceImpl(
    keyStorage: ref.watch(keyStorageServiceProvider),
    remoteDataSource: ref.watch(keyBundleRemoteDataSourceProvider),
    ownUserId: userId,
  );
});
