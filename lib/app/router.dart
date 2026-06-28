import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../features/auth/domain/entities/auth_session.dart';
import '../features/auth/domain/value_objects/phone_number.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/magic_link_sent_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart';
import '../features/auth/presentation/screens/setup_profile_screen.dart';
import '../features/auth/providers.dart';
import '../features/pairing/domain/entities/pair.dart';
import '../features/pairing/presentation/screens/enter_invite_screen.dart';
import '../features/pairing/presentation/screens/generate_invite_screen.dart';
import '../features/pairing/presentation/screens/pair_screen.dart';
import '../features/pairing/providers.dart';
import 'splash_screen.dart';

// Notifies GoRouter whenever auth OR pair state changes so redirect re-evaluates.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    _authSub = ref.listen<AsyncValue<AppAuthState>>(
      authStateProvider,
      (prev, next) => notifyListeners(),
    );
    _pairSub = ref.listen<AsyncValue<Pair?>>(
      pairStatusProvider,
      (prev, next) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AsyncValue<AppAuthState>> _authSub;
  late final ProviderSubscription<AsyncValue<Pair?>> _pairSub;

  @override
  void dispose() {
    _authSub.close();
    _pairSub.close();
    super.dispose();
  }
}

// Routes added per milestone:
// M1: login, otp, magic-link, setup-profile
// M3: pair, generate-invite, enter-invite      ← current
// M4: chat
// M6: image-viewer
// M8: my-profile, partner-profile
// M9: app-lock
// M10: settings/*
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authValue = ref.read(authStateProvider);
      final authState = authValue.valueOrNull ?? AppAuthState.unknown;
      final location = state.matchedLocation;

      if (authState == AppAuthState.unknown) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (authState == AppAuthState.unauthenticated) {
        final isAuthRoute = location == AppRoutes.login ||
            location == AppRoutes.otpVerification ||
            location == AppRoutes.magicLinkSent;
        return isAuthRoute ? null : AppRoutes.login;
      }

      if (authState == AppAuthState.registering) {
        return location == AppRoutes.setupProfile ? null : AppRoutes.setupProfile;
      }

      if (authState == AppAuthState.authenticated) {
        final pairValue = ref.read(pairStatusProvider);

        // Pair status not yet resolved — hold on splash while loading.
        if (!pairValue.hasValue) {
          return location == AppRoutes.splash ? null : AppRoutes.splash;
        }

        final pair = pairValue.requireValue;

        if (pair == null) {
          // Unpaired: only allow pairing screens.
          final isPairRoute = location == AppRoutes.pair ||
              location == AppRoutes.generateInvite ||
              location == AppRoutes.enterInvite;
          return isPairRoute ? null : AppRoutes.pair;
        }

        // Paired: block onboarding/pairing screens, send to chat.
        final isOnboardingOrPairRoute = location == AppRoutes.splash ||
            location == AppRoutes.login ||
            location == AppRoutes.otpVerification ||
            location == AppRoutes.magicLinkSent ||
            location == AppRoutes.setupProfile ||
            location == AppRoutes.pair ||
            location == AppRoutes.generateInvite ||
            location == AppRoutes.enterInvite;
        return isOnboardingOrPairRoute ? AppRoutes.chat : null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, state) => const SplashScreen(),
      ),

      // ── Auth routes (M1) ───────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (_, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otpVerification,
        builder: (_, state) {
          final phone = state.extra! as PhoneNumber;
          return OtpVerificationScreen(phone: phone);
        },
      ),
      GoRoute(
        path: AppRoutes.magicLinkSent,
        builder: (_, state) => const MagicLinkSentScreen(),
      ),
      GoRoute(
        path: AppRoutes.setupProfile,
        builder: (_, state) => const SetupProfileScreen(),
      ),

      // ── Pairing routes (M3) ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.pair,
        builder: (_, state) => const PairScreen(),
      ),
      GoRoute(
        path: AppRoutes.generateInvite,
        builder: (_, state) => const GenerateInviteScreen(),
      ),
      GoRoute(
        path: AppRoutes.enterInvite,
        builder: (_, state) => const EnterInviteScreen(),
      ),

      // ── Milestone placeholder (replaced in M4) ─────────────────────────────
      GoRoute(
        path: AppRoutes.chat,
        builder: (_, state) => const _MilestonePlaceholder(
          title: 'Chat',
          milestone: 'M4',
        ),
      ),
    ],
  );
});

class _MilestonePlaceholder extends StatelessWidget {
  const _MilestonePlaceholder({
    required this.title,
    required this.milestone,
  });

  final String title;
  final String milestone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '$title — Coming in $milestone',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
