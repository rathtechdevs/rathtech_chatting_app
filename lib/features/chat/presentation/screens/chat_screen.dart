import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../profile/presentation/widgets/avatar_widget.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/reaction.dart';
import '../../providers.dart';
import '../viewmodels/chat_state.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/date_separator.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_context_menu.dart';
import '../widgets/typing_indicator.dart';

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
      appBar: _buildAppBar(context, state),
      body: Column(
        children: [
          Expanded(child: _buildBody(context, state, ownUserId)),
          _buildInput(state),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, ChatState state) {
    final isTyping = state is ChatReady && state.isPartnerTyping;
    final partnerProfile = ref.watch(chatPartnerProfileProvider).valueOrNull;
    final presence = ref.watch(chatPartnerPresenceProvider).valueOrNull;
    final partnerId = ref.watch(chatPartnerIdProvider);

    final partnerName = partnerProfile?.displayName ?? AppStrings.appName;

    String subtitleText;
    if (isTyping) {
      subtitleText = AppStrings.chatTyping;
    } else if (presence?.isOnline == true) {
      subtitleText = AppStrings.chatOnline;
    } else if (presence != null) {
      subtitleText =
          '${AppStrings.chatLastSeen} ${presence.lastSeenAt.toLastSeen()}';
    } else {
      subtitleText = '';
    }

    return AppBar(
      leadingWidth: 56,
      leading: GestureDetector(
        onTap: () => context.push(
          AppRoutes.partnerProfile,
          extra: partnerId,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AvatarWidget(
            avatarUrl: partnerProfile?.avatarUrl,
            displayName: partnerName,
            radius: 18,
          ),
        ),
      ),
      title: GestureDetector(
        onTap: () => context.push(
          AppRoutes.partnerProfile,
          extra: partnerId,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              partnerName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (subtitleText.isNotEmpty)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  subtitleText,
                  key: ValueKey(subtitleText),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isTyping || presence?.isOnline == true
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                      ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_rounded),
          onPressed: () => context.push(AppRoutes.myProfile),
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
        child: Text(state.message,
            style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    final ready = state as ChatReady;
    final messages = ready.messages;

    if (messages.isEmpty) {
      return const _EmptyState();
    }

    return Stack(
      children: [
        _MessageList(
          messages: messages,
          reactions: ready.reactions,
          editedMessageIds: ready.editedMessageIds,
          ownUserId: ownUserId,
          scrollController: _scrollController,
          isLoadingMore: ready.isLoadingMore,
          isPartnerTyping: ready.isPartnerTyping,
          onLongPress: (message) =>
              _showContextMenu(context, message, ownUserId),
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
    final isRecording = state is ChatReady && state.isRecording;
    final recordingDuration =
        state is ChatReady ? state.recordingDuration : Duration.zero;
    final vm = ref.read(chatViewModelProvider.notifier);

    return ChatInputBar(
      isSending: isSending,
      isRecording: isRecording,
      recordingDuration: recordingDuration,
      onSend: (text) => vm.sendMessage(text),
      onTypingChanged: (isTyping) => vm.onTypingChanged(isTyping),
      onAttachImage: () => _pickImage(context),
      onVoiceRecordStart: vm.startRecording,
      onVoiceRecordEnd: vm.stopRecordingAndSend,
      onVoiceRecordCancel: vm.cancelRecording,
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final source = await _showImageSourceSheet(context);
    if (source == null) return;

    final file = await picker.pickImage(source: source, imageQuality: 90);
    if (file == null) return;

    if (context.mounted) {
      ref.read(chatViewModelProvider.notifier).sendImageMessage(file.path);
    }
  }

  Future<ImageSource?> _showImageSourceSheet(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text(AppStrings.chatSendImage),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(
    BuildContext context,
    Message message,
    String ownUserId,
  ) {
    final vm = ref.read(chatViewModelProvider.notifier);
    MessageContextMenu.show(
      context,
      message: message,
      isOwn: message.isSentBy(ownUserId),
      onReact: (emoji) => vm.reactToMessage(
        messageId: message.id,
        emoji: emoji,
      ),
      onEdit: () => _showEditDialog(context, message),
      onDelete: () => vm.deleteMessage(message.id),
    );
  }

  void _showEditDialog(BuildContext context, Message message) {
    final controller = TextEditingController(text: message.text ?? '');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.chatEditLabel),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newText = controller.text.trim();
              if (newText.isNotEmpty && newText != message.text) {
                ref.read(chatViewModelProvider.notifier).editMessage(
                      messageId: message.id,
                      pairId: ref.read(chatPairIdProvider),
                      newText: newText,
                      originalCreatedAt: message.createdAt,
                    );
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.reactions,
    required this.editedMessageIds,
    required this.ownUserId,
    required this.scrollController,
    required this.isLoadingMore,
    required this.isPartnerTyping,
    required this.onLongPress,
  });

  final List<Message> messages;
  final Map<String, List<Reaction>> reactions;
  final Set<String> editedMessageIds;
  final String ownUserId;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final bool isPartnerTyping;
  final void Function(Message) onLongPress;

  @override
  Widget build(BuildContext context) {
    final extraTop = isLoadingMore ? 1 : 0;
    final extraBottom = isPartnerTyping ? 1 : 0;
    final itemCount = messages.length + extraTop + extraBottom;

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

        if (index == itemCount - 1 && isPartnerTyping) {
          return const TypingIndicator();
        }

        final msgIndex = isLoadingMore ? index - 1 : index;
        final message = messages[msgIndex];
        final isOwn = message.isSentBy(ownUserId);

        final showDateSep = msgIndex == 0 ||
            !messages[msgIndex - 1]
                .createdAt
                .isSameDayAs(message.createdAt);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDateSep) DateSeparator(date: message.createdAt),
            MessageBubble(
              message: message,
              isOwn: isOwn,
              reactions: reactions[message.id] ?? const [],
              ownUserId: ownUserId,
              isEdited: editedMessageIds.contains(message.id),
              onLongPress: () => onLongPress(message),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.4),
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
