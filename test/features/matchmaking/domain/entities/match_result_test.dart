import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_result.dart';

void main() {
  const tMatchResult = MatchResult(
    gameId: 'game1',
    playerId: 'player1',
    yourColor: 'WHITE',
    opponentUserId: 'user2',
  );

  group('MatchResult', () {
    test('props contains all fields', () {
      expect(tMatchResult.props, ['game1', 'player1', 'WHITE', 'user2']);
    });

    test('equality: same values are equal', () {
      const other = MatchResult(
        gameId: 'game1',
        playerId: 'player1',
        yourColor: 'WHITE',
        opponentUserId: 'user2',
      );
      expect(tMatchResult, other);
    });

    test('equality: different gameId are not equal', () {
      const other = MatchResult(
        gameId: 'game2',
        playerId: 'player1',
        yourColor: 'WHITE',
        opponentUserId: 'user2',
      );
      expect(tMatchResult, isNot(other));
    });

    test('equality: different yourColor are not equal', () {
      const other = MatchResult(
        gameId: 'game1',
        playerId: 'player1',
        yourColor: 'BLACK',
        opponentUserId: 'user2',
      );
      expect(tMatchResult, isNot(other));
    });
  });
}
