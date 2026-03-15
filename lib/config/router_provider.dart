import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gchess_mobile/config/routes.dart';
import 'package:gchess_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:gchess_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:gchess_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:gchess_mobile/features/lobby/presentation/screens/lobby_screen.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_request.dart';
import 'package:gchess_mobile/features/matchmaking/presentation/screens/matchmaking_queue_screen.dart';
import 'package:gchess_mobile/features/game/presentation/screens/game_screen.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

// keepAlive — vit toute la session
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthBridge();
  ref.listen(authNotifierProvider, (_, __) => notifier.notify());
  ref.onDispose(notifier.dispose);

  return GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.lobby,
        builder: (context, state) => const LobbyScreen(),
      ),
      GoRoute(
        path: AppRoutes.matchmaking,
        builder: (context, state) {
          final request = state.extra as MatchRequest?;
          if (request == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid matchmaking request')),
            );
          }
          return MatchmakingQueueScreen(request: request);
        },
      ),
      GoRoute(
        path: '${AppRoutes.game}/:gameId/:playerId',
        builder: (context, state) {
          final gameId = state.pathParameters['gameId']!;
          final playerId = state.pathParameters['playerId']!;
          return GameScreen(gameId: gameId, playerId: playerId);
        },
      ),
    ],
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);
      final isLoggedIn = auth.value != null;
      final isLoading = auth.isLoading;

      final isOnSplash = state.matchedLocation == AppRoutes.splash;
      final isOnLogin =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      final isOnProtectedRoute =
          state.matchedLocation == AppRoutes.lobby ||
          state.matchedLocation.startsWith(AppRoutes.matchmaking) ||
          state.matchedLocation.startsWith(AppRoutes.game);

      if (isLoading || isOnSplash) return null;

      if (isLoggedIn && isOnLogin) return AppRoutes.lobby;

      if (!isLoggedIn && isOnProtectedRoute) return AppRoutes.login;

      return null;
    },
  );
});

class _AuthBridge extends ChangeNotifier {
  void notify() => notifyListeners();
}
