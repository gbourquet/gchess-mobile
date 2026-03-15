import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gchess_mobile/core/storage/secure_storage.dart';
import 'package:gchess_mobile/core/storage/preferences_storage.dart';
import 'package:gchess_mobile/core/error/exceptions.dart';
import 'package:gchess_mobile/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:gchess_mobile/features/auth/data/models/user_model.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

class MockPreferencesStorage extends Mock implements PreferencesStorage {}

void main() {
  late MockSecureStorage mockSecureStorage;
  late MockPreferencesStorage mockPreferencesStorage;
  late AuthLocalDataSourceImpl dataSource;

  const tToken = 'jwt-token-123';
  const tUsername = 'testuser';
  const tPassword = 'password123';
  const tUser = UserModel(
    id: 'user-id-1',
    username: tUsername,
    email: 'test@test.com',
  );

  // The key used internally by AuthLocalDataSourceImpl
  const tUserKey = 'current_user';

  setUp(() {
    mockSecureStorage = MockSecureStorage();
    mockPreferencesStorage = MockPreferencesStorage();
    dataSource = AuthLocalDataSourceImpl(
      mockSecureStorage,
      mockPreferencesStorage,
    );
  });

  // ---------------------------------------------------------------------------
  // saveToken
  // ---------------------------------------------------------------------------
  group('saveToken', () {
    test('should call SecureStorage.saveToken with the given token', () async {
      when(
        () => mockSecureStorage.saveToken(any()),
      ).thenAnswer((_) async {});

      await dataSource.saveToken(tToken);

      verify(() => mockSecureStorage.saveToken(tToken));
    });

    test('should throw CacheException when SecureStorage throws', () async {
      when(
        () => mockSecureStorage.saveToken(any()),
      ).thenThrow(Exception('storage error'));

      expect(
        () => dataSource.saveToken(tToken),
        throwsA(isA<CacheException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getToken
  // ---------------------------------------------------------------------------
  group('getToken', () {
    test('should return token when SecureStorage has one', () async {
      when(
        () => mockSecureStorage.getToken(),
      ).thenAnswer((_) async => tToken);

      final result = await dataSource.getToken();

      expect(result, tToken);
    });

    test('should return null when SecureStorage returns null', () async {
      when(
        () => mockSecureStorage.getToken(),
      ).thenAnswer((_) async => null);

      final result = await dataSource.getToken();

      expect(result, isNull);
    });

    test('should throw CacheException when SecureStorage throws', () async {
      when(
        () => mockSecureStorage.getToken(),
      ).thenThrow(Exception('storage error'));

      expect(
        () => dataSource.getToken(),
        throwsA(isA<CacheException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // deleteToken
  // ---------------------------------------------------------------------------
  group('deleteToken', () {
    test('should call SecureStorage.deleteToken', () async {
      when(
        () => mockSecureStorage.deleteToken(),
      ).thenAnswer((_) async {});

      await dataSource.deleteToken();

      verify(() => mockSecureStorage.deleteToken());
    });

    test('should throw CacheException when SecureStorage throws', () async {
      when(
        () => mockSecureStorage.deleteToken(),
      ).thenThrow(Exception('storage error'));

      expect(
        () => dataSource.deleteToken(),
        throwsA(isA<CacheException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // saveUser
  // ---------------------------------------------------------------------------
  group('saveUser', () {
    test('should store JSON-encoded user in PreferencesStorage', () async {
      when(
        () => mockPreferencesStorage.setString(any(), any()),
      ).thenAnswer((_) async {});

      await dataSource.saveUser(tUser);

      final expectedJson = json.encode(tUser.toJson());
      verify(
        () => mockPreferencesStorage.setString(tUserKey, expectedJson),
      );
    });

    test('should throw CacheException when PreferencesStorage throws',
        () async {
      when(
        () => mockPreferencesStorage.setString(any(), any()),
      ).thenThrow(Exception('storage error'));

      expect(
        () => dataSource.saveUser(tUser),
        throwsA(isA<CacheException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getUser
  // ---------------------------------------------------------------------------
  group('getUser', () {
    test('should return UserModel when PreferencesStorage has JSON', () async {
      final userJson = json.encode(tUser.toJson());
      when(
        () => mockPreferencesStorage.getString(tUserKey),
      ).thenReturn(userJson);

      final result = await dataSource.getUser();

      expect(result, tUser);
    });

    test('should return null when PreferencesStorage has no data', () async {
      when(
        () => mockPreferencesStorage.getString(tUserKey),
      ).thenReturn(null);

      final result = await dataSource.getUser();

      expect(result, isNull);
    });

    test('should throw CacheException when PreferencesStorage throws',
        () async {
      when(
        () => mockPreferencesStorage.getString(tUserKey),
      ).thenThrow(Exception('storage error'));

      expect(
        () => dataSource.getUser(),
        throwsA(isA<CacheException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // deleteUser
  // ---------------------------------------------------------------------------
  group('deleteUser', () {
    test('should call PreferencesStorage.remove with the user key', () async {
      when(
        () => mockPreferencesStorage.remove(any()),
      ).thenAnswer((_) async {});

      await dataSource.deleteUser();

      verify(() => mockPreferencesStorage.remove(tUserKey));
    });

    test('should throw CacheException when PreferencesStorage throws',
        () async {
      when(
        () => mockPreferencesStorage.remove(any()),
      ).thenThrow(Exception('storage error'));

      expect(
        () => dataSource.deleteUser(),
        throwsA(isA<CacheException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // saveCredentials
  // ---------------------------------------------------------------------------
  group('saveCredentials', () {
    test('should call SecureStorage.saveCredentials', () async {
      when(
        () => mockSecureStorage.saveCredentials(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});

      await dataSource.saveCredentials(
        username: tUsername,
        password: tPassword,
      );

      verify(
        () => mockSecureStorage.saveCredentials(
          username: tUsername,
          password: tPassword,
        ),
      );
    });

    test('should throw CacheException when SecureStorage throws', () async {
      when(
        () => mockSecureStorage.saveCredentials(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('storage error'));

      expect(
        () => dataSource.saveCredentials(
          username: tUsername,
          password: tPassword,
        ),
        throwsA(isA<CacheException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getUsername
  // ---------------------------------------------------------------------------
  group('getUsername', () {
    test('should return username when SecureStorage has one', () async {
      when(
        () => mockSecureStorage.getUsername(),
      ).thenAnswer((_) async => tUsername);

      final result = await dataSource.getUsername();

      expect(result, tUsername);
    });

    test('should return null when SecureStorage returns null', () async {
      when(
        () => mockSecureStorage.getUsername(),
      ).thenAnswer((_) async => null);

      final result = await dataSource.getUsername();

      expect(result, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // getPassword
  // ---------------------------------------------------------------------------
  group('getPassword', () {
    test('should return password when SecureStorage has one', () async {
      when(
        () => mockSecureStorage.getPassword(),
      ).thenAnswer((_) async => tPassword);

      final result = await dataSource.getPassword();

      expect(result, tPassword);
    });

    test('should return null when SecureStorage returns null', () async {
      when(
        () => mockSecureStorage.getPassword(),
      ).thenAnswer((_) async => null);

      final result = await dataSource.getPassword();

      expect(result, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // deleteCredentials
  // ---------------------------------------------------------------------------
  group('deleteCredentials', () {
    test('should call SecureStorage.deleteCredentials', () async {
      when(
        () => mockSecureStorage.deleteCredentials(),
      ).thenAnswer((_) async {});

      await dataSource.deleteCredentials();

      verify(() => mockSecureStorage.deleteCredentials());
    });

    test('should throw CacheException when SecureStorage throws', () async {
      when(
        () => mockSecureStorage.deleteCredentials(),
      ).thenThrow(Exception('storage error'));

      expect(
        () => dataSource.deleteCredentials(),
        throwsA(isA<CacheException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // hasStoredCredentials
  // ---------------------------------------------------------------------------
  group('hasStoredCredentials', () {
    test('should return true when both username and password are present',
        () async {
      when(
        () => mockSecureStorage.hasStoredCredentials(),
      ).thenAnswer((_) async => true);

      final result = await dataSource.hasStoredCredentials();

      expect(result, isTrue);
    });

    test('should return false when credentials are missing', () async {
      when(
        () => mockSecureStorage.hasStoredCredentials(),
      ).thenAnswer((_) async => false);

      final result = await dataSource.hasStoredCredentials();

      expect(result, isFalse);
    });
  });
}
