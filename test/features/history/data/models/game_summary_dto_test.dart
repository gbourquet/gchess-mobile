import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/history/data/models/game_summary_dto.dart';

void main() {
  group('GameSummaryDTO', () {
    test('fromJson parse tous les champs', () {
      final json = {
        'gameId': 'game-1',
        'whiteUserId': 'user-white',
        'blackUserId': 'user-black',
        'whiteUsername': 'Alice',
        'blackUsername': 'Bob',
        'status': 'CHECKMATE',
        'moveCount': 42,
      };
      final dto = GameSummaryDTO.fromJson(json);
      expect(dto.gameId, 'game-1');
      expect(dto.whiteUserId, 'user-white');
      expect(dto.blackUserId, 'user-black');
      expect(dto.whiteUsername, 'Alice');
      expect(dto.blackUsername, 'Bob');
      expect(dto.status, 'CHECKMATE');
      expect(dto.moveCount, 42);
    });

    test('fromJson parse moveCount entier', () {
      final json = {
        'gameId': 'g',
        'whiteUserId': 'w',
        'blackUserId': 'b',
        'whiteUsername': 'Alice',
        'blackUsername': 'Bob',
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
        'whiteUsername': 'w',
        'blackUsername': 'b',
        'status': 'RESIGNED',
        'moveCount': 10.0,
      };
      final dto = GameSummaryDTO.fromJson(json);
      expect(dto.moveCount, 10);
    });

    test('fromJson whiteUsername vaut "?" si absent', () {
      final json = {
        'gameId': 'g',
        'whiteUserId': 'w',
        'blackUserId': 'b',
        'status': 'DRAW',
        'moveCount': 0,
      };
      final dto = GameSummaryDTO.fromJson(json);
      expect(dto.whiteUsername, '?');
      expect(dto.blackUsername, '?');
    });

    test('fromJson parse totalTimeSeconds et incrementSeconds', () {
      final json = {
        'gameId': 'g',
        'whiteUserId': 'w',
        'blackUserId': 'b',
        'whiteUsername': 'Alice',
        'blackUsername': 'Bob',
        'status': 'CHECKMATE',
        'moveCount': 10,
        'totalTimeSeconds': 300,
        'incrementSeconds': 5,
      };
      final dto = GameSummaryDTO.fromJson(json);
      expect(dto.totalTimeSeconds, 300);
      expect(dto.incrementSeconds, 5);
    });

    test('fromJson parse playedAt', () {
      final json = {
        'gameId': 'g',
        'whiteUserId': 'w',
        'blackUserId': 'b',
        'whiteUsername': 'Alice',
        'blackUsername': 'Bob',
        'status': 'DRAW',
        'moveCount': 0,
        'playedAt': '2026-03-20T14:30:00Z',
      };
      final dto = GameSummaryDTO.fromJson(json);
      expect(dto.playedAt, isNotNull);
      expect(dto.playedAt!.year, 2026);
    });

    test('fromJson parse winnerUserId', () {
      final json = {
        'gameId': 'game-1',
        'whiteUserId': 'user-white',
        'blackUserId': 'user-black',
        'status': 'CHECKMATE',
        'moveCount': 42,
        'winnerUserId': 'user-white',
      };
      final dto = GameSummaryDTO.fromJson(json);
      expect(dto.winnerUserId, 'user-white');
    });

    test('fromJson winnerUserId null si absent (nulle)', () {
      final json = {
        'gameId': 'game-1',
        'whiteUserId': 'user-white',
        'blackUserId': 'user-black',
        'status': 'DRAW',
        'moveCount': 10,
      };
      final dto = GameSummaryDTO.fromJson(json);
      expect(dto.winnerUserId, isNull);
    });

    test('fromJson parse whiteTimeRemainingMs et blackTimeRemainingMs', () {
      final json = {
        'gameId': 'game-1',
        'whiteUserId': 'user-white',
        'blackUserId': 'user-black',
        'status': 'CHECKMATE',
        'moveCount': 42,
        'winnerUserId': 'user-white',
        'whiteTimeRemainingMs': 45000,
        'blackTimeRemainingMs': 12300,
      };
      final dto = GameSummaryDTO.fromJson(json);
      expect(dto.whiteTimeRemainingMs, 45000);
      expect(dto.blackTimeRemainingMs, 12300);
    });

    test('fromJson temps restants null si absents', () {
      final json = {
        'gameId': 'g',
        'whiteUserId': 'w',
        'blackUserId': 'b',
        'status': 'DRAW',
        'moveCount': 0,
      };
      final dto = GameSummaryDTO.fromJson(json);
      expect(dto.whiteTimeRemainingMs, isNull);
      expect(dto.blackTimeRemainingMs, isNull);
    });
  });
}
