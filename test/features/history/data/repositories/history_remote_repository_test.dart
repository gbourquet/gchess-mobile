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

GameRecord _makePartialRecord({
  String gameId = 'game-1',
  String whitePlayerId = 'user-white',
  String blackPlayerId = 'user-black',
  String result = 'DRAW',
  String whiteUsername = 'Alice',
  String blackUsername = 'Adversaire',
  int rawMoveCount = 0,
}) {
  return GameRecord(
    gameId: gameId,
    playerId: 'user-white',
    whiteUsername: whiteUsername,
    blackUsername: blackUsername,
    whitePlayerId: whitePlayerId,
    blackPlayerId: blackPlayerId,
    result: result,
    winner: null,
    uciHistory: const [],
    sanHistory: const [],
    fenHistory: const [],
    finalFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    totalTimeSeconds: null,
    incrementSeconds: null,
    playedAt: DateTime.utc(2026, 3, 20),
    rawMoveCount: rawMoveCount,
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
            const GameSummaryDTO(
              gameId: 'game-1',
              whiteUserId: 'user-white',
              blackUserId: 'user-black',
              status: 'RESIGNED',
              moveCount: 10,
            ),
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

    test('le username du joueur courant (blanc) est correct', () async {
      when(() => mockDataSource.fetchGames()).thenAnswer((_) async => [
            const GameSummaryDTO(
              gameId: 'g',
              whiteUserId: 'user-white',
              blackUserId: 'user-black',
              status: 'DRAW',
              moveCount: 5,
            ),
          ]);
      final result = await repo.fetchGames(_alice);
      expect(result.first.whiteUsername, 'Alice');
      expect(result.first.blackUsername, 'Adversaire');
    });

    test('le username du joueur courant (noir) est correct', () async {
      when(() => mockDataSource.fetchGames()).thenAnswer((_) async => [
            const GameSummaryDTO(
              gameId: 'g',
              whiteUserId: 'user-white',
              blackUserId: 'user-black',
              status: 'DRAW',
              moveCount: 5,
            ),
          ]);
      final result = await repo.fetchGames(_bob);
      expect(result.first.blackUsername, 'Bob');
      expect(result.first.whiteUsername, 'Adversaire');
    });

    test('uciHistory vide dans le record partiel', () async {
      when(() => mockDataSource.fetchGames()).thenAnswer((_) async => [
            const GameSummaryDTO(
              gameId: 'g',
              whiteUserId: 'user-white',
              blackUserId: 'user-black',
              status: 'DRAW',
              moveCount: 5,
            ),
          ]);
      final result = await repo.fetchGames(_alice);
      expect(result.first.uciHistory, isEmpty);
    });

    test('plusieurs parties retournées', () async {
      when(() => mockDataSource.fetchGames()).thenAnswer((_) async => [
            const GameSummaryDTO(
              gameId: 'g1',
              whiteUserId: 'user-white',
              blackUserId: 'user-black',
              status: 'DRAW',
              moveCount: 10,
            ),
            const GameSummaryDTO(
              gameId: 'g2',
              whiteUserId: 'user-black',
              blackUserId: 'user-white',
              status: 'CHECKMATE',
              moveCount: 30,
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

    test('winner calculé pour un mat — blanc gagne (Scholar\'s mate)', () async {
      // Scholar's mate: 1.e4 e5 2.Bc4 Nc6 3.Qh5 a6 4.Qxf7#
      // After Qxf7#, it's Black's turn → Black is checkmated → White wins
      when(() => mockDataSource.fetchMoves('game-1')).thenAnswer((_) async => [
            const MoveSummaryDTO(from: 'e2', to: 'e4', moveNumber: 1),
            const MoveSummaryDTO(from: 'e7', to: 'e5', moveNumber: 2),
            const MoveSummaryDTO(from: 'f1', to: 'c4', moveNumber: 3),
            const MoveSummaryDTO(from: 'b8', to: 'c6', moveNumber: 4),
            const MoveSummaryDTO(from: 'd1', to: 'h5', moveNumber: 5),
            const MoveSummaryDTO(from: 'a7', to: 'a6', moveNumber: 6),
            const MoveSummaryDTO(from: 'h5', to: 'f7', moveNumber: 7),
          ]);
      final partial = _makePartialRecord(
        result: 'CHECKMATE',
        whitePlayerId: 'user-white',
        blackPlayerId: 'user-black',
      );
      final full = await repo.loadFullRecord(partial);
      expect(full.winner, 'user-white');
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
