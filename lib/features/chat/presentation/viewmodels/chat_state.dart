import '../../domain/entities/message.dart';
import '../../domain/entities/reaction.dart';

sealed class ChatState {
  const ChatState();
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatReady extends ChatState {
  const ChatReady({
    required this.messages,
    this.reactions = const {},
    this.editedMessageIds = const {},
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
    this.isSending = false,
    this.isPartnerTyping = false,
    this.isRecording = false,
    this.recordingDuration = Duration.zero,
    this.sendError,
  });

  final List<Message> messages; // Oldest first; newest at bottom
  final Map<String, List<Reaction>> reactions; // messageId → reactions
  final Set<String> editedMessageIds; // tracks edits within this session
  final bool isLoadingMore;
  final bool hasMoreMessages;
  final bool isSending;
  final bool isPartnerTyping;
  final bool isRecording;
  final Duration recordingDuration;
  final String? sendError;

  ChatReady copyWith({
    List<Message>? messages,
    Map<String, List<Reaction>>? reactions,
    Set<String>? editedMessageIds,
    bool? isLoadingMore,
    bool? hasMoreMessages,
    bool? isSending,
    bool? isPartnerTyping,
    bool? isRecording,
    Duration? recordingDuration,
    String? Function()? sendError,
  }) {
    return ChatReady(
      messages: messages ?? this.messages,
      reactions: reactions ?? this.reactions,
      editedMessageIds: editedMessageIds ?? this.editedMessageIds,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isSending: isSending ?? this.isSending,
      isPartnerTyping: isPartnerTyping ?? this.isPartnerTyping,
      isRecording: isRecording ?? this.isRecording,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      sendError: sendError != null ? sendError() : this.sendError,
    );
  }
}

class ChatError extends ChatState {
  const ChatError(this.message);
  final String message;
}
