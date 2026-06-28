import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/components/loading_overlay.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../providers.dart';
import '../viewmodels/generate_invite_state.dart';

class GenerateInviteScreen extends ConsumerStatefulWidget {
  const GenerateInviteScreen({super.key});

  @override
  ConsumerState<GenerateInviteScreen> createState() =>
      _GenerateInviteScreenState();
}

class _GenerateInviteScreenState extends ConsumerState<GenerateInviteScreen> {
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(generateInviteViewModelProvider.notifier).generate();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(DateTime expiresAt) {
    _countdownTimer?.cancel();
    _updateRemaining(expiresAt);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining(expiresAt);
    });
  }

  void _updateRemaining(DateTime expiresAt) {
    final r = expiresAt.difference(DateTime.now());
    if (mounted) {
      setState(() => _remaining = r.isNegative ? Duration.zero : r);
    }
  }

  String _formatRemaining() {
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.generateInviteCopied),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildBody(GenerateInviteState state) {
    void regenerate() =>
        ref.read(generateInviteViewModelProvider.notifier).generate();

    if (state is GenerateInviteReady) {
      return _ReadyBody(
        code: state.inviteCode.code,
        countdown: _formatRemaining(),
        onCopy: () => _copyCode(state.inviteCode.code),
        onRegenerate: regenerate,
      );
    }
    if (state is GenerateInviteExpired) {
      return _ExpiredBody(onRegenerate: regenerate);
    }
    if (state is GenerateInviteError) {
      return _ErrorBody(message: state.message, onRetry: regenerate);
    }
    return const Center(child: CircularProgressIndicator());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(generateInviteViewModelProvider);

    ref.listen(generateInviteViewModelProvider, (_, next) {
      if (next is GenerateInviteReady) {
        _startCountdown(next.inviteCode.expiresAt);
      }
    });

    return LoadingOverlay(
      isLoading: state is GenerateInviteLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.generateInviteTitle),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildBody(state),
          ),
        ),
      ),
    );
  }
}

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({
    required this.code,
    required this.countdown,
    required this.onCopy,
    required this.onRegenerate,
  });

  final String code;
  final String countdown;
  final VoidCallback onCopy;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Text(
          AppStrings.generateInviteSubtitle,
          style: context.bodyMedium.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        // Code display
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                // Display code with a space in the middle for readability
                '${code.substring(0, 4)} ${code.substring(4)}',
                style: context.headlineLarge.copyWith(
                  letterSpacing: 6,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Expires in $countdown',
                    style: context.labelMedium.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onCopy,
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text(AppStrings.copy),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onRegenerate,
          child: const Text('Generate new code'),
        ),
        const Spacer(),
        // Waiting indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Waiting for your partner…',
              style: context.bodyMedium.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _ExpiredBody extends StatelessWidget {
  const _ExpiredBody({required this.onRegenerate});
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_off_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text('Code expired', style: context.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Your partner didn\'t join in time. Generate a new code.',
            style: context.bodyMedium.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: onRegenerate,
            child: const Text('Generate new code'),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(message,
              style: context.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onRetry,
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}
