import 'package:equatable/equatable.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_game.dart';

abstract class GameState extends Equatable {
  const GameState();
  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {
  const GameInitial();
}

class GameLoading extends GameState {
  const GameLoading();
}

class GameActive extends GameState {
  final ChessGame game;
  final String? lastMoveFrom;
  final String? lastMoveTo;
  final String? pendingDrawOfferId;
  final bool hasOfferedDraw;
  final int? totalTimeSeconds;
  final int? incrementSeconds;
  final int? whiteTimeRemainingMs;
  final int? blackTimeRemainingMs;

  const GameActive({
    required this.game,
    this.lastMoveFrom,
    this.lastMoveTo,
    this.pendingDrawOfferId,
    this.hasOfferedDraw = false,
    this.totalTimeSeconds,
    this.incrementSeconds,
    this.whiteTimeRemainingMs,
    this.blackTimeRemainingMs,
  });

  GameActive copyWith({
    ChessGame? game,
    String? lastMoveFrom,
    String? lastMoveTo,
    String? pendingDrawOfferId,
    bool? hasOfferedDraw,
    int? totalTimeSeconds,
    int? incrementSeconds,
    int? whiteTimeRemainingMs,
    int? blackTimeRemainingMs,
    bool clearPendingDraw = false,
  }) {
    return GameActive(
      game: game ?? this.game,
      lastMoveFrom: lastMoveFrom ?? this.lastMoveFrom,
      lastMoveTo: lastMoveTo ?? this.lastMoveTo,
      pendingDrawOfferId: clearPendingDraw ? null : (pendingDrawOfferId ?? this.pendingDrawOfferId),
      hasOfferedDraw: hasOfferedDraw ?? this.hasOfferedDraw,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
      incrementSeconds: incrementSeconds ?? this.incrementSeconds,
      whiteTimeRemainingMs: whiteTimeRemainingMs ?? this.whiteTimeRemainingMs,
      blackTimeRemainingMs: blackTimeRemainingMs ?? this.blackTimeRemainingMs,
    );
  }

  @override
  List<Object?> get props => [
        game,
        lastMoveFrom,
        lastMoveTo,
        pendingDrawOfferId,
        hasOfferedDraw,
        totalTimeSeconds,
        incrementSeconds,
        whiteTimeRemainingMs,
        blackTimeRemainingMs,
      ];
}

class GameEnded extends GameState {
  final ChessGame game;
  final String result;

  const GameEnded({required this.game, required this.result});

  @override
  List<Object?> get props => [game, result];
}

class GameError extends GameState {
  final String message;
  const GameError(this.message);
  @override
  List<Object?> get props => [message];
}
