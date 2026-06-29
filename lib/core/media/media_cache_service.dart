import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../logger/app_logger.dart';

class MediaCacheService {
  static const _dirName = 'media_cache';

  // Images → .jpg, voice → .m4a (AAC produced by the `record` package).
  static String extensionFor(String contentType) =>
      contentType == 'voice' ? 'm4a' : 'jpg';

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, _dirName));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<String> save({
    required String messageId,
    required String contentType,
    required Uint8List bytes,
  }) async {
    final dir = await _dir();
    final ext = extensionFor(contentType);
    final file = File(p.join(dir.path, '$messageId.$ext'));
    await file.writeAsBytes(bytes);
    AppLogger.info('MediaCache: saved ${file.path}');
    return file.path;
  }

  Future<String?> localPath(String messageId) async {
    final dir = await _dir();
    for (final ext in ['jpg', 'm4a']) {
      final f = File(p.join(dir.path, '$messageId.$ext'));
      if (f.existsSync()) return f.path;
    }
    return null;
  }
}
