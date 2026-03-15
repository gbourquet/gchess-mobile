import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gchess_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gchess_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:gchess_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:gchess_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:gchess_mobile/features/lobby/presentation/screens/lobby_screen.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_request.dart';
import 'package:gchess_mobile/features/matchmaking/presentation/screens/matchmaking_queue_screen.dart';
import 'package:gchess_mobile/features/game/presentation/screens/game_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String lobby = '/lobby';
  static const String matchmaking = '/matchmaking';
  static const String game = '/game';

  static String gameWithId(String gameId, String playerId) =>
      '/game/$gameId/$playerId';
}

class AppRouter {
  static late final AuthBloc _authBloc;
  static final navigatorKey = GlobalKey<NavigatorState>();

  static void init(AuthBloc bloc) {
    _authBloc = bloc;
  }

  static GoRouter get router => GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(_authBloc.stream),
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
      final authState = _authBloc.state;
      final isLoggedIn = authState is AuthAuthenticated;
      final isLoggingIn = authState is AuthLoading;

      final isOnSplash = state.matchedLocation == AppRoutes.splash;
      final isOnLogin =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      final isOnProtectedRoute =
          state.matchedLocation == AppRoutes.lobby ||
          state.matchedLocation.startsWith(AppRoutes.matchmaking) ||
          state.matchedLocation.startsWith(AppRoutes.game);

      if (isLoggingIn || isOnSplash) return null;

      if (isLoggedIn && isOnLogin) {
        return AppRoutes.lobby;
      }

      if (!isLoggedIn && isOnProtectedRoute) {
        return AppRoutes.login;
      }

      return null;
    },
  );
}

// Splash screen with auth check
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.lobby);
        } else if (state is AuthUnauthenticated) {
          context.go(AppRoutes.login);
        }
      },
      child: const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
