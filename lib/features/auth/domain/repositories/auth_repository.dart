import 'package:dartz/dartz.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> register({
    required String username,
    required String email,
    required String password,
  });

  Future<Either<Failure, User>> login({
    required String username,
    required String password,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, User?>> getCurrentUser();
}