import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../domain/entities/message.dart';

class ImageMessageBubble extends StatelessWidget {
  const ImageMessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
    required this.bubbleColor,
    required this.onLongPress,
  });

  final Message message;
  final bool isOwn;
  final Color bubbleColor;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Align(
        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.65,
          ),
          child: GestureDetector(
            onLongPress: onLongPress,
            onTap: message.mediaLocalPath != null
                ? () => context.push(
                      AppRoutes.imageViewer,
                      extra: (
                        localPath: message.mediaLocalPath!,
                        heroTag: message.id,
                      ),
                    )
                : null,
            child: Hero(
              tag: message.id,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isOwn ? 18 : 4),
                  bottomRight: Radius.circular(isOwn ? 4 : 18),
                ),
                child: message.mediaLocalPath != null
                    ? Image.file(
                        File(message.mediaLocalPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const _MediaErrorPlaceholder(),
                      )
                    : const _MediaLoadingPlaceholder(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Shown while media is being downloaded/decrypted by the background listener.
class _MediaLoadingPlaceholder extends StatelessWidget {
  const _MediaLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 160,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _MediaErrorPlaceholder extends StatelessWidget {
  const _MediaErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 160,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.broken_image_rounded,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        size: 40,
      ),
    );
  }
}

