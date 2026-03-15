import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_game.dart';
import 'package:gchess_mobile/features/game/domain/entities/game_status.dart';
import 'package:gchess_mobile/features/game/domain/entities/player.dart';

void main() {
  const tWhitePlayer = Player(
    playerId: 'p1',
    userId: 'u1',
    username: 'alice',
    color: 'WHITE',
  );
  const tBlackPlayer = Player(
    playerId: 'p2',
    userId: 'u2',
    username: 'bob',
    color: 'BLACK',
  );

  const tGame = ChessGame(
    gameId: 'g1',
    positionFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    moveHistory: [],
    gameStatus: GameStatus.active,
    currentSide: 'WHITE',
    isCheck: false,
    whitePlayer: tWhitePlayer,
    blackPlayer: tBlackPlayer,
  );

  group('ChessGame', () {
    test('optional fields default to null', () {
      expect(tGame.winner, isNull);
      expect(tGame.totalTimeSeconds, isNull);
      expect(tGame.incrementSeconds, isNull);
      expect(tGame.whiteTimeRemainingMs, isNull);
      expect(tGame.blackTimeRemainingMs, isNull);
    });

    test('props includes all fields', () {
      expect(tGame.props, [
        'g1',
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        <String>[],
        GameStatus.active,
        'WHITE',
        false,
        tWhitePlayer,
        tBlackPlayer,
        null,
        null,
        null,
        null,
        null,
      ]);
    });

    test('equality: same values are equal', () {
      const other = ChessGame(
        gameId: 'g1',
        positionFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        moveHistory: [],
        gameStatus: GameStatus.active,
        currentSide: 'WHITE',
        isCheck: false,
        whitePlayer: tWhitePlayer,
        blackPlayer: tBlackPlayer,
      );
      expect(tGame, other);
    });

    test('equality: different gameId are not equal', () {
      const other = ChessGame(
        gameId: 'g2',
        positionFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        moveHistory: [],
        gameStatus: GameStatus.active,
        currentSide: 'WHITE',
        isCheck: false,
        whitePlayer: tWhitePlayer,
        blackPlayer: tBlackPlayer,
      );
      expect(tGame, isNot(other));
    });

    test('supports optional fields', () {
      const withTime = ChessGame(
        gameId: 'g1',
        positionFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        moveHistory: ['e2-e4'],
        gameStatus: GameStatus.active,
        currentSide: 'BLACK',
        isCheck: false,
        whitePlayer: tWhitePlayer,
        blackPlayer: tBlackPlayer,
        winner: null,
        totalTimeSeconds: 600,
        incrementSeconds: 5,
        whiteTimeRemainingMs: 590000,
        blackTimeRemainingMs: 600000,
      );
      expect(withTime.totalTimeSeconds, 600);
      expect(withTime.incrementSeconds, 5);
      expect(withTime.whiteTimeRemainingMs, 590000);
      expect(withTime.blackTimeRemainingMs, 600000);
    });
  });
}
