import 'package:equatable/equatable.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_request.dart';

abstract class MatchmakingEvent extends Equatable {
  const MatchmakingEvent();

  @override
  List<Object?> get props => [];
}

class ConnectToMatchmakingEvent extends MatchmakingEvent {
  const ConnectToMatchmakingEvent();
}

class JoinQueueEvent extends MatchmakingEvent {
  final MatchRequest request;

  const JoinQueueEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class LeaveQueueEvent extends MatchmakingEvent {
  const LeaveQueueEvent();
}

class DisconnectFromMatchmakingEvent extends MatchmakingEvent {
  const DisconnectFromMatchmakingEvent();
}
