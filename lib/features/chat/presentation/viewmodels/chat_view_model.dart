import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logger/app_logger.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/use_cases/edit_message_use_case.dart';
import '../../domain/use_cases/react_to_message_use_case.dart';
import '../../providers.dart';
import 'chat_state.dart';

class ChatViewModel extends Notifier<ChatState> {
  String get _pairId => ref.read(chatPairIdProvider);
  String get _ownUserId => ref.read(chatOwnUserIdProvider);
  String get _partnerId => ref.read(chatPartnerIdProvider);

  Timer? _typingStopTimer;

  @override
  ChatState build() {
    final pairId = _pairId;
    final repo = ref.read(chatRepositoryProvider);

    repo.startRealtimeListener(pairId);
    ref.onDispose(() async {
      _typingStopTimer?.cancel();
      await repo.sendTyping(pairId, isTyping: false);
      await repo.stopRealtimeListener(pairId);
    });

    // Messages stream
    final msgSub = ref
        .read(watchMessagesUseCaseProvider)
        .execute(pairId)
        .listen((result) {
      result.fold(
        (failure) {
          AppLogger.error('watchMessages error', failure);
          state = ChatError(failure.message);
        },
        (messages) {
          if (state case final ChatReady ready) {
            state = ready.copyWith(messages: messages);
          } else {
            state = ChatReady(messages: messages);
          }
        },
      );
    });
    ref.onDispose(msgSub.cancel);

    // Reactions stream
    final reactionSub = repo.watchReactions(pairId).listen((reactions) {
      if (state case final ChatReady ready) {
        state = ready.copyWith(reactions: reactions);
      }
    });
    ref.onDispose(reactionSub.cancel);

    // Typing stream (channel must be started first — done above)
    final typingSub = repo.watchTyping(pairId).listen((isTyping) {
      if (state case final ChatReady ready) {
        state = ready.copyWith(isPartnerTyping: isTyping);
      }
    });
    ref.onDispose(typingSub.cancel);

    // Mark incoming messages as read once the screen opens.
    Future.microtask(
      () => ref.read(markAllReadUseCaseProvider).execute(pairId),
    );

    return const ChatInitial();
  }

  // ── Messaging ──────────────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (state case final ChatReady current) {
      state = current.copyWith(isSending: true, sendError: () => null);
    }

    final result = await ref.read(sendMessageUseCaseProvider).execute(
          SendMessageParams(
            pairId: _pairId,
            senderId: _ownUserId,
            partnerId: _partnerId,
            text: trimmed,
          ),
        );

    result.fold(
      (failure) {
        AppLogger.error('sendMessage failed', failure);
        if (state case final ChatReady ready) {
          state = ready.copyWith(
            isSending: false,
            sendError: () => failure.message,
          );
        }
      },
      (_) {
        if (state case final ChatReady ready) {
          state = ready.copyWith(isSending: false, sendError: () => null);
        }
      },
    );

    // Stop typing indicator when message is sent.
    _broadcastTyping(false);
  }

  Future<void> loadMore() async {
    if (state case final ChatReady current) {
      if (current.isLoadingMore || !current.hasMoreMessages) return;
      if (current.messages.isEmpty) return;

      state = current.copyWith(isLoadingMore: true);

      final oldest = current.messages.first.createdAt;

      final result = await ref.read(loadMoreMessagesUseCaseProvider).execute(
            LoadMoreParams(pairId: _pairId, before: oldest),
          );

      result.fold(
        (failure) {
          AppLogger.error('loadMore failed', failure);
          if (state case final ChatReady ready) {
            state = ready.copyWith(isLoadingMore: false);
          }
        },
        (older) {
          if (state case final ChatReady ready) {
            state = ready.copyWith(
              isLoadingMore: false,
              hasMoreMessages: older.length == 30,
            );
          }
        },
      );
    }
  }

  // ── Edit ───────────────────────────────────────────────────────────────────

  Future<void> editMessage({
    required String messageId,
    required String pairId,
    required String newText,
    required DateTime originalCreatedAt,
  }) async {
    final result = await ref.read(editMessageUseCaseProvider).execute(
          EditMessageParams(
            messageId: messageId,
            pairId: pairId,
            newText: newText,
            originalCreatedAt: originalCreatedAt,
          ),
        );

    result.fold(
      (failure) => AppLogger.error('editMessage failed', failure),
      (_) {
        if (state case final ChatReady ready) {
          state = ready.copyWith(
            editedMessageIds: {...ready.editedMessageIds, messageId},
          );
        }
      },
    );
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> deleteMessage(String messageId) async {
    final result = await ref
        .read(deleteMessageUseCaseProvider)
        .execute(messageId);

    result.fold(
      (failure) => AppLogger.error('deleteMessage failed', failure),
      (_) {},
    );
  }

  // ── Reactions ──────────────────────────────────────────────────────────────

  Future<void> reactToMessage({
    required String messageId,
    required String emoji,
  }) async {
    final result = await ref.read(reactToMessageUseCaseProvider).execute(
          ReactToMessageParams(
            messageId: messageId,
            pairId: _pairId,
            emoji: emoji,
          ),
        );

    result.fold(
      (failure) => AppLogger.error('reactToMessage failed', failure),
      (_) {},
    );
  }

  Future<void> removeReaction(String messageId) async {
    final result = await ref
        .read(chatRepositoryProvider)
        .removeReaction(messageId: messageId, pairId: _pairId);

    result.fold(
      (failure) => AppLogger.error('removeReaction failed', failure),
      (_) {},
    );
  }

  // ── Typing ─────────────────────────────────────────────────────────────────

  void onTypingChanged(bool isTyping) {
    _typingStopTimer?.cancel();
    _broadcastTyping(isTyping);
    if (isTyping) {
      // Auto-stop after 3 s of no new updates to avoid stale "typing" indicators.
      _typingStopTimer = Timer(
        const Duration(seconds: 3),
        () => _broadcastTyping(false),
      );
    }
  }

  void _broadcastTyping(bool isTyping) {
    ref
        .read(chatRepositoryProvider)
        .sendTyping(_pairId, isTyping: isTyping)
        .ignore();
  }
}
