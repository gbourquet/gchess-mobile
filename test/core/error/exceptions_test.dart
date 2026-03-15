import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/core/error/exceptions.dart';

void main() {
  group('Exceptions', () {
    test('ServerException has default message', () {
      final e = ServerException();
      expect(e.message, 'Server error occurred');
      expect(e.toString(), contains('ServerException'));
    });

    test('ServerException accepts custom message', () {
      final e = ServerException('custom');
      expect(e.message, 'custom');
    });

    test('NetworkException has default message', () {
      final e = NetworkException();
      expect(e.message, 'Network connection failed');
      expect(e.toString(), contains('NetworkException'));
    });

    test('NetworkException accepts custom message', () {
      expect(NetworkException('err').message, 'err');
    });

    test('CacheException has default message', () {
      final e = CacheException();
      expect(e.message, 'Cache error occurred');
      expect(e.toString(), contains('CacheException'));
    });

    test('CacheException accepts custom message', () {
      expect(CacheException('c').message, 'c');
    });

    test('AuthenticationException has default message', () {
      final e = AuthenticationException();
      expect(e.message, 'Authentication failed');
      expect(e.toString(), contains('AuthenticationException'));
    });

    test('AuthenticationException accepts custom message', () {
      expect(AuthenticationException('a').message, 'a');
    });

    test('ValidationException has default message', () {
      final e = ValidationException();
      expect(e.message, 'Validation error');
      expect(e.toString(), contains('ValidationException'));
    });

    test('ValidationException accepts custom message', () {
      expect(ValidationException('v').message, 'v');
    });

    test('WebSocketException has default message', () {
      final e = WebSocketException();
      expect(e.message, 'WebSocket connection failed');
      expect(e.toString(), contains('WebSocketException'));
    });

    test('WebSocketException accepts custom message', () {
      expect(WebSocketException('ws').message, 'ws');
    });

    test('ConflictException has default message', () {
      final e = ConflictException();
      expect(e.message, 'Resource already exists');
      expect(e.toString(), contains('ConflictException'));
    });

    test('ConflictException accepts custom message', () {
      expect(ConflictException('conflict').message, 'conflict');
    });
  });
}
