import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gchess_mobile/core/injection.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_game.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_move.dart';
import 'package:gchess_mobile/features/game/domain/entities/game_status.dart';
import 'package:gchess_mobile/features/game/domain/repositories/game_repository.dart';
import 'package:gchess_mobile/features/game/domain/usecases/connect_to_game.dart';
import 'package:gchess_mobile/features/game/domain/usecases/send_move.dart';
import 'package:gchess_mobile/features/game/presentation/bloc/game_state.dart';

// autoDispose par défaut — vit le temps de l'écran de jeu
final gameNotifierProvider =
    NotifierProvider.autoDispose<GameNotifier, GameState>(
  GameNotifier.new,
);

class GameNotifier extends Notifier<GameState> {
  StreamSubscription? _sub;
  late GameRepository _repo;

  @override
  GameState build() {
    _repo = getIt<GameRepository>();
    ref.onDispose(() {
      _sub?.cancel();
      _repo.disconnect(); // fire-and-forget
    });
    return const GameInitial();
  }

  Future<void> connect(String gameId) async {
    state = const GameLoading();
    final result = await getIt<ConnectToGame>()(gameId);
    result.fold(
      (f) => state = GameError(f.message),
      (_) {
        _sub?.cancel();
        _sub = _repo.eventStream.listen((streamEvent) {
          // Les 9 événements internes disparaissent — assignations directes
          if (streamEvent is GameStateSyncEvent) {
            _onGameStateSync(streamEvent.game);
          } else if (streamEvent is MoveExecutedEvent) {
            _onMoveExecuted(streamEvent);
          } else if (streamEvent is GameResignedEvent) {
            _onGameResigned(streamEvent);
          } else if (streamEvent is DrawOfferedEvent) {
            _onDrawOffered(streamEvent);
          } else if (streamEvent is DrawAcceptedEvent) {
            _onDrawAccepted(streamEvent);
          } else if (streamEvent is DrawRejectedEvent) {
            _onDrawRejected(streamEvent);
          } else if (streamEvent is TimeoutConfirmedEvent) {
            _onTimeoutConfirmed(streamEvent);
          } else if (streamEvent is TimeoutClaimRejectedEvent) {
            _onTimeoutClaimRejected(streamEvent);
          } else if (streamEvent is GameErrorEvent) {
            state = GameError(streamEvent.message);
          }
        });
      },
    );
  }

  Future<void> makeMove(ChessMove move) async {
    final result = await getIt<SendMove>()(move);
    result.fold((f) => state = GameError(f.message), (_) {});
  }

  Future<void> resign() async {
    final result = await _repo.resign();
    result.fold((f) => state = GameError(f.message), (_) {});
  }

  Future<void> offerDraw() async {
    final result = await _repo.offerDraw();
    result.fold((f) => state = GameError(f.message), (_) {
      if (state is GameActive) {
        state = (state as GameActive).copyWith(hasOfferedDraw: true);
      }
    });
  }

  Future<void> acceptDraw() async {
    final result = await _repo.acceptDraw();
    result.fold((f) => state = GameError(f.message), (_) {});
  }

  Future<void> rejectDraw() async {
    final result = await _repo.rejectDraw();
    result.fold((f) => state = GameError(f.message), (_) {
      if (state is GameActive) {
        state = (state as GameActive).copyWith(clearPendingDraw: true);
      }
    });
  }

  void tickClock(bool isWhite) {
    if (state is! GameActive) return;
    final currentState = state as GameActive;

    if (isWhite && currentState.whiteTimeRemainingMs != null) {
      final newTime = currentState.whiteTimeRemainingMs! - 1000;
      if (newTime <= 0) {
        _repo.claimTimeout();
        state = currentState.copyWith(whiteTimeRemainingMs: 0);
      } else {
        state = currentState.copyWith(whiteTimeRemainingMs: newTime);
      }
    } else if (!isWhite && currentState.blackTimeRemainingMs != null) {
      final newTime = currentState.blackTimeRemainingMs! - 1000;
      if (newTime <= 0) {
        _repo.claimTimeout();
        state = currentState.copyWith(blackTimeRemainingMs: 0);
      } else {
        state = currentState.copyWith(blackTimeRemainingMs: newTime);
      }
    }
  }

