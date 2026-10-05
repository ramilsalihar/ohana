import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/couple/presentation/couple_providers.dart';
import '../../features/couple/presentation/create_couple_screen.dart';
import '../../features/couple/presentation/join_couple_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/welcome/presentation/welcome_screen.dart';

/// Route paths used across the app.
abstract final class AppRoutes {
  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const home = '/home';
  static const createCouple = '/couple/create';
  static const join = '/join';

  /// Join screen with the code from an invite link filled in.
  static String joinWithCode(String code) => '$join/$code';

  /// Routes a signed-out user may see.
  static const public = {welcome, signIn};
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final pendingInvite = ref.watch(pendingInviteProvider);

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

      if (!signedIn) {
        // An invite link opened while signed out: remember the code and
        // come back to it after sign-in.
        final segments = state.uri.pathSegments;
        if (segments.length == 2 && '/${segments.first}' == AppRoutes.join) {
          pendingInvite.code = segments.last;
        }
        return onPublicRoute ? null : AppRoutes.welcome;
      }

      if (onPublicRoute) {
        final code = pendingInvite.take();
        return code == null ? AppRoutes.home : AppRoutes.joinWithCode(code);
      }
      return null;
    },
    // Links the router has no route for (such as the sign-in callback, which
    // the auth SDK handles itself) fall back to the start; `redirect` then
    // sends signed-in users on to home.
    onException: (context, state, router) => router.go(AppRoutes.welcome),
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
      GoRoute(
        path: AppRoutes.createCouple,
        builder: (context, state) => const CreateCoupleScreen(),
      ),
      GoRoute(
        path: AppRoutes.join,
        builder: (context, state) => const JoinCoupleScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.join}/:code',
        builder: (context, state) =>
            JoinCoupleScreen(initialCode: state.pathParameters['code']),
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
