import 'package:dartz/dartz.dart';
import 'package:gchess_mobile/core/error/exceptions.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/core/network/network_info.dart';
import 'package:gchess_mobile/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:gchess_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:gchess_mobile/features/auth/data/models/login_response.dart';
import 'package:gchess_mobile/features/auth/data/models/user_model.dart';
import 'package:gchess_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:gchess_mobile/features/auth/domain/entities/user.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late AuthRepositoryImpl repository;

  const tUser = UserModel(id: '1', username: 'test', email: 'test@test.com');
  // JWT valide avec exp = 4070908800 (année 2099)
  const tValidToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJzdWIiOiIxIiwiZXhwIjo0MDcwOTA4ODAwfQ'
      '.test';
  // JWT expiré avec exp = 1577836800 (01/01/2020)
  const tExpiredToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJzdWIiOiIxIiwiZXhwIjoxNTc3ODM2ODAwfQ'
      '.test';
  const tLoginResponse = LoginResponse(token: tValidToken, user: tUser);
  const tUsername = 'testuser';
  const tPassword = 'password123';
  const tEmail = 'test@test.com';

  setUpAll(() {
    registerFallbackValue(tUser);
  });

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('register', () {
    test(
      'should return Left(NetworkFailure) when no internet connection',
      () async {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        final result = await repository.register(
          username: tUsername,
          email: tEmail,
          password: tPassword,
        );

        expect(result, isA<Left<Failure, User>>());
        expect(result.fold((l) => l, (r) => r), isA<NetworkFailure>());
        verifyNever(
          () => mockRemoteDataSource.register(
            username: any(named: 'username'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
        verifyNoMoreInteractions(mockRemoteDataSource);
      },
    );

    test(
      'should return Left(ValidationFailure) when ValidationException occurs',
      () async {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(
          () => mockRemoteDataSource.register(
            username: any(named: 'username'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(ValidationException('Invalid data'));

        final result = await repository.register(
          username: tUsername,
          email: tEmail,
          password: tPassword,
        );

        expect(result, isA<Left<Failure, User>>());
        expect(result.fold((l) => l, (r) => r), isA<ValidationFailure>());
        verify(
          () => mockRemoteDataSource.register(
            username: tUsername,
            email: tEmail,
            password: tPassword,
          ),
        );
        verifyNoMoreInteractions(mockRemoteDataSource);
      },
    );

    test(
      'should return Left(ConflictFailure) when ConflictException occurs',
      () async {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(
          () => mockRemoteDataSource.register(
            username: any(named: 'username'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(ConflictException('User already exists'));

        final result = await repository.register(
          username: tUsername,
          email: tEmail,
          password: tPassword,
        );

        expect(result, isA<Left<Failure, User>>());
        expect(result.fold((l) => l, (r) => r), isA<ConflictFailure>());
        verify(
          () => mockRemoteDataSource.register(
            username: tUsername,
            email: tEmail,
            password: tPassword,
          ),
        );
        verifyNoMoreInteractions(mockRemoteDataSource);
      },
    );

    test(
      'should return Left(ServerFailure) when ServerException occurs',
      () async {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(
          () => mockRemoteDataSource.register(
            username: any(named: 'username'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(ServerException('Server error'));

        final result = await repository.register(
          username: tUsername,
          email: tEmail,
          password: tPassword,
        );

        expect(result, isA<Left<Failure, User>>());
        expect(result.fold((l) => l, (r) => r), isA<ServerFailure>());
        verify(
          () => mockRemoteDataSource.register(
            username: tUsername,
            email: tEmail,
            password: tPassword,
          ),
        );
        verifyNoMoreInteractions(mockRemoteDataSource);
      },
    );

    test('should return Right(User) on successful registration', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => mockRemoteDataSource.register(
          username: any(named: 'username'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => tUser);
      when(
        () => mockRemoteDataSource.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => tLoginResponse);
      when(
        () => mockLocalDataSource.saveToken(any()),
      ).thenAnswer((_) async => {});
      when(
        () => mockLocalDataSource.saveUser(any()),
      ).thenAnswer((_) async => {});
      when(
        () => mockLocalDataSource.saveCredentials(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => {});

      final result = await repository.register(
        username: tUsername,
        email: tEmail,
        password: tPassword,
      );

      expect(result, const Right(tUser));
      verify(
        () => mockRemoteDataSource.register(
          username: tUsername,
          email: tEmail,
          password: tPassword,
        ),
      );
      verify(
        () => mockRemoteDataSource.login(
          username: tUsername,
          password: tPassword,
        ),
      );
      verify(() => mockLocalDataSource.saveToken(tLoginResponse.token));
      verify(() => mockLocalDataSource.saveUser(tLoginResponse.user));
      verify(
        () => mockLocalDataSource.saveCredentials(
          username: tUsername,
          password: tPassword,
        ),
      );
      verifyNoMoreInteractions(mockRemoteDataSource);
      verifyNoMoreInteractions(mockLocalDataSource);
    });
  });

  group('login', () {
    test(
      'should return Left(NetworkFailure) when no internet connection',
      () async {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        final result = await repository.login(
          username: tUsername,
          password: tPassword,
        );

        expect(result, isA<Left<Failure, User>>());
        expect(result.fold((l) => l, (r) => r), isA<NetworkFailure>());
        verifyNever(
          () => mockRemoteDataSource.login(
            username: any(named: 'username'),
            password: any(named: 'password'),
          ),
        );
        verifyNoMoreInteractions(mockRemoteDataSource);
      },
    );

    test(
      'should return Left(AuthenticationFailure) when AuthenticationException occurs',
      () async {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(
          () => mockRemoteDataSource.login(
            username: any(named: 'username'),
            password: any(named: 'password'),
          ),
        ).thenThrow(AuthenticationException('Invalid credentials'));

        final result = await repository.login(
          username: tUsername,
          password: tPassword,
        );

        expect(result, isA<Left<Failure, User>>());
        expect(result.fold((l) => l, (r) => r), isA<AuthenticationFailure>());
        verify(
          () => mockRemoteDataSource.login(
            username: tUsername,
            password: tPassword,
          ),
        );
        verifyNoMoreInteractions(mockRemoteDataSource);
      },
    );

    test(
      'should return Left(ServerFailure) when ServerException occurs',
      () async {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(
          () => mockRemoteDataSource.login(
            username: any(named: 'username'),
            password: any(named: 'password'),
          ),
        ).thenThrow(ServerException('Server error'));

        final result = await repository.login(
          username: tUsername,
          password: tPassword,
        );

        expect(result, isA<Left<Failure, User>>());
        expect(result.fold((l) => l, (r) => r), isA<ServerFailure>());
        verify(
          () => mockRemoteDataSource.login(
            username: tUsername,
            password: tPassword,
          ),
        );
        verifyNoMoreInteractions(mockRemoteDataSource);
      },
    );

    test('should return Right(User) on successful login', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => mockRemoteDataSource.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => tLoginResponse);
      when(
        () => mockLocalDataSource.saveToken(any()),
      ).thenAnswer((_) async => {});
      when(
        () => mockLocalDataSource.saveUser(any()),
      ).thenAnswer((_) async => {});
      when(
        () => mockLocalDataSource.saveCredentials(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => {});

      final result = await repository.login(
        username: tUsername,
        password: tPassword,
      );

      expect(result, const Right(tUser));
      verify(
        () => mockRemoteDataSource.login(
          username: tUsername,
          password: tPassword,
        ),
      );
      verify(() => mockLocalDataSource.saveToken(tLoginResponse.token));
      verify(() => mockLocalDataSource.saveUser(tLoginResponse.user));
      verify(
        () => mockLocalDataSource.saveCredentials(
          username: tUsername,
          password: tPassword,
        ),
      );
      verifyNoMoreInteractions(mockRemoteDataSource);
      verifyNoMoreInteractions(mockLocalDataSource);
    });
  });

  group('logout', () {
    test('should return Right(null) on successful logout', () async {
      when(() => mockLocalDataSource.deleteToken()).thenAnswer((_) async => {});
      when(() => mockLocalDataSource.deleteUser()).thenAnswer((_) async => {});
      when(
        () => mockLocalDataSource.deleteCredentials(),
      ).thenAnswer((_) async => {});

      final result = await repository.logout();

      expect(result, isA<Right<Failure, void>>());
      verify(() => mockLocalDataSource.deleteToken());
      verify(() => mockLocalDataSource.deleteUser());
      verify(() => mockLocalDataSource.deleteCredentials());
      verifyNoMoreInteractions(mockLocalDataSource);
    });

    test(
      'should return Left(CacheFailure) when CacheException occurs',
      () async {
        when(
          () => mockLocalDataSource.deleteToken(),
        ).thenThrow(CacheException('Cache error'));
        when(
          () => mockLocalDataSource.deleteUser(),
        ).thenAnswer((_) async => {});
        when(
          () => mockLocalDataSource.deleteCredentials(),
        ).thenAnswer((_) async => {});

        final result = await repository.logout();

        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (l) => expect(l, isA<CacheFailure>()),
          (_) => fail('Should have returned Left'),
        );
        verify(() => mockLocalDataSource.deleteToken());
        verifyNoMoreInteractions(mockLocalDataSource);
      },
    );
  });

  group('getCurrentUser', () {
    test('should return Right(null) when token is null', () async {
      when(() => mockLocalDataSource.getToken()).thenAnswer((_) async => null);

      final result = await repository.getCurrentUser();

      expect(result, isA<Right<Failure, User?>>());
      result.fold(
        (_) => fail('Should have returned Right'),
        (r) => expect(r, isNull),
      );
      verify(() => mockLocalDataSource.getToken());
      verifyNever(() => mockLocalDataSource.getUser());
      verifyNoMoreInteractions(mockLocalDataSource);
    });

    test('should return Right(User) when token is valid (not expired)', () async {
      when(
        () => mockLocalDataSource.getToken(),
      ).thenAnswer((_) async => tValidToken);
      when(() => mockLocalDataSource.getUser()).thenAnswer((_) async => tUser);

      final result = await repository.getCurrentUser();

      expect(result, const Right(tUser));
      verify(() => mockLocalDataSource.getToken());
      verify(() => mockLocalDataSource.getUser());
      verifyNoMoreInteractions(mockLocalDataSource);
    });

    test(
      'should return Left(CacheFailure) when CacheException occurs',
      () async {
        when(
          () => mockLocalDataSource.getToken(),
        ).thenThrow(CacheException('Cache error'));

        final result = await repository.getCurrentUser();

        expect(result, isA<Left<Failure, User?>>());
        result.fold(
          (l) => expect(l, isA<CacheFailure>()),
          (_) => fail('Should have returned Left'),
        );
        verify(() => mockLocalDataSource.getToken());
        verifyNoMoreInteractions(mockLocalDataSource);
      },
    );

    test(
      'should return Right(null) and delete token when token is expired and no credentials stored',
      () async {
        when(
          () => mockLocalDataSource.getToken(),
        ).thenAnswer((_) async => tExpiredToken);
        when(
          () => mockLocalDataSource.getUsername(),
        ).thenAnswer((_) async => null);
        when(
          () => mockLocalDataSource.getPassword(),
        ).thenAnswer((_) async => null);
        when(
          () => mockLocalDataSource.deleteToken(),
        ).thenAnswer((_) async => {});

        final result = await repository.getCurrentUser();

        expect(result, isA<Right<Failure, User?>>());
        result.fold(
          (_) => fail('Should have returned Right'),
          (r) => expect(r, isNull),
        );
        verify(() => mockLocalDataSource.getToken());
        verify(() => mockLocalDataSource.getUsername());
        verify(() => mockLocalDataSource.getPassword());
        verify(() => mockLocalDataSource.deleteToken());
        verifyNoMoreInteractions(mockLocalDataSource);
        verifyNoMoreInteractions(mockRemoteDataSource);
      },
    );

    test(
      'should re-login and return Right(User) when token is expired and credentials available',
      () async {
        when(
          () => mockLocalDataSource.getToken(),
        ).thenAnswer((_) async => tExpiredToken);
        when(
          () => mockLocalDataSource.getUsername(),
        ).thenAnswer((_) async => tUsername);
        when(
          () => mockLocalDataSource.getPassword(),
        ).thenAnswer((_) async => tPassword);
        when(
          () => mockNetworkInfo.isConnected,
        ).thenAnswer((_) async => true);
        when(
          () => mockRemoteDataSource.login(
            username: any(named: 'username'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => tLoginResponse);
        when(
          () => mockLocalDataSource.saveToken(any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockLocalDataSource.saveUser(any()),
        ).thenAnswer((_) async => {});

        final result = await repository.getCurrentUser();

        expect(result, const Right(tUser));
        verify(() => mockLocalDataSource.getToken());
        verify(() => mockLocalDataSource.getUsername());
        verify(() => mockLocalDataSource.getPassword());
        verify(() => mockNetworkInfo.isConnected);
        verify(
          () => mockRemoteDataSource.login(
            username: tUsername,
            password: tPassword,
          ),
        );
        verify(() => mockLocalDataSource.saveToken(tValidToken));
        verify(() => mockLocalDataSource.saveUser(tUser));
        verifyNoMoreInteractions(mockRemoteDataSource);
        verifyNoMoreInteractions(mockLocalDataSource);
      },
    );

    test(
      'should return Right(null) and clear credentials when token is expired and re-login fails',
      () async {
        when(
          () => mockLocalDataSource.getToken(),
        ).thenAnswer((_) async => tExpiredToken);
        when(
          () => mockLocalDataSource.getUsername(),
        ).thenAnswer((_) async => tUsername);
        when(
          () => mockLocalDataSource.getPassword(),
        ).thenAnswer((_) async => tPassword);
        when(
          () => mockNetworkInfo.isConnected,
        ).thenAnswer((_) async => true);
        when(
          () => mockRemoteDataSource.login(
            username: any(named: 'username'),
            password: any(named: 'password'),
          ),
        ).thenThrow(AuthenticationException('Invalid credentials'));
        when(
          () => mockLocalDataSource.deleteToken(),
        ).thenAnswer((_) async => {});
        when(
          () => mockLocalDataSource.deleteCredentials(),
        ).thenAnswer((_) async => {});

        final result = await repository.getCurrentUser();

        expect(result, isA<Right<Failure, User?>>());
        result.fold(
          (_) => fail('Should have returned Right'),
          (r) => expect(r, isNull),
        );
        verify(() => mockLocalDataSource.getToken());
        verify(() => mockLocalDataSource.getUsername());
        verify(() => mockLocalDataSource.getPassword());
        verify(() => mockNetworkInfo.isConnected);
        verify(
          () => mockRemoteDataSource.login(
            username: tUsername,
            password: tPassword,
          ),
        );
        verify(() => mockLocalDataSource.deleteToken());
        verify(() => mockLocalDataSource.deleteCredentials());
        verifyNoMoreInteractions(mockRemoteDataSource);
        verifyNoMoreInteractions(mockLocalDataSource);
      },
    );

    test(
      'should return cached user when token is expired but no network connection',
      () async {
        when(
          () => mockLocalDataSource.getToken(),
        ).thenAnswer((_) async => tExpiredToken);
        when(
          () => mockLocalDataSource.getUsername(),
        ).thenAnswer((_) async => tUsername);
        when(
          () => mockLocalDataSource.getPassword(),
        ).thenAnswer((_) async => tPassword);
        when(
          () => mockNetworkInfo.isConnected,
        ).thenAnswer((_) async => false);
        when(
          () => mockLocalDataSource.getUser(),
        ).thenAnswer((_) async => tUser);

        final result = await repository.getCurrentUser();

        expect(result, const Right(tUser));
        verify(() => mockLocalDataSource.getToken());
        verify(() => mockLocalDataSource.getUsername());
        verify(() => mockLocalDataSource.getPassword());
        verify(() => mockNetworkInfo.isConnected);
        verify(() => mockLocalDataSource.getUser());
        verifyNoMoreInteractions(mockLocalDataSource);
        verifyNoMoreInteractions(mockRemoteDataSource);
      },
    );
  });
}
