import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/components/primary_button.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/value_objects/phone_number.dart';
import '../viewmodels/otp_state.dart';
import '../viewmodels/otp_view_model.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key, required this.phone});

  final PhoneNumber phone;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  final _controller = TextEditingController();
  Timer? _resendTimer;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _controller.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _secondsRemaining = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = otpViewModelProvider(widget.phone);

    ref.listen<OtpState>(provider, (previous, next) {
      if (next is OtpError) {
        context.showSnackBar(next.message, isError: true);
      } else if (next is OtpInitial && previous is OtpResending) {
        // Resend successful
        _startResendTimer();
        context.showSnackBar('Code resent successfully.');
      }
      // OtpVerified → GoRouter redirect handles navigation automatically
    });

    final state = ref.watch(provider);
    final isLoading = state is OtpLoading;
    final isResending = state is OtpResending;
    final canResend = _secondsRemaining == 0 && !isResending;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.authOtpTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                AppStrings.authOtpSubtitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 4),
              Text(
                widget.phone.value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                enabled: !isLoading && !isResending,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: AppStrings.authOtpHint,
                  counterText: '',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
                onSubmitted: (_) => _verify(),
                onChanged: (v) {
                  if (v.length == 6) _verify();
                },
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: AppStrings.authVerify,
                isLoading: isLoading,
                onPressed: isLoading || isResending ? null : _verify,
              ),
              const SizedBox(height: 16),
              Center(
                child: _ResendButton(
                  secondsRemaining: _secondsRemaining,
                  canResend: canResend,
                  isResending: isResending,
                  onResend: () => ref
                      .read(provider.notifier)
                      .resendOtp(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verify() {
    ref.read(otpViewModelProvider(widget.phone).notifier).verifyOtp(
      _controller.text,
    );
  }
}

class _ResendButton extends StatelessWidget {
  const _ResendButton({
    required this.secondsRemaining,
    required this.canResend,
    required this.isResending,
    required this.onResend,
  });

  final int secondsRemaining;
  final bool canResend;
  final bool isResending;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    if (isResending) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (!canResend) {
      return Text(
        '${AppStrings.authResendIn} ${secondsRemaining}s',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      );
    }

    return TextButton(
      onPressed: onResend,
      child: const Text(AppStrings.authResendCode),
    );
  }
}
