import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, this.isLoading = true, this.child});

  final bool isLoading;
  final Widget? child;

  static Future<T> show<T>(
    BuildContext context,
    Future<T> Function() action,
  ) async {
    final overlay = OverlayEntry(
      builder: (_) => const ColoredBox(
        color: AppColors.overlayDark,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
    Overlay.of(context).insert(overlay);
    try {
      return await action();
    } finally {
      overlay.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child ?? const SizedBox.shrink();

    return Stack(
      children: [
        ?child,
        const ColoredBox(
          color: AppColors.overlayDark,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}
