import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/core/injection.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_request.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_result.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/queue_position.dart';
import 'package:gchess_mobile/features/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:gchess_mobile/features/matchmaking/domain/usecases/connect_to_matchmaking.dart';
import 'package:gchess_mobile/features/matchmaking/domain/usecases/join_matchmaking_queue.dart';
import 'package:gchess_mobile/features/matchmaking/domain/usecases/leave_matchmaking_queue.dart';
import 'package:gchess_mobile/features/matchmaking/presentation/bloc/matchmaking_state.dart';
import 'package:gchess_mobile/features/matchmaking/presentation/providers/matchmaking_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';

class MockConnectToMatchmaking extends Mock implements ConnectToMatchmaking {}

class MockJoinMatchmakingQueue extends Mock implements JoinMatchmakingQueue {}

class MockLeaveMatchmakingQueue extends Mock implements LeaveMatchmakingQueue {}

class MockMatchmakingRepository extends Mock implements MatchmakingRepository {
  final _eventController = StreamController<MatchmakingStreamEvent>.broadcast();

  @override
  Stream<MatchmakingStreamEvent> get eventStream => _eventController.stream;

  void addEvent(MatchmakingStreamEvent event) => _eventController.add(event);

  @override
  Future<Either<Failure, void>> disconnect() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> connect() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> joinQueue(MatchRequest request) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> leaveQueue() async {
    return const Right(null);
  }
}

