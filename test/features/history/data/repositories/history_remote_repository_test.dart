import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gchess_mobile/features/auth/domain/entities/user.dart';
import 'package:gchess_mobile/features/history/data/datasources/history_remote_data_source.dart';
import 'package:gchess_mobile/features/history/data/models/game_summary_dto.dart';
import 'package:gchess_mobile/features/history/data/models/move_summary_dto.dart';
import 'package:gchess_mobile/features/history/data/repositories/history_remote_repository.dart';
import 'package:gchess_mobile/features/history/domain/entities/game_record.dart';

class _MockDataSource extends Mock implements HistoryRemoteDataSource {}

const _alice = User(id: 'user-white', username: 'Alice', email: 'a@a.com');
const _bob = User(id: 'user-black', username: 'Bob', email: 'b@b.com');

GameSummaryDTO _makeSummary({
  String gameId = 'game-1',
  String whiteUserId = 'user-white',
  String blackUserId = 'user-black',
  String whiteUsername = 'Alice',
  String blackUsername = 'Bob',
  String status = 'DRAW',
  int moveCount = 5,
  String? winnerUserId,
  int? whiteTimeRemainingMs,
  int? blackTimeRemainingMs,
  int? totalTimeSeconds,
  int? incrementSeconds,
}) {
  return GameSummaryDTO(
    gameId: gameId,
    whiteUserId: whiteUserId,
    blackUserId: blackUserId,
    whiteUsername: whiteUsername,
    blackUsername: blackUsername,
    status: status,
    moveCount: moveCount,
    winnerUserId: winnerUserId,
    whiteTimeRemainingMs: whiteTimeRemainingMs,
    blackTimeRemainingMs: blackTimeRemainingMs,
    totalTimeSeconds: totalTimeSeconds,
    incrementSeconds: incrementSeconds,
  );
}

GameRecord _makePartialRecord({
  String gameId = 'game-1',
  String whitePlayerId = 'user-white',
  String blackPlayerId = 'user-black',
  String result = 'DRAW',
  String whiteUsername = 'Alice',
  String blackUsername = 'Adversaire',
  int rawMoveCount = 0,
  String? winner,
  int? whiteTimeRemainingMs,
  int? blackTimeRemainingMs,
}) {
  return GameRecord(
    gameId: gameId,
    playerId: 'user-white',
    whiteUsername: whiteUsername,
    blackUsername: blackUsername,
    whitePlayerId: whitePlayerId,
    blackPlayerId: blackPlayerId,
    result: result,
    winner: winner,
    uciHistory: const [],
    sanHistory: const [],
    fenHistory: const [],
    finalFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    totalTimeSeconds: null,
    incrementSeconds: null,
    playedAt: DateTime.utc(2026, 3, 20),
    rawMoveCount: rawMoveCount,
    whiteTimeRemainingMs: whiteTimeRemainingMs,
    blackTimeRemainingMs: blackTimeRemainingMs,
  );
}

