import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../domain/entities/message.dart';
import '../../providers.dart';
import '../viewmodels/chat_state.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/date_separator.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  static const _loadMoreThreshold = 200.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - _loadMoreThreshold) {
      ref.read(chatViewModelProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatViewModelProvider);
    final ownUserId = ref.watch(chatOwnUserIdProvider);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(child: _buildBody(context, state, ownUserId)),
          _buildInput(state),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.appName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            AppStrings.chatOnline,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    ChatState state,
    String ownUserId,
  ) {
    if (state is ChatInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ChatError) {
      return Center(
        child: Text(state.message, style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    final ready = state as ChatReady;
    final messages = ready.messages;

    if (messages.isEmpty) {
      return _EmptyState();
    }

    return Stack(
      children: [
        _MessageList(
          messages: messages,
          ownUserId: ownUserId,
          scrollController: _scrollController,
          isLoadingMore: ready.isLoadingMore,
        ),
        if (ready.sendError != null)
          Positioned(
            bottom: 8,
            left: 16,
            right: 16,
            child: _ErrorBanner(message: ready.sendError!),
          ),
      ],
    );
  }

  Widget _buildInput(ChatState state) {
    final isSending = state is ChatReady && state.isSending;
    return ChatInputBar(
      isSending: isSending,
      onSend: (text) => ref.read(chatViewModelProvider.notifier).sendMessage(text),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.ownUserId,
    required this.scrollController,
    required this.isLoadingMore,
  });

  final List<Message> messages;
  final String ownUserId;
  final ScrollController scrollController;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    // Messages are oldest-first; we reverse the ListView so newest is at bottom.
    final itemCount = messages.length + (isLoadingMore ? 1 : 0);

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0 && isLoadingMore) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final msgIndex = isLoadingMore ? index - 1 : index;
        final message = messages[msgIndex];
        final isOwn = message.isSentBy(ownUserId);

        final showDateSep = msgIndex == 0 ||
            !messages[msgIndex - 1].createdAt.isSameDayAs(message.createdAt);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDateSep) DateSeparator(date: message.createdAt),
            MessageBubble(message: message, isOwn: isOwn),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.chatEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.chatEmptySubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
        ),
      ),
    );
  }
}
