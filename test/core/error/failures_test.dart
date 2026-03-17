import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/core/error/failures.dart';

void main() {
  group('Failures', () {
    group('ServerFailure', () {
      test('uses default message', () {
        const failure = ServerFailure();
        expect(failure.message, 'Server error occurred');
      });

      test('uses custom message', () {
        const failure = ServerFailure('Custom server error');
        expect(failure.message, 'Custom server error');
      });

      test('equality — same message', () {
        expect(
          const ServerFailure('msg'),
          equals(const ServerFailure('msg')),
        );
      });

      test('inequality — different message', () {
        expect(
          const ServerFailure('a'),
          isNot(equals(const ServerFailure('b'))),
        );
      });
    });

    group('NetworkFailure', () {
      test('uses default message', () {
        expect(const NetworkFailure().message, 'Network connection failed');
      });

      test('uses custom message', () {
        expect(
          const NetworkFailure('No internet').message,
          'No internet',
        );
      });

      test('equality', () {
        expect(const NetworkFailure(), equals(const NetworkFailure()));
      });
    });

    group('CacheFailure', () {
      test('uses default message', () {
        expect(const CacheFailure().message, 'Cache error occurred');
      });

      test('equality', () {
        expect(const CacheFailure('x'), equals(const CacheFailure('x')));
      });
    });

    group('AuthenticationFailure', () {
      test('uses default message', () {
        expect(
          const AuthenticationFailure().message,
          'Authentication failed',
        );
      });

      test('equality', () {
        expect(
          const AuthenticationFailure(),
          equals(const AuthenticationFailure()),
        );
      });
    });

    group('ValidationFailure', () {
      test('uses default message', () {
        expect(const ValidationFailure().message, 'Validation error');
      });

      test('equality', () {
        expect(
          const ValidationFailure('bad input'),
          equals(const ValidationFailure('bad input')),
        );
      });
    });

    group('WebSocketFailure', () {
      test('uses default message', () {
        expect(
          const WebSocketFailure().message,
          'WebSocket connection failed',
        );
      });

      test('equality', () {
        expect(
          const WebSocketFailure('closed'),
          equals(const WebSocketFailure('closed')),
        );
      });
    });

    group('UnknownFailure', () {
      test('uses default message', () {
        expect(const UnknownFailure().message, 'Unknown error occurred');
      });

      test('equality', () {
        expect(const UnknownFailure(), equals(const UnknownFailure()));
      });
    });

    group('ConflictFailure', () {
      test('uses default message', () {
        expect(const ConflictFailure().message, 'Resource already exists');
      });

      test('equality', () {
        expect(const ConflictFailure(), equals(const ConflictFailure()));
      });
    });

    group('cross-type inequality', () {
      test('ServerFailure != NetworkFailure with same message', () {
        expect(
          const ServerFailure('error'),
          isNot(equals(const NetworkFailure('error'))),
        );
      });

      test('AuthenticationFailure != ValidationFailure with same message', () {
        expect(
          const AuthenticationFailure('bad'),
          isNot(equals(const ValidationFailure('bad'))),
        );
      });
    });

    group('props', () {
      test('props contains the message', () {
        const failure = ServerFailure('test message');
        expect(failure.props, ['test message']);
      });
    });
  });
}
