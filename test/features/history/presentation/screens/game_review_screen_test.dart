import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/game/presentation/widgets/chess_board.dart';
import 'package:gchess_mobile/features/game/presentation/widgets/move_history_panel.dart';
import 'package:gchess_mobile/features/history/domain/entities/game_record.dart';
import 'package:gchess_mobile/features/history/presentation/screens/game_review_screen.dart';

// FEN après 1.e4 e5
const _kFenAfterE5 =
    'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2';

GameRecord _makeRecord({
  bool withMoves = true,
  bool playerIsWhite = true,
  String result = 'CHECKMATE',
  String? winner = 'player-white',
  int? totalTimeSeconds = 300,
  int? incrementSeconds = 0,
}) {
  return GameRecord.fromGame(
    gameId: 'game-review',
    playerId: playerIsWhite ? 'player-white' : 'player-black',
    whiteUsername: 'Alice',
    blackUsername: 'Bob',
    whitePlayerId: 'player-white',
    blackPlayerId: 'player-black',
    result: result,
    winner: winner,
    uciHistory: withMoves ? const ['e2-e4', 'e7-e5'] : const [],
    finalFen: _kFenAfterE5,
    totalTimeSeconds: totalTimeSeconds,
    incrementSeconds: incrementSeconds,
    playedAt: DateTime.utc(2026, 3, 17),
  );
}

Widget _buildScreen(GameRecord record) {
  return MaterialApp(home: GameReviewScreen(record: record));
}

