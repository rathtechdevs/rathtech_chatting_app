import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/message.dart';
import 'message_status_icon.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
  });

  final Message message;
  final bool isOwn;

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Align(
        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.isDeleted
                        ? AppStrings.chatMessageDeleted
                        : (message.text ?? ''),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                    textColor: textColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.message,
    required this.isOwn,
    required this.textColor,
  });

  final Message message;
  final bool isOwn;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
