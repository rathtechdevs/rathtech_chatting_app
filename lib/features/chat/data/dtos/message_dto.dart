import 'package:drift/drift.dart';

import '../../../../core/storage/app_database.dart';
import '../../domain/entities/message.dart';

abstract final class MessageDto {
  static Message fromLocalMessage(LocalMessage row) {
    // For voice messages, `decryptedText` stores the duration in ms as a
    // string (no schema change needed — text is always null for voice).
    final isVoice = row.contentType == 'voice';
    return Message(
      id: row.id,
      pairId: row.pairId,
      senderId: row.senderId,
      contentType: row.contentType,
      text: isVoice ? null : row.decryptedText,
      mediaDurationMs: isVoice ? int.tryParse(row.decryptedText ?? '') : null,
      mediaLocalPath: row.mediaLocalPath,
      mediaStorageUrl: row.mediaStorageUrl,
      status: MessageStatusExtension.fromString(row.status),
      createdAt: row.createdAt,
      replyToId: row.replyToId,
      isDeleted: row.isDeleted,
    );
  }

  static LocalMessagesCompanion toCompanion({
    required String id,
    required String pairId,
    required String senderId,
    required String contentType,
    required String status,
    required DateTime createdAt,
    String? decryptedText,
    // Passing non-null writes the value; passing null preserves existing DB value.
    String? mediaLocalPath,
    String? mediaStorageUrl,
    String? replyToId,
    bool isDeleted = false,
  }) {
    return LocalMessagesCompanion.insert(
      id: id,
      pairId: pairId,
      senderId: senderId,
      contentType: contentType,
      status: status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      decryptedText: Value(decryptedText),
      mediaLocalPath: mediaLocalPath != null
          ? Value(mediaLocalPath)
          : const Value.absent(),
      mediaStorageUrl: mediaStorageUrl != null
          ? Value(mediaStorageUrl)
          : const Value.absent(),
      replyToId: Value(replyToId),
      isDeleted: Value(isDeleted),
    );
  }
}
