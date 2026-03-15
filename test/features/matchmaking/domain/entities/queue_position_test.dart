import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/queue_position.dart';

void main() {
  group('QueuePosition', () {
    test('props contains position', () {
      const pos = QueuePosition(position: 3);
      expect(pos.props, [3]);
    });

    test('equality: same position are equal', () {
      const a = QueuePosition(position: 3);
      const b = QueuePosition(position: 3);
      expect(a, b);
    });

    test('equality: different positions are not equal', () {
      const a = QueuePosition(position: 1);
      const b = QueuePosition(position: 2);
      expect(a, isNot(b));
    });
  });
}
