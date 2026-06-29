import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/reaction.dart';
import 'image_message_bubble.dart';
import 'message_status_icon.dart';
import 'voice_message_bubble.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
    required this.reactions,
    required this.ownUserId,
    required this.isEdited,
    required this.onLongPress,
  });

  final Message message;
  final bool isOwn;
  final List<Reaction> reactions;
  final String ownUserId;
  final bool isEdited;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleColor = isOwn
        ? (isDark ? AppColors.sentBubbleDark : AppColors.sentBubbleLight)
        : (isDark ? AppColors.receivedBubbleDark : AppColors.receivedBubbleLight);

    final textColor = isOwn
        ? (isDark ? AppColors.sentBubbleTextDark : AppColors.sentBubbleTextLight)
        : (isDark
            ? AppColors.receivedBubbleTextDark
            : AppColors.receivedBubbleTextLight);

    // Media messages use their own layout; route by contentType.
    if (message.contentType == 'image' && !message.isDeleted) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ImageMessageBubble(
            message: message,
            isOwn: isOwn,
            bubbleColor: bubbleColor,
            onLongPress: onLongPress,
          ),
          if (reactions.isNotEmpty)
            Padding(
              padding:
                  EdgeInsets.only(left: isOwn ? 0 : 24, right: isOwn ? 24 : 0),
              child: _ReactionRow(reactions: reactions, ownUserId: ownUserId),
            ),
        ],
      );
    }

    if (message.contentType == 'voice' && !message.isDeleted) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Align(
          alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment:
                isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isOwn ? 18 : 4),
                    bottomRight: Radius.circular(isOwn ? 4 : 18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VoiceMessageBubble(
                      message: message,
                      isOwn: isOwn,
                      bubbleColor: bubbleColor,
                      textColor: textColor,
                      onLongPress: onLongPress,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12, bottom: 6),
                      child: _TimeRow(
                        message: message,
                        isOwn: isOwn,
                        isEdited: false,
                        textColor: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (reactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: _ReactionRow(
                    reactions: reactions,
                    ownUserId: ownUserId,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Text (and deleted) messages.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Align(
        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onLongPress: message.isDeleted ? null : onLongPress,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isOwn ? 18 : 4),
                      bottomRight: Radius.circular(isOwn ? 4 : 18),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.isDeleted
                              ? AppStrings.chatMessageDeleted
                              : (message.text ?? ''),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: message.isDeleted
                                    ? textColor.withValues(alpha: 0.6)
                                    : textColor,
                                fontStyle: message.isDeleted
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                        ),
                        const SizedBox(height: 2),
                        _TimeRow(
                          message: message,
                          isOwn: isOwn,
                          isEdited: isEdited,
                          textColor: textColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _ReactionRow(
                  reactions: reactions,
                  ownUserId: ownUserId,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.message,
    required this.isOwn,
    required this.isEdited,
    required this.textColor,
  });

  final Message message;
  final bool isOwn;
  final bool isEdited;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isEdited && !message.isDeleted) ...[
          Text(
            AppStrings.chatMessageEdited,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: textColor.withValues(alpha: 0.55),
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          message.createdAt.toMessageTime(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: textColor.withValues(alpha: 0.7),
                fontSize: 10,
              ),
        ),
        if (isOwn) ...[
          const SizedBox(width: 3),
          MessageStatusIcon(status: message.status),
        ],
      ],
    );
  }
}

class _ReactionRow extends StatelessWidget {
  const _ReactionRow({
    required this.reactions,
    required this.ownUserId,
  });

  final List<Reaction> reactions;
  final String ownUserId;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, int>{};
    for (final r in reactions) {
      grouped[r.emoji] = (grouped[r.emoji] ?? 0) + 1;
    }

    return Wrap(
      spacing: 4,
      children: grouped.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            entry.value > 1 ? '${entry.key} ${entry.value}' : entry.key,
            style: const TextStyle(fontSize: 13),
          ),
        );
      }).toList(),
    );
  }
}
