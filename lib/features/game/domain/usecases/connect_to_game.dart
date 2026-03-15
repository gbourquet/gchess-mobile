import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/features/game/domain/repositories/game_repository.dart';

@injectable
class ConnectToGame {
  final GameRepository repository;

  ConnectToGame(this.repository);

  Future<Either<Failure, void>> call(String gameId) {
    return repository.connect(gameId);
  }
}
