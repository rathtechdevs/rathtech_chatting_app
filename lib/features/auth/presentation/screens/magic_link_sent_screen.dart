import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../viewmodels/login_state.dart';
import '../viewmodels/login_view_model.dart';

class MagicLinkSentScreen extends ConsumerWidget {
  const MagicLinkSentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<LoginState>(loginViewModelProvider, (previous, next) {
      if (next is LoginMagicLinkSent) {
        context.showSnackBar('Link resent to your email.');
        ref.read(loginViewModelProvider.notifier).reset();
      } else if (next is LoginError) {
        context.showSnackBar(next.message, isError: true);
      }
    });

    final state = ref.watch(loginViewModelProvider);
    final isResending = state is LoginLoading;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.authMagicLinkTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.authMagicLinkTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.authMagicLinkSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 0.7,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (isResending)
                const Center(child: CircularProgressIndicator())
              else
                TextButton(
                  onPressed: () =>
                      ref.read(loginViewModelProvider.notifier).reset(),
                  child: const Text(AppStrings.authMagicLinkResend),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
