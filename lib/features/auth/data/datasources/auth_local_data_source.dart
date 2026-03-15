import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:gchess_mobile/core/error/exceptions.dart';
import 'package:gchess_mobile/core/storage/preferences_storage.dart';
import 'package:gchess_mobile/core/storage/secure_storage.dart';
import 'package:gchess_mobile/features/auth/data/models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();

  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser();
  Future<void> deleteUser();

  Future<void> saveCredentials({required String username, required String password});
  Future<String?> getUsername();
  Future<String?> getPassword();
  Future<void> deleteCredentials();
  Future<bool> hasStoredCredentials();
}

@Injectable(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorage _secureStorage;
  final PreferencesStorage _preferencesStorage;

  static const String _userKey = 'current_user';

  AuthLocalDataSourceImpl(
    this._secureStorage,
    this._preferencesStorage,
  );

  @override
  Future<void> saveToken(String token) async {
    try {
      await _secureStorage.saveToken(token);
    } catch (e) {
      throw CacheException('Failed to save token: $e');
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await _secureStorage.getToken();
    } catch (e) {
      throw CacheException('Failed to get token: $e');
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      await _secureStorage.deleteToken();
    } catch (e) {
      throw CacheException('Failed to delete token: $e');
    }
  }

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      final userJson = json.encode(user.toJson());
      await _preferencesStorage.setString(_userKey, userJson);
    } catch (e) {
      throw CacheException('Failed to save user: $e');
    }
  }

  @override
  Future<UserModel?> getUser() async {
    try {
      final userJson = _preferencesStorage.getString(_userKey);
      if (userJson == null) return null;

      final userMap = json.decode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (e) {
      throw CacheException('Failed to get user: $e');
    }
  }

  @override
  Future<void> deleteUser() async {
    try {
      await _preferencesStorage.remove(_userKey);
    } catch (e) {
      throw CacheException('Failed to delete user: $e');
    }
  }

  @override
  Future<void> saveCredentials({
    required String username,
    required String password,
  }) async {
    try {
      await _secureStorage.saveCredentials(
        username: username,
        password: password,
      );
    } catch (e) {
      throw CacheException('Failed to save credentials: $e');
    }
  }

  @override
  Future<String?> getUsername() async {
    try {
      return await _secureStorage.getUsername();
    } catch (e) {
      throw CacheException('Failed to get username: $e');
    }
  }

  @override
  Future<String?> getPassword() async {
    try {
      return await _secureStorage.getPassword();
    } catch (e) {
      throw CacheException('Failed to get password: $e');
    }
  }

  @override
  Future<void> deleteCredentials() async {
    try {
      await _secureStorage.deleteCredentials();
    } catch (e) {
      throw CacheException('Failed to delete credentials: $e');
    }
  }

  @override
  Future<bool> hasStoredCredentials() async {
    try {
      return await _secureStorage.hasStoredCredentials();
    } catch (e) {
      throw CacheException('Failed to check credentials: $e');
    }
  }
}
