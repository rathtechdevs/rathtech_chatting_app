import 'package:flutter/material.dart';

import '../../domain/entities/message.dart';

class MessageStatusIcon extends StatelessWidget {
  const MessageStatusIcon({super.key, required this.status});

  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      MessageStatus.pending => Icon(
          Icons.access_time_rounded,
          size: 12,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      MessageStatus.sent => Icon(
          Icons.check_rounded,
          size: 12,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      MessageStatus.delivered || MessageStatus.read => Icon(
          Icons.done_all_rounded,
          size: 12,
          color: status == MessageStatus.read
              ? Colors.lightBlueAccent
              : Colors.white.withValues(alpha: 0.7),
        ),
      MessageStatus.failed => Icon(
          Icons.error_outline_rounded,
          size: 12,
          color: Theme.of(context).colorScheme.error,
        ),
    };
  }
}