void main() {
  late _MockDataSource mockDataSource;
  late HistoryRemoteRepository repo;

  setUp(() {
    mockDataSource = _MockDataSource();
    repo = HistoryRemoteRepository(mockDataSource);
  });

  group('fetchGames', () {
    test('retourne une liste vide si l\'API renvoie []', () async {
      when(() => mockDataSource.fetchGames()).thenAnswer((_) async => []);
      final result = await repo.fetchGames(_alice);
      expect(result, isEmpty);
    });

    test('construit un GameRecord partiel par partie', () async {
      when(() => mockDataSource.fetchGames()).thenAnswer((_) async => [
            _makeSummary(gameId: 'game-1', status: 'RESIGNED', moveCount: 10),
          ]);
      final result = await repo.fetchGames(_alice);
      expect(result, hasLength(1));
      final r = result.first;
      expect(r.gameId, 'game-1');
      expect(r.playerId, 'user-white');
      expect(r.whitePlayerId, 'user-white');
      expect(r.blackPlayerId, 'user-black');
      expect(r.result, 'RESIGNED');
      expect(r.rawMoveCount, 10);
    });

    test('le username vient du DTO (blanc)', () async {
      when(() => mockDataSource.fetchGames()).thenAnswer((_) async => [
            _makeSummary(whiteUsername: 'Alice', blackUsername: 'Bob'),
          ]);
      final result = await repo.fetchGames(_alice);
      expect(result.first.whiteUsername, 'Alice');
      expect(result.first.blackUsername, 'Bob');
    });

    test('le username vient du DTO (noir)', () async {
      when(() => mockDataSource.fetchGames()).thenAnswer((_) async => [
            _makeSummary(whiteUsername: 'Alice', blackUsername: 'Bob'),
          ]);
      final result = await repo.fetchGames(_bob);
      expect(result.first.whiteUsername, 'Alice');
      expect(result.first.blackUsername, 'Bob');
    });

    test('winner provenant de winnerUserId dans le record partiel', () async {
      when(() => mockDataSource.fetchGames()).thenAnswer((_) async => [
            _makeSummary(status: 'CHECKMATE', winnerUserId: 'user-white'),
          ]);
      final result = await repo.fetchGames(_alice);
      expect(result.first.winner, 'user-white');
    });

    test('winner null quand winnerUserId absent (nulle)', () async {
      when(() => mockDataSource.fetchGames()).thenAnswer((_) async => [
            _makeSummary(status: 'DRAW'),
          ]);
      final result = await repo.fetchGames(_alice);
      expect(result.first.winner, isNull);
    });

    test('whiteTimeRemainingMs et blackTimeRemainingMs dans le record partiel',
        () async {
      when(() => mockDataSource.fetchGames()).thenAnswer((_) async => [
            _makeSummary(
              status: 'CHECKMATE',
              winnerUserId: 'user-white',
              whiteTimeRemainingMs: 45000,
              blackTimeRemainingMs: 12300,
            ),
          ]);
      final result = await repo.fetchGames(_alice);
      expect(result.first.whiteTimeRemainingMs, 45000);
      expect(result.first.blackTimeRemainingMs, 12300);
    });

    test('totalTimeSeconds et incrementSeconds dans le record partiel',
        () async {
      when(() => mockDataSource.fetchGames()).thenAnswer((_) async => [
            _makeSummary(
              status: 'DRAW',
              totalTimeSeconds: 300,
              incrementSeconds: 5,
            ),
          ]);
      final result = await repo.fetchGames(_alice);
      expect(result.first.totalTimeSeconds, 300);
      expect(result.first.incrementSeconds, 5);
    });

    test('les parties IN_PROGRESS sont filtrées', () async {
      when(() => mockDataSource.fetchGames()).thenAnswer((_) async => [
            _makeSummary(gameId: 'g1', status: 'DRAW'),
            _makeSummary(gameId: 'g2', status: 'IN_PROGRESS'),
            _makeSummary(gameId: 'g3', status: 'CHECKMATE', winnerUserId: 'user-white'),
          ]);
      final result = await repo.fetchGames(_alice);
      expect(result, hasLength(2));
      expect(result.map((r) => r.gameId), containsAll(['g1', 'g3']));
    });

    test('uciHistory vide dans le record partiel', () async {
      when(() => mockDataSource.fetchGames()).thenAnswer((_) async => [
            _makeSummary(),
          ]);
      final result = await repo.fetchGames(_alice);
      expect(result.first.uciHistory, isEmpty);
    });

    test('plusieurs parties terminées retournées', () async {
      when(() => mockDataSource.fetchGames()).thenAnswer((_) async => [
            _makeSummary(gameId: 'g1', status: 'DRAW'),
            _makeSummary(
              gameId: 'g2',
              whiteUserId: 'user-black',
              blackUserId: 'user-white',
              status: 'CHECKMATE',
              winnerUserId: 'user-black',
            ),
          ]);
      final result = await repo.fetchGames(_alice);
      expect(result, hasLength(2));
      expect(result[0].gameId, 'g1');
      expect(result[1].gameId, 'g2');
    });
  });

  group('loadFullRecord', () {
    test('reconstruit uciHistory depuis les coups', () async {
      when(() => mockDataSource.fetchMoves('game-1')).thenAnswer((_) async => [
            const MoveSummaryDTO(from: 'e2', to: 'e4', moveNumber: 1),
            const MoveSummaryDTO(from: 'e7', to: 'e5', moveNumber: 2),
          ]);
      final partial = _makePartialRecord(result: 'DRAW');
      final full = await repo.loadFullRecord(partial);
      expect(full.uciHistory, ['e2-e4', 'e7-e5']);
    });

    test('les coups sont triés par moveNumber', () async {
      when(() => mockDataSource.fetchMoves('game-1')).thenAnswer((_) async => [
            const MoveSummaryDTO(from: 'e7', to: 'e5', moveNumber: 2),
            const MoveSummaryDTO(from: 'e2', to: 'e4', moveNumber: 1),
          ]);
      final partial = _makePartialRecord(result: 'DRAW');
      final full = await repo.loadFullRecord(partial);
      expect(full.uciHistory.first, 'e2-e4');
    });

    test('promotion est incluse dans uciHistory', () async {
      // Set up a board position where e7-e8=Q is possible
      // We need a pawn on e7 - use a simpler promotion sequence
      when(() => mockDataSource.fetchMoves('game-1')).thenAnswer((_) async => [
            const MoveSummaryDTO(
                from: 'e7', to: 'e8', moveNumber: 1, promotion: 'q'),
          ]);
      final partial = _makePartialRecord(result: 'CHECKMATE');
      final full = await repo.loadFullRecord(partial);
      expect(full.uciHistory.first, 'e7-e8-q');
    });

    test('winner null pour une nulle', () async {
      when(() => mockDataSource.fetchMoves('game-1')).thenAnswer((_) async => [
            const MoveSummaryDTO(from: 'e2', to: 'e4', moveNumber: 1),
          ]);
      final partial = _makePartialRecord(result: 'DRAW');
      final full = await repo.loadFullRecord(partial);
      expect(full.winner, isNull);
    });

    test('winner null pour un abandon', () async {
      when(() => mockDataSource.fetchMoves('game-1')).thenAnswer((_) async => [
            const MoveSummaryDTO(from: 'e2', to: 'e4', moveNumber: 1),
          ]);
      final partial = _makePartialRecord(result: 'RESIGNED');
      final full = await repo.loadFullRecord(partial);
      expect(full.winner, isNull);
    });

    test('winner provenant du record partiel (depuis API)', () async {
      when(() => mockDataSource.fetchMoves('game-1')).thenAnswer((_) async => [
            const MoveSummaryDTO(from: 'e2', to: 'e4', moveNumber: 1),
            const MoveSummaryDTO(from: 'e7', to: 'e5', moveNumber: 2),
          ]);
      final partial = _makePartialRecord(
        result: 'CHECKMATE',
        winner: 'user-white',
      );
      final full = await repo.loadFullRecord(partial);
      expect(full.winner, 'user-white');
    });

    test('moveTimes extraits depuis les coups', () async {
      when(() => mockDataSource.fetchMoves('game-1')).thenAnswer((_) async => [
            const MoveSummaryDTO(
                from: 'e2', to: 'e4', moveNumber: 1, timeSpentMs: 3500),
            const MoveSummaryDTO(
                from: 'e7', to: 'e5', moveNumber: 2, timeSpentMs: 2100),
          ]);
      final partial = _makePartialRecord(result: 'DRAW');
      final full = await repo.loadFullRecord(partial);
      expect(full.moveTimes, [3500, 2100]);
    });

    test('moveTimes null si aucun coup n\'a de temps', () async {
      when(() => mockDataSource.fetchMoves('game-1')).thenAnswer((_) async => [
            const MoveSummaryDTO(from: 'e2', to: 'e4', moveNumber: 1),
            const MoveSummaryDTO(from: 'e7', to: 'e5', moveNumber: 2),
          ]);
      final partial = _makePartialRecord(result: 'DRAW');
      final full = await repo.loadFullRecord(partial);
      expect(full.moveTimes, isNull);
    });

    test('sanHistory non vide après chargement', () async {
      when(() => mockDataSource.fetchMoves('game-1')).thenAnswer((_) async => [
            const MoveSummaryDTO(from: 'e2', to: 'e4', moveNumber: 1),
            const MoveSummaryDTO(from: 'e7', to: 'e5', moveNumber: 2),
          ]);
      final partial = _makePartialRecord(result: 'DRAW');
      final full = await repo.loadFullRecord(partial);
      expect(full.sanHistory, isNotEmpty);
    });

    test('fenHistory a autant d\'entrées que de coups', () async {
      when(() => mockDataSource.fetchMoves('game-1')).thenAnswer((_) async => [
            const MoveSummaryDTO(from: 'e2', to: 'e4', moveNumber: 1),
            const MoveSummaryDTO(from: 'e7', to: 'e5', moveNumber: 2),
          ]);
      final partial = _makePartialRecord(result: 'DRAW');
      final full = await repo.loadFullRecord(partial);
      expect(full.fenHistory.length, 2);
    });

    test('partie sans coups — histories vides', () async {
      when(() => mockDataSource.fetchMoves('game-1'))
          .thenAnswer((_) async => []);
      final partial = _makePartialRecord(result: 'RESIGNED');
      final full = await repo.loadFullRecord(partial);
      expect(full.uciHistory, isEmpty);
      expect(full.sanHistory, isEmpty);
      expect(full.fenHistory, isEmpty);
    });

    test('conserve whiteTimeRemainingMs et blackTimeRemainingMs', () async {
      when(() => mockDataSource.fetchMoves('game-1')).thenAnswer((_) async => [
            const MoveSummaryDTO(from: 'e2', to: 'e4', moveNumber: 1),
          ]);
      final partial = _makePartialRecord(
        result: 'RESIGNED',
        whiteTimeRemainingMs: 45000,
        blackTimeRemainingMs: 12300,
      );
      final full = await repo.loadFullRecord(partial);
      expect(full.whiteTimeRemainingMs, 45000);
      expect(full.blackTimeRemainingMs, 12300);
    });

    test('conserve les métadonnées du record partiel', () async {
      when(() => mockDataSource.fetchMoves('game-1')).thenAnswer((_) async => [
            const MoveSummaryDTO(from: 'e2', to: 'e4', moveNumber: 1),
          ]);
      final partial = _makePartialRecord(
        whiteUsername: 'Alice',
        blackUsername: 'Adversaire',
        result: 'DRAW',
      );
      final full = await repo.loadFullRecord(partial);
      expect(full.whiteUsername, 'Alice');
      expect(full.blackUsername, 'Adversaire');
      expect(full.result, 'DRAW');
    });
  });
}
