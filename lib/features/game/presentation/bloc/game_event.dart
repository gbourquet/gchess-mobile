import 'package:equatable/equatable.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_move.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();
  @override
  List<Object?> get props => [];
}

class ConnectToGameEvent extends GameEvent {
  final String gameId;
  const ConnectToGameEvent(this.gameId);
  @override
  List<Object?> get props => [gameId];
}

class MakeMoveEvent extends GameEvent {
  final ChessMove move;
  const MakeMoveEvent(this.move);
  @override
  List<Object?> get props => [move];
}

class ResignGameEvent extends GameEvent {
  const ResignGameEvent();
}

class OfferDrawEvent extends GameEvent {
  const OfferDrawEvent();
}

class AcceptDrawEvent extends GameEvent {
  const AcceptDrawEvent();
}

class RejectDrawEvent extends GameEvent {
  const RejectDrawEvent();
}

class DisconnectFromGameEvent extends GameEvent {
  const DisconnectFromGameEvent();
}

class UpdateClockTimeEvent extends GameEvent {
  final bool isWhite;
  const UpdateClockTimeEvent({required this.isWhite});
  @override
  List<Object?> get props => [isWhite];
}
