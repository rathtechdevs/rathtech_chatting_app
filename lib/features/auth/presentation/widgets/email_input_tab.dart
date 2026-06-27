import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/components/primary_button.dart';
import '../../../../core/constants/app_strings.dart';
import '../viewmodels/login_state.dart';
import '../viewmodels/login_view_model.dart';

class EmailInputTab extends ConsumerStatefulWidget {
  const EmailInputTab({super.key});

  @override
  ConsumerState<EmailInputTab> createState() => _EmailInputTabState();
}

class _EmailInputTabState extends ConsumerState<EmailInputTab> {
  final _controller = TextEditingController();
  bool _ageConfirmed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginViewModelProvider);
    final isLoading = state is LoginLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.emailAddress,
            enabled: !isLoading,
            decoration: const InputDecoration(
              hintText: AppStrings.authEmailHint,
              prefixIcon: Icon(Icons.email_outlined),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          _AgeCheckbox(
            value: _ageConfirmed,
            onChanged: isLoading
                ? null
                : (v) => setState(() => _ageConfirmed = v ?? false),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: AppStrings.authGetMagicLink,
            isLoading: isLoading,
            onPressed: _ageConfirmed ? _submit : null,
          ),
        ],
      ),
    );
  }

  void _submit() {
    ref
        .read(loginViewModelProvider.notifier)
        .requestMagicLink(_controller.text);
  }
}

class _AgeCheckbox extends StatelessWidget {
  const _AgeCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(value: value, onChanged: onChanged),
        const SizedBox(width: 4),
        Expanded(
          child: GestureDetector(
            onTap: onChanged == null ? null : () => onChanged!(!value),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                AppStrings.authAgeConfirmation,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
