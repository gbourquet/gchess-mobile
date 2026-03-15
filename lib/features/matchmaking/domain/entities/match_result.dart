import 'package:equatable/equatable.dart';

class MatchResult extends Equatable {
  final String gameId;
  final String playerId;
  final String yourColor;
  final String opponentUserId;

  const MatchResult({
    required this.gameId,
    required this.playerId,
    required this.yourColor,
    required this.opponentUserId,
  });

  @override
  List<Object?> get props => [gameId, playerId, yourColor, opponentUserId];
}
