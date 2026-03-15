import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_game.dart';
import 'package:gchess_mobile/features/game/domain/entities/game_status.dart';
import 'package:gchess_mobile/features/game/domain/repositories/game_repository.dart';
import 'package:gchess_mobile/features/game/domain/usecases/connect_to_game.dart';
import 'package:gchess_mobile/features/game/domain/usecases/send_move.dart';
import 'package:gchess_mobile/features/game/presentation/bloc/game_event.dart';
import 'package:gchess_mobile/features/game/presentation/bloc/game_state.dart';

@injectable
class GameBloc extends Bloc<GameEvent, GameState> {
  final ConnectToGame connectToGame;
  final SendMove sendMove;
  final GameRepository repository;

  StreamSubscription? _eventSubscription;

  GameBloc({
    required this.connectToGame,
    required this.sendMove,
    required this.repository,
  }) : super(const GameInitial()) {
    on<ConnectToGameEvent>(_onConnect);
    on<MakeMoveEvent>(_onMakeMove);
    on<ResignGameEvent>(_onResign);
    on<OfferDrawEvent>(_onOfferDraw);
    on<AcceptDrawEvent>(_onAcceptDraw);
    on<RejectDrawEvent>(_onRejectDraw);
    on<DisconnectFromGameEvent>(_onDisconnect);
    on<UpdateClockTimeEvent>(_onUpdateClockTime);
    on<_GameStateSyncInternal>(_onGameStateSync);
    on<_MoveExecutedInternal>(_onMoveExecuted);
    on<_GameResignedInternal>(_onGameResigned);
    on<_DrawOfferedInternal>(_onDrawOffered);
    on<_DrawAcceptedInternal>(_onDrawAccepted);
    on<_DrawRejectedInternal>(_onDrawRejected);
    on<_TimeoutConfirmedInternal>(_onTimeoutConfirmed);
    on<_TimeoutClaimRejectedInternal>(_onTimeoutClaimRejected);
    on<_GameErrorInternal>(_onGameError);
  }

  Future<void> _onConnect(
    ConnectToGameEvent event,
    Emitter<GameState> emit,
  ) async {
    emit(const GameLoading());

    final result = await connectToGame(event.gameId);

    result.fold((failure) => emit(GameError(failure.message)), (_) {
      _eventSubscription?.cancel();
      _eventSubscription = repository.eventStream.listen((streamEvent) {
        if (streamEvent is GameStateSyncEvent) {
          add(_GameStateSyncInternal(streamEvent.game));
        } else if (streamEvent is MoveExecutedEvent) {
          add(_MoveExecutedInternal(streamEvent));
        } else if (streamEvent is GameResignedEvent) {
          add(_GameResignedInternal(streamEvent));
        } else if (streamEvent is DrawOfferedEvent) {
          add(_DrawOfferedInternal(streamEvent));
        } else if (streamEvent is DrawAcceptedEvent) {
          add(_DrawAcceptedInternal(streamEvent));
        } else if (streamEvent is DrawRejectedEvent) {
          add(_DrawRejectedInternal(streamEvent));
        } else if (streamEvent is TimeoutConfirmedEvent) {
          add(_TimeoutConfirmedInternal(streamEvent));
        } else if (streamEvent is TimeoutClaimRejectedEvent) {
          add(_TimeoutClaimRejectedInternal(streamEvent));
        } else if (streamEvent is GameErrorEvent) {
          add(_GameErrorInternal(streamEvent.message));
        }
      });
    });
  }

  Future<void> _onMakeMove(MakeMoveEvent event, Emitter<GameState> emit) async {
    final result = await sendMove(event.move);
    result.fold((failure) => emit(GameError(failure.message)), (_) {});
  }

  Future<void> _onDisconnect(
    DisconnectFromGameEvent event,
    Emitter<GameState> emit,
  ) async {
    await _eventSubscription?.cancel();
    await repository.disconnect();
    emit(const GameInitial());
  }

