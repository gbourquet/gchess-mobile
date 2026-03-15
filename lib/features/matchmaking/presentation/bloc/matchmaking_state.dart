import 'package:equatable/equatable.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_result.dart';

abstract class MatchmakingState extends Equatable {
  const MatchmakingState();

  @override
  List<Object?> get props => [];
}

class MatchmakingIdle extends MatchmakingState {
  const MatchmakingIdle();
}

class MatchmakingConnecting extends MatchmakingState {
  const MatchmakingConnecting();
}

class InQueue extends MatchmakingState {
  final int position;

  const InQueue({required this.position});

  @override
  List<Object?> get props => [position];
}

class MatchFound extends MatchmakingState {
  final MatchResult matchResult;

  const MatchFound(this.matchResult);

  @override
  List<Object?> get props => [matchResult];
}

class MatchmakingError extends MatchmakingState {
  final String message;

  const MatchmakingError(this.message);

  @override
  List<Object?> get props => [message];
}