  // ── Gestionnaires privés (remplacent les événements internes) ──────────────

  void _onGameStateSync(dynamic game) {
    final chessGame = game as ChessGame;
    print(
      '🔄 _onGameStateSync: currentSide=${chessGame.currentSide}, whiteTime=${chessGame.whiteTimeRemainingMs}, blackTime=${chessGame.blackTimeRemainingMs}',
    );

    if (chessGame.gameStatus != GameStatus.active) {
      // Préserver le winner déjà calculé localement si le serveur ne le fournit pas.
      // Peut arriver quand resign/timeout est reçu avant le sync final du serveur.
      final knownWinner = state is GameEnded
          ? (state as GameEnded).game.winner
          : null;
      final finalWinner = chessGame.winner ?? knownWinner;
      final finalGame = finalWinner != chessGame.winner
          ? ChessGame(
              gameId: chessGame.gameId,
              positionFen: chessGame.positionFen,
              moveHistory: chessGame.moveHistory,
              gameStatus: chessGame.gameStatus,
              currentSide: chessGame.currentSide,
              isCheck: chessGame.isCheck,
              whitePlayer: chessGame.whitePlayer,
              blackPlayer: chessGame.blackPlayer,
              winner: finalWinner,
              totalTimeSeconds: chessGame.totalTimeSeconds,
              incrementSeconds: chessGame.incrementSeconds,
              whiteTimeRemainingMs: chessGame.whiteTimeRemainingMs,
              blackTimeRemainingMs: chessGame.blackTimeRemainingMs,
            )
          : chessGame;
      state = GameEnded(
        game: finalGame,
        result: chessGame.gameStatus.toString(),
      );
    } else {
      final isWhiteTurn = chessGame.currentSide == 'WHITE';
      final opponentTimeMs = isWhiteTurn
          ? chessGame.blackTimeRemainingMs
          : chessGame.whiteTimeRemainingMs;

      if (opponentTimeMs != null && opponentTimeMs <= 0) {
        _repo.claimTimeout();
      }

      state = GameActive(
        game: chessGame,
        totalTimeSeconds: chessGame.totalTimeSeconds,
        incrementSeconds: chessGame.incrementSeconds,
        whiteTimeRemainingMs: chessGame.whiteTimeRemainingMs,
        blackTimeRemainingMs: chessGame.blackTimeRemainingMs,
      );
    }
  }

  void _onMoveExecuted(MoveExecutedEvent event) {
    if (state is! GameActive) return;
    final currentState = state as GameActive;

    print(
      '♟️ _onMoveExecuted: currentSide=${event.currentSide}, whiteTime=${event.whiteTimeRemainingMs}, blackTime=${event.blackTimeRemainingMs}',
    );

    final isWhiteTurn = event.currentSide == 'WHITE';
    final opponentTimeMs = isWhiteTurn
        ? event.blackTimeRemainingMs
        : event.whiteTimeRemainingMs;

    if (opponentTimeMs != null && opponentTimeMs <= 0) {
      _repo.claimTimeout();
    }

    final newStatus = GameStatusExtension.fromString(event.gameStatus);
    // Pour un mat, le gagnant est le joueur dont ce n'est PAS le tour
    // (currentSide est le camp échequeté = perdant)
    final winnerId = newStatus == GameStatus.checkmate
        ? (event.currentSide == 'WHITE'
            ? currentState.game.blackPlayer.playerId
            : currentState.game.whitePlayer.playerId)
        : null;

    final updatedGame = ChessGame(
      gameId: currentState.game.gameId,
      positionFen: event.newPositionFen,
      moveHistory: [
        ...currentState.game.moveHistory,
        '${event.move.from}-${event.move.to}',
      ],
      gameStatus: newStatus,
      currentSide: event.currentSide,
      isCheck: event.isCheck,
      whitePlayer: currentState.game.whitePlayer,
      blackPlayer: currentState.game.blackPlayer,
      winner: winnerId,
      totalTimeSeconds: currentState.totalTimeSeconds,
      incrementSeconds: currentState.incrementSeconds,
      whiteTimeRemainingMs: event.whiteTimeRemainingMs,
      blackTimeRemainingMs: event.blackTimeRemainingMs,
    );

    if (updatedGame.gameStatus != GameStatus.active) {
      state = GameEnded(
        game: updatedGame,
        result: updatedGame.gameStatus.toString(),
      );
    } else {
      state = GameActive(
        game: updatedGame,
        lastMoveFrom: event.move.from,
        lastMoveTo: event.move.to,
        totalTimeSeconds: currentState.totalTimeSeconds,
        incrementSeconds: currentState.incrementSeconds,
        whiteTimeRemainingMs: event.whiteTimeRemainingMs,
        blackTimeRemainingMs: event.blackTimeRemainingMs,
      );
    }
  }

