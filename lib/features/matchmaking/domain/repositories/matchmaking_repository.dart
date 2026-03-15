import 'package:dartz/dartz.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_request.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_result.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/queue_position.dart';

abstract class MatchmakingRepository {
  /// Connect to matchmaking WebSocket
  Future<Either<Failure, void>> connect();

  /// Join matchmaking queue
  Future<Either<Failure, void>> joinQueue(MatchRequest request);

  /// Leave matchmaking queue
  Future<Either<Failure, void>> leaveQueue();

  /// Disconnect from matchmaking WebSocket
  Future<Either<Failure, void>> disconnect();

  /// Stream of matchmaking events
  Stream<MatchmakingStreamEvent> get eventStream;
}

/// Base class for all matchmaking stream events
abstract class MatchmakingStreamEvent {}

/// Queue position update event
class QueuePositionEvent extends MatchmakingStreamEvent {
  final QueuePosition position;
  QueuePositionEvent(this.position);
}

/// Match found event
class MatchFoundEvent extends MatchmakingStreamEvent {
  final MatchResult matchResult;
  MatchFoundEvent(this.matchResult);
}

/// Matchmaking error event
class MatchmakingErrorEvent extends MatchmakingStreamEvent {
  final String message;
  MatchmakingErrorEvent(this.message);
}