void main() {
  late ProviderContainer container;
  late MockConnectToMatchmaking mockConnectToMatchmaking;
  late MockJoinMatchmakingQueue mockJoinMatchmakingQueue;
  late MockLeaveMatchmakingQueue mockLeaveMatchmakingQueue;
  late MockMatchmakingRepository mockMatchmakingRepository;

  const tMatchRequest = MatchRequest(totalTimeMinutes: 10, incrementSeconds: 0);
  const tMatchResult = MatchResult(
    gameId: 'game1',
    playerId: 'player1',
    yourColor: 'WHITE',
    opponentUserId: 'player2',
  );

  setUpAll(() {
    registerFallbackValue(
      const MatchRequest(totalTimeMinutes: 10, incrementSeconds: 0),
    );
  });

  setUp(() {
    getIt.reset();

    mockConnectToMatchmaking = MockConnectToMatchmaking();
    mockJoinMatchmakingQueue = MockJoinMatchmakingQueue();
    mockLeaveMatchmakingQueue = MockLeaveMatchmakingQueue();
    mockMatchmakingRepository = MockMatchmakingRepository();

    // Stub par défaut pour le onDispose du notifier (fire-and-forget)
    when(
      () => mockLeaveMatchmakingQueue(),
    ).thenAnswer((_) async => const Right(null));

    getIt.registerFactory<ConnectToMatchmaking>(() => mockConnectToMatchmaking);
    getIt.registerFactory<JoinMatchmakingQueue>(() => mockJoinMatchmakingQueue);
    getIt.registerFactory<LeaveMatchmakingQueue>(
      () => mockLeaveMatchmakingQueue,
    );
    getIt.registerFactory<MatchmakingRepository>(
      () => mockMatchmakingRepository,
    );

    container = ProviderContainer();
  });

  // Dispose du container avant que getIt soit réinitialisé dans le prochain setUp,
  // pour éviter que le timer autoDispose de Riverpod ne fire après getIt.reset().
  tearDown(() {
    container.dispose();
  });

  group('MatchmakingNotifier', () {
    test('build() should return MatchmakingIdle', () {
      final notifier = container.read(matchmakingNotifierProvider.notifier);
      final state = container.read(matchmakingNotifierProvider);

      expect(state, const MatchmakingIdle());
    });

    test(
      'connect() should transition to MatchmakingConnecting then MatchmakingIdle on success',
      () async {
        when(
          () => mockConnectToMatchmaking(),
        ).thenAnswer((_) async => const Right(null));

        final notifier = container.read(matchmakingNotifierProvider.notifier);
        final connectFuture = notifier.connect();

        expect(
          container.read(matchmakingNotifierProvider),
          const MatchmakingConnecting(),
        );
        await connectFuture;

        expect(
          container.read(matchmakingNotifierProvider),
          const MatchmakingIdle(),
        );
        verify(() => mockConnectToMatchmaking()).called(1);
      },
    );

    test(
      'connect() should transition to MatchmakingError on failure',
      () async {
        when(() => mockConnectToMatchmaking()).thenAnswer(
          (_) async => const Left(WebSocketFailure('Connection failed')),
        );

        final notifier = container.read(matchmakingNotifierProvider.notifier);
        await notifier.connect();

        expect(
          container.read(matchmakingNotifierProvider),
          isA<MatchmakingError>(),
        );
        verify(() => mockConnectToMatchmaking()).called(1);
      },
    );

    test('stream should emit QueuePositionEvent and update state', () async {
      when(
        () => mockConnectToMatchmaking(),
      ).thenAnswer((_) async => const Right(null));

      // Maintenir le provider vivant (autoDispose) pendant toute la durée du test
      final sub = container.listen(matchmakingNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(matchmakingNotifierProvider.notifier);
      await notifier.connect();

      const tPosition = QueuePosition(position: 3);
      final event = QueuePositionEvent(tPosition);
      mockMatchmakingRepository.addEvent(event);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(
        container.read(matchmakingNotifierProvider),
        const InQueue(position: 3),
      );
    });

    test('stream should emit MatchFoundEvent and update state', () async {
      when(
        () => mockConnectToMatchmaking(),
      ).thenAnswer((_) async => const Right(null));

      // Maintenir le provider vivant (autoDispose) pendant toute la durée du test
      final sub = container.listen(matchmakingNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(matchmakingNotifierProvider.notifier);
      await notifier.connect();

      final event = MatchFoundEvent(tMatchResult);
      mockMatchmakingRepository.addEvent(event);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(
        container.read(matchmakingNotifierProvider),
        MatchFound(tMatchResult),
      );
    });

    test('stream should emit MatchmakingErrorEvent and update state', () async {
      when(
        () => mockConnectToMatchmaking(),
      ).thenAnswer((_) async => const Right(null));

      // Maintenir le provider vivant (autoDispose) pendant toute la durée du test
      final sub = container.listen(matchmakingNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(matchmakingNotifierProvider.notifier);
      await notifier.connect();

      final event = MatchmakingErrorEvent('Error message');
      mockMatchmakingRepository.addEvent(event);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(
        container.read(matchmakingNotifierProvider),
        const MatchmakingError('Error message'),
      );
    });

    test('joinQueue() should return InQueue on success', () async {
      when(
        () => mockJoinMatchmakingQueue(any()),
      ).thenAnswer((_) async => const Right(null));

      final notifier = container.read(matchmakingNotifierProvider.notifier);
      await notifier.joinQueue(tMatchRequest);

      expect(
        container.read(matchmakingNotifierProvider),
        const InQueue(position: 1),
      );
      verify(() => mockJoinMatchmakingQueue(tMatchRequest)).called(1);
    });

    test('joinQueue() should return MatchmakingError on failure', () async {
      when(() => mockJoinMatchmakingQueue(any())).thenAnswer(
        (_) async => const Left(WebSocketFailure('Failed to join queue')),
      );

      final notifier = container.read(matchmakingNotifierProvider.notifier);
      await notifier.joinQueue(tMatchRequest);

      expect(
        container.read(matchmakingNotifierProvider),
        isA<MatchmakingError>(),
      );
      verify(() => mockJoinMatchmakingQueue(tMatchRequest)).called(1);
    });

    test('leaveQueue() should return MatchmakingIdle on success', () async {
      when(
        () => mockLeaveMatchmakingQueue(),
      ).thenAnswer((_) async => const Right(null));

      final notifier = container.read(matchmakingNotifierProvider.notifier);
      await notifier.leaveQueue();

      expect(
        container.read(matchmakingNotifierProvider),
        const MatchmakingIdle(),
      );
      verify(() => mockLeaveMatchmakingQueue()).called(1);
    });

    test('leaveQueue() should return MatchmakingError on failure', () async {
      when(() => mockLeaveMatchmakingQueue()).thenAnswer(
        (_) async => const Left(WebSocketFailure('Failed to leave queue')),
      );

      final notifier = container.read(matchmakingNotifierProvider.notifier);
      await notifier.leaveQueue();

      expect(
        container.read(matchmakingNotifierProvider),
        isA<MatchmakingError>(),
      );
      verify(() => mockLeaveMatchmakingQueue()).called(1);
    });
  });
}
