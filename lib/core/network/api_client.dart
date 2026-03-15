import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../storage/secure_storage.dart';
import '../error/exceptions.dart';

@singleton
class ApiClient {
  late final Dio _dio;
  final SecureStorage _secureStorage;

  ApiClient(this._secureStorage, @Named('baseUrl') String baseUrl) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(JwtInterceptor(_secureStorage, _dio));
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  Dio get dio => _dio;

  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return AuthenticationException('Unauthorized');
        } else if (statusCode == 403) {
          return AuthenticationException('Forbidden');
        } else if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          final message = error.response?.data['message'] ?? 'Client error';
          return ServerException(message);
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException('Server error');
        }
        return ServerException('Unknown server error');
      case DioExceptionType.cancel:
        return ServerException('Request cancelled');
      case DioExceptionType.unknown:
        if (error.error.toString().contains('SocketException')) {
          return NetworkException('No internet connection');
        }
        return NetworkException('Network error');
      default:
        return ServerException('Unknown error');
    }
  }
}

class JwtInterceptor extends Interceptor {
  final SecureStorage _secureStorage;
  final Dio _dio;

  JwtInterceptor(this._secureStorage, this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expired - try to refresh using stored credentials
      final username = await _secureStorage.getUsername();
      final password = await _secureStorage.getPassword();

      if (username != null && password != null) {
        try {
          // Attempt to re-login with stored credentials
          final response = await _dio.post(
            '/api/auth/login',
            data: {
              'username': username,
              'password': password,
            },
            options: Options(
              headers: {'Authorization': null}, // Don't send expired token
            ),
          );

          if (response.statusCode == 200) {
            final newToken = response.data['token'] as String;
            await _secureStorage.saveToken(newToken);

            // Retry the original request with new token
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newToken';

            final retryResponse = await _dio.fetch(options);
            return handler.resolve(retryResponse);
          }
        } catch (e) {
          // If re-login fails, clear credentials and pass error
          await _secureStorage.deleteToken();
          await _secureStorage.deleteCredentials();
        }
      }
    }
    handler.next(err);
  }
}
