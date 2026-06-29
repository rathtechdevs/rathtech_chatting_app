import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../features/auth/providers.dart';
import '../../providers.dart';
import '../viewmodels/profile_state.dart';
import '../widgets/avatar_widget.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _syncController(ProfileReady ready) {
    if (_nameController.text != ready.profile.displayName) {
      _nameController.text = ready.profile.displayName;
    }
  }

  Future<void> _pickAvatar(String userId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    if (!mounted) return;
    ref.read(profileViewModelProvider.notifier).uploadAvatar(userId, picked.path);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileViewModelProvider);
    final userId = ref.watch(currentUserIdProvider) ?? '';

    if (state is ProfileLoading || state is ProfileInitial) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.myProfileTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state is ProfileError) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.myProfileTitle)),
        body: Center(child: Text(state.message)),
      );
    }

    final ready = state as ProfileReady;
    _syncController(ready);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myProfileTitle),
        actions: [
          if (ready.isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )),
            )
          else
            TextButton(
              onPressed: () =>
                  ref.read(profileViewModelProvider.notifier)
                      .updateDisplayName(_nameController.text),
              child: const Text(AppStrings.save),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _AvatarSection(
              profile: ready,
              onTap: () => _pickAvatar(userId),
            ),
            const SizedBox(height: 32),
            _NameField(controller: _nameController, enabled: !ready.isSaving),
            if (ready.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                ready.errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.profile, required this.onTap});

  final ProfileReady profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: profile.isUploadingAvatar ? null : onTap,
          child: Stack(
            children: [
              AvatarWidget(
                avatarUrl: profile.profile.avatarUrl,
                displayName: profile.profile.displayName,
                radius: 48,
              ),
              if (profile.isUploadingAvatar)
                const Positioned.fill(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.black38,
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          profile.profile.hasAvatar
              ? AppStrings.profileChangePhoto
              : AppStrings.profileAddPhoto,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLength: 30,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Display name',
        hintText: AppStrings.profileDisplayNameHint,
        border: OutlineInputBorder(),
        counterText: '',
      ),
    );
  }
}
