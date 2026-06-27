import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import 'splash_screen.dart';

// Routes are added incrementally with each milestone:
// M1 adds: login, otp, magic-link, setup-profile
// M3 adds: pair, generate-invite, enter-invite
// M4 adds: chat
// M6 adds: image-viewer
// M8 adds: my-profile, partner-profile
// M9 adds: app-lock
// M10 adds: settings/*
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
    ],
  );
});
