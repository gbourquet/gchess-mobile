import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gchess_mobile/features/auth/presentation/providers/auth_provider.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String lobby = '/lobby';
  static const String matchmaking = '/matchmaking';
  static const String game = '/game';
  static const String history = '/history';

  static String gameWithId(String gameId, String playerId) =>
      '/game/$gameId/$playerId';
}

// Splash screen — navigue dès que l'état auth est résolu
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authNotifierProvider, (_, next) {
      if (next.isLoading) return;
      if (next.value != null) {
        context.go(AppRoutes.lobby);
      } else {
        context.go(AppRoutes.login);
      }
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
