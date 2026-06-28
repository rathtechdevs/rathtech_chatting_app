import '../../domain/entities/pair_invite_code.dart';

class InviteCodeDto {
  const InviteCodeDto({
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

  factory InviteCodeDto.fromJson(Map<String, dynamic> json) => InviteCodeDto(
        id: json['id'] as String,
        code: json['code'] as String,
        creatorId: json['creator_id'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String),
        used: json['used'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  PairInviteCode toEntity() => PairInviteCode(
        id: id,
        code: code,
        creatorId: creatorId,
        expiresAt: expiresAt,
        used: used,
        createdAt: createdAt,
      );
}
