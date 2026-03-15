import 'package:dartz/dartz.dart';
import 'package:gchess_mobile/core/error/exceptions.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/features/matchmaking/data/datasources/matchmaking_websocket_data_source.dart';
import 'package:gchess_mobile/features/matchmaking/data/models/match_request_model.dart';
import 'package:gchess_mobile/features/matchmaking/data/repositories/matchmaking_repository_impl.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_request.dart';
import 'package:gchess_mobile/features/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

class MockMatchmakingWebSocketDataSource extends Mock
    implements MatchmakingWebSocketDataSource {}

void main() {
  late MockMatchmakingWebSocketDataSource mockDataSource;
  late MatchmakingRepositoryImpl repository;
  late StreamController<MatchmakingStreamEvent> eventController;

  const tMatchRequest = MatchRequest(totalTimeMinutes: 10, incrementSeconds: 0);

  setUpAll(() {
    registerFallbackValue(MatchRequestModel());
  });

  setUp(() {
    mockDataSource = MockMatchmakingWebSocketDataSource();
    eventController = StreamController<MatchmakingStreamEvent>.broadcast();
    repository = MatchmakingRepositoryImpl(dataSource: mockDataSource);

    when(
      () => mockDataSource.eventStream,
    ).thenAnswer((_) => eventController.stream);
  });

  tearDown(() {
    eventController.close();
  });

  group('connect', () {
    test('should return Right(null) on successful connection', () async {
      when(() => mockDataSource.connect()).thenAnswer((_) async => {});

      final result = await repository.connect();

      expect(result, isA<Right<Failure, void>>());
      verify(() => mockDataSource.connect());
      verifyNoMoreInteractions(mockDataSource);
    });

    test(
      'should return Left(AuthenticationFailure) when AuthenticationException occurs',
      () async {
        when(
          () => mockDataSource.connect(),
        ).thenThrow(AuthenticationException('No auth token'));

        final result = await repository.connect();

        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (l) => expect(l, isA<AuthenticationFailure>()),
          (_) => fail('Should have returned Left'),
        );
        verify(() => mockDataSource.connect());
        verifyNoMoreInteractions(mockDataSource);
      },
    );

    test(
      'should return Left(WebSocketFailure) when WebSocketException occurs',
      () async {
        when(
          () => mockDataSource.connect(),
        ).thenThrow(WebSocketException('Connection failed'));

        final result = await repository.connect();

        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (l) => expect(l, isA<WebSocketFailure>()),
          (_) => fail('Should have returned Left'),
        );
        verify(() => mockDataSource.connect());
        verifyNoMoreInteractions(mockDataSource);
      },
    );
  });

  group('joinQueue', () {
    test(
      'should return Right(null) and call dataSource with MatchRequestModel',
      () async {
        when(() => mockDataSource.joinQueue(any())).thenAnswer((_) async => {});

        final result = await repository.joinQueue(tMatchRequest);

        expect(result, isA<Right<Failure, void>>());
        verify(() => mockDataSource.joinQueue(any()));
        verifyNoMoreInteractions(mockDataSource);
      },
    );

    test(
      'should return Left(WebSocketFailure) when WebSocketException occurs',
      () async {
        when(
          () => mockDataSource.joinQueue(any()),
        ).thenThrow(WebSocketException('Failed to join queue'));

        final result = await repository.joinQueue(tMatchRequest);

        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (l) => expect(l, isA<WebSocketFailure>()),
          (_) => fail('Should have returned Left'),
        );
        verify(() => mockDataSource.joinQueue(any()));
        verifyNoMoreInteractions(mockDataSource);
      },
    );
  });

  group('leaveQueue', () {
    test('should return Right(null) on successful leave', () async {
      when(() => mockDataSource.leaveQueue()).thenAnswer((_) async => {});

      final result = await repository.leaveQueue();

      expect(result, isA<Right<Failure, void>>());
      verify(() => mockDataSource.leaveQueue());
      verifyNoMoreInteractions(mockDataSource);
    });

    test(
      'should return Left(WebSocketFailure) when WebSocketException occurs',
      () async {
        when(
          () => mockDataSource.leaveQueue(),
        ).thenThrow(WebSocketException('Failed to leave queue'));

        final result = await repository.leaveQueue();

        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (l) => expect(l, isA<WebSocketFailure>()),
          (_) => fail('Should have returned Left'),
        );
        verify(() => mockDataSource.leaveQueue());
        verifyNoMoreInteractions(mockDataSource);
      },
    );
  });

  group('disconnect', () {
    test('should return Right(null) on successful disconnect', () async {
      when(() => mockDataSource.disconnect()).thenAnswer((_) async => {});

      final result = await repository.disconnect();

      expect(result, isA<Right<Failure, void>>());
      verify(() => mockDataSource.disconnect());
      verifyNoMoreInteractions(mockDataSource);
    });

    test(
      'should return Left(WebSocketFailure) when WebSocketException occurs',
      () async {
        when(
          () => mockDataSource.disconnect(),
        ).thenThrow(WebSocketException('Failed to disconnect'));

        final result = await repository.disconnect();

        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (l) => expect(l, isA<WebSocketFailure>()),
          (_) => fail('Should have returned Left'),
        );
        verify(() => mockDataSource.disconnect());
        verifyNoMoreInteractions(mockDataSource);
      },
    );
  });

  group('eventStream', () {
    test('should delegate eventStream to dataSource', () {
      when(
        () => mockDataSource.eventStream,
      ).thenAnswer((_) => eventController.stream);

      final stream = repository.eventStream;

      expect(stream, equals(eventController.stream));
      verify(() => mockDataSource.eventStream);
      verifyNoMoreInteractions(mockDataSource);
    });
  });
}
