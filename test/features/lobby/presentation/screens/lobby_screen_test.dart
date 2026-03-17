import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/auth/domain/entities/user.dart';
import 'package:gchess_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:gchess_mobile/features/lobby/presentation/screens/lobby_screen.dart';
import 'package:gchess_mobile/features/lobby/presentation/widgets/time_control_preset_button.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<User?> build() async =>
      const User(id: 'u1', username: 'Alice', email: 'alice@test.com');

  @override
  Future<void> logout() async {}
}

Widget _buildLobby() {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => _FakeAuthNotifier()),
    ],
    child: const MaterialApp(home: LobbyScreen()),
  );
}

void main() {
  group('LobbyScreen', () {
    group('en-têtes de sections', () {
      testWidgets('affiche la section Bullet', (tester) async {
        await tester.pumpWidget(_buildLobby());
        await tester.pumpAndSettle();
        expect(find.textContaining('Bullet'), findsWidgets);
      });

      testWidgets('affiche la section Blitz', (tester) async {
        await tester.pumpWidget(_buildLobby());
        await tester.pumpAndSettle();
        expect(find.textContaining('Blitz'), findsWidgets);
      });

      testWidgets('affiche la section Rapide', (tester) async {
        await tester.pumpWidget(_buildLobby());
        await tester.pumpAndSettle();
        expect(find.textContaining('Rapide'), findsWidgets);
      });

      testWidgets('affiche la section Classique', (tester) async {
        await tester.pumpWidget(_buildLobby());
        await tester.pumpAndSettle();
        expect(find.textContaining('Classique'), findsWidgets);
      });
    });

    group('boutons de contrôle de temps', () {
      testWidgets('affiche des boutons TimeControlPresetButton', (tester) async {
        await tester.pumpWidget(_buildLobby());
        await tester.pumpAndSettle();
        expect(find.byType(TimeControlPresetButton), findsWidgets);
      });

      testWidgets('affiche les presets bullet 1+0 et 2+1', (tester) async {
        await tester.pumpWidget(_buildLobby());
        await tester.pumpAndSettle();
        expect(find.text('1+0'), findsOneWidget);
        expect(find.text('2+1'), findsOneWidget);
      });

      testWidgets('affiche les presets blitz 3+0 et 5+3', (tester) async {
        await tester.pumpWidget(_buildLobby());
        await tester.pumpAndSettle();
        expect(find.text('3+0'), findsOneWidget);
        expect(find.text('5+3'), findsOneWidget);
      });

      testWidgets('affiche les presets rapide 10+0 et 15+10', (tester) async {
        await tester.pumpWidget(_buildLobby());
        await tester.pumpAndSettle();
        expect(find.text('10+0'), findsOneWidget);
        expect(find.text('15+10'), findsOneWidget);
      });

      testWidgets('affiche les presets classique 30+0 et 30+20', (tester) async {
        await tester.pumpWidget(_buildLobby());
        await tester.pumpAndSettle();
        expect(find.text('30+0'), findsOneWidget);
        expect(find.text('30+20'), findsOneWidget);
      });
    });

    group('bouton partie personnalisée', () {
      testWidgets('affiche le bouton "Partie personnalisée"', (tester) async {
        await tester.pumpWidget(_buildLobby());
        await tester.pumpAndSettle();
        expect(find.text('Partie personnalisée'), findsOneWidget);
      });

      testWidgets('taper "Partie personnalisée" ouvre le dialog Custom Game',
          (tester) async {
        await tester.pumpWidget(_buildLobby());
        await tester.pumpAndSettle();
        // S'assurer que le bouton est visible avant de tapper
        await tester.ensureVisible(find.text('Partie personnalisée'));
        await tester.tap(find.text('Partie personnalisée'));
        await tester.pumpAndSettle();
        expect(find.text('Custom Game'), findsOneWidget);
      });
    });

    group('header', () {
      testWidgets('affiche un RichText pour le logo', (tester) async {
        await tester.pumpWidget(_buildLobby());
        await tester.pumpAndSettle();
        expect(find.byType(RichText), findsWidgets);
      });

      testWidgets('affiche le bouton logout', (tester) async {
        await tester.pumpWidget(_buildLobby());
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.logout), findsOneWidget);
      });
    });
  });
}
