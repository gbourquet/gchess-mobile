import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/history/data/models/game_summary_dto.dart';

void main() {
  group('GameSummaryDTO', () {
    test('fromJson parse tous les champs', () {
      final json = {
        'gameId': 'game-1',
        'whiteUserId': 'user-white',
        'blackUserId': 'user-black',
        'status': 'CHECKMATE',
        'moveCount': 42,
      };
      final dto = GameSummaryDTO.fromJson(json);
      expect(dto.gameId, 'game-1');
      expect(dto.whiteUserId, 'user-white');
      expect(dto.blackUserId, 'user-black');
      expect(dto.status, 'CHECKMATE');
      expect(dto.moveCount, 42);
    });

    test('fromJson parse moveCount entier', () {
      final json = {
        'gameId': 'g',
        'whiteUserId': 'w',
        'blackUserId': 'b',
        'status': 'DRAW',
        'moveCount': 0,
      };
      final dto = GameSummaryDTO.fromJson(json);
      expect(dto.moveCount, 0);
    });

    test('fromJson accepte moveCount comme double (JSON number)', () {
      final json = {
        'gameId': 'g',
        'whiteUserId': 'w',
        'blackUserId': 'b',
        'status': 'RESIGNED',
        'moveCount': 10.0,
      };
      final dto = GameSummaryDTO.fromJson(json);
      expect(dto.moveCount, 10);
    });
  });
}
