import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gchess_mobile/features/auth/domain/entities/user.dart';
import 'package:gchess_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:gchess_mobile/features/auth/presentation/screens/login_screen.dart';

// ---------------------------------------------------------------------------
// Fake notifiers
// ---------------------------------------------------------------------------

/// Normal state fake — returns null immediately.
class FakeAuthNotifier extends AuthNotifier {
  @override
  Future<User?> build() async => null;
}

/// Loading state fake — future that never completes (no timer created).
class FakeLoadingAuthNotifier extends AuthNotifier {
  final _completer = Completer<User?>();

  @override
  Future<User?> build() => _completer.future;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/lobby',
        builder: (context, state) => const Scaffold(body: Text('Lobby')),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const Scaffold(body: Text('Register')),
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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('LoginScreen', () {
    testWidgets('renders username and password TextFormFields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(FakeAuthNotifier()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('renders username field with correct label',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(FakeAuthNotifier()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nom d\'utilisateur'), findsOneWidget);
    });

    testWidgets('renders password field with correct label',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(FakeAuthNotifier()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mot de passe'), findsOneWidget);
    });

    testWidgets('renders login ElevatedButton', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(FakeAuthNotifier()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows username validation error when login tapped with empty username',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(FakeAuthNotifier()),
      );
      await tester.pumpAndSettle();

      // Leave username empty, fill in a valid password
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'secret123',
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Username is required'), findsOneWidget);
    });

    testWidgets('shows password validation error when login tapped with empty password',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(FakeAuthNotifier()),
      );
      await tester.pumpAndSettle();

      // Fill in username, leave password empty
      await tester.enterText(
        find.byType(TextFormField).first,
        'validuser',
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows both validation errors when login tapped with all fields empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(FakeAuthNotifier()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Username is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when auth state is loading',
        (WidgetTester tester) async {
      // Use AsyncLoading so the fake notifier delays indefinitely
      await tester.pumpWidget(
        _buildApp(FakeLoadingAuthNotifier()),
      );
      // pump once to trigger build; do NOT pumpAndSettle (would wait for delay)
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('login button is disabled when auth state is loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(FakeLoadingAuthNotifier()),
      );
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('text fields are disabled when auth state is loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(FakeLoadingAuthNotifier()),
      );
      await tester.pump();

      final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
      for (final field in fields) {
        expect(field.enabled, isFalse);
      }
    });

    testWidgets('does not show CircularProgressIndicator in normal (non-loading) state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(FakeAuthNotifier()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows "Connexion" button text in normal state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(FakeAuthNotifier()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Connexion'), findsOneWidget);
    });

    testWidgets('register TextButton is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(FakeAuthNotifier()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextButton), findsOneWidget);
    });
  });
}
