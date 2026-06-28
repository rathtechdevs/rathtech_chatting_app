class Pair {
  const Pair({
    required this.id,
    required this.userAId,
    required this.userBId,
    required this.createdAt,
  });

  final String id;
  final String userAId;
  final String userBId;
  final DateTime createdAt;

  String partnerIdFor(String ownUserId) =>
      ownUserId == userAId ? userBId : userAId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Pair && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