  void _onGameResigned(GameResignedEvent event) {
    print('🏳 _onGameResigned: ${event.resignedPlayerId}');

    // Le gagnant est le joueur qui n'a pas abandonné
    String _winnerId(ChessGame game) =>
        event.resignedPlayerId == game.whitePlayer.playerId
            ? game.blackPlayer.playerId
            : game.whitePlayer.playerId;

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
        winner: _winnerId(currentState.game),
        totalTimeSeconds: currentState.totalTimeSeconds,
        incrementSeconds: currentState.incrementSeconds,
        whiteTimeRemainingMs: currentState.whiteTimeRemainingMs,
        blackTimeRemainingMs: currentState.blackTimeRemainingMs,
      );
      state = GameEnded(game: updatedGame, result: 'RESIGNED');
    } else if (state is GameEnded) {
      // Le sync a pu arriver en premier avec winner=null — on corrige le winner
      final ended = state as GameEnded;
      if (ended.game.winner == null) {
        final corrected = ChessGame(
          gameId: ended.game.gameId,
          positionFen: ended.game.positionFen,
          moveHistory: ended.game.moveHistory,
          gameStatus: ended.game.gameStatus,
          currentSide: ended.game.currentSide,
          isCheck: ended.game.isCheck,
          whitePlayer: ended.game.whitePlayer,
          blackPlayer: ended.game.blackPlayer,
          winner: _winnerId(ended.game),
          totalTimeSeconds: ended.game.totalTimeSeconds,
          incrementSeconds: ended.game.incrementSeconds,
          whiteTimeRemainingMs: ended.game.whiteTimeRemainingMs,
          blackTimeRemainingMs: ended.game.blackTimeRemainingMs,
        );
        state = GameEnded(game: corrected, result: 'RESIGNED');
      }
    }
  }

  void _onDrawOffered(DrawOfferedEvent event) {
    print('🤝 _onDrawOffered: ${event.offeredByPlayerId}');
    if (state is! GameActive) return;
    final currentState = state as GameActive;
    state = currentState.copyWith(
      pendingDrawOfferId: event.offeredByPlayerId,
      hasOfferedDraw: false,
    );
  }

  void _onDrawAccepted(DrawAcceptedEvent event) {
    print('🤝 _onDrawAccepted: ${event.acceptedByPlayerId}');
    if (state is! GameActive) return;
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

    state = GameEnded(game: updatedGame, result: 'DRAW');
  }

  void _onDrawRejected(DrawRejectedEvent event) {
    print('🚫 _onDrawRejected: ${event.rejectedByPlayerId}');
    if (state is! GameActive) return;
    final currentState = state as GameActive;
    state = currentState.copyWith(hasOfferedDraw: false, clearPendingDraw: true);
  }

  void _onTimeoutConfirmed(TimeoutConfirmedEvent event) {
    print('✅ _onTimeoutConfirmed: ${event.loserPlayerId}');
    if (state is! GameActive) return;
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

    state = GameEnded(game: updatedGame, result: 'TIMEOUT');
  }

  void _onTimeoutClaimRejected(TimeoutClaimRejectedEvent event) {
    print(
      '⚠️ _onTimeoutClaimRejected: remainingMs=${event.remainingMs}',
    );
    if (state is! GameActive) return;
    final currentState = state as GameActive;

    final isWhiteTurn = currentState.game.currentSide == 'WHITE';
    if (isWhiteTurn) {
      state = currentState.copyWith(whiteTimeRemainingMs: event.remainingMs);
    } else {
      state = currentState.copyWith(blackTimeRemainingMs: event.remainingMs);
    }

    if (event.remainingMs <= 0) {
      _repo.claimTimeout();
    }
  }
}
