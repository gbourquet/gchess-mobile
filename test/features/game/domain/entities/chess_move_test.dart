import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_move.dart';

void main() {
  group('ChessMove', () {
    test('props contains from, to, promotion', () {
      const move = ChessMove(from: 'e2', to: 'e4', promotion: 'q');
      expect(move.props, ['e2', 'e4', 'q']);
    });

    test('props contains null promotion when not set', () {
      const move = ChessMove(from: 'e2', to: 'e4');
      expect(move.props, ['e2', 'e4', null]);
    });

    test('equality: same values are equal', () {
      const a = ChessMove(from: 'e2', to: 'e4');
      const b = ChessMove(from: 'e2', to: 'e4');
      expect(a, b);
    });

    test('equality: with same promotion are equal', () {
      const a = ChessMove(from: 'e7', to: 'e8', promotion: 'q');
      const b = ChessMove(from: 'e7', to: 'e8', promotion: 'q');
      expect(a, b);
    });

    test('equality: different from are not equal', () {
      const a = ChessMove(from: 'e2', to: 'e4');
      const b = ChessMove(from: 'd2', to: 'e4');
      expect(a, isNot(b));
    });

    test('equality: different to are not equal', () {
      const a = ChessMove(from: 'e2', to: 'e4');
      const b = ChessMove(from: 'e2', to: 'e3');
      expect(a, isNot(b));
    });

    test('equality: different promotion are not equal', () {
      const a = ChessMove(from: 'e7', to: 'e8', promotion: 'q');
      const b = ChessMove(from: 'e7', to: 'e8', promotion: 'r');
      expect(a, isNot(b));
    });
  });
}
