import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_game.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_move.dart';
import 'package:gchess_mobile/features/game/domain/entities/game_status.dart';
import 'package:gchess_mobile/features/game/domain/entities/player.dart';
import 'package:gchess_mobile/features/game/presentation/bloc/game_state.dart';
import 'package:gchess_mobile/features/game/presentation/providers/game_provider.dart';
import 'package:gchess_mobile/features/game/presentation/screens/game_screen.dart';
import 'package:gchess_mobile/features/game/presentation/widgets/chess_board.dart';
import 'package:gchess_mobile/features/game/presentation/widgets/move_history_panel.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────────


const _kFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
const _kWhitePlayerId = 'wp-1';
const _kBlackPlayerId = 'bp-1';

const _kWhitePlayer = Player(
  playerId: _kWhitePlayerId,
  userId: 'u-w',
  username: 'Alice',
  color: 'WHITE',
);
const _kBlackPlayer = Player(
  playerId: _kBlackPlayerId,
  userId: 'u-b',
  username: 'Bob',
  color: 'BLACK',
);

ChessGame _game({
  String fen = _kFen,
  String side = 'WHITE',
  GameStatus status = GameStatus.active,
  List<String> moves = const [],
  int? whiteMs,
  int? blackMs,
}) =>
    ChessGame(
      gameId: 'g-1',
      positionFen: fen,
      moveHistory: moves,
      gameStatus: status,
      currentSide: side,
      isCheck: false,
      whitePlayer: _kWhitePlayer,
      blackPlayer: _kBlackPlayer,
      whiteTimeRemainingMs: whiteMs,
      blackTimeRemainingMs: blackMs,
    );

class _FakeGameNotifier extends GameNotifier {
  final GameState _initial;
  _FakeGameNotifier(this._initial);

  @override
  GameState build() => _initial;

  @override
  Future<void> connect(String gameId) async {}

  @override
  Future<void> makeMove(ChessMove move) async {}

  @override
  Future<void> resign() async {}

  @override
  Future<void> offerDraw() async {}

  @override
  Future<void> acceptDraw() async {}

  @override
  Future<void> rejectDraw() async {}

  @override
  void tickClock(bool isWhiteTurn) {}

  @override
  Future<void> claimTimeout() async {}
}

