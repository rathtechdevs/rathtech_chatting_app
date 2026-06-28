import '../../domain/entities/pair.dart';

class PairDto {
  const PairDto({
    required this.id,
    required this.userAId,
    required this.userBId,
    required this.createdAt,
  });

  final String id;
  final String userAId;
  final String userBId;
  final DateTime createdAt;

  factory PairDto.fromJson(Map<String, dynamic> json) => PairDto(
        id: json['id'] as String,
        userAId: json['user_a_id'] as String,
        userBId: json['user_b_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Pair toEntity() => Pair(
        id: id,
        userAId: userAId,
        userBId: userBId,
        createdAt: createdAt,
      );
}