  void _onUpdateClockTime(UpdateClockTimeEvent event, Emitter<GameState> emit) {
    if (state is GameActive) {
      final currentState = state as GameActive;

      final isWhiteTurn = currentState.game.currentSide == 'WHITE';

      print(
        '🕐 _onUpdateClockTime: isWhiteTurn=$isWhiteTurn, whiteTime=${currentState.whiteTimeRemainingMs}, blackTime=${currentState.blackTimeRemainingMs}',
      );

      if (event.isWhite && currentState.whiteTimeRemainingMs != null) {
        final newTime = currentState.whiteTimeRemainingMs! - 1000;
        if (newTime <= 0) {
          print('⏱️ White clock reached 0');
          print('🚨 Sending claimTimeout request');
          repository.claimTimeout();
          emit(currentState.copyWith(whiteTimeRemainingMs: 0));
        } else {
          emit(currentState.copyWith(whiteTimeRemainingMs: newTime));
        }
      } else if (!event.isWhite && currentState.blackTimeRemainingMs != null) {
        final newTime = currentState.blackTimeRemainingMs! - 1000;
        if (newTime <= 0) {
          print('⏱️ Black clock reached 0');
          print('🚨 Sending claimTimeout request');
          repository.claimTimeout();
          emit(currentState.copyWith(blackTimeRemainingMs: 0));
        } else {
          emit(currentState.copyWith(blackTimeRemainingMs: newTime));
        }
      }
    }
  }

  void _onGameStateSync(_GameStateSyncInternal event, Emitter<GameState> emit) {
    final game = event.game as ChessGame;
    print(
      '🔄 _onGameStateSync: currentSide=${game.currentSide}, whiteTime=${game.whiteTimeRemainingMs}, blackTime=${game.blackTimeRemainingMs}',
    );

    if (game.gameStatus != GameStatus.active) {
      emit(GameEnded(game: game, result: game.gameStatus.toString()));
    } else {
      final isWhiteTurn = game.currentSide == 'WHITE';
      final opponentTimeMs = isWhiteTurn
          ? game.blackTimeRemainingMs
          : game.whiteTimeRemainingMs;

      if (opponentTimeMs != null && opponentTimeMs <= 0) {
        print(
          '🚨 _onGameStateSync: Opponent clock at 0 - sending claimTimeout request',
        );
        repository.claimTimeout();
      }

      emit(
        GameActive(
          game: game,
          totalTimeSeconds: game.totalTimeSeconds,
          incrementSeconds: game.incrementSeconds,
          whiteTimeRemainingMs: game.whiteTimeRemainingMs,
          blackTimeRemainingMs: game.blackTimeRemainingMs,
        ),
      );
    }
  }

  void _onMoveExecuted(_MoveExecutedInternal event, Emitter<GameState> emit) {
    if (state is GameActive) {
      final currentState = state as GameActive;
      final moveEvent = event.moveEvent as MoveExecutedEvent;

      print(
        '♟️ _onMoveExecuted: currentSide=${moveEvent.currentSide}, whiteTime=${moveEvent.whiteTimeRemainingMs}, blackTime=${moveEvent.blackTimeRemainingMs}',
      );

      final isWhiteTurn = moveEvent.currentSide == 'WHITE';
      final opponentTimeMs = isWhiteTurn
          ? moveEvent.blackTimeRemainingMs
          : moveEvent.whiteTimeRemainingMs;

      if (opponentTimeMs != null && opponentTimeMs <= 0) {
        print(
          '🚨 _onMoveExecuted: Opponent clock at 0 - sending claimTimeout request',
        );
        repository.claimTimeout();
      }

      final updatedGame = ChessGame(
        gameId: currentState.game.gameId,
        positionFen: moveEvent.newPositionFen,
        moveHistory: [
          ...currentState.game.moveHistory,
          '${moveEvent.move.from}-${moveEvent.move.to}',
        ],
        gameStatus: GameStatusExtension.fromString(moveEvent.gameStatus),
        currentSide: moveEvent.currentSide,
        isCheck: moveEvent.isCheck,
        whitePlayer: currentState.game.whitePlayer,
        blackPlayer: currentState.game.blackPlayer,
        winner: currentState.game.winner,
        totalTimeSeconds: currentState.totalTimeSeconds,
        incrementSeconds: currentState.incrementSeconds,
        whiteTimeRemainingMs: moveEvent.whiteTimeRemainingMs,
        blackTimeRemainingMs: moveEvent.blackTimeRemainingMs,
      );

      if (updatedGame.gameStatus != GameStatus.active) {
        emit(
          GameEnded(
            game: updatedGame,
            result: updatedGame.gameStatus.toString(),
          ),
        );
      } else {
        emit(
          GameActive(
            game: updatedGame,
            lastMoveFrom: moveEvent.move.from,
            lastMoveTo: moveEvent.move.to,
            totalTimeSeconds: currentState.totalTimeSeconds,
            incrementSeconds: currentState.incrementSeconds,
            whiteTimeRemainingMs: moveEvent.whiteTimeRemainingMs,
            blackTimeRemainingMs: moveEvent.blackTimeRemainingMs,
          ),
        );
      }
    }
  }