void main() {
  group('GameReviewScreen', () {
    group('affichage initial', () {
      testWidgets('affiche un ChessBoard', (tester) async {
        await tester.pumpWidget(_buildScreen(_makeRecord()));
        await tester.pump();
        expect(find.byType(ChessBoard), findsOneWidget);
      });

      testWidgets('affiche un MoveHistoryPanel', (tester) async {
        await tester.pumpWidget(_buildScreen(_makeRecord()));
        await tester.pump();
        expect(find.byType(MoveHistoryPanel), findsOneWidget);
      });

      testWidgets('affiche les deux usernames dans les infos', (tester) async {
        await tester.pumpWidget(_buildScreen(_makeRecord()));
        await tester.pump();
        expect(find.textContaining('Alice'), findsWidgets);
        expect(find.textContaining('Bob'), findsWidgets);
      });

      testWidgets('affiche le titre "Analyse de partie"', (tester) async {
        await tester.pumpWidget(_buildScreen(_makeRecord()));
        await tester.pump();
        expect(find.text('Analyse de partie'), findsOneWidget);
      });

      testWidgets('affiche "Victoire" quand le joueur local a gagné',
          (tester) async {
        await tester.pumpWidget(_buildScreen(
          _makeRecord(winner: 'player-white', playerIsWhite: true),
        ));
        await tester.pump();
        expect(find.text('Victoire'), findsOneWidget);
      });

      testWidgets('affiche "Défaite" quand le joueur local a perdu',
          (tester) async {
        await tester.pumpWidget(_buildScreen(
          _makeRecord(winner: 'player-white', playerIsWhite: false),
        ));
        await tester.pump();
        expect(find.text('Défaite'), findsOneWidget);
      });

      testWidgets('affiche "½ - ½" pour une nulle', (tester) async {
        await tester.pumpWidget(_buildScreen(
          _makeRecord(result: 'DRAW', winner: null),
        ));
        await tester.pump();
        expect(find.text('½ - ½'), findsOneWidget);
      });

      testWidgets('affiche le contrôle de temps quand renseigné',
          (tester) async {
        await tester.pumpWidget(
            _buildScreen(_makeRecord(totalTimeSeconds: 300, incrementSeconds: 0)));
        await tester.pump();
        expect(find.text('5min'), findsOneWidget);
      });

      testWidgets('affiche contrôle de temps avec incrément', (tester) async {
        await tester.pumpWidget(
            _buildScreen(_makeRecord(totalTimeSeconds: 180, incrementSeconds: 2)));
        await tester.pump();
        expect(find.text('3+2'), findsOneWidget);
      });

      testWidgets('n\'affiche pas de badge temps quand totalTimeSeconds est null',
          (tester) async {
        await tester.pumpWidget(
            _buildScreen(_makeRecord(totalTimeSeconds: null)));
        await tester.pump();
        expect(find.text('5min'), findsNothing);
      });

      testWidgets('affiche le label de résultat CHECKMATE', (tester) async {
        await tester.pumpWidget(_buildScreen(_makeRecord(result: 'CHECKMATE')));
        await tester.pump();
        expect(find.text('Échec et mat'), findsOneWidget);
      });

      testWidgets('affiche le label de résultat RESIGNED', (tester) async {
        await tester.pumpWidget(_buildScreen(_makeRecord(result: 'RESIGNED')));
        await tester.pump();
        expect(find.text('Abandon'), findsOneWidget);
      });

      testWidgets('affiche le label de résultat STALEMATE', (tester) async {
        await tester.pumpWidget(_buildScreen(_makeRecord(result: 'STALEMATE')));
        await tester.pump();
        expect(find.text('Pat'), findsOneWidget);
      });

      testWidgets('affiche le label de résultat TIMEOUT', (tester) async {
        await tester.pumpWidget(_buildScreen(_makeRecord(result: 'TIMEOUT')));
        await tester.pump();
        expect(find.text('Temps écoulé'), findsOneWidget);
      });

      testWidgets('résultat inconnu affiche la valeur brute', (tester) async {
        await tester.pumpWidget(_buildScreen(_makeRecord(result: 'UNKNOWN')));
        await tester.pump();
        expect(find.text('UNKNOWN'), findsWidgets);
      });

      testWidgets('gère un historique vide sans erreur', (tester) async {
        await tester.pumpWidget(_buildScreen(_makeRecord(withMoves: false)));
        await tester.pump();
        tester.takeException();
        expect(find.byType(ChessBoard), findsOneWidget);
      });
    });

    group('navigation', () {
      testWidgets('le bouton retour (arrow_back) est présent', (tester) async {
        await tester.pumpWidget(_buildScreen(_makeRecord()));
        await tester.pump();
        expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
      });

      testWidgets('taper chevron_left recule d\'un coup', (tester) async {
        await tester.pumpWidget(_buildScreen(_makeRecord()));
        await tester.pump();
        // Au départ on est à la position finale (_reviewIndex = -1)
        // Taper "précédent" → on passe au dernier coup
        await tester.tap(find.byIcon(Icons.chevron_left_rounded));
        await tester.pump();
        tester.takeException();
        // Le MoveHistoryPanel est toujours là
        expect(find.byType(MoveHistoryPanel), findsOneWidget);
      });

      testWidgets('taper first_page_rounded va au premier coup', (tester) async {
        await tester.pumpWidget(_buildScreen(_makeRecord()));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.first_page_rounded));
        await tester.pump();
        tester.takeException();
        expect(find.byType(ChessBoard), findsOneWidget);
      });

      testWidgets('taper last_page_rounded va à la position finale',
          (tester) async {
        await tester.pumpWidget(_buildScreen(_makeRecord()));
        await tester.pump();
        // D'abord aller au premier coup
        await tester.tap(find.byIcon(Icons.first_page_rounded));
        await tester.pump();
        // Puis aller au dernier
        await tester.tap(find.byIcon(Icons.last_page_rounded));
        await tester.pump();
        tester.takeException();
        expect(find.byType(ChessBoard), findsOneWidget);
      });

      testWidgets('taper chevron_right depuis le début avance d\'un coup',
          (tester) async {
        await tester.pumpWidget(_buildScreen(_makeRecord()));
        await tester.pump();
        // Aller au début
        await tester.tap(find.byIcon(Icons.first_page_rounded));
        await tester.pump();
        // Avancer
        await tester.tap(find.byIcon(Icons.chevron_right_rounded));
        await tester.pump();
        tester.takeException();
        expect(find.byType(ChessBoard), findsOneWidget);
      });

      testWidgets('navigation complète : first → prev ne crash pas',
          (tester) async {
        await tester.pumpWidget(_buildScreen(_makeRecord()));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.first_page_rounded));
        await tester.pump();
        // Précédent depuis le premier coup → doit rester au premier
        await tester.tap(find.byIcon(Icons.chevron_left_rounded));
        await tester.pump();
        tester.takeException();
        expect(find.byType(ChessBoard), findsOneWidget);
      });
    });
  });
}
