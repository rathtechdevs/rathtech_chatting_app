class UserPresence {
  const UserPresence({
    required this.userId,
    required this.isOnline,
    required this.lastSeenAt,
  });

  final String userId;
  final bool isOnline;
  final DateTime lastSeenAt;
}
