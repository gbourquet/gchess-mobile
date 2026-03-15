import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:gchess_mobile/core/error/exceptions.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/features/matchmaking/data/datasources/matchmaking_websocket_data_source.dart';
import 'package:gchess_mobile/features/matchmaking/data/models/match_request_model.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_request.dart';
import 'package:gchess_mobile/features/matchmaking/domain/repositories/matchmaking_repository.dart';

@Singleton(as: MatchmakingRepository)
class MatchmakingRepositoryImpl implements MatchmakingRepository {
  final MatchmakingWebSocketDataSource dataSource;

  MatchmakingRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, void>> connect() async {
    try {
      await dataSource.connect();
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
  Future<Either<Failure, void>> joinQueue(MatchRequest request) async {
    try {
      final model = MatchRequestModel.fromEntity(request);
      await dataSource.joinQueue(model);
      return const Right(null);
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(e.message));
    } catch (e) {
      return Left(WebSocketFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> leaveQueue() async {
    try {
      await dataSource.leaveQueue();
      return const Right(null);
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(e.message));
    } catch (e) {
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
  Stream<MatchmakingStreamEvent> get eventStream => dataSource.eventStream;
}
