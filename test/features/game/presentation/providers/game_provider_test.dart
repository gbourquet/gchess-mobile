import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/core/injection.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_game.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_move.dart';
import 'package:gchess_mobile/features/game/domain/entities/game_status.dart';
import 'package:gchess_mobile/features/game/domain/entities/player.dart';
import 'package:gchess_mobile/features/game/domain/repositories/game_repository.dart';
import 'package:gchess_mobile/features/game/domain/usecases/connect_to_game.dart';
import 'package:gchess_mobile/features/game/domain/usecases/send_move.dart';
import 'package:gchess_mobile/features/game/presentation/bloc/game_state.dart';
import 'package:gchess_mobile/features/game/presentation/providers/game_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';

class MockConnectToGame extends Mock implements ConnectToGame {}

class MockSendMove extends Mock implements SendMove {}

class MockGameRepository extends Mock implements GameRepository {
  final _eventController = StreamController<GameStreamEvent>.broadcast();

  @override
  Stream<GameStreamEvent> get eventStream => _eventController.stream;

  void addEvent(GameStreamEvent event) => _eventController.add(event);

  @override
  Future<Either<Failure, void>> connect(String gameId) =>
      super.noSuchMethod(Invocation.method(#connect, [gameId]));

  @override
  Future<Either<Failure, void>> sendMove(ChessMove move) =>
      super.noSuchMethod(Invocation.method(#sendMove, [move]));

  @override
  Future<Either<Failure, void>> resign() =>
      super.noSuchMethod(Invocation.method(#resign, []));

  @override
  Future<Either<Failure, void>> offerDraw() =>
      super.noSuchMethod(Invocation.method(#offerDraw, []));

  @override
  Future<Either<Failure, void>> acceptDraw() =>
      super.noSuchMethod(Invocation.method(#acceptDraw, []));

  @override
  Future<Either<Failure, void>> rejectDraw() =>
      super.noSuchMethod(Invocation.method(#rejectDraw, []));

  @override
  Future<Either<Failure, void>> claimTimeout() =>
      super.noSuchMethod(Invocation.method(#claimTimeout, []));

  @override
  Future<Either<Failure, void>> disconnect() =>
      super.noSuchMethod(Invocation.method(#disconnect, []));

  void close() => _eventController.close();
}

void main() {
  late ProviderContainer container;
  late MockConnectToGame mockConnectToGame;
  late MockSendMove mockSendMove;
  late MockGameRepository mockGameRepository;

  const tGameId = 'game123';
  const tChessMove = ChessMove(from: 'e2', to: 'e4');

  const tWhitePlayer = Player(
    playerId: 'player1',
    userId: 'user1',
    username: 'White',
    color: 'WHITE',
  );

  const tBlackPlayer = Player(
    playerId: 'player2',
    userId: 'user2',
    username: 'Black',
    color: 'BLACK',
  );

  const tActiveGame = ChessGame(
    gameId: tGameId,
    positionFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR',
    moveHistory: [],
    gameStatus: GameStatus.active,
    currentSide: 'WHITE',
    isCheck: false,
    whitePlayer: tWhitePlayer,
    blackPlayer: tBlackPlayer,
    totalTimeSeconds: 600,
    incrementSeconds: 0,
    whiteTimeRemainingMs: 600000,
    blackTimeRemainingMs: 600000,
  );

  setUpAll(() {
    registerFallbackValue(tChessMove);
    registerFallbackValue(tGameId);
  });

  setUp(() {
    getIt.reset();

    mockConnectToGame = MockConnectToGame();
    mockSendMove = MockSendMove();
    mockGameRepository = MockGameRepository();

    when(
      () => mockGameRepository.disconnect(),
    ).thenAnswer((_) async => const Right(null));

    getIt.registerFactory<ConnectToGame>(() => mockConnectToGame);
    getIt.registerFactory<SendMove>(() => mockSendMove);
    getIt.registerFactory<GameRepository>(() => mockGameRepository);

    container = ProviderContainer();
  });

  // Dispose du container avant que getIt soit réinitialisé dans le prochain setUp
  tearDown(() {
    mockGameRepository.close();
    container.dispose();
  });

  group('GameNotifier', () {
    test('build() should return GameInitial', () {
      final notifier = container.read(gameNotifierProvider.notifier);
      final state = container.read(gameNotifierProvider);

      expect(state, const GameInitial());
    });

    test('connect() should transition to GameLoading on start', () async {
      when(
        () => mockConnectToGame(any()),
      ).thenAnswer((_) async => const Right(null));

      final notifier = container.read(gameNotifierProvider.notifier);
      final connectFuture = notifier.connect(tGameId);

      expect(container.read(gameNotifierProvider), const GameLoading());
      await connectFuture;

      verify(() => mockConnectToGame(tGameId)).called(1);
    });

    test('connect() should transition to GameError on failure', () async {
      when(() => mockConnectToGame(any())).thenAnswer(
        (_) async => const Left(WebSocketFailure('Connection failed')),
      );

      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.connect(tGameId);

      expect(container.read(gameNotifierProvider), isA<GameError>());
      verify(() => mockConnectToGame(tGameId)).called(1);
    });

    test('makeMove() should succeed', () async {
      when(
        () => mockSendMove(any()),
      ).thenAnswer((_) async => const Right(null));

      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.makeMove(tChessMove);

      verify(() => mockSendMove(tChessMove)).called(1);
    });

    test('makeMove() should fail', () async {
      when(() => mockSendMove(any())).thenAnswer(
        (_) async => const Left(WebSocketFailure('Failed to send move')),
      );

      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.makeMove(tChessMove);

      expect(container.read(gameNotifierProvider), isA<GameError>());
    });

    test('resign() should fail', () async {
      when(() => mockGameRepository.resign()).thenAnswer(
        (_) async => const Left(WebSocketFailure('Failed to resign')),
      );

      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.resign();

      expect(container.read(gameNotifierProvider), isA<GameError>());
    });

    test('offerDraw() should fail', () async {
      when(() => mockGameRepository.offerDraw()).thenAnswer(
        (_) async => const Left(WebSocketFailure('Failed to offer draw')),
      );

      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.offerDraw();

      expect(container.read(gameNotifierProvider), isA<GameError>());
    });

    test('rejectDraw() should succeed', () async {
      when(
        () => mockConnectToGame(any()),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockGameRepository.rejectDraw(),
      ).thenAnswer((_) async => const Right(null));

      // Maintenir le provider vivant (autoDispose) pendant toute la durée du test
      final sub = container.listen(gameNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.connect(tGameId);

      final syncEvent = GameStateSyncEvent(tActiveGame);
      mockGameRepository.addEvent(syncEvent);

      await Future.delayed(const Duration(milliseconds: 100));

      await notifier.rejectDraw();

      final state = container.read(gameNotifierProvider);
      expect(state, isA<GameActive>());
    });

    test('tickClock(isWhite: true) with 5000ms remaining', () async {
      when(
        () => mockConnectToGame(any()),
      ).thenAnswer((_) async => const Right(null));

      // Maintenir le provider vivant (autoDispose) pendant toute la durée du test
      final sub = container.listen(gameNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.connect(tGameId);

      final syncEvent = GameStateSyncEvent(tActiveGame);
      mockGameRepository.addEvent(syncEvent);

      await Future.delayed(const Duration(milliseconds: 100));

      notifier.tickClock(true);

      final state = container.read(gameNotifierProvider);
      expect(state, isA<GameActive>());
    });

    test(
      'tickClock(isWhite: true) with <= 1000ms should call claimTimeout',
      () async {
        const gameWithLowTime = ChessGame(
          gameId: tGameId,
          positionFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR',
          moveHistory: [],
          gameStatus: GameStatus.active,
          currentSide: 'WHITE',
          isCheck: false,
          whitePlayer: tWhitePlayer,
          blackPlayer: tBlackPlayer,
          totalTimeSeconds: 600,
          incrementSeconds: 0,
          whiteTimeRemainingMs: 500,
          blackTimeRemainingMs: 600000,
        );

        when(
          () => mockConnectToGame(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGameRepository.claimTimeout(),
        ).thenAnswer((_) async => const Right(null));

        // Maintenir le provider vivant (autoDispose) pendant toute la durée du test
        final sub = container.listen(gameNotifierProvider, (_, __) {});
        addTearDown(sub.close);

        final notifier = container.read(gameNotifierProvider.notifier);
        await notifier.connect(tGameId);

        final syncEvent = GameStateSyncEvent(gameWithLowTime);
        mockGameRepository.addEvent(syncEvent);

        await Future.delayed(const Duration(milliseconds: 100));

        notifier.tickClock(true);

        verify(() => mockGameRepository.claimTimeout()).called(1);
      },
    );

    test('tickClock(isWhite: false) decrements black time', () async {
      when(
        () => mockConnectToGame(any()),
      ).thenAnswer((_) async => const Right(null));

      final sub = container.listen(gameNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.connect(tGameId);

      final syncEvent = GameStateSyncEvent(tActiveGame);
      mockGameRepository.addEvent(syncEvent);
      await Future.delayed(const Duration(milliseconds: 100));

      notifier.tickClock(false);

      final state = container.read(gameNotifierProvider) as GameActive;
      expect(state.blackTimeRemainingMs, 599000);
    });

    test(
      'tickClock(isWhite: false) with <= 1000ms calls claimTimeout',
      () async {
        const gameWithLowBlackTime = ChessGame(
          gameId: tGameId,
          positionFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR',
          moveHistory: [],
          gameStatus: GameStatus.active,
          currentSide: 'WHITE',
          isCheck: false,
          whitePlayer: tWhitePlayer,
          blackPlayer: tBlackPlayer,
          totalTimeSeconds: 600,
          incrementSeconds: 0,
          whiteTimeRemainingMs: 600000,
          blackTimeRemainingMs: 500,
        );

        when(
          () => mockConnectToGame(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGameRepository.claimTimeout(),
        ).thenAnswer((_) async => const Right(null));

        final sub = container.listen(gameNotifierProvider, (_, __) {});
        addTearDown(sub.close);

        final notifier = container.read(gameNotifierProvider.notifier);
        await notifier.connect(tGameId);

        mockGameRepository.addEvent(GameStateSyncEvent(gameWithLowBlackTime));
        await Future.delayed(const Duration(milliseconds: 100));

        notifier.tickClock(false);

        verify(() => mockGameRepository.claimTimeout()).called(1);
      },
    );

    test('tickClock when state is not GameActive is a no-op', () {
      final notifier = container.read(gameNotifierProvider.notifier);
      notifier.tickClock(true);
      expect(container.read(gameNotifierProvider), isA<GameInitial>());
    });

    test('resign() success does not change state', () async {
      when(
        () => mockGameRepository.resign(),
      ).thenAnswer((_) async => const Right(null));

      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.resign();

      expect(container.read(gameNotifierProvider), isA<GameInitial>());
    });

    test('acceptDraw() success does not change state', () async {
      when(
        () => mockGameRepository.acceptDraw(),
      ).thenAnswer((_) async => const Right(null));

      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.acceptDraw();

      expect(container.read(gameNotifierProvider), isA<GameInitial>());
    });

    test('acceptDraw() failure transitions to GameError', () async {
      when(() => mockGameRepository.acceptDraw()).thenAnswer(
        (_) async => const Left(WebSocketFailure('Failed to accept draw')),
      );

      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.acceptDraw();

      expect(container.read(gameNotifierProvider), isA<GameError>());
    });

    test(
      'offerDraw() success with GameActive state sets hasOfferedDraw',
      () async {
        when(
          () => mockConnectToGame(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGameRepository.offerDraw(),
        ).thenAnswer((_) async => const Right(null));

        final sub = container.listen(gameNotifierProvider, (_, __) {});
        addTearDown(sub.close);

        final notifier = container.read(gameNotifierProvider.notifier);
        await notifier.connect(tGameId);

        mockGameRepository.addEvent(GameStateSyncEvent(tActiveGame));
        await Future.delayed(const Duration(milliseconds: 100));

        await notifier.offerDraw();

        final state = container.read(gameNotifierProvider) as GameActive;
        expect(state.hasOfferedDraw, isTrue);
      },
    );

    // ── Stream event handlers ─────────────────────────────────────────────────

    test(
      'GameStateSyncEvent with non-active status transitions to GameEnded',
      () async {
        const endedGame = ChessGame(
          gameId: tGameId,
          positionFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR',
          moveHistory: [],
          gameStatus: GameStatus.checkmate,
          currentSide: 'WHITE',
          isCheck: true,
          whitePlayer: tWhitePlayer,
          blackPlayer: tBlackPlayer,
        );

        when(
          () => mockConnectToGame(any()),
        ).thenAnswer((_) async => const Right(null));

        final sub = container.listen(gameNotifierProvider, (_, __) {});
        addTearDown(sub.close);

        final notifier = container.read(gameNotifierProvider.notifier);
        await notifier.connect(tGameId);

        mockGameRepository.addEvent(GameStateSyncEvent(endedGame));
        await Future.delayed(const Duration(milliseconds: 100));

        expect(container.read(gameNotifierProvider), isA<GameEnded>());
      },
    );

    test(
      'GameStateSyncEvent with opponent time <= 0 calls claimTimeout',
      () async {
        const gameOpponentTimedOut = ChessGame(
          gameId: tGameId,
          positionFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR',
          moveHistory: [],
          gameStatus: GameStatus.active,
          currentSide: 'WHITE', // white's turn → black is opponent
          isCheck: false,
          whitePlayer: tWhitePlayer,
          blackPlayer: tBlackPlayer,
          whiteTimeRemainingMs: 600000,
          blackTimeRemainingMs: 0,
        );

        when(
          () => mockConnectToGame(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGameRepository.claimTimeout(),
        ).thenAnswer((_) async => const Right(null));

        final sub = container.listen(gameNotifierProvider, (_, __) {});
        addTearDown(sub.close);

        final notifier = container.read(gameNotifierProvider.notifier);
        await notifier.connect(tGameId);

        mockGameRepository.addEvent(GameStateSyncEvent(gameOpponentTimedOut));
        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => mockGameRepository.claimTimeout()).called(1);
      },
    );

    test('MoveExecutedEvent updates state to GameActive', () async {
      when(
        () => mockConnectToGame(any()),
      ).thenAnswer((_) async => const Right(null));

      final sub = container.listen(gameNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.connect(tGameId);

      mockGameRepository.addEvent(GameStateSyncEvent(tActiveGame));
      await Future.delayed(const Duration(milliseconds: 100));

      mockGameRepository.addEvent(
        MoveExecutedEvent(
          move: const ChessMove(from: 'e2', to: 'e4'),
          newPositionFen:
              'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
          gameStatus: 'ACTIVE',
          currentSide: 'BLACK',
          isCheck: false,
          whiteTimeRemainingMs: 595000,
          blackTimeRemainingMs: 600000,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(gameNotifierProvider);
      expect(state, isA<GameActive>());
      final activeState = state as GameActive;
      expect(activeState.lastMoveFrom, 'e2');
      expect(activeState.lastMoveTo, 'e4');
      expect(activeState.game.currentSide, 'BLACK');
    });

    test('MoveExecutedEvent with game-ending status transitions to GameEnded',
        () async {
      when(
        () => mockConnectToGame(any()),
      ).thenAnswer((_) async => const Right(null));

      final sub = container.listen(gameNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.connect(tGameId);

      mockGameRepository.addEvent(GameStateSyncEvent(tActiveGame));
      await Future.delayed(const Duration(milliseconds: 100));

      mockGameRepository.addEvent(
        MoveExecutedEvent(
          move: const ChessMove(from: 'e2', to: 'e4'),
          newPositionFen: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR',
          gameStatus: 'CHECKMATE',
          currentSide: 'BLACK',
          isCheck: true,
          whiteTimeRemainingMs: null,
          blackTimeRemainingMs: null,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 100));

      expect(container.read(gameNotifierProvider), isA<GameEnded>());
    });

    test(
      'MoveExecutedEvent with opponent time <= 0 calls claimTimeout',
      () async {
        when(
          () => mockConnectToGame(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGameRepository.claimTimeout(),
        ).thenAnswer((_) async => const Right(null));

        final sub = container.listen(gameNotifierProvider, (_, __) {});
        addTearDown(sub.close);

        final notifier = container.read(gameNotifierProvider.notifier);
        await notifier.connect(tGameId);

        mockGameRepository.addEvent(GameStateSyncEvent(tActiveGame));
        await Future.delayed(const Duration(milliseconds: 100));

        mockGameRepository.addEvent(
          MoveExecutedEvent(
            move: const ChessMove(from: 'e2', to: 'e4'),
            newPositionFen:
                'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
            gameStatus: 'ACTIVE',
            currentSide: 'BLACK', // black's turn → white is opponent
            isCheck: false,
            whiteTimeRemainingMs: 0,
            blackTimeRemainingMs: 600000,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => mockGameRepository.claimTimeout()).called(1);
      },
    );

    test(
      'MoveExecutedEvent when state is not GameActive is a no-op',
      () async {
        when(
          () => mockConnectToGame(any()),
        ).thenAnswer((_) async => const Right(null));

        final sub = container.listen(gameNotifierProvider, (_, __) {});
        addTearDown(sub.close);

        final notifier = container.read(gameNotifierProvider.notifier);
        await notifier.connect(tGameId);
        // State is GameLoading after connect (no GameStateSyncEvent) → not GameActive

        mockGameRepository.addEvent(
          MoveExecutedEvent(
            move: const ChessMove(from: 'e2', to: 'e4'),
            newPositionFen: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR',
            gameStatus: 'ACTIVE',
            currentSide: 'BLACK',
            isCheck: false,
            whiteTimeRemainingMs: null,
            blackTimeRemainingMs: null,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 100));

        // Should not be GameActive (was GameLoading before event)
        expect(container.read(gameNotifierProvider), isNot(isA<GameActive>()));
      },
    );

    test('GameResignedEvent transitions to GameEnded', () async {
      when(
        () => mockConnectToGame(any()),
      ).thenAnswer((_) async => const Right(null));

      final sub = container.listen(gameNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.connect(tGameId);

      mockGameRepository.addEvent(GameStateSyncEvent(tActiveGame));
      await Future.delayed(const Duration(milliseconds: 100));

      mockGameRepository.addEvent(
        GameResignedEvent(
          resignedPlayerId: 'player2',
          gameStatus: 'RESIGNED',
        ),
      );
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(gameNotifierProvider);
      expect(state, isA<GameEnded>());
      expect((state as GameEnded).result, 'RESIGNED');
    });

    test('GameResignedEvent — le joueur qui abandonne (noir) donne la victoire au blanc',
        () async {
      when(
        () => mockConnectToGame(any()),
      ).thenAnswer((_) async => const Right(null));

      final sub = container.listen(gameNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      await container.read(gameNotifierProvider.notifier).connect(tGameId);
      mockGameRepository.addEvent(GameStateSyncEvent(tActiveGame));
      await Future.delayed(const Duration(milliseconds: 100));

      // Noir (player2) abandonne → blanc (player1) gagne
      mockGameRepository.addEvent(
        GameResignedEvent(resignedPlayerId: 'player2', gameStatus: 'RESIGNED'),
      );
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(gameNotifierProvider) as GameEnded;
      expect(state.game.winner, 'player1');
    });

    test('GameResignedEvent — le joueur qui abandonne (blanc) donne la victoire au noir',
        () async {
      when(
        () => mockConnectToGame(any()),
      ).thenAnswer((_) async => const Right(null));

      final sub = container.listen(gameNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      await container.read(gameNotifierProvider.notifier).connect(tGameId);
      mockGameRepository.addEvent(GameStateSyncEvent(tActiveGame));
      await Future.delayed(const Duration(milliseconds: 100));

      // Blanc (player1) abandonne → noir (player2) gagne
      mockGameRepository.addEvent(
        GameResignedEvent(resignedPlayerId: 'player1', gameStatus: 'RESIGNED'),
      );
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(gameNotifierProvider) as GameEnded;
      expect(state.game.winner, 'player2');
    });

    test('DrawOfferedEvent sets pendingDrawOfferId', () async {
      when(
        () => mockConnectToGame(any()),
      ).thenAnswer((_) async => const Right(null));

      final sub = container.listen(gameNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.connect(tGameId);

      mockGameRepository.addEvent(GameStateSyncEvent(tActiveGame));
      await Future.delayed(const Duration(milliseconds: 100));

      mockGameRepository.addEvent(
        DrawOfferedEvent(offeredByPlayerId: 'player2'),
      );
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(gameNotifierProvider) as GameActive;
      expect(state.pendingDrawOfferId, 'player2');
      expect(state.hasOfferedDraw, isFalse);
    });

    test('DrawAcceptedEvent transitions to GameEnded', () async {
      when(
        () => mockConnectToGame(any()),
      ).thenAnswer((_) async => const Right(null));

      final sub = container.listen(gameNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.connect(tGameId);

      mockGameRepository.addEvent(GameStateSyncEvent(tActiveGame));
      await Future.delayed(const Duration(milliseconds: 100));

      mockGameRepository.addEvent(
        DrawAcceptedEvent(
          acceptedByPlayerId: 'player2',
          gameStatus: 'DRAW',
        ),
      );
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(gameNotifierProvider);
      expect(state, isA<GameEnded>());
      expect((state as GameEnded).result, 'DRAW');
    });

    test('DrawRejectedEvent clears pending draw', () async {
      when(
        () => mockConnectToGame(any()),
      ).thenAnswer((_) async => const Right(null));

      final sub = container.listen(gameNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.connect(tGameId);

      mockGameRepository.addEvent(GameStateSyncEvent(tActiveGame));
      await Future.delayed(const Duration(milliseconds: 100));

      // First offer a draw so there's a pending draw
      mockGameRepository.addEvent(
        DrawOfferedEvent(offeredByPlayerId: 'player2'),
      );
      await Future.delayed(const Duration(milliseconds: 100));

      mockGameRepository.addEvent(
        DrawRejectedEvent(rejectedByPlayerId: 'player1'),
      );
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(gameNotifierProvider) as GameActive;
      expect(state.pendingDrawOfferId, isNull);
      expect(state.hasOfferedDraw, isFalse);
    });

    test('TimeoutConfirmedEvent transitions to GameEnded', () async {
      when(
        () => mockConnectToGame(any()),
      ).thenAnswer((_) async => const Right(null));

      final sub = container.listen(gameNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.connect(tGameId);

      mockGameRepository.addEvent(GameStateSyncEvent(tActiveGame));
      await Future.delayed(const Duration(milliseconds: 100));

      mockGameRepository.addEvent(
        TimeoutConfirmedEvent(
          loserPlayerId: 'player2',
          gameStatus: 'TIMEOUT',
        ),
      );
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(gameNotifierProvider);
      expect(state, isA<GameEnded>());
      expect((state as GameEnded).result, 'TIMEOUT');
    });

    test(
      'TimeoutClaimRejectedEvent updates white time when white turn',
      () async {
        const whiteToPlay = ChessGame(
          gameId: tGameId,
          positionFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR',
          moveHistory: [],
          gameStatus: GameStatus.active,
          currentSide: 'WHITE',
          isCheck: false,
          whitePlayer: tWhitePlayer,
          blackPlayer: tBlackPlayer,
          whiteTimeRemainingMs: 500,
          blackTimeRemainingMs: 600000,
        );

        when(
          () => mockConnectToGame(any()),
        ).thenAnswer((_) async => const Right(null));

        final sub = container.listen(gameNotifierProvider, (_, __) {});
        addTearDown(sub.close);

        final notifier = container.read(gameNotifierProvider.notifier);
        await notifier.connect(tGameId);

        mockGameRepository.addEvent(GameStateSyncEvent(whiteToPlay));
        await Future.delayed(const Duration(milliseconds: 100));

        mockGameRepository.addEvent(
          TimeoutClaimRejectedEvent(remainingMs: 5000),
        );
        await Future.delayed(const Duration(milliseconds: 100));

        final state = container.read(gameNotifierProvider) as GameActive;
        expect(state.whiteTimeRemainingMs, 5000);
      },
    );

    test(
      'TimeoutClaimRejectedEvent updates black time when black turn',
      () async {
        const blackToPlay = ChessGame(
          gameId: tGameId,
          positionFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR',
          moveHistory: [],
          gameStatus: GameStatus.active,
          currentSide: 'BLACK',
          isCheck: false,
          whitePlayer: tWhitePlayer,
          blackPlayer: tBlackPlayer,
          whiteTimeRemainingMs: 600000,
          blackTimeRemainingMs: 500,
        );

        when(
          () => mockConnectToGame(any()),
        ).thenAnswer((_) async => const Right(null));

        final sub = container.listen(gameNotifierProvider, (_, __) {});
        addTearDown(sub.close);

        final notifier = container.read(gameNotifierProvider.notifier);
        await notifier.connect(tGameId);

        mockGameRepository.addEvent(GameStateSyncEvent(blackToPlay));
        await Future.delayed(const Duration(milliseconds: 100));

        mockGameRepository.addEvent(
          TimeoutClaimRejectedEvent(remainingMs: 3000),
        );
        await Future.delayed(const Duration(milliseconds: 100));

        final state = container.read(gameNotifierProvider) as GameActive;
        expect(state.blackTimeRemainingMs, 3000);
      },
    );

    test(
      'TimeoutClaimRejectedEvent with remainingMs <= 0 calls claimTimeout',
      () async {
        when(
          () => mockConnectToGame(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGameRepository.claimTimeout(),
        ).thenAnswer((_) async => const Right(null));

        final sub = container.listen(gameNotifierProvider, (_, __) {});
        addTearDown(sub.close);

        final notifier = container.read(gameNotifierProvider.notifier);
        await notifier.connect(tGameId);

        mockGameRepository.addEvent(GameStateSyncEvent(tActiveGame));
        await Future.delayed(const Duration(milliseconds: 100));

        mockGameRepository.addEvent(
          TimeoutClaimRejectedEvent(remainingMs: 0),
        );
        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => mockGameRepository.claimTimeout()).called(1);
      },
    );

    test('GameErrorEvent transitions to GameError', () async {
      when(
        () => mockConnectToGame(any()),
      ).thenAnswer((_) async => const Right(null));

      final sub = container.listen(gameNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.connect(tGameId);

      mockGameRepository.addEvent(GameStateSyncEvent(tActiveGame));
      await Future.delayed(const Duration(milliseconds: 100));

      mockGameRepository.addEvent(GameErrorEvent('Something went wrong'));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(container.read(gameNotifierProvider), isA<GameError>());
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Robustesse : séquences d'événements mixtes (sync + resign)
  // ──────────────────────────────────────────────────────────────────────────

  group('robustesse séquence resign + GameStateSyncEvent', () {
    // GameStateSyncEvent d'un jeu terminé avec winner null (comme peut l'envoyer le serveur)
    ChessGame _resignedGameNoWinner() => const ChessGame(
          gameId: tGameId,
          positionFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR',
          moveHistory: [],
          gameStatus: GameStatus.resigned,
          currentSide: 'WHITE',
          isCheck: false,
          whitePlayer: tWhitePlayer,
          blackPlayer: tBlackPlayer,
          winner: null, // le serveur ne remplit pas toujours ce champ
        );

    Future<void> _setupActiveGame() async {
      when(() => mockConnectToGame(any()))
          .thenAnswer((_) async => const Right(null));
      final sub = container.listen(gameNotifierProvider, (_, __) {});
      addTearDown(sub.close);
      await container.read(gameNotifierProvider.notifier).connect(tGameId);
      mockGameRepository.addEvent(GameStateSyncEvent(tActiveGame));
      await Future.delayed(const Duration(milliseconds: 100));
    }

    test(
      'scénario A : resign reçu d\'abord puis sync(winner=null) — winner reste player1',
      () async {
        await _setupActiveGame();

        // 1. Resign → winner calculé correctement
        mockGameRepository.addEvent(
          GameResignedEvent(resignedPlayerId: 'player2', gameStatus: 'RESIGNED'),
        );
        await Future.delayed(const Duration(milliseconds: 100));

        // 2. Sync arrive après avec winner=null → NE doit PAS écraser le winner
        mockGameRepository.addEvent(GameStateSyncEvent(_resignedGameNoWinner()));
        await Future.delayed(const Duration(milliseconds: 100));

        final state = container.read(gameNotifierProvider) as GameEnded;
        expect(state.game.winner, 'player1',
            reason: 'Le sync ne doit pas écraser le winner déjà calculé');
      },
    );

    test(
      'scénario B : sync(winner=null) reçu d\'abord puis resign — winner doit être corrigé',
      () async {
        await _setupActiveGame();

        // 1. Sync avec état terminé mais winner=null
        mockGameRepository.addEvent(GameStateSyncEvent(_resignedGameNoWinner()));
        await Future.delayed(const Duration(milliseconds: 100));

        // 2. Resign arrive après → doit corriger le winner même si déjà GameEnded
        mockGameRepository.addEvent(
          GameResignedEvent(resignedPlayerId: 'player2', gameStatus: 'RESIGNED'),
        );
        await Future.delayed(const Duration(milliseconds: 100));

        final state = container.read(gameNotifierProvider) as GameEnded;
        expect(state.game.winner, 'player1',
            reason: 'Le resign doit corriger le winner même si déjà en GameEnded');
      },
    );
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Couverture exhaustive du champ `winner` pour tous les modes de fin
  // ──────────────────────────────────────────────────────────────────────────

  group('fin de partie — champ winner', () {
    // Helper : connecte et envoie un GameStateSyncEvent pour partir d'un état actif
    Future<void> _setupActiveGame() async {
      when(() => mockConnectToGame(any()))
          .thenAnswer((_) async => const Right(null));
      final sub = container.listen(gameNotifierProvider, (_, __) {});
      addTearDown(sub.close);
      await container.read(gameNotifierProvider.notifier).connect(tGameId);
      mockGameRepository.addEvent(GameStateSyncEvent(tActiveGame));
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Helper : construit un MoveExecutedEvent de fin de partie
    MoveExecutedEvent _checkmateEvent({required String currentSide}) =>
        MoveExecutedEvent(
          move: const ChessMove(from: 'e1', to: 'e2'),
          newPositionFen: tActiveGame.positionFen,
          gameStatus: 'CHECKMATE',
          currentSide: currentSide,
          isCheck: true,
        );

    MoveExecutedEvent _stalemateEvent({required String currentSide}) =>
        MoveExecutedEvent(
          move: const ChessMove(from: 'e1', to: 'e2'),
          newPositionFen: tActiveGame.positionFen,
          gameStatus: 'STALEMATE',
          currentSide: currentSide,
          isCheck: false,
        );

    // ── Échec et mat ──────────────────────────────────────────────────────────

    test('CHECKMATE currentSide=BLACK → blanc (player1) est vainqueur', () async {
      await _setupActiveGame();
      // Blanc joue le coup qui met noir en échec et mat → currentSide=BLACK (noir checmaté)
      mockGameRepository.addEvent(_checkmateEvent(currentSide: 'BLACK'));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(gameNotifierProvider) as GameEnded;
      expect(state.game.winner, 'player1',
          reason: 'Black est échequeté → White gagne');
    });

    test('CHECKMATE currentSide=WHITE → noir (player2) est vainqueur', () async {
      await _setupActiveGame();
      // Noir joue le coup qui met blanc en échec et mat → currentSide=WHITE (blanc checmaté)
      mockGameRepository.addEvent(_checkmateEvent(currentSide: 'WHITE'));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(gameNotifierProvider) as GameEnded;
      expect(state.game.winner, 'player2',
          reason: 'White est échequeté → Black gagne');
    });

    // ── Pat (stalemate = nulle) ───────────────────────────────────────────────

    test('STALEMATE currentSide=BLACK → nulle (winner null)', () async {
      await _setupActiveGame();
      mockGameRepository.addEvent(_stalemateEvent(currentSide: 'BLACK'));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(gameNotifierProvider) as GameEnded;
      expect(state.game.winner, isNull,
          reason: 'Le stalemate est une nulle, aucun gagnant');
    });

    test('STALEMATE currentSide=WHITE → nulle (winner null)', () async {
      await _setupActiveGame();
      mockGameRepository.addEvent(_stalemateEvent(currentSide: 'WHITE'));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(gameNotifierProvider) as GameEnded;
      expect(state.game.winner, isNull,
          reason: 'Le stalemate est une nulle, aucun gagnant');
    });

    // ── Abandon ───────────────────────────────────────────────────────────────

    test('RESIGNED joueur blanc abandonne → noir (player2) est vainqueur',
        () async {
      await _setupActiveGame();
      mockGameRepository.addEvent(
          GameResignedEvent(resignedPlayerId: 'player1', gameStatus: 'RESIGNED'));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(gameNotifierProvider) as GameEnded;
      expect(state.game.winner, 'player2');
    });

    test('RESIGNED joueur noir abandonne → blanc (player1) est vainqueur',
        () async {
      await _setupActiveGame();
      mockGameRepository.addEvent(
          GameResignedEvent(resignedPlayerId: 'player2', gameStatus: 'RESIGNED'));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(gameNotifierProvider) as GameEnded;
      expect(state.game.winner, 'player1');
    });

    // ── Nulle acceptée ────────────────────────────────────────────────────────

    test('DRAW accepté par noir (blanc avait proposé) → winner null', () async {
      await _setupActiveGame();
      mockGameRepository.addEvent(
          DrawAcceptedEvent(acceptedByPlayerId: 'player2', gameStatus: 'DRAW'));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(gameNotifierProvider) as GameEnded;
      expect(state.game.winner, isNull);
      expect(state.result, 'DRAW');
    });

    test('DRAW accepté par blanc (noir avait proposé) → winner null', () async {
      await _setupActiveGame();
      mockGameRepository.addEvent(
          DrawAcceptedEvent(acceptedByPlayerId: 'player1', gameStatus: 'DRAW'));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(gameNotifierProvider) as GameEnded;
      expect(state.game.winner, isNull);
      expect(state.result, 'DRAW');
    });
  });
}
