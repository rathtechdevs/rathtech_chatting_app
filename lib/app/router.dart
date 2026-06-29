import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../features/app_lock/presentation/screens/setup_pin_screen.dart';
import '../features/auth/domain/entities/auth_session.dart';
import '../features/auth/domain/value_objects/phone_number.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/magic_link_sent_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart';
import '../features/auth/presentation/screens/setup_profile_screen.dart';
import '../features/auth/providers.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/chat/presentation/screens/image_viewer_screen.dart';
import '../features/pairing/domain/entities/pair.dart';
import '../features/pairing/presentation/screens/enter_invite_screen.dart';
import '../features/pairing/presentation/screens/generate_invite_screen.dart';
import '../features/pairing/presentation/screens/pair_screen.dart';
import '../features/pairing/providers.dart';
import '../features/profile/presentation/screens/partner_profile_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/settings/presentation/screens/account_settings_screen.dart';
import '../features/settings/presentation/screens/chat_settings_screen.dart';
import '../features/settings/presentation/screens/notification_settings_screen.dart';
import '../features/settings/presentation/screens/privacy_settings_screen.dart';
import '../features/settings/presentation/screens/security_settings_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
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
// M3: pair, generate-invite, enter-invite
// M4: chat
// M6: image-viewer
// M8: my-profile, partner-profile
// M9: setup-pin (lock shown as overlay in app.dart)
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

      // ── Chat (M4) ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.chat,
        builder: (_, state) => const ChatScreen(),
      ),

      // ── Image viewer (M6) ──────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.imageViewer,
        builder: (_, state) {
          final extra =
              state.extra! as ({String localPath, String heroTag});
          return ImageViewerScreen(
            localPath: extra.localPath,
            heroTag: extra.heroTag,
          );
        },
      ),

      // ── Profile (M8) ───────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.myProfile,
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.partnerProfile,
        builder: (_, state) {
          final partnerId = state.extra! as String;
          return PartnerProfileScreen(partnerId: partnerId);
        },
      ),

      // ── App lock (M9) ──────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.appLock,
        builder: (_, _) => const SetupPinScreen(),
      ),

      // ── Settings (M10) ─────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        builder: (_, _) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacySettings,
        builder: (_, _) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.securitySettings,
        builder: (_, _) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.chatSettings,
        builder: (_, _) => const ChatSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountSettings,
        builder: (_, _) => const AccountSettingsScreen(),
      ),
    ],
  );
});
