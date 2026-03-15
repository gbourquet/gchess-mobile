import 'package:equatable/equatable.dart';
import 'package:gchess_mobile/features/game/domain/entities/game_status.dart';
import 'package:gchess_mobile/features/game/domain/entities/player.dart';

class ChessGame extends Equatable {
  final String gameId;
  final String positionFen;
  final List<String> moveHistory;
  final GameStatus gameStatus;
  final String currentSide;
  final bool isCheck;
  final Player whitePlayer;
  final Player blackPlayer;
  final String? winner;
  final int? totalTimeSeconds;
  final int? incrementSeconds;
  final int? whiteTimeRemainingMs;
  final int? blackTimeRemainingMs;

  const ChessGame({
    required this.gameId,
    required this.positionFen,
    required this.moveHistory,
    required this.gameStatus,
    required this.currentSide,
    required this.isCheck,
    required this.whitePlayer,
    required this.blackPlayer,
    this.winner,
    this.totalTimeSeconds,
    this.incrementSeconds,
    this.whiteTimeRemainingMs,
    this.blackTimeRemainingMs,
  });

  @override
  List<Object?> get props => [
        gameId,
        positionFen,
        moveHistory,
        gameStatus,
        currentSide,
        isCheck,
        whitePlayer,
        blackPlayer,
        winner,
        totalTimeSeconds,
        incrementSeconds,
        whiteTimeRemainingMs,
        blackTimeRemainingMs,
      ];
}
