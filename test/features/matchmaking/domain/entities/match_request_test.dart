import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_request.dart';

void main() {
  group('MatchRequest', () {
    test('default values are 0', () {
      const req = MatchRequest();
      expect(req.totalTimeMinutes, 0);
      expect(req.incrementSeconds, 0);
    });

    test('props contains totalTimeMinutes and incrementSeconds', () {
      const req = MatchRequest(totalTimeMinutes: 10, incrementSeconds: 5);
      expect(req.props, [10, 5]);
    });

    test('equality: same values are equal', () {
      const a = MatchRequest(totalTimeMinutes: 10, incrementSeconds: 5);
      const b = MatchRequest(totalTimeMinutes: 10, incrementSeconds: 5);
      expect(a, b);
    });

    test('equality: different totalTimeMinutes are not equal', () {
      const a = MatchRequest(totalTimeMinutes: 10, incrementSeconds: 5);
      const b = MatchRequest(totalTimeMinutes: 5, incrementSeconds: 5);
      expect(a, isNot(b));
    });

    test('equality: different incrementSeconds are not equal', () {
      const a = MatchRequest(totalTimeMinutes: 10, incrementSeconds: 5);
      const b = MatchRequest(totalTimeMinutes: 10, incrementSeconds: 0);
      expect(a, isNot(b));
    });

    test('null fields are supported', () {
      const req = MatchRequest(totalTimeMinutes: null, incrementSeconds: null);
      expect(req.totalTimeMinutes, isNull);
      expect(req.incrementSeconds, isNull);
      expect(req.props, [null, null]);
    });
  });
}
