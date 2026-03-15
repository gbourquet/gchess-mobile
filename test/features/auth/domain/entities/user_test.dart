import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/auth/domain/entities/user.dart';

void main() {
  const tUser = User(id: '1', username: 'alice', email: 'alice@example.com');

  group('User', () {
    test('props contains id, username, email', () {
      expect(tUser.props, ['1', 'alice', 'alice@example.com']);
    });

    test('equality: same values are equal', () {
      const other = User(id: '1', username: 'alice', email: 'alice@example.com');
      expect(tUser, other);
    });

    test('equality: different id are not equal', () {
      const other = User(id: '2', username: 'alice', email: 'alice@example.com');
      expect(tUser, isNot(other));
    });

    test('equality: different username are not equal', () {
      const other = User(id: '1', username: 'bob', email: 'alice@example.com');
      expect(tUser, isNot(other));
    });

    test('equality: different email are not equal', () {
      const other = User(id: '1', username: 'alice', email: 'bob@example.com');
      expect(tUser, isNot(other));
    });
  });
}
