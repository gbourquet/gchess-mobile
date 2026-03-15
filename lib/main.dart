import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/app_config.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'core/debug/debug_overlay.dart';
import 'core/injection.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure environment
  AppConfig.setEnvironment(
    kDebugMode ? Environment.development : Environment.production,
  );

  // Initialize dependency injection
  await configureDependencies();

  runApp(const GChessApp());
}

class GChessApp extends StatelessWidget {
  const GChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>()..add(const AuthCheckRequested()),
      child: Builder(
        builder: (context) {
          AppRouter.init(context.read<AuthBloc>());
          return MaterialApp.router(
            title: 'gChess',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            routerConfig: AppRouter.router,
            builder: (context, child) => DebugOverlay(child: child!),
          );
        },
      ),
    );
  }
}
