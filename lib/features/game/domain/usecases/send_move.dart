import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_move.dart';
import 'package:gchess_mobile/features/game/domain/repositories/game_repository.dart';

@injectable
class SendMove {
  final GameRepository repository;

  SendMove(this.repository);

  Future<Either<Failure, void>> call(ChessMove move) {
    return repository.sendMove(move);
  }
}
