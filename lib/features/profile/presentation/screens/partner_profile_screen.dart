import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../providers.dart';
import '../widgets/avatar_widget.dart';

class PartnerProfileScreen extends ConsumerWidget {
  const PartnerProfileScreen({super.key, required this.partnerId});

  final String partnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(partnerProfileStreamProvider(partnerId)).valueOrNull;
    final presence =
        ref.watch(partnerPresenceStreamProvider(partnerId)).valueOrNull;

    final displayName = profile?.displayName ?? '…';
    final avatarUrl = profile?.avatarUrl;

    String presenceText;
    if (presence == null) {
      presenceText = '';
    } else if (presence.isOnline) {
      presenceText = AppStrings.chatOnline;
    } else {
      presenceText =
          '${AppStrings.chatLastSeen} ${presence.lastSeenAt.toLastSeen()}';
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.partnerProfileTitle)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AvatarWidget(
              avatarUrl: avatarUrl,
              displayName: displayName,
              radius: 56,
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (presenceText.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                presenceText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: presence?.isOnline == true
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
