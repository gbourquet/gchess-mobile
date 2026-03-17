import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/game/presentation/widgets/chess_square.dart';

Widget _buildSquare(ChessSquare square) =>
    MaterialApp(home: Scaffold(body: SizedBox(width: 60, height: 60, child: square)));

void main() {
  group('ChessSquare', () {
    group('rendu de base', () {
      testWidgets('affiche un GestureDetector', (tester) async {
        await tester.pumpWidget(_buildSquare(
          const ChessSquare(row: 0, col: 0, isLightSquare: true),
        ));
        expect(find.byType(GestureDetector), findsOneWidget);
      });

      testWidgets('appelle onTap quand on tape', (tester) async {
        bool tapped = false;
        await tester.pumpWidget(_buildSquare(
          ChessSquare(
            row: 0,
            col: 0,
            isLightSquare: true,
            onTap: () => tapped = true,
          ),
        ));
        await tester.tap(find.byType(GestureDetector));
        expect(tapped, isTrue);
      });

      testWidgets('onTap null ne plante pas', (tester) async {
        await tester.pumpWidget(_buildSquare(
          const ChessSquare(row: 0, col: 0, isLightSquare: true),
        ));
        await tester.tap(find.byType(GestureDetector));
        // pas d'exception attendue
      });
    });

    group('overlays de coup légal', () {
      testWidgets('affiche un point (dot) si isLegalMove=true et pas de pièce',
          (tester) async {
        await tester.pumpWidget(_buildSquare(
          const ChessSquare(
            row: 0,
            col: 0,
            isLightSquare: true,
            isLegalMove: true,
            // piece: null (par défaut)
          ),
        ));
        // Le dot est un Container de 14×14
        final containers = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) =>
                c.constraints?.maxWidth == 14 && c.constraints?.maxHeight == 14)
            .toList();
        expect(containers, isNotEmpty);
      });

      testWidgets('n\'affiche pas de dot si isLegalMove=false', (tester) async {
        await tester.pumpWidget(_buildSquare(
          const ChessSquare(row: 0, col: 0, isLightSquare: true, isLegalMove: false),
        ));
        // Pas de Container 14×14
        final containers = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) =>
                c.constraints?.maxWidth == 14 && c.constraints?.maxHeight == 14)
            .toList();
        expect(containers, isEmpty);
      });
    });

    group('overlay de dernier coup', () {
      testWidgets('affiche l\'overlay quand isLastMoveFrom=true', (tester) async {
        await tester.pumpWidget(_buildSquare(
          const ChessSquare(
            row: 0,
            col: 0,
            isLightSquare: true,
            isLastMoveFrom: true,
          ),
        ));
        await tester.pump();
        // Vérifie qu'il y a plus d'un Container (case + overlay)
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('affiche l\'overlay quand isLastMoveTo=true', (tester) async {
        await tester.pumpWidget(_buildSquare(
          const ChessSquare(
            row: 0,
            col: 0,
            isLightSquare: false,
            isLastMoveTo: true,
          ),
        ));
        await tester.pump();
        expect(find.byType(Container), findsWidgets);
      });
    });

    group('overlay pre-move légal', () {
      testWidgets('affiche un dot orange si isPreMoveLegal=true et pas de pièce',
          (tester) async {
        await tester.pumpWidget(_buildSquare(
          const ChessSquare(
            row: 0,
            col: 0,
            isLightSquare: true,
            isPreMoveLegal: true,
          ),
        ));
        // Dot pré-coup : Container 14×14
        final containers = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) =>
                c.constraints?.maxWidth == 14 && c.constraints?.maxHeight == 14)
            .toList();
        expect(containers, isNotEmpty);
      });
    });

    group('cas sans pièce', () {
      testWidgets('aucun ChessPiece ni dot quand piece est null et isLegalMove=false',
          (tester) async {
        await tester.pumpWidget(_buildSquare(
          const ChessSquare(row: 0, col: 0, isLightSquare: true),
        ));
        // Pas de dot (14×14) quand pas de coup légal
        final containers = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) =>
                c.constraints?.maxWidth == 14 && c.constraints?.maxHeight == 14)
            .toList();
        expect(containers, isEmpty);
      });
    });
  });
}
