import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/lobby/presentation/widgets/custom_game_dialog.dart';

Widget _buildDialog({required Function(int, int) onStartGame}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => CustomGameDialog(onStartGame: onStartGame),
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  );
}

Future<void> _openDialog(WidgetTester tester, {required Function(int, int) onStart}) async {
  await tester.pumpWidget(_buildDialog(onStartGame: onStart));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  group('CustomGameDialog', () {
    group('rendu initial', () {
      testWidgets('affiche le titre "Custom Game"', (tester) async {
        await _openDialog(tester, onStart: (_, __) {});
        expect(find.text('Custom Game'), findsOneWidget);
      });

      testWidgets('affiche les champs Time et Increment', (tester) async {
        await _openDialog(tester, onStart: (_, __) {});
        expect(find.text('Time (minutes)'), findsOneWidget);
        expect(find.text('Increment (seconds)'), findsOneWidget);
      });

      testWidgets('valeurs par défaut : 10 et 0', (tester) async {
        await _openDialog(tester, onStart: (_, __) {});
        // Les deux champs ont des valeurs initiales
        expect(find.text('10'), findsWidgets);
        expect(find.text('0'), findsWidgets);
      });

      testWidgets('affiche les boutons Cancel et Start Game', (tester) async {
        await _openDialog(tester, onStart: (_, __) {});
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Start Game'), findsOneWidget);
      });
    });

    group('validation', () {
      testWidgets('champ Time vide → erreur "Please enter time"', (tester) async {
        await _openDialog(tester, onStart: (_, __) {});
        await tester.enterText(find.byType(TextFormField).first, '');
        await tester.tap(find.text('Start Game'));
        await tester.pumpAndSettle();
        expect(find.text('Please enter time'), findsOneWidget);
      });

      testWidgets('champ Time = 0 → erreur "Must be at least 1 minute"', (tester) async {
        await _openDialog(tester, onStart: (_, __) {});
        await tester.enterText(find.byType(TextFormField).first, '0');
        await tester.tap(find.text('Start Game'));
        await tester.pumpAndSettle();
        expect(find.text('Must be at least 1 minute'), findsOneWidget);
      });

      testWidgets('champ Time non numérique → erreur "Invalid number"', (tester) async {
        await _openDialog(tester, onStart: (_, __) {});
        await tester.enterText(find.byType(TextFormField).first, 'abc');
        await tester.tap(find.text('Start Game'));
        await tester.pumpAndSettle();
        expect(find.text('Invalid number'), findsOneWidget);
      });

      testWidgets('champ Increment vide → erreur "Please enter increment"', (tester) async {
        await _openDialog(tester, onStart: (_, __) {});
        await tester.enterText(find.byType(TextFormField).last, '');
        await tester.tap(find.text('Start Game'));
        await tester.pumpAndSettle();
        expect(find.text('Please enter increment'), findsOneWidget);
      });

      testWidgets('champ Increment non numérique → erreur "Invalid number"', (tester) async {
        await _openDialog(tester, onStart: (_, __) {});
        await tester.enterText(find.byType(TextFormField).last, 'xyz');
        await tester.tap(find.text('Start Game'));
        await tester.pumpAndSettle();
        expect(find.text('Invalid number'), findsOneWidget);
      });
    });

    group('soumission valide', () {
      testWidgets('appelle onStartGame avec les valeurs saisies', (tester) async {
        int? receivedTime;
        int? receivedIncrement;

        await _openDialog(tester, onStart: (t, i) {
          receivedTime = t;
          receivedIncrement = i;
        });

        await tester.enterText(find.byType(TextFormField).first, '5');
        await tester.enterText(find.byType(TextFormField).last, '3');
        await tester.tap(find.text('Start Game'));
        await tester.pumpAndSettle();

        expect(receivedTime, 5);
        expect(receivedIncrement, 3);
      });

      testWidgets('ferme le dialog après soumission valide', (tester) async {
        await _openDialog(tester, onStart: (_, __) {});
        await tester.enterText(find.byType(TextFormField).first, '10');
        await tester.enterText(find.byType(TextFormField).last, '0');
        await tester.tap(find.text('Start Game'));
        await tester.pumpAndSettle();
        expect(find.text('Custom Game'), findsNothing);
      });
    });

    group('annulation', () {
      testWidgets('le bouton Cancel ferme le dialog', (tester) async {
        await _openDialog(tester, onStart: (_, __) {});
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Custom Game'), findsNothing);
      });

      testWidgets('Cancel ne déclenche pas onStartGame', (tester) async {
        bool called = false;
        await _openDialog(tester, onStart: (_, __) => called = true);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(called, isFalse);
      });
    });
  });
}
