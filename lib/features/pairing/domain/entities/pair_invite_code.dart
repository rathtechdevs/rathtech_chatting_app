class PairInviteCode {
  const PairInviteCode({
    required this.id,
    required this.code,
    required this.creatorId,
    required this.expiresAt,
    required this.used,
    required this.createdAt,
  });

  final String id;
  final String code;
  final String creatorId;
  final DateTime expiresAt;
  final bool used;
  final DateTime createdAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !used && !isExpired;
  Duration get remaining => expiresAt.difference(DateTime.now());
}
