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

  /// Re-encrypts and sends the edited text; updates local cache.
  Future<Either<Failure, Message>> editMessage(EditMessageParams params);

  /// Soft-deletes the message on server and marks it locally.
  Future<Either<Failure, void>> deleteMessage(String messageId);

  /// Adds or replaces the caller's reaction on a message.
  Future<Either<Failure, void>> reactToMessage(ReactToMessageParams params);

  /// Removes the caller's reaction from a message.
  Future<Either<Failure, void>> removeReaction({
    required String messageId,
    required String pairId,
  });

  /// Marks all messages from the partner as 'read'.
  Future<Either<Failure, void>> markAllRead(String pairId);

  /// Live stream of all reactions grouped by message ID.
  Stream<Map<String, List<Reaction>>> watchReactions(String pairId);

  /// Broadcasts the caller's typing state to the partner.
  Future<void> sendTyping(String pairId, {required bool isTyping});

  /// Stream of the partner's typing state.
  Stream<bool> watchTyping(String pairId);
}
