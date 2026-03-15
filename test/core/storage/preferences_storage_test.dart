import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/core/storage/preferences_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockSharedPreferences mockPrefs;
  late PreferencesStorage storage;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    storage = PreferencesStorage(mockPrefs);
  });

  group('PreferencesStorage.saveUser / getUser', () {
    test('saveUser encodes map to JSON and stores it', () async {
      when(
        () => mockPrefs.setString(any(), any()),
      ).thenAnswer((_) async => true);

      await storage.saveUser({'id': '1', 'username': 'alice'});

      verify(() => mockPrefs.setString('cached_user', any())).called(1);
    });

    test('getUser returns null when nothing stored', () {
      when(() => mockPrefs.getString('cached_user')).thenReturn(null);

      expect(storage.getUser(), isNull);
    });

    test('getUser decodes JSON string to map', () {
      when(
        () => mockPrefs.getString('cached_user'),
      ).thenReturn('{"id":"1","username":"alice"}');

      final user = storage.getUser();
      expect(user, {'id': '1', 'username': 'alice'});
    });
  });

  group('PreferencesStorage.deleteUser', () {
    test('removes cached_user key', () async {
      when(() => mockPrefs.remove('cached_user')).thenAnswer((_) async => true);

      await storage.deleteUser();

      verify(() => mockPrefs.remove('cached_user')).called(1);
    });
  });

  group('PreferencesStorage.clearAll', () {
    test('calls preferences.clear()', () async {
      when(() => mockPrefs.clear()).thenAnswer((_) async => true);

      await storage.clearAll();

      verify(() => mockPrefs.clear()).called(1);
    });
  });

  group('PreferencesStorage generic string/bool/int', () {
    test('setString stores value', () async {
      when(
        () => mockPrefs.setString('key', 'val'),
      ).thenAnswer((_) async => true);

      await storage.setString('key', 'val');

      verify(() => mockPrefs.setString('key', 'val')).called(1);
    });

    test('getString returns value', () {
      when(() => mockPrefs.getString('key')).thenReturn('val');

      expect(storage.getString('key'), 'val');
    });

    test('setBool stores value', () async {
      when(
        () => mockPrefs.setBool('flag', true),
      ).thenAnswer((_) async => true);

      await storage.setBool('flag', true);

      verify(() => mockPrefs.setBool('flag', true)).called(1);
    });

    test('getBool returns value', () {
      when(() => mockPrefs.getBool('flag')).thenReturn(true);

      expect(storage.getBool('flag'), isTrue);
    });

    test('setInt stores value', () async {
      when(() => mockPrefs.setInt('count', 42)).thenAnswer((_) async => true);

      await storage.setInt('count', 42);

      verify(() => mockPrefs.setInt('count', 42)).called(1);
    });

    test('getInt returns value', () {
      when(() => mockPrefs.getInt('count')).thenReturn(42);

      expect(storage.getInt('count'), 42);
    });

    test('remove deletes key', () async {
      when(() => mockPrefs.remove('key')).thenAnswer((_) async => true);

      await storage.remove('key');

      verify(() => mockPrefs.remove('key')).called(1);
    });
  });
}
