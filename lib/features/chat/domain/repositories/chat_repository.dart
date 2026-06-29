import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/message.dart';
import '../entities/reaction.dart';
import '../use_cases/edit_message_use_case.dart';
import '../use_cases/react_to_message_use_case.dart';

class SendMessageParams {
  const SendMessageParams({
    required this.pairId,
    required this.senderId,
    required this.partnerId,
    required this.text,
  });

  final String pairId;
  final String senderId;
  final String partnerId;
  final String text;
}

class SendMediaParams {
  const SendMediaParams({
    required this.pairId,
    required this.senderId,
    required this.partnerId,
    required this.contentType,
    required this.localFilePath,
    this.durationMs,
  });

  final String pairId;
  final String senderId;
  final String partnerId;
  final String contentType; // 'image' | 'voice'
  final String localFilePath;
  final int? durationMs; // voice messages only
}

class LoadMoreParams {
  const LoadMoreParams({
    required this.pairId,
    required this.before,
    this.limit = 30,
  });

  final String pairId;
  final DateTime before;
  final int limit;
}

abstract interface class ChatRepository {
  // ── M4: Core messaging ────────────────────────────────────────────────────

  Future<Either<Failure, Message>> sendMessage(SendMessageParams params);

  Stream<Either<Failure, List<Message>>> watchMessages(String pairId);

  Future<Either<Failure, List<Message>>> loadMoreMessages(LoadMoreParams params);

  void startRealtimeListener(String pairId);

  Future<void> stopRealtimeListener(String pairId);

  // ── M5: Message features ──────────────────────────────────────────────────

  Future<Either<Failure, Message>> editMessage(EditMessageParams params);

  Future<Either<Failure, void>> deleteMessage(String messageId);

  Future<Either<Failure, void>> reactToMessage(ReactToMessageParams params);

  Future<Either<Failure, void>> removeReaction({
    required String messageId,
    required String pairId,
  });

  Future<Either<Failure, void>> markAllRead(String pairId);

  Stream<Map<String, List<Reaction>>> watchReactions(String pairId);

  Future<void> sendTyping(String pairId, {required bool isTyping});

  Stream<bool> watchTyping(String pairId);

  // ── M6: Media messages ────────────────────────────────────────────────────

  Future<Either<Failure, Message>> sendMediaMessage(SendMediaParams params);
}
