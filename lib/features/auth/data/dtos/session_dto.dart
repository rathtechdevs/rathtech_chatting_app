import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/auth_session.dart';

class SessionDto {
  const SessionDto({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.userId,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresAt;
  final String userId;

  factory SessionDto.fromSupabaseSession(Session session) => SessionDto(
    accessToken: session.accessToken,
    refreshToken: session.refreshToken ?? '',
    expiresAt: session.expiresAt ?? 0,
    userId: session.user.id,
  );

  factory SessionDto.fromJson(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return SessionDto(
      accessToken: map['access_token'] as String,
      refreshToken: map['refresh_token'] as String,
      expiresAt: map['expires_at'] as int,
      userId: map['user_id'] as String,
    );
  }

  String toJson() => jsonEncode({
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt,
    'user_id': userId,
  });

  AuthSession toDomain() => AuthSession(
    userId: userId,
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000),
  );
}
