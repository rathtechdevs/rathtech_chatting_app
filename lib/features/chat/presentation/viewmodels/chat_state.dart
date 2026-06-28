import '../../domain/entities/message.dart';

sealed class ChatState {
  const ChatState();
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatReady extends ChatState {
  const ChatReady({
    required this.messages,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
    this.isSending = false,
    this.sendError,
  });

  final List<Message> messages; // Oldest first; newest at bottom of list
  final bool isLoadingMore;
  final bool hasMoreMessages;
  final bool isSending;
  final String? sendError;

  ChatReady copyWith({
    List<Message>? messages,
    bool? isLoadingMore,
    bool? hasMoreMessages,
    bool? isSending,
    String? Function()? sendError,
  }) {
    return ChatReady(
      messages: messages ?? this.messages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isSending: isSending ?? this.isSending,
      sendError: sendError != null ? sendError() : this.sendError,
    );
  }
}

class ChatError extends ChatState {
  const ChatError(this.message);
  final String message;
}
