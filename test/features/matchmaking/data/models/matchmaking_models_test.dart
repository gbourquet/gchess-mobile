import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/matchmaking/data/models/match_found_model.dart';
import 'package:gchess_mobile/features/matchmaking/data/models/match_request_model.dart';
import 'package:gchess_mobile/features/matchmaking/data/models/queue_position_model.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_request.dart';

void main() {
  group('MatchFoundModel', () {
    final tJson = {
      'gameId': 'game-1',
      'playerId': 'player-1',
      'yourColor': 'WHITE',
      'opponentUserId': 'opponent-1',
    };

    test('fromJson creates instance with correct fields', () {
      final result = MatchFoundModel.fromJson(tJson);
      expect(result.gameId, 'game-1');
      expect(result.playerId, 'player-1');
      expect(result.yourColor, 'WHITE');
      expect(result.opponentUserId, 'opponent-1');
    });

    test('toJson returns correct map', () {
      final model = MatchFoundModel.fromJson(tJson);
      expect(model.toJson(), tJson);
    });

    test('round-trip', () {
      const model = MatchFoundModel(
        gameId: 'game-2',
        playerId: 'player-2',
        yourColor: 'BLACK',
        opponentUserId: 'opponent-2',
      );
      final result = MatchFoundModel.fromJson(model.toJson());
      expect(result.gameId, model.gameId);
      expect(result.yourColor, model.yourColor);
    });
  });

  group('QueuePositionModel', () {
    test('fromJson parses position', () {
      final result = QueuePositionModel.fromJson({'position': 3});
      expect(result.position, 3);
    });

    test('toJson serializes position', () {
      const model = QueuePositionModel(position: 5);
      expect(model.toJson(), {'position': 5});
    });

    test('round-trip', () {
      const model = QueuePositionModel(position: 1);
      final result = QueuePositionModel.fromJson(model.toJson());
      expect(result.position, 1);
    });
  });

  group('MatchRequestModel', () {
    test('default values are set', () {
      final model = MatchRequestModel();
      expect(model.type, 'JoinQueue');
      expect(model.totalTimeMinutes, 0);
      expect(model.incrementSeconds, 0);
    });

    test('fromEntity maps entity fields', () {
      const entity = MatchRequest(totalTimeMinutes: 10, incrementSeconds: 5);
      final model = MatchRequestModel.fromEntity(entity);
      expect(model.totalTimeMinutes, 10);
      expect(model.incrementSeconds, 5);
      expect(model.type, 'JoinQueue');
    });

    test('fromEntity avec valeurs par défaut (0)', () {
      // MatchRequest() a totalTimeMinutes=0 et incrementSeconds=0 par défaut
      const entity = MatchRequest();
      final model = MatchRequestModel.fromEntity(entity);
      expect(model.totalTimeMinutes, 0);
      expect(model.incrementSeconds, 0);
    });

    test('fromJson / toJson round-trip', () {
      final model = MatchRequestModel(
        type: 'JoinQueue',
        totalTimeMinutes: 5,
        incrementSeconds: 3,
      );
      final result = MatchRequestModel.fromJson(model.toJson());
      expect(result.type, 'JoinQueue');
      expect(result.totalTimeMinutes, 5);
      expect(result.incrementSeconds, 3);
    });
  });
}
