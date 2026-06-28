import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';

// Common emojis available for reactions.
const _kEmojis = ['❤️', '😂', '😮', '😢', '👍', '👎'];

/// Bottom-sheet emoji picker. Calls [onEmojiSelected] and pops itself.
class ReactionPicker extends StatelessWidget {
  const ReactionPicker({
    super.key,
    required this.onEmojiSelected,
  });

  final void Function(String emoji) onEmojiSelected;

  static Future<void> show(
    BuildContext context, {
    required void Function(String emoji) onEmojiSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (_) => ReactionPicker(onEmojiSelected: onEmojiSelected),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.chatReactLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _kEmojis
                  .map(
                    (emoji) => _EmojiButton(
                      emoji: emoji,
                      onTap: () {
                        Navigator.of(context).pop();
                        onEmojiSelected(emoji);
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  const _EmojiButton({required this.emoji, required this.onTap});

  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }
}
