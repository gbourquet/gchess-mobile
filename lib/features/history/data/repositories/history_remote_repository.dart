import 'package:chess/chess.dart' as chess_lib;
import 'package:gchess_mobile/features/auth/domain/entities/user.dart';
import 'package:gchess_mobile/features/history/data/datasources/history_remote_data_source.dart';
import 'package:gchess_mobile/features/history/data/models/game_summary_dto.dart';
import 'package:gchess_mobile/features/history/data/models/move_summary_dto.dart';
import 'package:gchess_mobile/features/history/domain/entities/game_record.dart';

class HistoryRemoteRepository {
  final HistoryRemoteDataSource _dataSource;

  HistoryRemoteRepository(this._dataSource);

  /// Fetches game summaries (without move history) for the current user.
  Future<List<GameRecord>> fetchGames(User currentUser) async {
    final summaries = await _dataSource.fetchGames();
    return summaries
        .map((s) => _toPartialRecord(s, currentUser))
        .toList();
  }

  /// Fetches moves for a partial record and returns a complete GameRecord.
  Future<GameRecord> loadFullRecord(GameRecord partial) async {
    final moves = await _dataSource.fetchMoves(partial.gameId);
    final sortedMoves = List<MoveSummaryDTO>.from(moves)
      ..sort((a, b) => a.moveNumber.compareTo(b.moveNumber));

    final uciHistory = sortedMoves.map((m) => m.toUci()).toList();

    // Determine winner for CHECKMATE by replaying moves
    String? winner;
    if (partial.result.toUpperCase() == 'CHECKMATE' &&
        sortedMoves.isNotEmpty) {
      final chess = chess_lib.Chess();
      for (final m in sortedMoves) {
        final moveMap = <String, dynamic>{'from': m.from, 'to': m.to};
        if (m.promotion != null) moveMap['promotion'] = m.promotion;
        chess.move(moveMap);
      }
      // After the last move, chess.turn is the side that is in checkmate (the loser)
      winner = chess.turn == chess_lib.Color.BLACK
          ? partial.whitePlayerId
          : partial.blackPlayerId;
    }

    // Compute final FEN by replaying moves
    final chessForFen = chess_lib.Chess();
    for (final m in sortedMoves) {
      final moveMap = <String, dynamic>{'from': m.from, 'to': m.to};
      if (m.promotion != null) moveMap['promotion'] = m.promotion;
      chessForFen.move(moveMap);
    }
    final finalFen = chessForFen.fen;

    return GameRecord.fromGame(
      gameId: partial.gameId,
      playerId: partial.playerId,
      whiteUsername: partial.whiteUsername,
      blackUsername: partial.blackUsername,
      whitePlayerId: partial.whitePlayerId,
      blackPlayerId: partial.blackPlayerId,
      result: partial.result,
      winner: winner,
      uciHistory: uciHistory,
      finalFen: finalFen,
      totalTimeSeconds: partial.totalTimeSeconds,
      incrementSeconds: partial.incrementSeconds,
      playedAt: partial.playedAt,
    );
  }

  GameRecord _toPartialRecord(GameSummaryDTO summary, User currentUser) {
    final isWhite = summary.whiteUserId == currentUser.id;
    return GameRecord(
      gameId: summary.gameId,
      playerId: currentUser.id,
      whiteUsername: isWhite ? currentUser.username : 'Adversaire',
      blackUsername: isWhite ? 'Adversaire' : currentUser.username,
      whitePlayerId: summary.whiteUserId,
      blackPlayerId: summary.blackUserId,
      result: summary.status,
      winner: null,
      uciHistory: const [],
      sanHistory: const [],
      fenHistory: const [],
      finalFen:
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      totalTimeSeconds: null,
      incrementSeconds: null,
      playedAt: DateTime.now(),
      rawMoveCount: summary.moveCount,
    );
  }
}
