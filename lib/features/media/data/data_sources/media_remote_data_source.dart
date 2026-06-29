import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart' hide StorageException;
import '../../../../core/logger/app_logger.dart';

abstract interface class MediaRemoteDataSource {
  Future<void> upload({required String storagePath, required Uint8List bytes});
  Future<Uint8List> download(String storagePath);
}

class MediaRemoteDataSourceImpl implements MediaRemoteDataSource {
  const MediaRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;
  static const _bucket = 'media';

  @override
  Future<void> upload({
    required String storagePath,
    required Uint8List bytes,
  }) async {
    try {
      await _client.storage.from(_bucket).uploadBinary(
        storagePath,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'application/octet-stream',
        ),
      );
    } on StorageException catch (e) {
      AppLogger.error('upload media failed: $storagePath', e);
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<Uint8List> download(String storagePath) async {
    try {
      return await _client.storage.from(_bucket).download(storagePath);
    } on StorageException catch (e) {
      AppLogger.error('download media failed: $storagePath', e);
      throw ServerException(message: e.message);
    }
  }
}
