import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/components/primary_button.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../viewmodels/setup_profile_state.dart';
import '../viewmodels/setup_profile_view_model.dart';

class SetupProfileScreen extends ConsumerStatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  ConsumerState<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends ConsumerState<SetupProfileScreen> {
  final _nameController = TextEditingController();
  DateTime? _dateOfBirth;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SetupProfileState>(setupProfileViewModelProvider, (prev, next) {
      if (next is SetupProfileSuccess) {
        // Session refresh triggers watchAuthState → authenticated → GoRouter
        // redirects to /pair automatically. Navigate as fallback.
        context.go(AppRoutes.pair);
      } else if (next is SetupProfileError) {
        context.showSnackBar(next.message, isError: true);
      }
    });

    final state = ref.watch(setupProfileViewModelProvider);
    final isLoading = state is SetupProfileLoading;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileSetupTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                AppStrings.profileSetupSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                enabled: !isLoading,
                maxLength: 30,
                decoration: const InputDecoration(
                  hintText: AppStrings.profileDisplayNameHint,
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),
              _DobPicker(
                selectedDate: _dateOfBirth,
                enabled: !isLoading,
                onDateSelected: (d) => setState(() => _dateOfBirth = d),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: AppStrings.profileSave,
                isLoading: isLoading,
                onPressed: isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    ref.read(setupProfileViewModelProvider.notifier).createProfile(
      rawDisplayName: _nameController.text,
      dateOfBirth: _dateOfBirth,
    );
  }
}

class _DobPicker extends StatelessWidget {
  const _DobPicker({
    required this.selectedDate,
    required this.enabled,
    required this.onDateSelected,
  });

  final DateTime? selectedDate;
  final bool enabled;
  final ValueChanged<DateTime?> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final label = selectedDate != null
        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
        : 'Date of birth (optional — required for age verification)';

    return OutlinedButton.icon(
      onPressed: enabled ? () => _pick(context) : null,
      icon: const Icon(Icons.calendar_today_outlined),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(label),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(DateTime.now().year - 18),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select your date of birth',
    );
    if (picked != null) onDateSelected(picked);
  }
}
