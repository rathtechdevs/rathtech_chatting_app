import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../viewmodels/login_state.dart';
import '../viewmodels/login_view_model.dart';
import '../widgets/email_input_tab.dart';
import '../widgets/phone_input_tab.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<LoginState>(loginViewModelProvider, (previous, next) {
      if (next is LoginOtpSent) {
        ref.read(loginViewModelProvider.notifier).reset();
        context.push(AppRoutes.otpVerification, extra: next.phone);
      } else if (next is LoginMagicLinkSent) {
        ref.read(loginViewModelProvider.notifier).reset();
        context.push(AppRoutes.magicLinkSent);
      } else if (next is LoginError) {
        context.showSnackBar(next.message, isError: true);
      }
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              _Header(),
              const SizedBox(height: 32),
              const TabBar(
                tabs: [
                  Tab(text: AppStrings.authTabPhone),
                  Tab(text: AppStrings.authTabEmail),
                ],
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    SingleChildScrollView(child: PhoneInputTab()),
                    SingleChildScrollView(child: EmailInputTab()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_rounded,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.authWelcome,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.authSubtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
