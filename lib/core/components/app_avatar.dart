import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.radius = 24,
    this.onTap,
  });

  final String? imageUrl;
  final String? initials;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget avatar;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = CachedNetworkImage(
        imageUrl: imageUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => _Placeholder(
          radius: radius,
          initials: initials,
          colorScheme: colorScheme,
        ),
        errorWidget: (context, url, error) => _Placeholder(
          radius: radius,
          initials: initials,
          colorScheme: colorScheme,
        ),
      );
    } else {
      avatar = _Placeholder(
        radius: radius,
        initials: initials,
        colorScheme: colorScheme,
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.radius,
    required this.colorScheme,
    this.initials,
  });

  final double radius;
  final ColorScheme colorScheme;
  final String? initials;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.15),
      child: initials != null
          ? Text(
              initials!,
              style: TextStyle(
                fontSize: radius * 0.7,
                fontWeight: FontWeight.w600,
                color: AppColors.brandPrimary,
              ),
            )
          : Icon(Icons.person_outline, size: radius, color: AppColors.brandPrimary),
    );
  }
}
