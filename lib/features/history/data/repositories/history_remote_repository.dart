import 'package:chess/chess.dart' as chess_lib;
import 'package:gchess_mobile/features/auth/domain/entities/user.dart';
import 'package:gchess_mobile/features/history/data/datasources/history_remote_data_source.dart';
import 'package:gchess_mobile/features/history/data/models/game_summary_dto.dart';
import 'package:gchess_mobile/features/history/data/models/move_summary_dto.dart';
import 'package:gchess_mobile/features/history/domain/entities/game_record.dart';

class HistoryRemoteRepository {
  final HistoryRemoteDataSource _dataSource;

  HistoryRemoteRepository(this._dataSource);

  /// Fetches finished game summaries (without move history) for the current user.
  Future<List<GameRecord>> fetchGames(User currentUser) async {
    final summaries = await _dataSource.fetchGames();
    return summaries
        .where((s) => _finishedStatuses.contains(s.status.toUpperCase()))
        .map((s) => _toPartialRecord(s, currentUser))
        .toList();
  }

  /// Fetches moves for a partial record and returns a complete GameRecord.
  Future<GameRecord> loadFullRecord(GameRecord partial) async {
    final moves = await _dataSource.fetchMoves(partial.gameId);
    final sortedMoves = List<MoveSummaryDTO>.from(moves)
      ..sort((a, b) => a.moveNumber.compareTo(b.moveNumber));

    final uciHistory = sortedMoves.map((m) => m.toUci()).toList();

    // Compute final FEN by replaying moves
    final chessForFen = chess_lib.Chess();
    for (final m in sortedMoves) {
      final moveMap = <String, dynamic>{'from': m.from, 'to': m.to};
      if (m.promotion != null) moveMap['promotion'] = m.promotion;
      chessForFen.move(moveMap);
    }
    final finalFen = chessForFen.fen;

    // Extract move times if at least one move has timing data
    final hasTimes = sortedMoves.any((m) => m.timeSpentMs != null);
    final moveTimes = hasTimes
        ? sortedMoves.map((m) => m.timeSpentMs).toList()
        : null;

    return GameRecord.fromGame(
      gameId: partial.gameId,
      playerId: partial.playerId,
      whiteUsername: partial.whiteUsername,
      blackUsername: partial.blackUsername,
      whitePlayerId: partial.whitePlayerId,
      blackPlayerId: partial.blackPlayerId,
      result: partial.result,
      winner: partial.winner,
      uciHistory: uciHistory,
      finalFen: finalFen,
      totalTimeSeconds: partial.totalTimeSeconds,
      incrementSeconds: partial.incrementSeconds,
      playedAt: partial.playedAt,
      whiteTimeRemainingMs: partial.whiteTimeRemainingMs,
      blackTimeRemainingMs: partial.blackTimeRemainingMs,
      moveTimes: moveTimes,
    );
  }

  static const _finishedStatuses = {
    'CHECKMATE', 'STALEMATE', 'DRAW', 'RESIGNED', 'TIMEOUT',
    'DRAW_BY_REPETITION', 'DRAW_BY_FIFTY_MOVES', 'DRAW_BY_INSUFFICIENT_MATERIAL',
  };

  GameRecord _toPartialRecord(GameSummaryDTO summary, User currentUser) {
    final isWhite = summary.whiteUserId == currentUser.id;
    // Use backend usernames when available, fallback to current user's name
    final hasWhiteUsername =
        summary.whiteUsername.isNotEmpty && summary.whiteUsername != '?';
    final hasBlackUsername =
        summary.blackUsername.isNotEmpty && summary.blackUsername != '?';
    final whiteUsername = hasWhiteUsername
        ? summary.whiteUsername
        : (isWhite ? currentUser.username : 'Adversaire');
    final blackUsername = hasBlackUsername
        ? summary.blackUsername
        : (isWhite ? 'Adversaire' : currentUser.username);
    return GameRecord(
      gameId: summary.gameId,
      playerId: currentUser.id,
      whiteUsername: whiteUsername,
      blackUsername: blackUsername,
      whitePlayerId: summary.whiteUserId,
      blackPlayerId: summary.blackUserId,
      result: summary.status,
      winner: summary.winnerUserId,
      uciHistory: const [],
      sanHistory: const [],
      fenHistory: const [],
      finalFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      totalTimeSeconds: summary.totalTimeSeconds,
      incrementSeconds: summary.incrementSeconds,
      playedAt: summary.playedAt ?? DateTime.now(),
      rawMoveCount: summary.moveCount,
      whiteTimeRemainingMs: summary.whiteTimeRemainingMs,
      blackTimeRemainingMs: summary.blackTimeRemainingMs,
    );
  }
}
