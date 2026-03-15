import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/features/auth/domain/repositories/auth_repository.dart';

@injectable
class LogoutUser {
  final AuthRepository repository;

  LogoutUser(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.logout();
  }
}