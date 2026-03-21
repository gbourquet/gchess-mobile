import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:gchess_mobile/core/error/exceptions.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/core/network/network_info.dart';
import 'package:gchess_mobile/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:gchess_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:gchess_mobile/features/auth/domain/entities/user.dart';
import 'package:gchess_mobile/features/auth/domain/repositories/auth_repository.dart';

@Injectable(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.register(
        username: username,
        email: email,
        password: password,
      );

      // Automatically log in after registration to obtain the JWT token
      final loginResponse = await remoteDataSource.login(
        username: username,
        password: password,
      );

      await localDataSource.saveToken(loginResponse.token);
      await localDataSource.saveUser(loginResponse.user);
      await localDataSource.saveCredentials(
        username: username,
        password: password,
      );

      return Right(loginResponse.user);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ConflictException catch (e) {
      return Left(ConflictFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> login({
    required String username,
    required String password,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final loginResponse = await remoteDataSource.login(
        username: username,
        password: password,
      );

      await localDataSource.saveToken(loginResponse.token);
      await localDataSource.saveUser(loginResponse.user);
      // Save credentials for auto-refresh on token expiration
      await localDataSource.saveCredentials(
        username: username,
        password: password,
      );

      return Right(loginResponse.user);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.deleteToken();
      await localDataSource.deleteUser();
      await localDataSource.deleteCredentials();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error during logout: $e'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) return const Right(null);

      if (_isTokenExpired(token)) {
        final username = await localDataSource.getUsername();
        final password = await localDataSource.getPassword();

        if (username == null || password == null) {
          await localDataSource.deleteToken();
          return const Right(null);
        }

        if (!await networkInfo.isConnected) {
          final user = await localDataSource.getUser();
          return Right(user);
        }

        try {
          final loginResponse = await remoteDataSource.login(
            username: username,
            password: password,
          );
          await localDataSource.saveToken(loginResponse.token);
          await localDataSource.saveUser(loginResponse.user);
          return Right(loginResponse.user);
        } on AuthenticationException {
          await localDataSource.deleteToken();
          await localDataSource.deleteCredentials();
          return const Right(null);
        } on ServerException {
          final user = await localDataSource.getUser();
          return Right(user);
        }
      }

      final user = await localDataSource.getUser();
      return Right(user);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error getting user: $e'));
    }
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      String payload = parts[1];
      final remainder = payload.length % 4;
      if (remainder != 0) {
        payload = payload.padRight(payload.length + (4 - remainder), '=');
      }

      final decoded = utf8.decode(base64Url.decode(payload));
      final data = json.decode(decoded) as Map<String, dynamic>;

      final exp = data['exp'] as int?;
      if (exp == null) return false;

      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return nowSeconds >= exp;
    } catch (_) {
      return true;
    }
  }
}
