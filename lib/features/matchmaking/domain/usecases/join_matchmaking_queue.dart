import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_request.dart';
import 'package:gchess_mobile/features/matchmaking/domain/repositories/matchmaking_repository.dart';

@injectable
class JoinMatchmakingQueue {
  final MatchmakingRepository repository;

  JoinMatchmakingQueue(this.repository);

  Future<Either<Failure, void>> call(MatchRequest request) {
    return repository.joinQueue(request);
  }
}
