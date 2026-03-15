import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gchess_mobile/core/network/websocket_client.dart';
import 'package:gchess_mobile/core/storage/secure_storage.dart';
import 'package:gchess_mobile/core/error/exceptions.dart';
import 'package:gchess_mobile/features/matchmaking/data/datasources/matchmaking_websocket_data_source.dart';
import 'package:gchess_mobile/features/matchmaking/data/models/match_request_model.dart';
import 'package:gchess_mobile/features/matchmaking/domain/repositories/matchmaking_repository.dart';

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
class TestableMatchmakingDataSource
    extends MatchmakingWebSocketDataSourceImpl {
  final WebSocketClient _testClient;

  TestableMatchmakingDataSource(
    super.secureStorage,
    this._testClient,
  );

  @override
  WebSocketClient createClient(String url, List<String> protocols) =>
      _testClient;
}

class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late MockSecureStorage mockSecureStorage;
  late FakeWebSocketClient fakeClient;
  late TestableMatchmakingDataSource dataSource;

  setUpAll(() {
    registerFallbackValue(MatchRequestModel());
  });

  setUp(() {
    mockSecureStorage = MockSecureStorage();
    fakeClient = FakeWebSocketClient();
    dataSource = TestableMatchmakingDataSource(mockSecureStorage, fakeClient);
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

      await dataSource.connect();

      expect(fakeClient.currentStatus, WebSocketStatus.connected);
    });

    test('should be a no-op when already connected', () async {
      when(
        () => mockSecureStorage.getToken(),
      ).thenAnswer((_) async => 'valid-token');

      // First connection
      await dataSource.connect();
      expect(fakeClient.currentStatus, WebSocketStatus.connected);

      // getToken should not be called again for the second attempt
      await dataSource.connect();

      // Only called once
      verify(() => mockSecureStorage.getToken()).called(1);
    });

    test('should throw WebSocketException when token is null', () async {
      when(
        () => mockSecureStorage.getToken(),
      ).thenAnswer((_) async => null);

      expect(
        () => dataSource.connect(),
        throwsA(isA<WebSocketException>()),
      );
    });

    test('should throw WebSocketException when token is empty', () async {
      when(
        () => mockSecureStorage.getToken(),
      ).thenAnswer((_) async => '');

      expect(
        () => dataSource.connect(),
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
      await dataSource.connect();
    });

    test('QueuePositionUpdate emits QueuePositionEvent', () async {
      expect(
        dataSource.eventStream,
        emits(isA<QueuePositionEvent>()),
      );

      fakeClient.addMessage({
        'type': 'QueuePositionUpdate',
        'position': 3,
      });
    });

    test('MatchFound emits MatchFoundEvent', () async {
      expect(
        dataSource.eventStream,
        emits(isA<MatchFoundEvent>()),
      );

      fakeClient.addMessage({
        'type': 'MatchFound',
        'gameId': 'game-id-1',
        'playerId': 'player-id-1',
        'yourColor': 'WHITE',
        'opponentUserId': 'opponent-user-id-1',
      });
    });

    test('MatchmakingError emits MatchmakingErrorEvent', () async {
      expect(
        dataSource.eventStream,
        emits(isA<MatchmakingErrorEvent>()),
      );

      fakeClient.addMessage({
        'type': 'MatchmakingError',
        'message': 'Queue is full',
      });
    });

    test('AuthFailed emits MatchmakingErrorEvent', () async {
      expect(
        dataSource.eventStream,
        emits(isA<MatchmakingErrorEvent>()),
      );

      fakeClient.addMessage({
        'type': 'AuthFailed',
        'reason': 'Invalid token',
      });
    });

    test('AuthSuccess emits nothing', () async {
      final events = <MatchmakingStreamEvent>[];
      final subscription = dataSource.eventStream.listen(events.add);

      fakeClient.addMessage({'type': 'AuthSuccess'});

      // Give the stream a chance to process
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      expect(events, isEmpty);
    });

    test('unknown message type emits nothing', () async {
      final events = <MatchmakingStreamEvent>[];
      final subscription = dataSource.eventStream.listen(events.add);

      fakeClient.addMessage({'type': 'SomethingUnknown', 'data': 42});

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      expect(events, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // joinQueue()
  // ---------------------------------------------------------------------------
  group('joinQueue', () {
    test('should send message when connected', () async {
      when(
        () => mockSecureStorage.getToken(),
      ).thenAnswer((_) async => 'valid-token');
      await dataSource.connect();

      final request = MatchRequestModel(
        totalTimeMinutes: 10,
        incrementSeconds: 0,
      );

      // Should not throw
      await dataSource.joinQueue(request);
    });

    test('should throw WebSocketException when not connected', () async {
      final request = MatchRequestModel(
        totalTimeMinutes: 10,
        incrementSeconds: 0,
      );

      expect(
        () => dataSource.joinQueue(request),
        throwsA(isA<WebSocketException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // leaveQueue()
  // ---------------------------------------------------------------------------
  group('leaveQueue', () {
    test('should send LeaveQueue message when connected', () async {
      when(
        () => mockSecureStorage.getToken(),
      ).thenAnswer((_) async => 'valid-token');
      await dataSource.connect();

      // Should not throw
      await dataSource.leaveQueue();
    });

    test('should throw WebSocketException when not connected', () async {
      expect(
        () => dataSource.leaveQueue(),
        throwsA(isA<WebSocketException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // disconnect()
  // ---------------------------------------------------------------------------
  group('disconnect', () {
    test('should set client to null so a new connection can be made', () async {
      when(
        () => mockSecureStorage.getToken(),
      ).thenAnswer((_) async => 'valid-token');

      await dataSource.connect();
      expect(fakeClient.currentStatus, WebSocketStatus.connected);

      await dataSource.disconnect();

      // After disconnect, connecting again should succeed (creates a new client
      // via createClient — the fake is returned again here)
      await dataSource.connect();
      // getToken called twice: once before first connect, once before reconnect
      verify(() => mockSecureStorage.getToken()).called(2);
    });
  });
}