  Future<void> _onResign(ResignGameEvent event, Emitter<GameState> emit) async {
    final result = await repository.resign();
    result.fold((failure) => emit(GameError(failure.message)), (_) {});
  }

  Future<void> _onOfferDraw(
    OfferDrawEvent event,
    Emitter<GameState> emit,
  ) async {
    final result = await repository.offerDraw();
    result.fold((failure) => emit(GameError(failure.message)), (_) {
      if (state is GameActive) {
        final currentState = state as GameActive;
        emit(currentState.copyWith(hasOfferedDraw: true));
      }
    });
  }

  Future<void> _onAcceptDraw(
    AcceptDrawEvent event,
    Emitter<GameState> emit,
  ) async {
    final result = await repository.acceptDraw();
    result.fold((failure) => emit(GameError(failure.message)), (_) {});
  }

  Future<void> _onRejectDraw(
    RejectDrawEvent event,
    Emitter<GameState> emit,
  ) async {
    final result = await repository.rejectDraw();
    result.fold((failure) => emit(GameError(failure.message)), (_) {
      if (state is GameActive) {
        final currentState = state as GameActive;
        emit(currentState.copyWith(clearPendingDraw: true));
      }
    });
  }

  void _onGameResigned(_GameResignedInternal event, Emitter<GameState> emit) {
    print('🏳 _onGameResigned: ${event.event.resignedPlayerId}');
    if (state is GameActive) {
      final currentState = state as GameActive;

      final updatedGame = ChessGame(
        gameId: currentState.game.gameId,
        positionFen: currentState.game.positionFen,
        moveHistory: currentState.game.moveHistory,
        gameStatus: GameStatus.resigned,
        currentSide: currentState.game.currentSide,
        isCheck: false,
        whitePlayer: currentState.game.whitePlayer,
        blackPlayer: currentState.game.blackPlayer,
        winner: currentState.game.winner,
        totalTimeSeconds: currentState.totalTimeSeconds,
        incrementSeconds: currentState.incrementSeconds,
        whiteTimeRemainingMs: currentState.whiteTimeRemainingMs,
        blackTimeRemainingMs: currentState.blackTimeRemainingMs,
      );

      emit(GameEnded(game: updatedGame, result: 'RESIGNED'));
    }
  }

  void _onDrawOffered(_DrawOfferedInternal event, Emitter<GameState> emit) {
    print('🤝 _onDrawOffered: ${event.event.offeredByPlayerId}');
    if (state is GameActive) {
      final currentState = state as GameActive;
      final drawEvent = event.event as DrawOfferedEvent;

      emit(
        currentState.copyWith(
          pendingDrawOfferId: drawEvent.offeredByPlayerId,
          hasOfferedDraw: false,
        ),
      );
    }
  }

  void _onDrawAccepted(_DrawAcceptedInternal event, Emitter<GameState> emit) {
    print('🤝 _onDrawAccepted: ${event.event.acceptedByPlayerId}');
    if (state is GameActive) {
      final currentState = state as GameActive;

      final updatedGame = ChessGame(
        gameId: currentState.game.gameId,
        positionFen: currentState.game.positionFen,
        moveHistory: currentState.game.moveHistory,
        gameStatus: GameStatus.draw,
        currentSide: currentState.game.currentSide,
        isCheck: false,
        whitePlayer: currentState.game.whitePlayer,
        blackPlayer: currentState.game.blackPlayer,
        winner: null,
        totalTimeSeconds: currentState.totalTimeSeconds,
        incrementSeconds: currentState.incrementSeconds,
        whiteTimeRemainingMs: currentState.whiteTimeRemainingMs,
        blackTimeRemainingMs: currentState.blackTimeRemainingMs,
      );

      emit(GameEnded(game: updatedGame, result: 'DRAW'));
    }
  }

  void _onDrawRejected(_DrawRejectedInternal event, Emitter<GameState> emit) {
    print('🚫 _onDrawRejected: ${event.event.rejectedByPlayerId}');
    if (state is GameActive) {
      final currentState = state as GameActive;
      emit(
        currentState.copyWith(hasOfferedDraw: false, clearPendingDraw: true),
      );
    }
  }

