import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_request.dart';
import 'package:gchess_mobile/features/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:gchess_mobile/features/matchmaking/domain/usecases/connect_to_matchmaking.dart';
import 'package:gchess_mobile/features/matchmaking/domain/usecases/join_matchmaking_queue.dart';
import 'package:gchess_mobile/features/matchmaking/domain/usecases/leave_matchmaking_queue.dart';
import 'package:mocktail/mocktail.dart';

class MockMatchmakingRepository extends Mock implements MatchmakingRepository {}

void main() {
  late MockMatchmakingRepository mockMatchmakingRepository;
  late ConnectToMatchmaking connectToMatchmaking;
  late JoinMatchmakingQueue joinMatchmakingQueue;
  late LeaveMatchmakingQueue leaveMatchmakingQueue;

  const tMatchRequest = MatchRequest(totalTimeMinutes: 10, incrementSeconds: 0);

  setUpAll(() {
    registerFallbackValue(tMatchRequest);
  });

  setUp(() {
    mockMatchmakingRepository = MockMatchmakingRepository();
    connectToMatchmaking = ConnectToMatchmaking(mockMatchmakingRepository);
    joinMatchmakingQueue = JoinMatchmakingQueue(mockMatchmakingRepository);
    leaveMatchmakingQueue = LeaveMatchmakingQueue(mockMatchmakingRepository);
  });

  group('ConnectToMatchmaking', () {
    test('should return Right(null) when connection is successful', () async {
      when(
        () => mockMatchmakingRepository.connect(),
      ).thenAnswer((_) async => const Right(null));

      final result = await connectToMatchmaking();

      expect(result, const Right(null));
      verify(() => mockMatchmakingRepository.connect());
      verifyNoMoreInteractions(mockMatchmakingRepository);
    });

    test(
      'should return Left(WebSocketFailure) when connection fails',
      () async {
        const tFailure = WebSocketFailure('Connection failed');
        when(
          () => mockMatchmakingRepository.connect(),
        ).thenAnswer((_) async => const Left(tFailure));

        final result = await connectToMatchmaking();

        expect(result, const Left(tFailure));
        verify(() => mockMatchmakingRepository.connect());
        verifyNoMoreInteractions(mockMatchmakingRepository);
      },
    );
  });

  group('JoinMatchmakingQueue', () {
    test(
      'should return Right(null) and call repository with MatchRequest',
      () async {
        when(
          () => mockMatchmakingRepository.joinQueue(any()),
        ).thenAnswer((_) async => const Right(null));

        final result = await joinMatchmakingQueue(tMatchRequest);

        expect(result, const Right(null));
        verify(() => mockMatchmakingRepository.joinQueue(tMatchRequest));
        verifyNoMoreInteractions(mockMatchmakingRepository);
      },
    );

    test(
      'should return Left(WebSocketFailure) when join queue fails',
      () async {
        const tFailure = WebSocketFailure('Failed to join queue');
        when(
          () => mockMatchmakingRepository.joinQueue(any()),
        ).thenAnswer((_) async => const Left(tFailure));

        final result = await joinMatchmakingQueue(tMatchRequest);

        expect(result, const Left(tFailure));
        verify(() => mockMatchmakingRepository.joinQueue(tMatchRequest));
        verifyNoMoreInteractions(mockMatchmakingRepository);
      },
    );
  });

  group('LeaveMatchmakingQueue', () {
    test('should return Right(null) when leave queue is successful', () async {
      when(
        () => mockMatchmakingRepository.leaveQueue(),
      ).thenAnswer((_) async => const Right(null));

      final result = await leaveMatchmakingQueue();

      expect(result, const Right(null));
      verify(() => mockMatchmakingRepository.leaveQueue());
      verifyNoMoreInteractions(mockMatchmakingRepository);
    });

    test(
      'should return Left(WebSocketFailure) when leave queue fails',
      () async {
        const tFailure = WebSocketFailure('Failed to leave queue');
        when(
          () => mockMatchmakingRepository.leaveQueue(),
        ).thenAnswer((_) async => const Left(tFailure));

        final result = await leaveMatchmakingQueue();

        expect(result, const Left(tFailure));
        verify(() => mockMatchmakingRepository.leaveQueue());
        verifyNoMoreInteractions(mockMatchmakingRepository);
      },
    );
  });
}
