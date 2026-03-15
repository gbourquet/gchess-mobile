import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gchess_mobile/core/network/api_client.dart';
import 'package:gchess_mobile/core/error/exceptions.dart';
import 'package:gchess_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:gchess_mobile/features/auth/data/models/user_model.dart';
import 'package:gchess_mobile/features/auth/data/models/login_response.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late AuthRemoteDataSourceImpl dataSource;

  const tUsername = 'testuser';
  const tEmail = 'test@test.com';
  const tPassword = 'password123';

  const tUserModel = UserModel(
    id: 'user-id-1',
    username: tUsername,
    email: tEmail,
  );

  const tLoginResponse = LoginResponse(
    token: 'jwt-token-123',
    user: tUserModel,
  );

  final tUserJson = {
    'id': 'user-id-1',
    'username': tUsername,
    'email': tEmail,
  };

  final tLoginResponseJson = {
    'token': 'jwt-token-123',
    'user': tUserJson,
  };

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = AuthRemoteDataSourceImpl(mockApiClient);
  });

  RequestOptions tRequestOptions() => RequestOptions(path: '/test');

  DioException makeDioException({
    required int statusCode,
    Map<String, dynamic>? data,
    DioExceptionType type = DioExceptionType.badResponse,
  }) {
    return DioException(
      requestOptions: tRequestOptions(),
      response: Response(
        requestOptions: tRequestOptions(),
        statusCode: statusCode,
        data: data ?? {'message': 'error'},
      ),
      type: type,
    );
  }

  DioException makeNetworkDioException() {
    return DioException(
      requestOptions: tRequestOptions(),
      type: DioExceptionType.unknown,
      message: 'Network error',
    );
  }

  group('register', () {
    test('should return UserModel on successful registration', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: tRequestOptions(),
          statusCode: 200,
          data: tUserJson,
        ),
      );

      final result = await dataSource.register(
        username: tUsername,
        email: tEmail,
        password: tPassword,
      );

      expect(result, tUserModel);
      verify(
        () => mockApiClient.post(
          '/api/auth/register',
          data: any(named: 'data'),
        ),
      );
    });

    test('should throw ValidationException on DioException with status 400',
        () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        makeDioException(
          statusCode: 400,
          data: {'message': 'Invalid registration data'},
        ),
      );

      expect(
        () => dataSource.register(
          username: tUsername,
          email: tEmail,
          password: tPassword,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('should throw ConflictException on DioException with status 409',
        () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        makeDioException(
          statusCode: 409,
          data: {'message': 'User already exists'},
        ),
      );

      expect(
        () => dataSource.register(
          username: tUsername,
          email: tEmail,
          password: tPassword,
        ),
        throwsA(isA<ConflictException>()),
      );
    });

    test('should throw ServerException on network DioException', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(makeNetworkDioException());

      expect(
        () => dataSource.register(
          username: tUsername,
          email: tEmail,
          password: tPassword,
        ),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('login', () {
    test('should return LoginResponse on successful login', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: tRequestOptions(),
          statusCode: 200,
          data: tLoginResponseJson,
        ),
      );

      final result = await dataSource.login(
        username: tUsername,
        password: tPassword,
      );

      expect(result.token, tLoginResponse.token);
      expect(result.user, tLoginResponse.user);
      verify(
        () => mockApiClient.post(
          '/api/auth/login',
          data: any(named: 'data'),
        ),
      );
    });

    test('should throw AuthenticationException on DioException with status 401',
        () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        makeDioException(
          statusCode: 401,
          data: {'message': 'Unauthorized'},
        ),
      );

      expect(
        () => dataSource.login(
          username: tUsername,
          password: tPassword,
        ),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('should throw ServerException on network DioException', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(makeNetworkDioException());

      expect(
        () => dataSource.login(
          username: tUsername,
          password: tPassword,
        ),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
