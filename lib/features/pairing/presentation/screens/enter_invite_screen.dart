import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/components/app_text_field.dart';
import '../../../../core/components/loading_overlay.dart';
import '../../../../core/components/primary_button.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../providers.dart';
import '../viewmodels/enter_invite_state.dart';

class EnterInviteScreen extends ConsumerStatefulWidget {
  const EnterInviteScreen({super.key});

  @override
  ConsumerState<EnterInviteScreen> createState() => _EnterInviteScreenState();
}

class _EnterInviteScreenState extends ConsumerState<EnterInviteScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    ref
        .read(enterInviteViewModelProvider.notifier)
        .submit(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(enterInviteViewModelProvider);
    final isLoading = state is EnterInviteLoading;
    final String? errorText;
    if (state is EnterInviteError) {
      errorText = state.message;
    } else {
      errorText = null;
    }

    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.enterInviteTitle),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Ask your partner to share their invite code, then enter it below.',
                  style: context.bodyMedium.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                AppTextField(
                  hint: AppStrings.enterInviteHint,
                  controller: _controller,
                  autofocus: true,
                  maxLength: 8,
                  errorText: errorText,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    // Only allow alphanumeric characters
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                    _UpperCaseFormatter(),
                  ],
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: AppStrings.enterInviteButton,
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _submit,
                ),
                if (state is EnterInviteSuccess) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.pairSuccessTitle,
                        style: context.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
