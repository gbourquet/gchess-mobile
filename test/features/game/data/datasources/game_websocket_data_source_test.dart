import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gchess_mobile/core/network/websocket_client.dart';
import 'package:gchess_mobile/core/storage/secure_storage.dart';
import 'package:gchess_mobile/core/error/exceptions.dart';
import 'package:gchess_mobile/features/game/data/datasources/game_websocket_data_source.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_move.dart';
import 'package:gchess_mobile/features/game/domain/repositories/game_repository.dart';

// ---------------------------------------------------------------------------
// Fake WebSocketClient with controllable message stream
// ---------------------------------------------------------------------------
class FakeWebSocketClient extends Fake implements WebSocketClient {
  final _messagesController =
      StreamController<Map<String, dynamic>>.broadcast();
  bool _connected = false;

  @override
  Stream<Map<String, dynamic>> get messages => _messagesController.stream;

  @override
  WebSocketStatus get currentStatus =>
      _connected ? WebSocketStatus.connected : WebSocketStatus.disconnected;

  @override
  Future<void> connect() async {
    _connected = true;
  }

  @override
  void send(Map<String, dynamic> message) {}

  @override
  Future<void> disconnect() async {
    _connected = false;
  }

  @override
  void dispose() {}

  void addMessage(Map<String, dynamic> message) =>
      _messagesController.add(message);

  void close() => _messagesController.close();
}

// ---------------------------------------------------------------------------
// Testable subclass that injects the fake client
// ---------------------------------------------------------------------------
class TestableGameDataSource extends GameWebSocketDataSourceImpl {
  final WebSocketClient _testClient;

  TestableGameDataSource(
    super.secureStorage,
    this._testClient,
  );

  @override
  WebSocketClient createClient(String url, List<String> protocols) =>
      _testClient;
}

class MockSecureStorage extends Mock implements SecureStorage {}

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

/// A valid GameStateSync message JSON that ChessGameModel.fromJson can parse.
/// Note: ChessGameModel.fromJson reads flat fields: whitePlayerId,
/// blackPlayerId, whiteUsername, blackUsername.
const Map<String, dynamic> tGameStateSyncMessage = {
  'type': 'GameStateSync',
  'gameId': 'game1',
  'positionFen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR',
  'moveHistory': <dynamic>[],
  'gameStatus': 'ACTIVE',
  'currentSide': 'WHITE',
  'isCheck': false,
  'whitePlayerId': 'p1',
  'blackPlayerId': 'p2',
  'whiteUsername': 'White',
  'blackUsername': 'Black',
  'totalTimeSeconds': 600,
  'incrementSeconds': 0,
  'whiteTimeRemainingMs': 600000,
  'blackTimeRemainingMs': 600000,
};

const Map<String, dynamic> tMoveExecutedMessage = {
  'type': 'MoveExecuted',
  'move': {'from': 'e2', 'to': 'e4'},
  'newPositionFen': 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR',
  'gameStatus': 'ACTIVE',
  'currentSide': 'BLACK',
  'isCheck': false,
  'whiteTimeRemainingMs': 598000,
  'blackTimeRemainingMs': 600000,
};

