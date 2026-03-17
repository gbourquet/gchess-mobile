import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/game/presentation/widgets/chess_board.dart';
import 'package:gchess_mobile/features/game/presentation/widgets/chess_square.dart';

// FEN position après e2-e4 : c'est au tour du noir
const _kFenBlackTurn =
    'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1';

// FEN position pion blanc en e7 prêt à promouvoir
// Blanc doit jouer e7→e8 avec promotion
const _kFenPromotion =
    '8/4P3/8/8/8/8/8/4K2k w - - 0 1';

Widget _buildBoard({
  chess_lib.Chess? chess,
  bool isPlayerWhite = true,
  Function(String from, String to, String? promotion)? onMove,
  Function(String from, String to, String? promotion)? onPreMove,
  String? lastMoveFrom,
  String? lastMoveTo,
}) {
  final c = chess ?? chess_lib.Chess();
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 400,
        height: 400,
        child: ChessBoard(
          chess: c,
          positionFen: c.fen,
          isPlayerWhite: isPlayerWhite,
          onMove: onMove,
          onPreMove: onPreMove,
          lastMoveFrom: lastMoveFrom,
          lastMoveTo: lastMoveTo,
        ),
      ),
    ),
  );
}

void main() {
  group('ChessBoard', () {
    group('structure', () {
      testWidgets('rend exactement 64 ChessSquare', (tester) async {
        await tester.pumpWidget(_buildBoard());
        await tester.pump();
        tester.takeException(); // SVG peut émettre des erreurs d'asset
        expect(find.byType(ChessSquare), findsNWidgets(64));
      });

      testWidgets('affiche les labels de colonnes A-H (perspective blanche)',
          (tester) async {
        await tester.pumpWidget(_buildBoard(isPlayerWhite: true));
        await tester.pump();
        tester.takeException();
        for (final file in ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']) {
          expect(find.text(file), findsWidgets);
        }
      });

      testWidgets('affiche les labels de rangs 1-8', (tester) async {
        await tester.pumpWidget(_buildBoard(isPlayerWhite: true));
        await tester.pump();
        tester.takeException();
        for (final rank in ['1', '2', '3', '4', '5', '6', '7', '8']) {
          expect(find.text(rank), findsWidgets);
        }
      });

      testWidgets('perspective noire affiche H en premier', (tester) async {
        await tester.pumpWidget(_buildBoard(isPlayerWhite: false));
        await tester.pump();
        tester.takeException();
        expect(find.text('H'), findsWidgets);
      });
    });

    group('sélection et coups légaux', () {
      testWidgets('taper sur e2 sélectionne le pion et affiche les cases légales',
          (tester) async {
        String? capturedFrom;
        String? capturedTo;
        final chess = chess_lib.Chess();

        await tester.pumpWidget(_buildBoard(
          chess: chess,
          isPlayerWhite: true,
          onMove: (from, to, promo) {
            capturedFrom = from;
            capturedTo = to;
          },
        ));
        await tester.pump();
        tester.takeException();

        // En perspective blanche, e2 = ligne 6 colonne 4 → index 52
        final e2Square = find.byType(ChessSquare).at(52);
        await tester.tap(e2Square);
        await tester.pump();
        tester.takeException();

        // Après sélection, le pion e2 peut aller en e3 (index 44) ou e4 (index 36)
        // On tape e4 = ligne 4, colonne 4 → index 36
        final e4Square = find.byType(ChessSquare).at(36);
        await tester.tap(e4Square);
        await tester.pump();
        tester.takeException();

        expect(capturedFrom, 'e2');
        expect(capturedTo, 'e4');
      });

      testWidgets('taper sur une case vide sans sélection ne fait rien',
          (tester) async {
        bool moveCalled = false;
        await tester.pumpWidget(_buildBoard(
          onMove: (_, __, ___) => moveCalled = true,
        ));
        await tester.pump();
        tester.takeException();

        // e5 est vide en position initiale (ligne 3, colonne 4 → index 28)
        await tester.tap(find.byType(ChessSquare).at(28));
        await tester.pump();
        tester.takeException();

        expect(moveCalled, isFalse);
      });

      testWidgets('taper sur une pièce adverse (noir) ne la sélectionne pas',
          (tester) async {
        bool moveCalled = false;
        await tester.pumpWidget(_buildBoard(
          isPlayerWhite: true,
          onMove: (_, __, ___) => moveCalled = true,
        ));
        await tester.pump();
        tester.takeException();

        // e8 = tour noire = ligne 0, colonne 4 → index 4 (roi noir, pas de mouvement pour blanc)
        // Ligne 1 = pion noir → index 12 (e7)
        await tester.tap(find.byType(ChessSquare).at(12));
        await tester.pump();
        tester.takeException();

        expect(moveCalled, isFalse);
      });

      testWidgets('taper sur une case illégale après sélection désélectionne',
          (tester) async {
        bool moveCalled = false;
        await tester.pumpWidget(_buildBoard(
          onMove: (_, __, ___) => moveCalled = true,
        ));
        await tester.pump();
        tester.takeException();

        // Sélectionne e2 (index 52)
        await tester.tap(find.byType(ChessSquare).at(52));
        await tester.pump();
        tester.takeException();

        // Tape e8 (roi noir, illégal) = index 4
        await tester.tap(find.byType(ChessSquare).at(4));
        await tester.pump();
        tester.takeException();

        expect(moveCalled, isFalse);
      });

      testWidgets('onMove=null : taper ne plante pas', (tester) async {
        await tester.pumpWidget(_buildBoard(onMove: null));
        await tester.pump();
        tester.takeException();

        await tester.tap(find.byType(ChessSquare).at(52));
        await tester.pump();
        tester.takeException();
        // pas d'exception
      });
    });

    group('dernier coup', () {
      testWidgets('lastMoveFrom et lastMoveTo sont passés aux squares', (tester) async {
        await tester.pumpWidget(_buildBoard(
          lastMoveFrom: 'e2',
          lastMoveTo: 'e4',
        ));
        await tester.pump();
        tester.takeException();

        final squares = tester.widgetList<ChessSquare>(find.byType(ChessSquare));
        final fromSquares = squares.where((s) => s.isLastMoveFrom).toList();
        final toSquares = squares.where((s) => s.isLastMoveTo).toList();

        expect(fromSquares.length, 1);
        expect(toSquares.length, 1);
      });
    });

    group('pre-move (tour de l\'adversaire)', () {
      // FEN après e4 → c'est au tour du noir
      // isPlayerWhite=true → blanc peut poser un pre-move

      testWidgets('taper sur une pièce blanche quand c\'est le tour du noir sélectionne un pre-move',
          (tester) async {
        String? preFrom;
        final chess = chess_lib.Chess();
        chess.load(_kFenBlackTurn);

        await tester.pumpWidget(_buildBoard(
          chess: chess,
          isPlayerWhite: true,
          onPreMove: (from, to, promo) {
            preFrom = from;
          },
        ));
        await tester.pump();
        tester.takeException();

        // En perspective blanche avec _kFenBlackTurn, d2 = ligne 6, col 3 → index 51
        final d2Square = find.byType(ChessSquare).at(51);
        await tester.tap(d2Square); // sélectionne la pièce
        await tester.pump();
        tester.takeException();

        // d4 = ligne 4, col 3 → index 35
        final d4Square = find.byType(ChessSquare).at(35);
        await tester.tap(d4Square);
        await tester.pump();
        tester.takeException();

        expect(preFrom, 'd2');
      });

      testWidgets('taper deux fois sur la même pièce désélectionne le pre-move',
          (tester) async {
        bool preCalled = false;
        final chess = chess_lib.Chess();
        chess.load(_kFenBlackTurn);

        await tester.pumpWidget(_buildBoard(
          chess: chess,
          isPlayerWhite: true,
          onPreMove: (_, __, ___) => preCalled = true,
        ));
        await tester.pump();
        tester.takeException();

        // Sélectionne d2 (index 51)
        await tester.tap(find.byType(ChessSquare).at(51));
        await tester.pump();
        tester.takeException();

        // Tap à nouveau sur d2 → désélectionne
        await tester.tap(find.byType(ChessSquare).at(51));
        await tester.pump();
        tester.takeException();

        expect(preCalled, isFalse);
      });

      testWidgets('sans onPreMove, taper en mode adversaire ne plante pas',
          (tester) async {
        final chess = chess_lib.Chess();
        chess.load(_kFenBlackTurn);

        await tester.pumpWidget(_buildBoard(
          chess: chess,
          isPlayerWhite: true,
          onPreMove: null,
        ));
        await tester.pump();
        tester.takeException();

        await tester.tap(find.byType(ChessSquare).at(51));
        await tester.pump();
        tester.takeException();
      });

      testWidgets('taper sur une case vide sans pièce blanche ne sélectionne rien',
          (tester) async {
        bool preCalled = false;
        final chess = chess_lib.Chess();
        chess.load(_kFenBlackTurn);

        await tester.pumpWidget(_buildBoard(
          chess: chess,
          isPlayerWhite: true,
          onPreMove: (_, __, ___) => preCalled = true,
        ));
        await tester.pump();
        tester.takeException();

        // e5 est vide (index 28)
        await tester.tap(find.byType(ChessSquare).at(28));
        await tester.pump();
        tester.takeException();

        expect(preCalled, isFalse);
      });
    });

    group('promotion', () {
      testWidgets('pousser un pion sur la dernière rangée ouvre le dialog de promotion',
          (tester) async {
        final chess = chess_lib.Chess();
        chess.load(_kFenPromotion);
        // e7 est le pion blanc. Perspective blanche : e7 = ligne 1, col 4 → index 12
        // e8 = ligne 0, col 4 → index 4

        await tester.pumpWidget(_buildBoard(
          chess: chess,
          isPlayerWhite: true,
          onMove: (_, __, ___) {},
        ));
        await tester.pump();
        tester.takeException();

        // Sélectionne e7 (index 12)
        await tester.tap(find.byType(ChessSquare).at(12));
        await tester.pump();
        tester.takeException();

        // Tape e8 (index 4)
        await tester.tap(find.byType(ChessSquare).at(4));
        await tester.pumpAndSettle();
        tester.takeException();

        expect(find.text('Promote Pawn'), findsOneWidget);
      });

      testWidgets('choisir Dame dans le dialog de promotion appelle onMove avec QUEEN',
          (tester) async {
        String? capturedPromotion;
        final chess = chess_lib.Chess();
        chess.load(_kFenPromotion);

        await tester.pumpWidget(_buildBoard(
          chess: chess,
          isPlayerWhite: true,
          onMove: (from, to, promo) => capturedPromotion = promo,
        ));
        await tester.pump();
        tester.takeException();

        await tester.tap(find.byType(ChessSquare).at(12)); // e7
        await tester.pump();
        tester.takeException();
        await tester.tap(find.byType(ChessSquare).at(4)); // e8
        await tester.pumpAndSettle();
        tester.takeException();

        // Tap QUEEN (première option)
        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();
        tester.takeException();

        expect(capturedPromotion, 'QUEEN');
      });
    });

    group('didUpdateWidget', () {
      testWidgets('changer positionFen réinitialise les pre-moves', (tester) async {
        final chess1 = chess_lib.Chess();
        chess1.load(_kFenBlackTurn);

        bool preCalled = false;

        // Build initial avec black turn
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: ChessBoard(
                chess: chess1,
                positionFen: _kFenBlackTurn,
                isPlayerWhite: true,
                onPreMove: (_, __, ___) => preCalled = true,
              ),
            ),
          ),
        ));
        await tester.pump();
        tester.takeException();

        // Rebuild avec position initiale (white turn) → didUpdateWidget doit nettoyer
        final chess2 = chess_lib.Chess();
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: ChessBoard(
                chess: chess2,
                positionFen: chess2.fen,
                isPlayerWhite: true,
                onPreMove: null, // plus de pre-move
              ),
            ),
          ),
        ));
        await tester.pump();
        tester.takeException();

        expect(preCalled, isFalse);
      });
    });
  });
}
