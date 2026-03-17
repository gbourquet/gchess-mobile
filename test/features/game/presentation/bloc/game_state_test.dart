import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_game.dart';
import 'package:gchess_mobile/features/game/domain/entities/game_status.dart';
import 'package:gchess_mobile/features/game/domain/entities/player.dart';
import 'package:gchess_mobile/features/game/presentation/bloc/game_state.dart';

Player _player(String id, String username, String color) => Player(
      playerId: id,
      userId: 'u-$id',
      username: username,
      color: color,
    );

ChessGame _game({String id = 'g1', String side = 'WHITE'}) => ChessGame(
      gameId: id,
      whitePlayer: _player('wp', 'Alice', 'WHITE'),
      blackPlayer: _player('bp', 'Bob', 'BLACK'),
      positionFen:
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      currentSide: side,
      gameStatus: GameStatus.active,
      isCheck: false,
      moveHistory: const [],
    );

void main() {
  group('GameInitial', () {
    test('equality', () {
      expect(const GameInitial(), equals(const GameInitial()));
    });

    test('props is empty', () {
      expect(const GameInitial().props, isEmpty);
    });
  });

  group('GameLoading', () {
    test('equality', () {
      expect(const GameLoading(), equals(const GameLoading()));
    });

    test('props is empty', () {
      expect(const GameLoading().props, isEmpty);
    });
  });

  group('GameError', () {
    test('equality — same message', () {
      expect(const GameError('oops'), equals(const GameError('oops')));
    });

    test('inequality — different message', () {
      expect(const GameError('a'), isNot(equals(const GameError('b'))));
    });

    test('props contains message', () {
      expect(const GameError('err').props, ['err']);
    });
  });

  group('GameEnded', () {
    final game = _game();

    test('equality', () {
      expect(
        GameEnded(game: game, result: 'CHECKMATE'),
        equals(GameEnded(game: game, result: 'CHECKMATE')),
      );
    });

    test('inequality — different result', () {
      expect(
        GameEnded(game: game, result: 'CHECKMATE'),
        isNot(equals(GameEnded(game: game, result: 'DRAW'))),
      );
    });

    test('props contains game and result', () {
      final state = GameEnded(game: game, result: 'TIMEOUT');
      expect(state.props, [game, 'TIMEOUT']);
    });
  });

  group('GameActive', () {
    final game = _game();

    test('equality with same fields', () {
      expect(
        GameActive(game: game, hasOfferedDraw: false),
        equals(GameActive(game: game, hasOfferedDraw: false)),
      );
    });

    test('inequality when hasOfferedDraw differs', () {
      expect(
        GameActive(game: game, hasOfferedDraw: false),
        isNot(equals(GameActive(game: game, hasOfferedDraw: true))),
      );
    });

    test('props contains all fields', () {
      final state = GameActive(
        game: game,
        lastMoveFrom: 'e2',
        lastMoveTo: 'e4',
        pendingDrawOfferId: 'draw-1',
        hasOfferedDraw: true,
        totalTimeSeconds: 600,
        incrementSeconds: 5,
        whiteTimeRemainingMs: 300000,
        blackTimeRemainingMs: 299000,
      );
      expect(state.props, [
        game,
        'e2',
        'e4',
        'draw-1',
        true,
        600,
        5,
        300000,
        299000,
      ]);
    });

    group('copyWith', () {
      late GameActive base;

      setUp(() {
        base = GameActive(
          game: game,
          lastMoveFrom: 'e2',
          lastMoveTo: 'e4',
          pendingDrawOfferId: 'offer-1',
          hasOfferedDraw: false,
          totalTimeSeconds: 600,
          incrementSeconds: 5,
          whiteTimeRemainingMs: 300000,
          blackTimeRemainingMs: 299000,
        );
      });

      test('returns identical copy when no arguments passed', () {
        expect(base.copyWith(), equals(base));
      });

      test('updates game', () {
        final newGame = _game(id: 'g2');
        final copy = base.copyWith(game: newGame);
        expect(copy.game, newGame);
        expect(copy.lastMoveFrom, base.lastMoveFrom);
      });

      test('updates lastMoveFrom and lastMoveTo', () {
        final copy = base.copyWith(lastMoveFrom: 'd2', lastMoveTo: 'd4');
        expect(copy.lastMoveFrom, 'd2');
        expect(copy.lastMoveTo, 'd4');
      });

      test('updates hasOfferedDraw', () {
        final copy = base.copyWith(hasOfferedDraw: true);
        expect(copy.hasOfferedDraw, isTrue);
      });

      test('updates clock times', () {
        final copy = base.copyWith(
          whiteTimeRemainingMs: 250000,
          blackTimeRemainingMs: 298000,
        );
        expect(copy.whiteTimeRemainingMs, 250000);
        expect(copy.blackTimeRemainingMs, 298000);
      });

      test('updates pendingDrawOfferId', () {
        final copy = base.copyWith(pendingDrawOfferId: 'offer-2');
        expect(copy.pendingDrawOfferId, 'offer-2');
      });

      test('clearPendingDraw=true sets pendingDrawOfferId to null', () {
        final copy = base.copyWith(clearPendingDraw: true);
        expect(copy.pendingDrawOfferId, isNull);
      });

      test(
          'clearPendingDraw=true takes precedence over new pendingDrawOfferId',
          () {
        final copy = base.copyWith(
          clearPendingDraw: true,
          pendingDrawOfferId: 'ignored',
        );
        expect(copy.pendingDrawOfferId, isNull);
      });

      test('clearPendingDraw=false preserves existing pendingDrawOfferId', () {
        final copy = base.copyWith(clearPendingDraw: false);
        expect(copy.pendingDrawOfferId, 'offer-1');
      });

      test('null time values remain null when not provided', () {
        final state = GameActive(game: game);
        final copy = state.copyWith(hasOfferedDraw: true);
        expect(copy.whiteTimeRemainingMs, isNull);
        expect(copy.blackTimeRemainingMs, isNull);
      });
    });
  });
}