void main() {
  late MockSecureStorage mockSecureStorage;
  late FakeWebSocketClient fakeClient;
  late TestableGameDataSource dataSource;

  const tGameId = 'game-id-1';

  setUpAll(() {
    registerFallbackValue(const ChessMove(from: 'e2', to: 'e4'));
  });

  setUp(() {
    mockSecureStorage = MockSecureStorage();
    fakeClient = FakeWebSocketClient();
    dataSource = TestableGameDataSource(mockSecureStorage, fakeClient);
  });

  tearDown(() {
    fakeClient.close();
  });

  // ---------------------------------------------------------------------------
  // connect()
  // ---------------------------------------------------------------------------
  group('connect', () {
    test('should connect successfully when token is present', () async {
      when(
        () => mockSecureStorage.getToken(),
      ).thenAnswer((_) async => 'valid-token');

      await dataSource.connect(tGameId);

      expect(fakeClient.currentStatus, WebSocketStatus.connected);
    });

    test('should be a no-op when already connected', () async {
      when(
        () => mockSecureStorage.getToken(),
      ).thenAnswer((_) async => 'valid-token');

      await dataSource.connect(tGameId);
      expect(fakeClient.currentStatus, WebSocketStatus.connected);

      await dataSource.connect(tGameId);

      // getToken should only be called once
      verify(() => mockSecureStorage.getToken()).called(1);
    });

    test('should throw WebSocketException when token is null', () async {
      when(
        () => mockSecureStorage.getToken(),
      ).thenAnswer((_) async => null);

      expect(
        () => dataSource.connect(tGameId),
        throwsA(isA<WebSocketException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // _handleMessage (via FakeWebSocketClient.addMessage after connect)
  // ---------------------------------------------------------------------------
  group('_handleMessage', () {
    setUp(() async {
      when(
        () => mockSecureStorage.getToken(),
      ).thenAnswer((_) async => 'valid-token');
      await dataSource.connect(tGameId);
    });

    test('GameStateSync emits GameStateSyncEvent', () async {
      expect(
        dataSource.eventStream,
        emits(isA<GameStateSyncEvent>()),
      );

      fakeClient.addMessage(tGameStateSyncMessage);
    });

    test('MoveExecuted emits MoveExecutedEvent', () async {
      expect(
        dataSource.eventStream,
        emits(isA<MoveExecutedEvent>()),
      );

      fakeClient.addMessage(tMoveExecutedMessage);
    });

    test('MoveRejected emits MoveRejectedEvent', () async {
      expect(
        dataSource.eventStream,
        emits(isA<MoveRejectedEvent>()),
      );

      fakeClient.addMessage({
        'type': 'MoveRejected',
        'reason': 'Illegal move',
      });
    });

    test('GameResigned emits GameResignedEvent', () async {
      expect(
        dataSource.eventStream,
        emits(isA<GameResignedEvent>()),
      );

      fakeClient.addMessage({
        'type': 'GameResigned',
        'resignedPlayerId': 'player-id-1',
        'gameStatus': 'RESIGNED',
      });
    });

    test('DrawOffered emits DrawOfferedEvent', () async {
      expect(
        dataSource.eventStream,
        emits(isA<DrawOfferedEvent>()),
      );

      fakeClient.addMessage({
        'type': 'DrawOffered',
        'offeredByPlayerId': 'player-id-1',
      });
    });

    test('DrawRejected emits DrawRejectedEvent', () async {
      expect(
        dataSource.eventStream,
        emits(isA<DrawRejectedEvent>()),
      );

      fakeClient.addMessage({
        'type': 'DrawRejected',
        'rejectedByPlayerId': 'player-id-2',
      });
    });

    test('TimeoutConfirmed emits TimeoutConfirmedEvent', () async {
      expect(
        dataSource.eventStream,
        emits(isA<TimeoutConfirmedEvent>()),
      );

      fakeClient.addMessage({
        'type': 'TimeoutConfirmed',
        'loserPlayerId': 'player-id-2',
        'gameStatus': 'TIMEOUT',
      });
    });

    test('TimeoutClaimRejected emits TimeoutClaimRejectedEvent', () async {
      expect(
        dataSource.eventStream,
        emits(isA<TimeoutClaimRejectedEvent>()),
      );

      fakeClient.addMessage({
        'type': 'TimeoutClaimRejected',
        'remainingMs': 5000,
      });
    });

    test('GameError emits GameErrorEvent', () async {
      expect(
        dataSource.eventStream,
        emits(isA<GameErrorEvent>()),
      );

      fakeClient.addMessage({
        'type': 'GameError',
        'message': 'Something went wrong',
      });
    });

    test('unknown message type emits nothing', () async {
      final events = <GameStreamEvent>[];
      final subscription = dataSource.eventStream.listen(events.add);

      fakeClient.addMessage({'type': 'SomethingUnknown', 'data': 42});

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      expect(events, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // sendMove()
  // ---------------------------------------------------------------------------
  group('sendMove', () {
    test('should send MoveAttempt message when connected', () async {
      when(
        () => mockSecureStorage.getToken(),
      ).thenAnswer((_) async => 'valid-token');
      await dataSource.connect(tGameId);

      const move = ChessMove(from: 'e2', to: 'e4');

      // Should not throw
      await dataSource.sendMove(move);
    });

    test('should throw WebSocketException when not connected', () async {
      const move = ChessMove(from: 'e2', to: 'e4');

      expect(
        () => dataSource.sendMove(move),
        throwsA(isA<WebSocketException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // resign()
  // ---------------------------------------------------------------------------
  group('resign', () {
    test('should send Resign message when connected', () async {
      when(
        () => mockSecureStorage.getToken(),
      ).thenAnswer((_) async => 'valid-token');
      await dataSource.connect(tGameId);

      await dataSource.resign();
    });

    test('should throw WebSocketException when not connected', () async {
      expect(
        () => dataSource.resign(),
        throwsA(isA<WebSocketException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // offerDraw()
  // ---------------------------------------------------------------------------
  group('offerDraw', () {
    test('should send OfferDraw message when connected', () async {
      when(
        () => mockSecureStorage.getToken(),
      ).thenAnswer((_) async => 'valid-token');
      await dataSource.connect(tGameId);

      await dataSource.offerDraw();
    });

    test('should throw WebSocketException when not connected', () async {
      expect(
        () => dataSource.offerDraw(),
        throwsA(isA<WebSocketException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // acceptDraw()
  // ---------------------------------------------------------------------------
  group('acceptDraw', () {
    test('should send AcceptDraw message when connected', () async {
      when(
        () => mockSecureStorage.getToken(),
      ).thenAnswer((_) async => 'valid-token');
      await dataSource.connect(tGameId);

      await dataSource.acceptDraw();
    });

    test('should throw WebSocketException when not connected', () async {
      expect(
        () => dataSource.acceptDraw(),
        throwsA(isA<WebSocketException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // rejectDraw()
  // ---------------------------------------------------------------------------
  group('rejectDraw', () {
    test('should send RejectDraw message when connected', () async {
      when(
        () => mockSecureStorage.getToken(),
      ).thenAnswer((_) async => 'valid-token');
      await dataSource.connect(tGameId);

      await dataSource.rejectDraw();
    });

    test('should throw WebSocketException when not connected', () async {
      expect(
        () => dataSource.rejectDraw(),
        throwsA(isA<WebSocketException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // claimTimeout()
  // ---------------------------------------------------------------------------
  group('claimTimeout', () {
    test('should send ClaimTimeout message when connected', () async {
      when(
        () => mockSecureStorage.getToken(),
      ).thenAnswer((_) async => 'valid-token');
      await dataSource.connect(tGameId);

      await dataSource.claimTimeout();
    });

    test('should throw WebSocketException when not connected', () async {
      expect(
        () => dataSource.claimTimeout(),
        throwsA(isA<WebSocketException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // disconnect()
  // ---------------------------------------------------------------------------
  group('disconnect', () {
    test('should clean up so a new connection can be established', () async {
      when(
        () => mockSecureStorage.getToken(),
      ).thenAnswer((_) async => 'valid-token');

      await dataSource.connect(tGameId);
      expect(fakeClient.currentStatus, WebSocketStatus.connected);

      await dataSource.disconnect();

      // After disconnect, connecting again should succeed
      await dataSource.connect(tGameId);

      // getToken called twice: once before first connect, once after disconnect
      verify(() => mockSecureStorage.getToken()).called(2);
    });
  });
}
