class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.dateOfBirth,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final DateTime createdAt;

  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
  }) => UserProfile(
    id: id,
    displayName: displayName ?? this.displayName,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    dateOfBirth: dateOfBirth,
    createdAt: createdAt,
  );
}
