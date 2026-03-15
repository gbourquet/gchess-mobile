import 'package:dartz/dartz.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_move.dart';
import 'package:gchess_mobile/features/game/domain/repositories/game_repository.dart';
import 'package:gchess_mobile/features/game/domain/usecases/claim_timeout.dart';
import 'package:gchess_mobile/features/game/domain/usecases/connect_to_game.dart';
import 'package:gchess_mobile/features/game/domain/usecases/disconnect_from_game.dart';
import 'package:gchess_mobile/features/game/domain/usecases/send_move.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class MockGameRepository extends Mock implements GameRepository {}

void main() {
  late MockGameRepository mockGameRepository;
  late ConnectToGame connectToGame;
  late SendMove sendMove;
  late DisconnectFromGame disconnectFromGame;
  late ClaimTimeout claimTimeout;

  const tGameId = 'game123';
  const tChessMove = ChessMove(from: 'e2', to: 'e4');

  setUpAll(() {
    registerFallbackValue(tChessMove);
    registerFallbackValue(tGameId);
  });

  setUp(() {
    mockGameRepository = MockGameRepository();
    connectToGame = ConnectToGame(mockGameRepository);
    sendMove = SendMove(mockGameRepository);
    disconnectFromGame = DisconnectFromGame(mockGameRepository);
    claimTimeout = ClaimTimeout(mockGameRepository);
  });

  group('ConnectToGame', () {
    test('should return Right(null) and call repository with gameId', () async {
      when(
        () => mockGameRepository.connect(any()),
      ).thenAnswer((_) async => const Right(null));

      final result = await connectToGame(tGameId);

      expect(result, const Right(null));
      verify(() => mockGameRepository.connect(tGameId));
      verifyNoMoreInteractions(mockGameRepository);
    });

    test(
      'should return Left(WebSocketFailure) when connection fails',
      () async {
        const tFailure = WebSocketFailure('Connection failed');
        when(
          () => mockGameRepository.connect(any()),
        ).thenAnswer((_) async => const Left(tFailure));

        final result = await connectToGame(tGameId);

        expect(result, const Left(tFailure));
        verify(() => mockGameRepository.connect(tGameId));
        verifyNoMoreInteractions(mockGameRepository);
      },
    );
  });

  group('SendMove', () {
    test(
      'should return Right(null) and call repository with ChessMove',
      () async {
        when(
          () => mockGameRepository.sendMove(any()),
        ).thenAnswer((_) async => const Right(null));

        final result = await sendMove(tChessMove);

        expect(result, const Right(null));
        verify(() => mockGameRepository.sendMove(tChessMove));
        verifyNoMoreInteractions(mockGameRepository);
      },
    );

    test('should return Left(WebSocketFailure) when send move fails', () async {
      const tFailure = WebSocketFailure('Failed to send move');
      when(
        () => mockGameRepository.sendMove(any()),
      ).thenAnswer((_) async => const Left(tFailure));

      final result = await sendMove(tChessMove);

      expect(result, const Left(tFailure));
      verify(() => mockGameRepository.sendMove(tChessMove));
      verifyNoMoreInteractions(mockGameRepository);
    });
  });

  group('DisconnectFromGame', () {
    test('should return Right(null) when disconnect is successful', () async {
      when(
        () => mockGameRepository.disconnect(),
      ).thenAnswer((_) async => const Right(null));

      final result = await disconnectFromGame();

      expect(result, const Right(null));
      verify(() => mockGameRepository.disconnect());
      verifyNoMoreInteractions(mockGameRepository);
    });

    test(
      'should return Left(WebSocketFailure) when disconnect fails',
      () async {
        const tFailure = WebSocketFailure('Failed to disconnect');
        when(
          () => mockGameRepository.disconnect(),
        ).thenAnswer((_) async => const Left(tFailure));

        final result = await disconnectFromGame();

        expect(result, const Left(tFailure));
        verify(() => mockGameRepository.disconnect());
        verifyNoMoreInteractions(mockGameRepository);
      },
    );
  });

  group('ClaimTimeout', () {
    test(
      'should return Right(null) when claim timeout is successful',
      () async {
        when(
          () => mockGameRepository.claimTimeout(),
        ).thenAnswer((_) async => const Right(null));

        final result = await claimTimeout();

        expect(result, const Right(null));
        verify(() => mockGameRepository.claimTimeout());
        verifyNoMoreInteractions(mockGameRepository);
      },
    );

    test(
      'should return Left(WebSocketFailure) when claim timeout fails',
      () async {
        const tFailure = WebSocketFailure('Failed to claim timeout');
        when(
          () => mockGameRepository.claimTimeout(),
        ).thenAnswer((_) async => const Left(tFailure));

        final result = await claimTimeout();

        expect(result, const Left(tFailure));
        verify(() => mockGameRepository.claimTimeout());
        verifyNoMoreInteractions(mockGameRepository);
      },
    );
  });
}
