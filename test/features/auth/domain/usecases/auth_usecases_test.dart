import 'package:dartz/dartz.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/features/auth/domain/entities/user.dart';
import 'package:gchess_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:gchess_mobile/features/auth/domain/usecases/get_current_user.dart';
import 'package:gchess_mobile/features/auth/domain/usecases/login_user.dart';
import 'package:gchess_mobile/features/auth/domain/usecases/logout_user.dart';
import 'package:gchess_mobile/features/auth/domain/usecases/register_user.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late LoginUser loginUser;
  late RegisterUser registerUser;
  late LogoutUser logoutUser;
  late GetCurrentUser getCurrentUser;

  const tUser = User(id: '1', username: 'test', email: 'test@test.com');
  const tUsername = 'testuser';
  const tPassword = 'password123';
  const tEmail = 'test@test.com';

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    loginUser = LoginUser(mockAuthRepository);
    registerUser = RegisterUser(mockAuthRepository);
    logoutUser = LogoutUser(mockAuthRepository);
    getCurrentUser = GetCurrentUser(mockAuthRepository);
  });

  group('LoginUser', () {
    test('should return Right(User) when login is successful', () async {
      when(
        () => mockAuthRepository.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(tUser));

      final result = await loginUser.call(
        username: tUsername,
        password: tPassword,
      );

      expect(result, const Right(tUser));
      verify(
        () =>
            mockAuthRepository.login(username: tUsername, password: tPassword),
      );
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test(
      'should return Left(AuthenticationFailure) when login fails',
      () async {
        const tFailure = AuthenticationFailure('Invalid credentials');
        when(
          () => mockAuthRepository.login(
            username: any(named: 'username'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Left(tFailure));

        final result = await loginUser.call(
          username: tUsername,
          password: tPassword,
        );

        expect(result, const Left(tFailure));
        verify(
          () => mockAuthRepository.login(
            username: tUsername,
            password: tPassword,
          ),
        );
        verifyNoMoreInteractions(mockAuthRepository);
      },
    );
  });

  group('RegisterUser', () {
    test('should return Right(User) when registration is successful', () async {
      when(
        () => mockAuthRepository.register(
          username: any(named: 'username'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(tUser));

      final result = await registerUser.call(
        username: tUsername,
        email: tEmail,
        password: tPassword,
      );

      expect(result, const Right(tUser));
      verify(
        () => mockAuthRepository.register(
          username: tUsername,
          email: tEmail,
          password: tPassword,
        ),
      );
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return Left(ServerFailure) when registration fails', () async {
      const tFailure = ServerFailure('Registration failed');
      when(
        () => mockAuthRepository.register(
          username: any(named: 'username'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      final result = await registerUser.call(
        username: tUsername,
        email: tEmail,
        password: tPassword,
      );

      expect(result, const Left(tFailure));
      verify(
        () => mockAuthRepository.register(
          username: tUsername,
          email: tEmail,
          password: tPassword,
        ),
      );
      verifyNoMoreInteractions(mockAuthRepository);
    });
  });

  group('LogoutUser', () {
    test('should return Right(null) when logout is successful', () async {
      when(
        () => mockAuthRepository.logout(),
      ).thenAnswer((_) async => const Right(null));

      final result = await logoutUser();

      expect(result, isA<Right<Failure, void>>());
      result.fold((l) => fail('Should have returned Right'), (_) {});
      verify(() => mockAuthRepository.logout());
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return Left(CacheFailure) when logout fails', () async {
      const tFailure = CacheFailure('Logout failed');
      when(
        () => mockAuthRepository.logout(),
      ).thenAnswer((_) async => const Left(tFailure));

      final result = await logoutUser();

      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (l) => expect(l, isA<CacheFailure>()),
        (_) => fail('Should have returned Left'),
      );
      verify(() => mockAuthRepository.logout());
      verifyNoMoreInteractions(mockAuthRepository);
    });
  });

  group('GetCurrentUser', () {
    test('should return Right(User) when user exists', () async {
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(tUser));

      final result = await getCurrentUser();

      expect(result, const Right(tUser));
      verify(() => mockAuthRepository.getCurrentUser());
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return Right(null) when user does not exist', () async {
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(null));

      final result = await getCurrentUser();

      expect(result, isA<Right<Failure, User?>>());
      result.fold(
        (_) => fail('Should have returned Right'),
        (r) => expect(r, isNull),
      );
      verify(() => mockAuthRepository.getCurrentUser());
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test(
      'should return Left(CacheFailure) when getCurrentUser fails',
      () async {
        const tFailure = CacheFailure('Failed to get user');
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenAnswer((_) async => const Left(tFailure));

        final result = await getCurrentUser();

        expect(result, isA<Left<Failure, User?>>());
        result.fold(
          (l) => expect(l, isA<CacheFailure>()),
          (_) => fail('Should have returned Left'),
        );
        verify(() => mockAuthRepository.getCurrentUser());
        verifyNoMoreInteractions(mockAuthRepository);
      },
    );
  });
}
