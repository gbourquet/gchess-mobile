import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/game/domain/entities/player.dart';

void main() {
  const tPlayer = Player(
    playerId: 'p1',
    userId: 'u1',
    username: 'alice',
    color: 'WHITE',
  );

  group('Player', () {
    test('props contains all fields', () {
      expect(tPlayer.props, ['p1', 'u1', 'alice', 'WHITE']);
    });

    test('equality: same values are equal', () {
      const other = Player(
        playerId: 'p1',
        userId: 'u1',
        username: 'alice',
        color: 'WHITE',
      );
      expect(tPlayer, other);
    });

    test('equality: different playerId are not equal', () {
      const other = Player(
        playerId: 'p2',
        userId: 'u1',
        username: 'alice',
        color: 'WHITE',
      );
      expect(tPlayer, isNot(other));
    });

    test('equality: different color are not equal', () {
      const other = Player(
        playerId: 'p1',
        userId: 'u1',
        username: 'alice',
        color: 'BLACK',
      );
      expect(tPlayer, isNot(other));
    });
  });
}
