import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:gchess_mobile/core/error/exceptions.dart';
import 'package:gchess_mobile/core/network/api_client.dart';
import 'package:gchess_mobile/features/auth/data/models/login_request.dart';
import 'package:gchess_mobile/features/auth/data/models/login_response.dart';
import 'package:gchess_mobile/features/auth/data/models/register_request.dart';
import 'package:gchess_mobile/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  });

  Future<LoginResponse> login({
    required String username,
    required String password,
  });
}

@Injectable(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final request = RegisterRequest(
        username: username,
        email: email,
        password: password,
      );

      final response = await _apiClient.post(
        '/api/auth/register',
        data: request.toJson(),
      );

      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw ValidationException(
          e.response?.data['message'] ?? 'Invalid registration data',
        );
      } else if (e.response?.statusCode == 409) {
        throw ConflictException(
          e.response?.data['message'] ?? 'User already exists',
        );
      }
      throw ServerException('Failed to register: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to register: $e');
    }
  }

  @override
  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final request = LoginRequest(
        username: username,
        password: password,
      );

      final response = await _apiClient.post(
        '/api/auth/login',
        data: request.toJson(),
      );

      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthenticationException('Invalid username or password');
      }
      throw ServerException('Failed to login: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to login: $e');
    }
  }
}
