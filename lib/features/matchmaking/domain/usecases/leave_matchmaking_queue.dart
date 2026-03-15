import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/features/matchmaking/domain/repositories/matchmaking_repository.dart';

@injectable
class LeaveMatchmakingQueue {
  final MatchmakingRepository repository;

  LeaveMatchmakingQueue(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.leaveQueue();
  }
}
