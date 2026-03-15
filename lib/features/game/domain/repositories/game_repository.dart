import 'package:dartz/dartz.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_game.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_move.dart';

abstract class GameRepository {
  /// Connect to game WebSocket
  Future<Either<Failure, void>> connect(String gameId);

  /// Send a move
  Future<Either<Failure, void>> sendMove(ChessMove move);

  /// Resign from game
  Future<Either<Failure, void>> resign();

  /// Offer a draw to opponent
  Future<Either<Failure, void>> offerDraw();

  /// Accept a draw offer from opponent
  Future<Either<Failure, void>> acceptDraw();

  /// Reject a draw offer from opponent
  Future<Either<Failure, void>> rejectDraw();

  /// Claim opponent timeout
  Future<Either<Failure, void>> claimTimeout();

  /// Disconnect from game WebSocket
  Future<Either<Failure, void>> disconnect();

  /// Stream of game events
  Stream<GameStreamEvent> get eventStream;
}

/// Base class for all game stream events
abstract class GameStreamEvent {}

/// Game state sync event (initial state when connecting)
class GameStateSyncEvent extends GameStreamEvent {
  final ChessGame game;
  GameStateSyncEvent(this.game);
}

/// Move executed event
class MoveExecutedEvent extends GameStreamEvent {
  final ChessMove move;
  final String newPositionFen;
  final String gameStatus;
  final String currentSide;
  final bool isCheck;
  final int? whiteTimeRemainingMs;
  final int? blackTimeRemainingMs;

  MoveExecutedEvent({
    required this.move,
    required this.newPositionFen,
    required this.gameStatus,
    required this.currentSide,
    required this.isCheck,
    this.whiteTimeRemainingMs,
    this.blackTimeRemainingMs,
  });
}

/// Move rejected event
class MoveRejectedEvent extends GameStreamEvent {
  final String reason;
  MoveRejectedEvent(this.reason);
}

/// Player disconnected event
class PlayerDisconnectedEvent extends GameStreamEvent {
  final String playerId;
  PlayerDisconnectedEvent(this.playerId);
}

/// Player reconnected event
class PlayerReconnectedEvent extends GameStreamEvent {
  final String playerId;
  PlayerReconnectedEvent(this.playerId);
}

/// Game error event
class GameErrorEvent extends GameStreamEvent {
  final String message;
  GameErrorEvent(this.message);
}

/// Game resigned event - a player has resigned
class GameResignedEvent extends GameStreamEvent {
  final String resignedPlayerId;
  final String gameStatus;

  GameResignedEvent({required this.resignedPlayerId, required this.gameStatus});
}

/// Draw offered event - opponent offers a draw
class DrawOfferedEvent extends GameStreamEvent {
  final String offeredByPlayerId;

  DrawOfferedEvent({required this.offeredByPlayerId});
}

/// Draw accepted event - draw offer has been accepted
class DrawAcceptedEvent extends GameStreamEvent {
  final String acceptedByPlayerId;
  final String gameStatus;

  DrawAcceptedEvent({
    required this.acceptedByPlayerId,
    required this.gameStatus,
  });
}

/// Draw rejected event - draw offer has been rejected
class DrawRejectedEvent extends GameStreamEvent {
  final String rejectedByPlayerId;

  DrawRejectedEvent({required this.rejectedByPlayerId});
}

/// Timeout confirmed event - game ended due to timeout
class TimeoutConfirmedEvent extends GameStreamEvent {
  final String loserPlayerId;
  final String gameStatus;

  TimeoutConfirmedEvent({
    required this.loserPlayerId,
    required this.gameStatus,
  });
}

/// Timeout claim rejected event - opponent still has time
class TimeoutClaimRejectedEvent extends GameStreamEvent {
  final int remainingMs;

  TimeoutClaimRejectedEvent({required this.remainingMs});
}
