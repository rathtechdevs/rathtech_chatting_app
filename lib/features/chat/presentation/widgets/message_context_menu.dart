import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/message.dart';

/// Long-press context menu for a single message.
class MessageContextMenu extends StatelessWidget {
  const MessageContextMenu({
    super.key,
    required this.message,
    required this.isOwn,
    required this.onReact,
    required this.onEdit,
    required this.onDelete,
  });

  final Message message;
  final bool isOwn;
  final void Function(String emoji) onReact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static Future<void> show(
    BuildContext context, {
    required Message message,
    required bool isOwn,
    required void Function(String emoji) onReact,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (_) => MessageContextMenu(
        message: message,
        isOwn: isOwn,
        onReact: onReact,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // React row
          if (!message.isDeleted) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '😂', '😮', '😢', '👍', '👎']
                    .map(
                      (emoji) => GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          onReact(emoji);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const Divider(height: 1),
          ],

          // Copy
          if (!message.isDeleted && message.text != null)
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text(AppStrings.chatCopyLabel),
              onTap: () {
                Navigator.of(context).pop();
                Clipboard.setData(ClipboardData(text: message.text ?? '')).ignore();
              },
            ),

          // Edit (own non-deleted messages only, within 15 min)
          if (isOwn &&
              !message.isDeleted &&
              DateTime.now()
                      .difference(message.createdAt)
                      .inMinutes <
                  15)
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text(AppStrings.chatEditLabel),
              onTap: () {
                Navigator.of(context).pop();
                onEdit();
              },
            ),

          // Delete (own non-deleted messages only)
          if (isOwn && !message.isDeleted)
            ListTile(
              leading:
                  Icon(Icons.delete_rounded, color: Colors.red.shade400),
              title: Text(
                AppStrings.chatDeleteLabel,
                style: TextStyle(color: Colors.red.shade400),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onDelete();
              },
            ),
        ],
      ),
    );
  }
}
