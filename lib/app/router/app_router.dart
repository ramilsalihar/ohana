import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/welcome/presentation/welcome_screen.dart';

/// Route paths used across the app.
abstract final class AppRoutes {
  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const home = '/home';

  /// Routes a signed-out user may see.
  static const public = {welcome, signIn};
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);

  // Re-run `redirect` whenever the user signs in or out.
  final authChanged = ValueNotifier<int>(0);
  final subscription = auth.authStateChanges().listen(
    (_) => authChanged.value++,
  );

  final router = GoRouter(
    initialLocation: AppRoutes.welcome,
    refreshListenable: authChanged,
    redirect: (context, state) {
      final signedIn = auth.currentUser != null;
      final onPublicRoute = AppRoutes.public.contains(state.matchedLocation);
      if (signedIn && onPublicRoute) return AppRoutes.home;
      if (!signedIn && !onPublicRoute) return AppRoutes.welcome;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    unawaited(subscription.cancel());
    authChanged.dispose();
    router.dispose();
  });
  return router;
});
