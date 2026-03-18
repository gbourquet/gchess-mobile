import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/history/domain/entities/game_record.dart';

void main() {
  // Partie simple : 1.e4 e5 (UCI: e2-e4, e7-e5)
  const uciHistory = ['e2-e4', 'e7-e5'];
  const whitePlayerId = 'player-white';
  const blackPlayerId = 'player-black';
  const playerId = whitePlayerId; // le joueur local joue blanc

  group('GameRecord.fromGame', () {
    test('calcule sanHistory depuis uciHistory', () {
      final record = GameRecord.fromGame(
        gameId: 'game-1',
        playerId: playerId,
        whiteUsername: 'Alice',
        blackUsername: 'Bob',
        whitePlayerId: whitePlayerId,
        blackPlayerId: blackPlayerId,
        result: 'CHECKMATE',
        winner: whitePlayerId,
        uciHistory: uciHistory,
        finalFen:
            'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
        totalTimeSeconds: 300,
        incrementSeconds: 0,
        playedAt: DateTime(2026, 3, 17),
      );

      expect(record.sanHistory, hasLength(2));
      expect(record.sanHistory[0], 'e4');
      expect(record.sanHistory[1], 'e5');
    });

    test('calcule fenHistory avec une entrée par coup', () {
      final record = GameRecord.fromGame(
        gameId: 'game-1',
        playerId: playerId,
        whiteUsername: 'Alice',
        blackUsername: 'Bob',
        whitePlayerId: whitePlayerId,
        blackPlayerId: blackPlayerId,
        result: 'CHECKMATE',
        winner: whitePlayerId,
        uciHistory: uciHistory,
        finalFen:
            'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
        playedAt: DateTime(2026, 3, 17),
      );

      expect(record.fenHistory, hasLength(2));
      // Après e4
      expect(record.fenHistory[0],
          'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1');
      // Après e5
      expect(record.fenHistory[1],
          'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2');
    });

    test('préserve uciHistory vide sans erreur', () {
      final record = GameRecord.fromGame(
        gameId: 'game-2',
        playerId: playerId,
        whiteUsername: 'Alice',
        blackUsername: 'Bob',
        whitePlayerId: whitePlayerId,
        blackPlayerId: blackPlayerId,
        result: 'RESIGNED',
        winner: null,
        uciHistory: const [],
        finalFen:
            'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        playedAt: DateTime(2026, 3, 17),
      );

      expect(record.sanHistory, isEmpty);
      expect(record.fenHistory, isEmpty);
    });
  });

  group('GameRecord computed properties', () {
    late GameRecord record;

    setUp(() {
      record = GameRecord.fromGame(
        gameId: 'game-1',
        playerId: playerId,
        whiteUsername: 'Alice',
        blackUsername: 'Bob',
        whitePlayerId: whitePlayerId,
        blackPlayerId: blackPlayerId,
        result: 'CHECKMATE',
        winner: whitePlayerId,
        uciHistory: uciHistory,
        finalFen: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
        totalTimeSeconds: 300,
        incrementSeconds: 0,
        playedAt: DateTime(2026, 3, 17),
      );
    });

    test('isPlayerWhite retourne true quand le joueur local joue blanc', () {
      expect(record.isPlayerWhite, isTrue);
    });

    test('isPlayerWhite retourne false quand le joueur local joue noir', () {
      final blackRecord = GameRecord.fromGame(
        gameId: 'game-1',
        playerId: blackPlayerId, // local player = noir
        whiteUsername: 'Alice',
        blackUsername: 'Bob',
        whitePlayerId: whitePlayerId,
        blackPlayerId: blackPlayerId,
        result: 'CHECKMATE',
        winner: whitePlayerId,
        uciHistory: uciHistory,
        finalFen: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
        playedAt: DateTime(2026, 3, 17),
      );
      expect(blackRecord.isPlayerWhite, isFalse);
    });

    test('opponentUsername retourne le nom de l\'adversaire (noir quand local=blanc)', () {
      expect(record.opponentUsername, 'Bob');
    });
  });

  group('GameRecord sérialisation JSON', () {
    late GameRecord original;

    setUp(() {
      original = GameRecord.fromGame(
        gameId: 'game-42',
        playerId: playerId,
        whiteUsername: 'Alice',
        blackUsername: 'Bob',
        whitePlayerId: whitePlayerId,
        blackPlayerId: blackPlayerId,
        result: 'CHECKMATE',
        winner: whitePlayerId,
        uciHistory: uciHistory,
        finalFen: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
        totalTimeSeconds: 300,
        incrementSeconds: 3,
        playedAt: DateTime.utc(2026, 3, 17, 14, 30),
      );
    });

    test('toJson → fromJson roundtrip préserve tous les champs', () {
      final json = original.toJson();
      final restored = GameRecord.fromJson(json);

      expect(restored.gameId, original.gameId);
      expect(restored.playerId, original.playerId);
      expect(restored.whiteUsername, original.whiteUsername);
      expect(restored.blackUsername, original.blackUsername);
      expect(restored.whitePlayerId, original.whitePlayerId);
      expect(restored.blackPlayerId, original.blackPlayerId);
      expect(restored.result, original.result);
      expect(restored.winner, original.winner);
      expect(restored.uciHistory, original.uciHistory);
      expect(restored.sanHistory, original.sanHistory);
      expect(restored.fenHistory, original.fenHistory);
      expect(restored.finalFen, original.finalFen);
      expect(restored.totalTimeSeconds, original.totalTimeSeconds);
      expect(restored.incrementSeconds, original.incrementSeconds);
      expect(restored.playedAt, original.playedAt);
    });

    test('winner null est préservé après roundtrip', () {
      final drawRecord = GameRecord.fromGame(
        gameId: 'game-draw',
        playerId: playerId,
        whiteUsername: 'Alice',
        blackUsername: 'Bob',
        whitePlayerId: whitePlayerId,
        blackPlayerId: blackPlayerId,
        result: 'DRAW',
        winner: null,
        uciHistory: const [],
        finalFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        playedAt: DateTime.utc(2026, 3, 17),
      );

      final restored = GameRecord.fromJson(drawRecord.toJson());
      expect(restored.winner, isNull);
    });
  });
}
