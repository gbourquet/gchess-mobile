import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gchess_mobile/features/history/data/repositories/history_storage_port.dart';

@singleton
class PreferencesStorage implements HistoryStoragePort {
  final SharedPreferences _preferences;

  static const _userKey = 'cached_user';

  PreferencesStorage(this._preferences);

  Future<void> saveUser(Map<String, dynamic> user) async {
    await _preferences.setString(_userKey, json.encode(user));
  }

  Map<String, dynamic>? getUser() {
    final userString = _preferences.getString(_userKey);
    if (userString != null) {
      return json.decode(userString) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> deleteUser() async {
    await _preferences.remove(_userKey);
  }

  Future<void> clearAll() async {
    await _preferences.clear();
  }

  Future<void> setString(String key, String value) async {
    await _preferences.setString(key, value);
  }

  String? getString(String key) {
    return _preferences.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    await _preferences.setBool(key, value);
  }

  bool? getBool(String key) {
    return _preferences.getBool(key);
  }

  Future<void> setInt(String key, int value) async {
    await _preferences.setInt(key, value);
  }

  int? getInt(String key) {
    return _preferences.getInt(key);
  }

  Future<void> remove(String key) async {
    await _preferences.remove(key);
  }
}