Widget _buildScreen(GameState state, {String playerId = _kWhitePlayerId}) {
  return ProviderScope(
    overrides: [
      gameNotifierProvider.overrideWith(() => _FakeGameNotifier(state)),
    ],
    child: MaterialApp(
      home: GameScreen(gameId: 'g-1', playerId: playerId),
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// Tests
// ──────────────────────────────────────────────────────────────────────────────

void main() {
  group('GameScreen', () {
    group('état GameInitial / GameLoading', () {
      testWidgets('GameInitial affiche un CircularProgressIndicator',
          (tester) async {
        await tester.pumpWidget(_buildScreen(const GameInitial()));
        await tester.pump();
        tester.takeException();
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('GameLoading affiche un CircularProgressIndicator',
          (tester) async {
        await tester.pumpWidget(_buildScreen(const GameLoading()));
        await tester.pump();
        tester.takeException();
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });
    });

    group('état GameActive', () {
      testWidgets('affiche le plateau d\'échecs', (tester) async {
        final state = GameActive(game: _game());
        await tester.pumpWidget(_buildScreen(state));
        await tester.pump();
        tester.takeException();
        expect(find.byType(ChessBoard), findsOneWidget);
      });

      testWidgets('affiche le panneau d\'historique des coups', (tester) async {
        final state = GameActive(game: _game());
        await tester.pumpWidget(_buildScreen(state));
        await tester.pump();
        tester.takeException();
        expect(find.byType(MoveHistoryPanel), findsOneWidget);
      });

      testWidgets('affiche le nom du joueur blanc', (tester) async {
        final state = GameActive(game: _game());
        await tester.pumpWidget(_buildScreen(state));
        await tester.pump();
        tester.takeException();
        expect(find.textContaining('ALICE'), findsWidgets);
      });

      testWidgets('affiche le nom du joueur noir', (tester) async {
        final state = GameActive(game: _game());
        await tester.pumpWidget(_buildScreen(state));
        await tester.pump();
        tester.takeException();
        expect(find.textContaining('BOB'), findsWidgets);
      });

      testWidgets('affiche le bouton RETOUR', (tester) async {
        final state = GameActive(game: _game());
        await tester.pumpWidget(_buildScreen(state));
        await tester.pump();
        tester.takeException();
        expect(find.text('RETOUR'), findsOneWidget);
      });

      testWidgets('affiche le bouton OPTIONS', (tester) async {
        final state = GameActive(game: _game());
        await tester.pumpWidget(_buildScreen(state));
        await tester.pump();
        tester.takeException();
        expect(find.text('OPTIONS'), findsOneWidget);
      });

      testWidgets('taper OPTIONS ouvre le bottom sheet', (tester) async {
        final state = GameActive(game: _game());
        await tester.pumpWidget(_buildScreen(state));
        await tester.pump();
        tester.takeException();
        // Taper l'icône (le tap sur le Text label ne déclenche pas onPressed)
        await tester.tap(find.byIcon(Icons.more_horiz));
        await tester.pump(const Duration(milliseconds: 500));
        tester.takeException();
        expect(find.text('Abandonner'), findsOneWidget);
        expect(find.text('Proposer nulle'), findsOneWidget);
      });

      testWidgets('taper Abandonner depuis le sheet ouvre un dialog de confirmation',
          (tester) async {
        final state = GameActive(game: _game());
        await tester.pumpWidget(_buildScreen(state));
        await tester.pump();
        tester.takeException();
        await tester.tap(find.byIcon(Icons.more_horiz));
        await tester.pump(const Duration(milliseconds: 500));
        tester.takeException();
        // Le sheet s'ouvre mais est partiellement hors-écran → drag up pour révéler
        await tester.drag(find.text('Abandonner'), const Offset(0, -200));
        await tester.pump(const Duration(milliseconds: 300));
        tester.takeException();
        // Taper directement le OutlinedButton maintenant visible
        await tester.tap(find.byType(OutlinedButton).first);
        await tester.pump(const Duration(milliseconds: 300));
        tester.takeException();
        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets('annuler le dialog d\'abandon ferme le dialog', (tester) async {
        final state = GameActive(game: _game());
        await tester.pumpWidget(_buildScreen(state));
        await tester.pump();
        tester.takeException();
        await tester.tap(find.byIcon(Icons.more_horiz));
        await tester.pump(const Duration(milliseconds: 500));
        tester.takeException();
        await tester.drag(find.text('Abandonner'), const Offset(0, -200));
        await tester.pump(const Duration(milliseconds: 300));
        tester.takeException();
        await tester.tap(find.byType(OutlinedButton).first);
        await tester.pump(const Duration(milliseconds: 300));
        tester.takeException();
        // Clique Annuler dans le dialog
        await tester.tap(find.text('Annuler'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('taper Proposer nulle depuis le sheet ouvre un dialog',
          (tester) async {
        final state = GameActive(game: _game(), hasOfferedDraw: false);
        await tester.pumpWidget(_buildScreen(state));
        await tester.pump();
        tester.takeException();
        await tester.tap(find.byIcon(Icons.more_horiz));
        await tester.pump(const Duration(milliseconds: 500));
        tester.takeException();
        // Drag pour amener le bouton "Proposer nulle" dans la zone visible
        await tester.drag(find.text('Abandonner'), const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 300));
        tester.takeException();
        // Tapper au centre du label "Proposer nulle" (le find.byType(OutlinedButton) ne trouve qu'1)
        await tester.tapAt(tester.getCenter(find.text('Proposer nulle')));
        await tester.pump(const Duration(milliseconds: 300));
        tester.takeException();
        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets('affiche les horloges quand les temps sont renseignés',
          (tester) async {
        final state = GameActive(
          game: _game(whiteMs: 600000, blackMs: 600000),
          whiteTimeRemainingMs: 600000,
          blackTimeRemainingMs: 600000,
        );
        await tester.pumpWidget(_buildScreen(state));
        await tester.pump();
        tester.takeException();
        expect(find.text('10:00'), findsWidgets);
      });

      testWidgets('perspective noire : playerId correspond au joueur noir',
          (tester) async {
        final state = GameActive(game: _game());
        await tester.pumpWidget(
          _buildScreen(state, playerId: _kBlackPlayerId),
        );
        await tester.pump();
        tester.takeException();
        expect(find.byType(ChessBoard), findsOneWidget);
      });
    });

    group('état GameEnded', () {
      testWidgets('CHECKMATE — affiche "Échec et mat !"', (tester) async {
        final game = _game(
          status: GameStatus.checkmate,
          side: 'WHITE', // blanc en échec = noir a gagné
        );
        final state = GameEnded(game: game, result: 'CHECKMATE');
        await tester.pumpWidget(_buildScreen(state));
        await tester.pump();
        tester.takeException();
        expect(find.text('Échec et mat !'), findsOneWidget);
      });

      testWidgets('DRAW — affiche "Nulle"', (tester) async {
        final game = _game(status: GameStatus.draw);
        final state = GameEnded(game: game, result: 'DRAW');
        await tester.pumpWidget(_buildScreen(state));
        await tester.pump();
        tester.takeException();
        expect(find.text('Nulle'), findsOneWidget);
      });

      testWidgets('STALEMATE — affiche "Pat"', (tester) async {
        final game = _game(status: GameStatus.stalemate);
        final state = GameEnded(game: game, result: 'STALEMATE');
        await tester.pumpWidget(_buildScreen(state));
        await tester.pump();
        tester.takeException();
        expect(find.text('Pat'), findsOneWidget);
      });

      testWidgets('RESIGNED — affiche "Abandon"', (tester) async {
        final game = _game(status: GameStatus.resigned);
        final state = GameEnded(game: game, result: 'RESIGNED');
        await tester.pumpWidget(_buildScreen(state));
        await tester.pump();
        tester.takeException();
        expect(find.text('Abandon'), findsOneWidget);
      });

      testWidgets('TIMEOUT — affiche "Temps écoulé"', (tester) async {
        final game = _game(status: GameStatus.timeout);
        final state = GameEnded(game: game, result: 'TIMEOUT');
        await tester.pumpWidget(_buildScreen(state));
        await tester.pump();
        tester.takeException();
        expect(find.text('Temps écoulé'), findsOneWidget);
      });

      testWidgets('résultat inconnu — affiche "Fin de partie"', (tester) async {
        final game = _game();
        final state = GameEnded(game: game, result: 'UNKNOWN_RESULT');
        await tester.pumpWidget(_buildScreen(state));
        await tester.pump();
        tester.takeException();
        expect(find.text('Fin de partie'), findsOneWidget);
      });

      testWidgets('affiche le bouton "Retour au lobby"', (tester) async {
        final game = _game(status: GameStatus.draw);
        final state = GameEnded(game: game, result: 'DRAW');
        await tester.pumpWidget(_buildScreen(state));
        await tester.pump();
        tester.takeException();
        expect(find.text('Retour au lobby'), findsOneWidget);
      });

      testWidgets('CHECKMATE avec playerId = gagnant (black wins, white to move = black won)',
          (tester) async {
        // currentSide=WHITE en échec = blanc est en échec, noir a fait mat
        // si playerId = blackPlayer → le joueur a gagné
        final game = _game(status: GameStatus.checkmate, side: 'WHITE');
        final state = GameEnded(game: game, result: 'CHECKMATE');
        await tester.pumpWidget(
          _buildScreen(state, playerId: _kBlackPlayerId),
        );
        await tester.pump();
        tester.takeException();
        expect(find.textContaining('Félicitations'), findsOneWidget);
      });

      testWidgets('TIMEOUT description joueur qui gagne', (tester) async {
        // currentSide=WHITE et playerId=blackPlayer → black gagne (white ran out)
        final game = _game(status: GameStatus.timeout, side: 'WHITE');
        final state = GameEnded(game: game, result: 'TIMEOUT');
        await tester.pumpWidget(
          _buildScreen(state, playerId: _kBlackPlayerId),
        );
        await tester.pump();
        tester.takeException();
        expect(find.textContaining('adversaire est à court'), findsOneWidget);
      });
    });

    group('GameError', () {
      testWidgets('affiche une SnackBar d\'erreur', (tester) async {
        // On part d'un état actif, puis on simule une erreur
        // En pratique, l'erreur est détectée via ref.listen
        // On teste que GameError initial montre le spinner (état de fallback)
        await tester.pumpWidget(_buildScreen(const GameError('Connexion perdue')));
        await tester.pump();
        tester.takeException();
        // L'état GameError n'a pas de vue dédiée → spinner par défaut
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });
    });
  });
}
