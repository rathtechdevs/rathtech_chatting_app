import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../providers.dart';
import '../widgets/pin_dots.dart';
import '../widgets/pin_pad.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  String _pin = '';
  bool _isVerifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    final settings = ref.read(appLockSettingsProvider);
    if (!settings.isBiometricEnabled) return;
    await _authenticateWithBiometric();
  }

  Future<void> _authenticateWithBiometric() async {
    if (!mounted) return;
    setState(() {
      _isVerifying = true;
      _error = null;
    });
    final result =
        await ref.read(authenticateWithBiometricUseCaseProvider).execute();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _isVerifying = false;
        _error = failure.message;
      }),
      (success) {
        if (success) {
          ref.read(appLockStatusProvider.notifier).unlock();
        } else {
          setState(() => _isVerifying = false);
        }
      },
    );
  }

  void _onDigit(String digit) {
    if (_pin.length >= 6 || _isVerifying) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == 6) _verifyPin();
  }

  void _onBackspace() {
    if (_pin.isEmpty || _isVerifying) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verifyPin() async {
    setState(() => _isVerifying = true);
    final result = await ref.read(verifyPinUseCaseProvider).execute(_pin);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _isVerifying = false;
        _pin = '';
        _error = failure.message;
      }),
      (correct) {
        if (correct) {
          ref.read(appLockStatusProvider.notifier).unlock();
        } else {
          setState(() {
            _isVerifying = false;
            _pin = '';
            _error = 'Incorrect PIN. Please try again.';
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appLockSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Icon(
                  Icons.lock_rounded,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.appLockTitle,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.appLockSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 48),
                PinDots(filledCount: _pin.length),
                const SizedBox(height: 16),
                AnimatedOpacity(
                  opacity: _error != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _error ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                PinPad(
                  onDigit: _onDigit,
                  onBackspace: _onBackspace,
                  enabled: !_isVerifying,
                ),
                const Spacer(),
                if (settings.isBiometricEnabled) ...[
                  TextButton.icon(
                    onPressed: _isVerifying ? null : _authenticateWithBiometric,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text(AppStrings.appLockUseBiometric),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
