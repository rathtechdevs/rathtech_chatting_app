enum MessageStatus {
  pending,   // Inserted locally, not yet confirmed by server
  sent,      // Server confirmed receipt
  delivered, // Partner device received it
  read,      // Partner opened it
  failed,    // Server or encryption error
}

extension MessageStatusExtension on MessageStatus {
  String get value => name;

  static MessageStatus fromString(String s) =>
      MessageStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => MessageStatus.sent,
      );
}

class Message {
  const Message({
    required this.id,
    required this.pairId,
    required this.senderId,
    required this.contentType,
    required this.status,
    required this.createdAt,
    this.text,
    this.mediaLocalPath,
    this.mediaStorageUrl,
    this.mediaDurationMs,
    this.replyToId,
    this.isDeleted = false,
  });

  final String id;
  final String pairId;
  final String senderId;
  final String contentType; // 'text' | 'image' | 'voice' | 'system'
  final String? text;
  final String? mediaLocalPath;
  final String? mediaStorageUrl;
  final int? mediaDurationMs;
  final MessageStatus status;
  final DateTime createdAt;
  final String? replyToId;
  final bool isDeleted;

  bool isSentBy(String userId) => senderId == userId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Message && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
