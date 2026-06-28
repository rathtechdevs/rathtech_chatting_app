import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/message.dart';

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
  // Encrypts and sends a text message; inserts to local DB optimistically.
  Future<Either<Failure, Message>> sendMessage(SendMessageParams params);

  // Watches the local Drift message list for pairId (newest-first).
  Stream<Either<Failure, List<Message>>> watchMessages(String pairId);

  // Loads older messages from Supabase and caches them locally.
  Future<Either<Failure, List<Message>>> loadMoreMessages(LoadMoreParams params);

  // Starts listening to Realtime inserts for pairId; decrypts and upserts locally.
  void startRealtimeListener(String pairId);

  // Removes the Realtime channel for pairId.
  Future<void> stopRealtimeListener(String pairId);
}
