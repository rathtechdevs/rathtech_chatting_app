import 'package:drift/drift.dart';

import '../../../../core/storage/app_database.dart';
import '../../domain/entities/message.dart';

abstract final class MessageDto {
  static Message fromLocalMessage(LocalMessage row) {
    return Message(
      id: row.id,
      pairId: row.pairId,
      senderId: row.senderId,
      contentType: row.contentType,
      text: row.decryptedText,
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
      replyToId: Value(replyToId),
      isDeleted: Value(isDeleted),
    );
  }
}
