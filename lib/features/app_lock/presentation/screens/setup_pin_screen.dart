import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../providers.dart';
import '../viewmodels/setup_pin_state.dart';
import '../widgets/pin_dots.dart';
import '../widgets/pin_pad.dart';

class SetupPinScreen extends ConsumerWidget {
  const SetupPinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(setupPinNotifierProvider);
    final theme = Theme.of(context);

    if (state is SetupPinDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.pop();
      });
    }

    final (title, filledCount, isSaving) = switch (state) {
      SetupPinEntering(:final pin) => (
          AppStrings.appLockSetPin,
          pin.length,
          false,
        ),
      SetupPinConfirming(:final confirmPin) => (
          AppStrings.appLockConfirmPin,
          confirmPin.length,
          false,
        ),
      SetupPinSaving() => (AppStrings.appLockConfirmPin, 6, true),
      SetupPinDone() => (AppStrings.appLockConfirmPin, 6, false),
    };

    final error = state is SetupPinConfirming ? state.error : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appLockEnablePin),
        leading: BackButton(
          onPressed: () {
            ref.read(setupPinNotifierProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Text(title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 40),
                PinDots(filledCount: filledCount),
                const SizedBox(height: 16),
                AnimatedOpacity(
                  opacity: error != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    error ?? '',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (isSaving)
                  const CircularProgressIndicator()
                else
                  PinPad(
                    onDigit: (d) =>
                        ref.read(setupPinNotifierProvider.notifier).onDigit(d),
                    onBackspace: () => ref
                        .read(setupPinNotifierProvider.notifier)
                        .onBackspace(),
                  ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
