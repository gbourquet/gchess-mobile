import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gchess_mobile/features/auth/domain/entities/user.dart';
import 'package:gchess_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:gchess_mobile/features/auth/presentation/screens/register_screen.dart';

class FakeAuthNotifier extends AuthNotifier {
  @override
  Future<User?> build() async => null;
}

class FakeLoadingAuthNotifier extends AuthNotifier {
  final _completer = Completer<User?>();

  @override
  Future<User?> build() => _completer.future;
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/register',
    routes: [
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/lobby',
        builder: (context, state) => const Scaffold(body: Text('Lobby')),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(body: Text('Login')),
      ),
    ],
  );
}

Widget _buildApp(AuthNotifier notifier) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => notifier),
    ],
    child: MaterialApp.router(routerConfig: _buildRouter()),
  );
}

void main() {
  group('RegisterScreen', () {
    testWidgets('renders 4 TextFormFields', (WidgetTester tester) async {
      await tester.pumpWidget(_buildApp(FakeAuthNotifier()));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(4));
    });

    testWidgets('renders register ElevatedButton', (WidgetTester tester) async {
      await tester.pumpWidget(_buildApp(FakeAuthNotifier()));
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('renders login TextButton', (WidgetTester tester) async {
      await tester.pumpWidget(_buildApp(FakeAuthNotifier()));
      await tester.pumpAndSettle();

      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('shows validation errors when register tapped with empty fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildApp(FakeAuthNotifier()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Username is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildApp(FakeLoadingAuthNotifier()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('button is disabled when loading', (WidgetTester tester) async {
      await tester.pumpWidget(_buildApp(FakeLoadingAuthNotifier()));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('does not show CircularProgressIndicator in normal state',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildApp(FakeAuthNotifier()));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows email validation error for invalid email',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildApp(FakeAuthNotifier()));
      await tester.pumpAndSettle();

      // Enter valid username but invalid email
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'validuser',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'notanemail',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'password123',
      );
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'password123',
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });
  });
}
