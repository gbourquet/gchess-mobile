import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/core/error/failures.dart';
import 'package:gchess_mobile/core/injection.dart';
import 'package:gchess_mobile/features/auth/domain/entities/user.dart';
import 'package:gchess_mobile/features/auth/domain/usecases/get_current_user.dart';
import 'package:gchess_mobile/features/auth/domain/usecases/login_user.dart';
import 'package:gchess_mobile/features/auth/domain/usecases/logout_user.dart';
import 'package:gchess_mobile/features/auth/domain/usecases/register_user.dart';
import 'package:gchess_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockLoginUser extends Mock implements LoginUser {}

class MockLogoutUser extends Mock implements LogoutUser {}

class MockRegisterUser extends Mock implements RegisterUser {}

void main() {
  late ProviderContainer container;
  late MockGetCurrentUser mockGetCurrentUser;
  late MockLoginUser mockLoginUser;
  late MockLogoutUser mockLogoutUser;
  late MockRegisterUser mockRegisterUser;

  const tUser = User(id: '1', username: 'test', email: 'test@test.com');
  const tUsername = 'testuser';
  const tPassword = 'password123';
  const tEmail = 'test@test.com';

  setUp(() {
    getIt.reset();

    mockGetCurrentUser = MockGetCurrentUser();
    mockLoginUser = MockLoginUser();
    mockLogoutUser = MockLogoutUser();
    mockRegisterUser = MockRegisterUser();

    getIt.registerFactory<GetCurrentUser>(() => mockGetCurrentUser);
    getIt.registerFactory<LoginUser>(() => mockLoginUser);
    getIt.registerFactory<LogoutUser>(() => mockLogoutUser);
    getIt.registerFactory<RegisterUser>(() => mockRegisterUser);

    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthNotifier', () {
    test(
      'build() should return AsyncData(User) when GetCurrentUser returns user',
      () async {
        when(
          () => mockGetCurrentUser(),
        ).thenAnswer((_) async => const Right(tUser));

        final notifier = container.read(authNotifierProvider.notifier);
        await container.read(authNotifierProvider.future);

        expect(container.read(authNotifierProvider), AsyncData<User?>(tUser));
        verify(() => mockGetCurrentUser()).called(1);
      },
    );

    test(
      'build() should return AsyncData(null) when GetCurrentUser returns CacheFailure',
      () async {
        when(
          () => mockGetCurrentUser(),
        ).thenAnswer((_) async => const Left(CacheFailure('Cache error')));

        final notifier = container.read(authNotifierProvider.notifier);
        await container.read(authNotifierProvider.future);

        expect(container.read(authNotifierProvider), const AsyncData<User?>(null));
        verify(() => mockGetCurrentUser()).called(1);
      },
    );

    test('login() should return AsyncData(User) on success', () async {
      when(
        () => mockLoginUser(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(tUser));

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.login(tUsername, tPassword);

      expect(container.read(authNotifierProvider), AsyncData<User?>(tUser));
      verify(
        () => mockLoginUser(username: tUsername, password: tPassword),
      ).called(1);
    });

    test('login() should return AsyncError on failure', () async {
      const tFailure = AuthenticationFailure('Invalid credentials');
      when(
        () => mockLoginUser(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.login(tUsername, tPassword);

      expect(container.read(authNotifierProvider).hasError, true);
      verify(
        () => mockLoginUser(username: tUsername, password: tPassword),
      ).called(1);
    });

    test('register() should return AsyncData(User) on success', () async {
      when(
        () => mockRegisterUser(
          username: any(named: 'username'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(tUser));

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.register(tUsername, tEmail, tPassword);

      expect(container.read(authNotifierProvider), AsyncData<User?>(tUser));
      verify(
        () => mockRegisterUser(
          username: tUsername,
          email: tEmail,
          password: tPassword,
        ),
      ).called(1);
    });

    test('register() should return AsyncError on failure', () async {
      const tFailure = ServerFailure('Registration failed');
      when(
        () => mockRegisterUser(
          username: any(named: 'username'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.register(tUsername, tEmail, tPassword);

      expect(container.read(authNotifierProvider).hasError, true);
      verify(
        () => mockRegisterUser(
          username: tUsername,
          email: tEmail,
          password: tPassword,
        ),
      ).called(1);
    });

    test('logout() should return AsyncData(null) on success', () async {
      when(() => mockLogoutUser()).thenAnswer((_) async => const Right(null));

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.logout();

      expect(container.read(authNotifierProvider), const AsyncData<User?>(null));
      verify(() => mockLogoutUser()).called(1);
    });

    test('logout() should return AsyncError on failure', () async {
      const tFailure = CacheFailure('Logout failed');
      when(
        () => mockLogoutUser(),
      ).thenAnswer((_) async => const Left(tFailure));

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.logout();

      expect(container.read(authNotifierProvider).hasError, true);
      verify(() => mockLogoutUser()).called(1);
    });
  });
}
