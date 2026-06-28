class Reaction {
  const Reaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.emoji,
    required this.createdAt,
  });

  final String id;
  final String messageId;
  final String userId;
  final String emoji;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Reaction && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
