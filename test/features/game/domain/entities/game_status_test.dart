import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/game/domain/entities/game_status.dart';

void main() {
  group('GameStatusExtension', () {
    test('fromString should return active for ACTIVE', () {
      expect(GameStatusExtension.fromString('ACTIVE'), GameStatus.active);
      expect(GameStatusExtension.fromString('active'), GameStatus.active);
      expect(GameStatusExtension.fromString('Active'), GameStatus.active);
    });

    test('fromString should return checkmate for CHECKMATE', () {
      expect(GameStatusExtension.fromString('CHECKMATE'), GameStatus.checkmate);
      expect(GameStatusExtension.fromString('checkmate'), GameStatus.checkmate);
      expect(GameStatusExtension.fromString('Checkmate'), GameStatus.checkmate);
    });

    test('fromString should return stalemate for STALEMATE', () {
      expect(GameStatusExtension.fromString('STALEMATE'), GameStatus.stalemate);
      expect(GameStatusExtension.fromString('stalemate'), GameStatus.stalemate);
      expect(GameStatusExtension.fromString('Stalemate'), GameStatus.stalemate);
    });

    test('fromString should return draw for DRAW', () {
      expect(GameStatusExtension.fromString('DRAW'), GameStatus.draw);
      expect(GameStatusExtension.fromString('draw'), GameStatus.draw);
      expect(GameStatusExtension.fromString('Draw'), GameStatus.draw);
    });

    test('fromString should return resigned for RESIGNED', () {
      expect(GameStatusExtension.fromString('RESIGNED'), GameStatus.resigned);
      expect(GameStatusExtension.fromString('resigned'), GameStatus.resigned);
      expect(GameStatusExtension.fromString('Resigned'), GameStatus.resigned);
    });

    test('fromString should return timeout for TIMEOUT', () {
      expect(GameStatusExtension.fromString('TIMEOUT'), GameStatus.timeout);
      expect(GameStatusExtension.fromString('timeout'), GameStatus.timeout);
      expect(GameStatusExtension.fromString('Timeout'), GameStatus.timeout);
    });

    test('fromString should return active for unknown status', () {
      expect(GameStatusExtension.fromString('UNKNOWN'), GameStatus.active);
      expect(GameStatusExtension.fromString('invalid'), GameStatus.active);
      expect(GameStatusExtension.fromString(''), GameStatus.active);
    });
  });

  group('GameStatusExtension.toApiString', () {
    test('toApiString returns uppercase name', () {
      expect(GameStatus.active.toApiString(), 'ACTIVE');
      expect(GameStatus.checkmate.toApiString(), 'CHECKMATE');
      expect(GameStatus.stalemate.toApiString(), 'STALEMATE');
      expect(GameStatus.draw.toApiString(), 'DRAW');
      expect(GameStatus.resigned.toApiString(), 'RESIGNED');
      expect(GameStatus.timeout.toApiString(), 'TIMEOUT');
    });
  });
}
