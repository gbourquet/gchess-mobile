import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/game/data/models/player_model.dart';

void main() {
  group('PlayerModel', () {
    const tModel = PlayerModel(
      playerId: 'player-1',
      userId: 'user-1',
      username: 'Alice',
      color: 'WHITE',
    );

    final tJson = {
      'playerId': 'player-1',
      'userId': 'user-1',
      'username': 'Alice',
      'color': 'WHITE',
    };

    test('fromJson creates instance with correct fields', () {
      final result = PlayerModel.fromJson(tJson);
      expect(result.playerId, 'player-1');
      expect(result.userId, 'user-1');
      expect(result.username, 'Alice');
      expect(result.color, 'WHITE');
    });

    test('toJson returns correct map', () {
      expect(tModel.toJson(), tJson);
    });

    test('round-trip', () {
      final result = PlayerModel.fromJson(tModel.toJson());
      expect(result.playerId, tModel.playerId);
      expect(result.userId, tModel.userId);
      expect(result.username, tModel.username);
      expect(result.color, tModel.color);
    });

    test('BLACK color is preserved', () {
      final json = {'playerId': 'p2', 'userId': 'u2', 'username': 'Bob', 'color': 'BLACK'};
      final result = PlayerModel.fromJson(json);
      expect(result.color, 'BLACK');
    });
  });
}
