import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/core/utils/validators.dart';

void main() {
  group('Validators.validateEmail', () {
    test('returns error when null', () {
      expect(Validators.validateEmail(null), isNotNull);
    });

    test('returns error when empty', () {
      expect(Validators.validateEmail(''), isNotNull);
    });

    test('returns error for invalid email', () {
      expect(Validators.validateEmail('notanemail'), isNotNull);
      expect(Validators.validateEmail('missing@tld'), isNotNull);
      expect(Validators.validateEmail('@nodomain.com'), isNotNull);
    });

    test('returns null for valid email', () {
      expect(Validators.validateEmail('user@example.com'), isNull);
      expect(Validators.validateEmail('a.b+c@sub.domain.org'), isNull);
    });
  });

  group('Validators.validateUsername', () {
    test('returns error when null', () {
      expect(Validators.validateUsername(null), isNotNull);
    });

    test('returns error when empty', () {
      expect(Validators.validateUsername(''), isNotNull);
    });

    test('returns error when too short', () {
      expect(Validators.validateUsername('ab'), isNotNull);
    });

    test('returns error when too long', () {
      expect(Validators.validateUsername('a' * 21), isNotNull);
    });

    test('returns error for invalid characters', () {
      expect(Validators.validateUsername('user name'), isNotNull);
      expect(Validators.validateUsername('user@name'), isNotNull);
    });

    test('returns null for valid username', () {
      expect(Validators.validateUsername('abc'), isNull);
      expect(Validators.validateUsername('user_123'), isNull);
      expect(Validators.validateUsername('a' * 20), isNull);
    });
  });

  group('Validators.validatePassword', () {
    test('returns error when null', () {
      expect(Validators.validatePassword(null), isNotNull);
    });

    test('returns error when empty', () {
      expect(Validators.validatePassword(''), isNotNull);
    });

    test('returns error when too short', () {
      expect(Validators.validatePassword('12345'), isNotNull);
    });

    test('returns null for valid password', () {
      expect(Validators.validatePassword('123456'), isNull);
      expect(Validators.validatePassword('mysecretpassword'), isNull);
    });
  });

  group('Validators.validateConfirmPassword', () {
    test('returns error when null', () {
      expect(Validators.validateConfirmPassword(null, 'pass'), isNotNull);
    });

    test('returns error when empty', () {
      expect(Validators.validateConfirmPassword('', 'pass'), isNotNull);
    });

    test('returns error when passwords do not match', () {
      expect(Validators.validateConfirmPassword('other', 'pass'), isNotNull);
    });

    test('returns null when passwords match', () {
      expect(Validators.validateConfirmPassword('pass', 'pass'), isNull);
    });
  });

  group('Validators.validateRequired', () {
    test('returns error when null', () {
      expect(Validators.validateRequired(null, 'Field'), isNotNull);
    });

    test('returns error when empty', () {
      expect(Validators.validateRequired('', 'Field'), isNotNull);
    });

    test('returns null when value is present', () {
      expect(Validators.validateRequired('value', 'Field'), isNull);
    });

    test('includes field name in error message', () {
      final error = Validators.validateRequired(null, 'Email');
      expect(error, contains('Email'));
    });
  });
}
