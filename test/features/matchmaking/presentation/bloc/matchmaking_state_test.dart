import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_result.dart';
import 'package:gchess_mobile/features/matchmaking/presentation/bloc/matchmaking_state.dart';

const _tMatchResult = MatchResult(
  gameId: 'game-1',
  playerId: 'player-1',
  yourColor: 'WHITE',
  opponentUserId: 'opponent-1',
);

void main() {
  group('MatchmakingIdle', () {
    test('equality', () {
      expect(const MatchmakingIdle(), equals(const MatchmakingIdle()));
    });

    test('props is empty', () {
      expect(const MatchmakingIdle().props, isEmpty);
    });
  });

  group('MatchmakingConnecting', () {
    test('equality', () {
      expect(
        const MatchmakingConnecting(),
        equals(const MatchmakingConnecting()),
      );
    });

    test('props is empty', () {
      expect(const MatchmakingConnecting().props, isEmpty);
    });
  });

  group('InQueue', () {
    test('equality — same position', () {
      expect(
        const InQueue(position: 3),
        equals(const InQueue(position: 3)),
      );
    });

    test('inequality — different position', () {
      expect(
        const InQueue(position: 1),
        isNot(equals(const InQueue(position: 2))),
      );
    });

    test('props contains position', () {
      expect(const InQueue(position: 5).props, [5]);
    });
  });

  group('MatchFound', () {
    test('equality', () {
      expect(
        MatchFound(_tMatchResult),
        equals(MatchFound(_tMatchResult)),
      );
    });

    test('inequality — different matchResult', () {
      const other = MatchResult(
        gameId: 'game-2',
        playerId: 'player-2',
        yourColor: 'BLACK',
        opponentUserId: 'opponent-2',
      );
      expect(
        MatchFound(_tMatchResult),
        isNot(equals(MatchFound(other))),
      );
    });

    test('props contains matchResult', () {
      expect(MatchFound(_tMatchResult).props, [_tMatchResult]);
    });

    test('exposes matchResult', () {
      expect(MatchFound(_tMatchResult).matchResult, _tMatchResult);
    });
  });

  group('MatchmakingError', () {
    test('equality — same message', () {
      expect(
        const MatchmakingError('oops'),
        equals(const MatchmakingError('oops')),
      );
    });

    test('inequality — different message', () {
      expect(
        const MatchmakingError('a'),
        isNot(equals(const MatchmakingError('b'))),
      );
    });

    test('props contains message', () {
      expect(const MatchmakingError('err').props, ['err']);
    });
  });

  group('cross-type inequality', () {
    test('MatchmakingIdle != MatchmakingConnecting', () {
      expect(
        const MatchmakingIdle(),
        isNot(equals(const MatchmakingConnecting())),
      );
    });

    test('InQueue != MatchmakingError', () {
      expect(
        const InQueue(position: 1),
        isNot(equals(const MatchmakingError('error'))),
      );
    });
  });
}
