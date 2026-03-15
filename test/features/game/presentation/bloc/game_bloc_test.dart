import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_game.dart';
import 'package:gchess_mobile/features/game/domain/entities/player.dart';
import 'package:gchess_mobile/features/game/domain/entities/game_status.dart';
import 'package:gchess_mobile/features/game/domain/repositories/game_repository.dart';
import 'package:gchess_mobile/features/game/presentation/bloc/game_bloc.dart';
import 'package:gchess_mobile/features/game/presentation/bloc/game_event.dart';
import 'package:gchess_mobile/features/game/presentation/bloc/game_state.dart';
import 'package:gchess_mobile/features/game/domain/usecases/connect_to_game.dart';
import 'package:gchess_mobile/features/game/domain/usecases/send_move.dart';
import 'package:mocktail/mocktail.dart';

class MockGameRepository extends Mock implements GameRepository {}

class MockConnectToGame extends Mock implements ConnectToGame {}

class MockSendMove extends Mock implements SendMove {}

void main() {
  late GameBloc gameBloc;
  late MockGameRepository mockRepository;

  setUp(() {
    mockRepository = MockGameRepository();
    gameBloc = GameBloc(
      connectToGame: MockConnectToGame(),
      sendMove: MockSendMove(),
      repository: mockRepository,
    );
  });

  tearDown(() {
    gameBloc.close();
  });

  group('Claim Timeout', () {
    test(
      'should claim timeout when opponent clock reaches 0 - white to play, black at 0',
      () async {
        final game = ChessGame(
          gameId: 'game123',
          positionFen:
              'rnbqkbnr/pppppppp/8/8/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
          moveHistory: [],
          gameStatus: GameStatus.active,
          currentSide: 'WHITE',
          isCheck: false,
          whitePlayer: const Player(
            playerId: 'player1',
            userId: 'user1',
            username: 'WhitePlayer',
            color: 'WHITE',
          ),
          blackPlayer: const Player(
            playerId: 'player2',
            userId: 'user2',
            username: 'BlackPlayer',
            color: 'BLACK',
          ),
          winner: null,
          totalTimeSeconds: 300,
          incrementSeconds: 3,
          whiteTimeRemainingMs: 150000,
          blackTimeRemainingMs: 0,
        );

        final activeState = GameActive(
          game: game,
          totalTimeSeconds: 300,
          incrementSeconds: 3,
          whiteTimeRemainingMs: 150000,
          blackTimeRemainingMs: 0,
        );

        gameBloc.emit(activeState);

        when(
          () => mockRepository.claimTimeout(),
        ).thenAnswer((_) async => const Right(null));

        gameBloc.add(const UpdateClockTimeEvent(isWhite: true));

        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => mockRepository.claimTimeout()).called(1);
      },
    );

    test(
      'should claim timeout when opponent clock reaches 0 - black to play, white at 0',
      () async {
        final game = ChessGame(
          gameId: 'game123',
          positionFen:
              'rnbqkbnr/pppppppp/8/8/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1',
          moveHistory: [],
          gameStatus: GameStatus.active,
          currentSide: 'BLACK',
          isCheck: false,
          whitePlayer: const Player(
            playerId: 'player1',
            userId: 'user1',
            username: 'WhitePlayer',
            color: 'WHITE',
          ),
          blackPlayer: const Player(
            playerId: 'player2',
            userId: 'user2',
            username: 'BlackPlayer',
            color: 'BLACK',
          ),
          winner: null,
          totalTimeSeconds: 300,
          incrementSeconds: 3,
          whiteTimeRemainingMs: 0,
          blackTimeRemainingMs: 150000,
        );

        final activeState = GameActive(
          game: game,
          totalTimeSeconds: 300,
          incrementSeconds: 3,
          whiteTimeRemainingMs: 0,
          blackTimeRemainingMs: 150000,
        );

        gameBloc.emit(activeState);

        when(
          () => mockRepository.claimTimeout(),
        ).thenAnswer((_) async => const Right(null));

        gameBloc.add(const UpdateClockTimeEvent(isWhite: false));

        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => mockRepository.claimTimeout()).called(1);
      },
    );

    test('should NOT claim timeout when opponent still has time', () async {
      final game = ChessGame(
        gameId: 'game123',
        positionFen:
            'rnbqkbnr/pppppppp/8/8/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        moveHistory: [],
        gameStatus: GameStatus.active,
        currentSide: 'WHITE',
        isCheck: false,
        whitePlayer: const Player(
          playerId: 'player1',
          userId: 'user1',
          username: 'WhitePlayer',
          color: 'WHITE',
        ),
        blackPlayer: const Player(
          playerId: 'player2',
          userId: 'user2',
          username: 'BlackPlayer',
          color: 'BLACK',
        ),
        winner: null,
        totalTimeSeconds: 300,
        incrementSeconds: 3,
        whiteTimeRemainingMs: 150000,
        blackTimeRemainingMs: 150000,
      );

      final activeState = GameActive(
        game: game,
        totalTimeSeconds: 300,
        incrementSeconds: 3,
        whiteTimeRemainingMs: 150000,
        blackTimeRemainingMs: 150000,
      );

      gameBloc.emit(activeState);

      gameBloc.add(const UpdateClockTimeEvent(isWhite: true));

      await Future.delayed(const Duration(milliseconds: 100));

      verifyNever(() => mockRepository.claimTimeout());
    });
  });
}
