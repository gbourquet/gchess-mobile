import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/features/auth/domain/entities/user.dart';
import 'package:gchess_mobile/features/auth/domain/repositories/auth_repository.dart';

@injectable
class LoginUser {
  final AuthRepository repository;

  LoginUser(this.repository);

  Future<Either<Failure, User>> call({
    required String username,
    required String password,
  }) {
    return repository.login(
      username: username,
      password: password,
    );
  }
}