import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum OnlineStatus { online, offline }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.size = 12});

  final OnlineStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: status == OnlineStatus.online
            ? AppColors.online
            : AppColors.offline,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 2,
        ),
      ),
    );
  }
}
