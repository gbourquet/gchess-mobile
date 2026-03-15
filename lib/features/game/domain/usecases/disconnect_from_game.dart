import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/features/game/domain/repositories/game_repository.dart';

@injectable
class DisconnectFromGame {
  final GameRepository repository;

  DisconnectFromGame(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.disconnect();
  }
}
