import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/game/data/models/chess_game_model.dart';
import 'package:gchess_mobile/features/game/domain/entities/game_status.dart';

void main() {
  const tJson = {
    'gameId': 'g1',
    'whitePlayerId': 'p1',
    'blackPlayerId': 'p2',
    'whiteUsername': 'alice',
    'blackUsername': 'bob',
    'positionFen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    'moveHistory': [],
    'gameStatus': 'ACTIVE',
    'currentSide': 'WHITE',
    'isCheck': false,
    'winner': null,
    'totalTimeSeconds': 600,
    'incrementSeconds': 5,
    'whiteTimeRemainingMs': 590000,
    'blackTimeRemainingMs': 600000,
  };

  group('ChessGameModel.fromJson', () {
    test('parses basic fields correctly', () {
      final model = ChessGameModel.fromJson(tJson);

      expect(model.gameId, 'g1');
      expect(model.positionFen,
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
      expect(model.gameStatus, GameStatus.active);
      expect(model.currentSide, 'WHITE');
      expect(model.isCheck, isFalse);
    });

    test('parses player info correctly', () {
      final model = ChessGameModel.fromJson(tJson);

      expect(model.whitePlayer.playerId, 'p1');
      expect(model.whitePlayer.username, 'alice');
      expect(model.whitePlayer.color, 'WHITE');
      expect(model.blackPlayer.playerId, 'p2');
      expect(model.blackPlayer.username, 'bob');
      expect(model.blackPlayer.color, 'BLACK');
    });

    test('parses time fields correctly', () {
      final model = ChessGameModel.fromJson(tJson);

      expect(model.totalTimeSeconds, 600);
      expect(model.incrementSeconds, 5);
      expect(model.whiteTimeRemainingMs, 590000);
      expect(model.blackTimeRemainingMs, 600000);
    });

    test('uses default username when whiteUsername is null', () {
      final json = Map<String, dynamic>.from(tJson)
        ..remove('whiteUsername')
        ..remove('blackUsername');

      final model = ChessGameModel.fromJson(json);
      expect(model.whitePlayer.username, 'White');
      expect(model.blackPlayer.username, 'Black');
    });

    test('parses string move history', () {
      final json = Map<String, dynamic>.from(tJson)
        ..['moveHistory'] = ['e2-e4', 'e7-e5'];

      final model = ChessGameModel.fromJson(json);
      expect(model.moveHistory, ['e2-e4', 'e7-e5']);
    });

    test('parses map move history to "from-to" strings', () {
      final json = Map<String, dynamic>.from(tJson)
        ..['moveHistory'] = [
          {'from': 'e2', 'to': 'e4'},
          {'from': 'e7', 'to': 'e5'},
        ];

      final model = ChessGameModel.fromJson(json);
      expect(model.moveHistory, ['e2-e4', 'e7-e5']);
    });

    test('handles null moveHistory as empty list', () {
      final json = Map<String, dynamic>.from(tJson)..['moveHistory'] = null;

      final model = ChessGameModel.fromJson(json);
      expect(model.moveHistory, isEmpty);
    });

    test('parses isCheck=true correctly', () {
      final json = Map<String, dynamic>.from(tJson)..['isCheck'] = true;

      final model = ChessGameModel.fromJson(json);
      expect(model.isCheck, isTrue);
    });

    test('defaults isCheck to false when null', () {
      final json = Map<String, dynamic>.from(tJson)..['isCheck'] = null;

      final model = ChessGameModel.fromJson(json);
      expect(model.isCheck, isFalse);
    });

    test('parses winner field', () {
      final json = Map<String, dynamic>.from(tJson)..['winner'] = 'p1';

      final model = ChessGameModel.fromJson(json);
      expect(model.winner, 'p1');
    });
  });

  group('ChessGameModel.toJson', () {
    test('serializes required fields', () {
      final model = ChessGameModel.fromJson(tJson);
      final json = model.toJson();

      expect(json['gameId'], 'g1');
      expect(json['positionFen'],
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
      expect(json['gameStatus'], 'ACTIVE');
      expect(json['currentSide'], 'WHITE');
      expect(json['isCheck'], isFalse);
    });

    test('includes optional time fields when present', () {
      final model = ChessGameModel.fromJson(tJson);
      final json = model.toJson();

      expect(json['totalTimeSeconds'], 600);
      expect(json['incrementSeconds'], 5);
      expect(json['whiteTimeRemainingMs'], 590000);
      expect(json['blackTimeRemainingMs'], 600000);
    });

    test('omits optional fields when null', () {
      final json = Map<String, dynamic>.from(tJson)
        ..remove('totalTimeSeconds')
        ..remove('incrementSeconds')
        ..remove('whiteTimeRemainingMs')
        ..remove('blackTimeRemainingMs')
        ..remove('winner');

      final model = ChessGameModel.fromJson(json);
      final result = model.toJson();

      expect(result.containsKey('totalTimeSeconds'), isFalse);
      expect(result.containsKey('incrementSeconds'), isFalse);
      expect(result.containsKey('winner'), isFalse);
    });
  });
}
