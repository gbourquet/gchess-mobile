import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/auth/data/models/login_request.dart';
import 'package:gchess_mobile/features/auth/data/models/login_response.dart';
import 'package:gchess_mobile/features/auth/data/models/register_request.dart';
import 'package:gchess_mobile/features/auth/data/models/user_model.dart';

void main() {
  group('LoginRequest', () {
    const tModel = LoginRequest(username: 'alice', password: 'secret');
    final tJson = {'username': 'alice', 'password': 'secret'};

    test('fromJson creates instance with correct fields', () {
      final result = LoginRequest.fromJson(tJson);
      expect(result.username, 'alice');
      expect(result.password, 'secret');
    });

    test('toJson returns correct map', () {
      expect(tModel.toJson(), tJson);
    });

    test('toJson → fromJson round-trip', () {
      final result = LoginRequest.fromJson(tModel.toJson());
      expect(result.username, tModel.username);
      expect(result.password, tModel.password);
    });
  });

  group('RegisterRequest', () {
    const tModel = RegisterRequest(
      username: 'alice',
      email: 'alice@example.com',
      password: 'secret',
    );
    final tJson = {
      'username': 'alice',
      'email': 'alice@example.com',
      'password': 'secret',
    };

    test('fromJson creates instance with correct fields', () {
      final result = RegisterRequest.fromJson(tJson);
      expect(result.username, 'alice');
      expect(result.email, 'alice@example.com');
      expect(result.password, 'secret');
    });

    test('toJson returns correct map', () {
      expect(tModel.toJson(), tJson);
    });

    test('toJson → fromJson round-trip', () {
      final result = RegisterRequest.fromJson(tModel.toJson());
      expect(result.username, tModel.username);
      expect(result.email, tModel.email);
      expect(result.password, tModel.password);
    });
  });

  group('UserModel', () {
    const tModel = UserModel(
      id: 'user-1',
      username: 'alice',
      email: 'alice@example.com',
    );
    final tJson = {
      'id': 'user-1',
      'username': 'alice',
      'email': 'alice@example.com',
    };

    test('fromJson creates instance with correct fields', () {
      final result = UserModel.fromJson(tJson);
      expect(result.id, 'user-1');
      expect(result.username, 'alice');
      expect(result.email, 'alice@example.com');
    });

    test('toJson returns correct map', () {
      expect(tModel.toJson(), tJson);
    });

    test('round-trip', () {
      final result = UserModel.fromJson(tModel.toJson());
      expect(result.id, tModel.id);
      expect(result.username, tModel.username);
      expect(result.email, tModel.email);
    });
  });

  group('LoginResponse', () {
    final tJson = {
      'token': 'jwt-token-123',
      'user': {
        'id': 'user-1',
        'username': 'alice',
        'email': 'alice@example.com',
      },
    };

    test('fromJson parses token and nested user', () {
      final result = LoginResponse.fromJson(tJson);
      expect(result.token, 'jwt-token-123');
      expect(result.user.id, 'user-1');
      expect(result.user.username, 'alice');
      expect(result.user.email, 'alice@example.com');
    });

    test('toJson serializes token', () {
      final model = LoginResponse.fromJson(tJson);
      final json = model.toJson();
      expect(json['token'], 'jwt-token-123');
    });

    test('toJson contient la clé user', () {
      final model = LoginResponse.fromJson(tJson);
      final json = model.toJson();
      expect(json.containsKey('user'), isTrue);
    });
  });
}