  void _onGameError(_GameErrorInternal event, Emitter<GameState> emit) {
    print('❌ _onGameError: ${event.message}');
    emit(GameError(event.message));
  }

  void _onTimeoutConfirmed(
    _TimeoutConfirmedInternal event,
    Emitter<GameState> emit,
  ) {
    print('✅ _onTimeoutConfirmed: ${event.timeoutEvent.loserPlayerId}');
    if (state is GameActive) {
      final currentState = state as GameActive;

      final updatedGame = ChessGame(
        gameId: currentState.game.gameId,
        positionFen: currentState.game.positionFen,
        moveHistory: currentState.game.moveHistory,
        gameStatus: GameStatus.timeout,
        currentSide: currentState.game.currentSide,
        isCheck: false,
        whitePlayer: currentState.game.whitePlayer,
        blackPlayer: currentState.game.blackPlayer,
        winner: currentState.game.winner,
        totalTimeSeconds: currentState.totalTimeSeconds,
        incrementSeconds: currentState.incrementSeconds,
        whiteTimeRemainingMs: currentState.whiteTimeRemainingMs,
        blackTimeRemainingMs: currentState.blackTimeRemainingMs,
      );

      emit(GameEnded(game: updatedGame, result: 'TIMEOUT'));
    }
  }

  void _onTimeoutClaimRejected(
    _TimeoutClaimRejectedInternal event,
    Emitter<GameState> emit,
  ) {
    print(
      '⚠️ _onTimeoutClaimRejected: remainingMs=${event.rejectEvent.remainingMs}',
    );
    if (state is GameActive) {
      final currentState = state as GameActive;
      final rejectEvent = event.rejectEvent as TimeoutClaimRejectedEvent;

      final isWhiteTurn = currentState.game.currentSide == 'WHITE';
      final timeMs = isWhiteTurn
          ? currentState.whiteTimeRemainingMs
          : currentState.blackTimeRemainingMs;

      if (timeMs != null) {
        if (isWhiteTurn) {
          emit(
            currentState.copyWith(
              whiteTimeRemainingMs: rejectEvent.remainingMs,
            ),
          );
        } else {
          emit(
            currentState.copyWith(
              blackTimeRemainingMs: rejectEvent.remainingMs,
            ),
          );
        }

        if (rejectEvent.remainingMs <= 0) {
          print(
            '🔄 _onTimeoutClaimRejected: resending claimTimeout request (time still 0)',
          );
          repository.claimTimeout();
        }
      }
    }
  }

  @override
  Future<void> close() {
    _eventSubscription?.cancel();
    return super.close();
  }
}

// Internal events
class _GameStateSyncInternal extends GameEvent {
  final dynamic game;
  const _GameStateSyncInternal(this.game);
  @override
  List<Object?> get props => [game];
}

class _MoveExecutedInternal extends GameEvent {
  final dynamic moveEvent;
  const _MoveExecutedInternal(this.moveEvent);
  @override
  List<Object?> get props => [moveEvent];
}

class _GameErrorInternal extends GameEvent {
  final String message;
  const _GameErrorInternal(this.message);
  @override
  List<Object?> get props => [message];
}

class _GameResignedInternal extends GameEvent {
  final dynamic event;
  const _GameResignedInternal(this.event);
  @override
  List<Object?> get props => [event];
}

class _DrawOfferedInternal extends GameEvent {
  final dynamic event;
  const _DrawOfferedInternal(this.event);
  @override
  List<Object?> get props => [event];
}

class _DrawAcceptedInternal extends GameEvent {
  final dynamic event;
  const _DrawAcceptedInternal(this.event);
  @override
  List<Object?> get props => [event];
}

class _DrawRejectedInternal extends GameEvent {
  final dynamic event;
  const _DrawRejectedInternal(this.event);
  @override
  List<Object?> get props => [event];
}

class _TimeoutConfirmedInternal extends GameEvent {
  final dynamic timeoutEvent;
  const _TimeoutConfirmedInternal(this.timeoutEvent);
  @override
  List<Object?> get props => [timeoutEvent];
}

class _TimeoutClaimRejectedInternal extends GameEvent {
  final dynamic rejectEvent;
  const _TimeoutClaimRejectedInternal(this.rejectEvent);
  @override
  List<Object?> get props => [rejectEvent];
}
