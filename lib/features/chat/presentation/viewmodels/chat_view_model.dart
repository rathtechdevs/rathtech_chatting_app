import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logger/app_logger.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../providers.dart';
import 'chat_state.dart';

class ChatViewModel extends Notifier<ChatState> {
  String get _pairId => ref.read(chatPairIdProvider);
  String get _ownUserId => ref.read(chatOwnUserIdProvider);
  String get _partnerId => ref.read(chatPartnerIdProvider);

  @override
  ChatState build() {
    final pairId = _pairId;

    ref.read(chatRepositoryProvider).startRealtimeListener(pairId);
    ref.onDispose(() {
      ref.read(chatRepositoryProvider).stopRealtimeListener(pairId);
    });

    final sub = ref
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

    ref.onDispose(sub.cancel);

    return const ChatInitial();
  }

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
}
