import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/core/storage/secure_storage.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorage secureStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    secureStorage = SecureStorage(mockStorage);
  });

  group('SecureStorage token', () {
    test('saveToken writes to auth_token key', () async {
      when(
        () => mockStorage.write(key: 'auth_token', value: 'mytoken'),
      ).thenAnswer((_) async {});

      await secureStorage.saveToken('mytoken');

      verify(() => mockStorage.write(key: 'auth_token', value: 'mytoken'))
          .called(1);
    });

    test('getToken reads from auth_token key', () async {
      when(
        () => mockStorage.read(key: 'auth_token'),
      ).thenAnswer((_) async => 'mytoken');

      expect(await secureStorage.getToken(), 'mytoken');
    });

    test('getToken returns null when not set', () async {
      when(
        () => mockStorage.read(key: 'auth_token'),
      ).thenAnswer((_) async => null);

      expect(await secureStorage.getToken(), isNull);
    });

    test('deleteToken deletes auth_token key', () async {
      when(
        () => mockStorage.delete(key: 'auth_token'),
      ).thenAnswer((_) async {});

      await secureStorage.deleteToken();

      verify(() => mockStorage.delete(key: 'auth_token')).called(1);
    });
  });

  group('SecureStorage credentials', () {
    test('saveCredentials writes username and password', () async {
      when(
        () => mockStorage.write(key: 'auth_username', value: 'alice'),
      ).thenAnswer((_) async {});
      when(
        () => mockStorage.write(key: 'auth_password', value: 'secret'),
      ).thenAnswer((_) async {});

      await secureStorage.saveCredentials(
        username: 'alice',
        password: 'secret',
      );

      verify(
        () => mockStorage.write(key: 'auth_username', value: 'alice'),
      ).called(1);
      verify(
        () => mockStorage.write(key: 'auth_password', value: 'secret'),
      ).called(1);
    });

    test('getUsername reads from auth_username key', () async {
      when(
        () => mockStorage.read(key: 'auth_username'),
      ).thenAnswer((_) async => 'alice');

      expect(await secureStorage.getUsername(), 'alice');
    });

    test('getPassword reads from auth_password key', () async {
      when(
        () => mockStorage.read(key: 'auth_password'),
      ).thenAnswer((_) async => 'secret');

      expect(await secureStorage.getPassword(), 'secret');
    });

    test('hasStoredCredentials returns true when both are set', () async {
      when(
        () => mockStorage.read(key: 'auth_username'),
      ).thenAnswer((_) async => 'alice');
      when(
        () => mockStorage.read(key: 'auth_password'),
      ).thenAnswer((_) async => 'secret');

      expect(await secureStorage.hasStoredCredentials(), isTrue);
    });

    test('hasStoredCredentials returns false when username is null', () async {
      when(
        () => mockStorage.read(key: 'auth_username'),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorage.read(key: 'auth_password'),
      ).thenAnswer((_) async => 'secret');

      expect(await secureStorage.hasStoredCredentials(), isFalse);
    });

    test('hasStoredCredentials returns false when password is null', () async {
      when(
        () => mockStorage.read(key: 'auth_username'),
      ).thenAnswer((_) async => 'alice');
      when(
        () => mockStorage.read(key: 'auth_password'),
      ).thenAnswer((_) async => null);

      expect(await secureStorage.hasStoredCredentials(), isFalse);
    });

    test('deleteCredentials deletes both keys', () async {
      when(
        () => mockStorage.delete(key: 'auth_username'),
      ).thenAnswer((_) async {});
      when(
        () => mockStorage.delete(key: 'auth_password'),
      ).thenAnswer((_) async {});

      await secureStorage.deleteCredentials();

      verify(() => mockStorage.delete(key: 'auth_username')).called(1);
      verify(() => mockStorage.delete(key: 'auth_password')).called(1);
    });
  });

  group('SecureStorage generic operations', () {
    test('clearAll calls deleteAll', () async {
      when(() => mockStorage.deleteAll()).thenAnswer((_) async {});

      await secureStorage.clearAll();

      verify(() => mockStorage.deleteAll()).called(1);
    });

    test('write delegates to storage', () async {
      when(
        () => mockStorage.write(key: 'k', value: 'v'),
      ).thenAnswer((_) async {});

      await secureStorage.write('k', 'v');

      verify(() => mockStorage.write(key: 'k', value: 'v')).called(1);
    });

    test('read delegates to storage', () async {
      when(
        () => mockStorage.read(key: 'k'),
      ).thenAnswer((_) async => 'v');

      expect(await secureStorage.read('k'), 'v');
    });

    test('delete delegates to storage', () async {
      when(() => mockStorage.delete(key: 'k')).thenAnswer((_) async {});

      await secureStorage.delete('k');

      verify(() => mockStorage.delete(key: 'k')).called(1);
    });
  });
}
