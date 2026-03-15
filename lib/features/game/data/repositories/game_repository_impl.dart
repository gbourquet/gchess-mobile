import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:gchess_mobile/core/error/exceptions.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/features/game/data/datasources/game_websocket_data_source.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_move.dart';
import 'package:gchess_mobile/features/game/domain/repositories/game_repository.dart';

@Singleton(as: GameRepository)
class GameRepositoryImpl implements GameRepository {
  final GameWebSocketDataSource dataSource;

  GameRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, void>> connect(String gameId) async {
    try {
      await dataSource.connect(gameId);
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(e.message));
    } catch (e) {
      return Left(WebSocketFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> sendMove(ChessMove move) async {
    try {
      await dataSource.sendMove(move);
      return const Right(null);
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(e.message));
    } catch (e) {
      return Left(WebSocketFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> resign() async {
    try {
      await dataSource.resign();
      return const Right(null);
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(e.message));
    } catch (e) {
      return Left(WebSocketFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> offerDraw() async {
    try {
      await dataSource.offerDraw();
      return const Right(null);
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(e.message));
    } catch (e) {
      return Left(WebSocketFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> acceptDraw() async {
    try {
      await dataSource.acceptDraw();
      return const Right(null);
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(e.message));
    } catch (e) {
      return Left(WebSocketFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> rejectDraw() async {
    try {
      await dataSource.rejectDraw();
      return const Right(null);
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(e.message));
    } catch (e) {
      return Left(WebSocketFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> claimTimeout() async {
    try {
      print('📤 Sending ClaimTimeout message to WebSocket');
      await dataSource.claimTimeout();
      return const Right(null);
    } on WebSocketException catch (e) {
      print('❌ ClaimTimeout failed: ${e.message}');
      return Left(WebSocketFailure(e.message));
    } catch (e) {
      print('❌ ClaimTimeout unexpected error: $e');
      return Left(WebSocketFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> disconnect() async {
    try {
      await dataSource.disconnect();
      return const Right(null);
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(e.message));
    } catch (e) {
      return Left(WebSocketFailure('Unexpected error: $e'));
    }
  }

  @override
  Stream<GameStreamEvent> get eventStream => dataSource.eventStream;
}
