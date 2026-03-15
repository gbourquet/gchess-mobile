import 'package:dartz/dartz.dart';
import 'package:gchess_mobile/core/error/exceptions.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/features/game/data/datasources/game_websocket_data_source.dart';
import 'package:gchess_mobile/features/game/data/repositories/game_repository_impl.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_move.dart';
import 'package:gchess_mobile/features/game/domain/repositories/game_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

class MockGameWebSocketDataSource extends Mock
    implements GameWebSocketDataSource {}

void main() {
  late MockGameWebSocketDataSource mockDataSource;
  late GameRepositoryImpl repository;
  late StreamController<GameStreamEvent> eventController;

  const tGameId = 'game123';
  const tChessMove = ChessMove(from: 'e2', to: 'e4');

  setUpAll(() {
    registerFallbackValue(tChessMove);
  });

  setUp(() {
    mockDataSource = MockGameWebSocketDataSource();
    eventController = StreamController<GameStreamEvent>.broadcast();
    repository = GameRepositoryImpl(dataSource: mockDataSource);

    when(
      () => mockDataSource.eventStream,
    ).thenAnswer((_) => eventController.stream);
  });

  tearDown(() {
    eventController.close();
  });

  group('connect', () {
    test('should return Right(null) and call dataSource with gameId', () async {
      when(() => mockDataSource.connect(any())).thenAnswer((_) async => {});

      final result = await repository.connect(tGameId);

      expect(result, isA<Right<Failure, void>>());
      verify(() => mockDataSource.connect(tGameId));
      verifyNoMoreInteractions(mockDataSource);
    });

    test(
      'should return Left(AuthenticationFailure) when AuthenticationException occurs',
      () async {
        when(
          () => mockDataSource.connect(any()),
        ).thenThrow(AuthenticationException('No auth token'));

        final result = await repository.connect(tGameId);

        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (l) => expect(l, isA<AuthenticationFailure>()),
          (_) => fail('Should have returned Left'),
        );
        verify(() => mockDataSource.connect(tGameId));
        verifyNoMoreInteractions(mockDataSource);
      },
    );

    test(
      'should return Left(WebSocketFailure) when WebSocketException occurs',
      () async {
        when(
          () => mockDataSource.connect(any()),
        ).thenThrow(WebSocketException('Connection failed'));

        final result = await repository.connect(tGameId);

        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (l) => expect(l, isA<WebSocketFailure>()),
          (_) => fail('Should have returned Left'),
        );
        verify(() => mockDataSource.connect(tGameId));
        verifyNoMoreInteractions(mockDataSource);
      },
    );
  });

  group('sendMove', () {
    test(
      'should return Right(null) and call dataSource with ChessMove',
      () async {
        when(() => mockDataSource.sendMove(any())).thenAnswer((_) async => {});

        final result = await repository.sendMove(tChessMove);

        expect(result, isA<Right<Failure, void>>());
        verify(() => mockDataSource.sendMove(tChessMove));
        verifyNoMoreInteractions(mockDataSource);
      },
    );

    test(
      'should return Left(WebSocketFailure) when WebSocketException occurs',
      () async {
        when(
          () => mockDataSource.sendMove(any()),
        ).thenThrow(WebSocketException('Failed to send move'));

        final result = await repository.sendMove(tChessMove);

        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (l) => expect(l, isA<WebSocketFailure>()),
          (_) => fail('Should have returned Left'),
        );
        verify(() => mockDataSource.sendMove(tChessMove));
        verifyNoMoreInteractions(mockDataSource);
      },
    );
  });

  group('resign', () {
    test('should return Right(null) on successful resign', () async {
      when(() => mockDataSource.resign()).thenAnswer((_) async => {});

      final result = await repository.resign();

      expect(result, isA<Right<Failure, void>>());
      verify(() => mockDataSource.resign());
      verifyNoMoreInteractions(mockDataSource);
    });

    test(
      'should return Left(WebSocketFailure) when WebSocketException occurs',
      () async {
        when(
          () => mockDataSource.resign(),
        ).thenThrow(WebSocketException('Failed to resign'));

        final result = await repository.resign();

        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (l) => expect(l, isA<WebSocketFailure>()),
          (_) => fail('Should have returned Left'),
        );
        verify(() => mockDataSource.resign());
        verifyNoMoreInteractions(mockDataSource);
      },
    );
  });

  group('offerDraw', () {
    test('should return Right(null) on successful offer draw', () async {
      when(() => mockDataSource.offerDraw()).thenAnswer((_) async => {});

      final result = await repository.offerDraw();

      expect(result, isA<Right<Failure, void>>());
      verify(() => mockDataSource.offerDraw());
      verifyNoMoreInteractions(mockDataSource);
    });

    test(
      'should return Left(WebSocketFailure) when WebSocketException occurs',
      () async {
        when(
          () => mockDataSource.offerDraw(),
        ).thenThrow(WebSocketException('Failed to offer draw'));

        final result = await repository.offerDraw();

        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (l) => expect(l, isA<WebSocketFailure>()),
          (_) => fail('Should have returned Left'),
        );
        verify(() => mockDataSource.offerDraw());
        verifyNoMoreInteractions(mockDataSource);
      },
    );
  });

  group('acceptDraw', () {
    test('should return Right(null) on successful accept draw', () async {
      when(() => mockDataSource.acceptDraw()).thenAnswer((_) async => {});

      final result = await repository.acceptDraw();

      expect(result, isA<Right<Failure, void>>());
      verify(() => mockDataSource.acceptDraw());
      verifyNoMoreInteractions(mockDataSource);
    });

    test(
      'should return Left(WebSocketFailure) when WebSocketException occurs',
      () async {
        when(
          () => mockDataSource.acceptDraw(),
        ).thenThrow(WebSocketException('Failed to accept draw'));

        final result = await repository.acceptDraw();

        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (l) => expect(l, isA<WebSocketFailure>()),
          (_) => fail('Should have returned Left'),
        );
        verify(() => mockDataSource.acceptDraw());
        verifyNoMoreInteractions(mockDataSource);
      },
    );
  });

  group('rejectDraw', () {
    test('should return Right(null) on successful reject draw', () async {
      when(() => mockDataSource.rejectDraw()).thenAnswer((_) async => {});

      final result = await repository.rejectDraw();

      expect(result, isA<Right<Failure, void>>());
      verify(() => mockDataSource.rejectDraw());
      verifyNoMoreInteractions(mockDataSource);
    });

    test(
      'should return Left(WebSocketFailure) when WebSocketException occurs',
      () async {
        when(
          () => mockDataSource.rejectDraw(),
        ).thenThrow(WebSocketException('Failed to reject draw'));

        final result = await repository.rejectDraw();

        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (l) => expect(l, isA<WebSocketFailure>()),
          (_) => fail('Should have returned Left'),
        );
        verify(() => mockDataSource.rejectDraw());
        verifyNoMoreInteractions(mockDataSource);
      },
    );
  });

  group('claimTimeout', () {
    test('should return Right(null) on successful claim timeout', () async {
      when(() => mockDataSource.claimTimeout()).thenAnswer((_) async => {});

      final result = await repository.claimTimeout();

      expect(result, isA<Right<Failure, void>>());
      verify(() => mockDataSource.claimTimeout());
      verifyNoMoreInteractions(mockDataSource);
    });

    test(
      'should return Left(WebSocketFailure) when WebSocketException occurs',
      () async {
        when(
          () => mockDataSource.claimTimeout(),
        ).thenThrow(WebSocketException('Failed to claim timeout'));

        final result = await repository.claimTimeout();

        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (l) => expect(l, isA<WebSocketFailure>()),
          (_) => fail('Should have returned Left'),
        );
        verify(() => mockDataSource.claimTimeout());
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
