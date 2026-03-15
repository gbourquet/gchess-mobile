import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/core/error/exceptions.dart';
import 'package:gchess_mobile/core/network/websocket_client.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A fake WebSocketSink that captures sent messages.
class FakeWebSocketSink implements WebSocketSink {
  final List<dynamic> sent = [];
  final _completer = Completer<void>();

  @override
  void add(dynamic data) => sent.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<dynamic> addStream(Stream<dynamic> stream) async {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    if (!_completer.isCompleted) _completer.complete();
  }

  @override
  Future<void> get done => _completer.future;
}

/// A fake WebSocketChannel backed by a StreamController.
class FakeWebSocketChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast();
  final FakeWebSocketSink _sink = FakeWebSocketSink();

  /// Access sent messages for assertions.
  List<dynamic> get sentMessages => _sink.sent;

  @override
  Stream<dynamic> get stream => _controller.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  Future<void> get ready => Future.value();

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  void addMessage(dynamic message) => _controller.add(message);

  void addError(dynamic error) => _controller.addError(error);

  Future<void> close() async {
    await _controller.close();
    await _sink.close();
  }
}

/// Testable subclass that injects FakeWebSocketChannel.
class TestableWebSocketClient extends WebSocketClient {
  final FakeWebSocketChannel fakeChannel;

  TestableWebSocketClient(this.fakeChannel)
      : super(url: 'ws://localhost:8080/test');

  @override
  WebSocketChannel createChannel(Uri uri, {Iterable<String>? protocols}) =>
      fakeChannel;
}

void main() {
  late FakeWebSocketChannel fakeChannel;
  late TestableWebSocketClient client;

  setUp(() {
    fakeChannel = FakeWebSocketChannel();
    client = TestableWebSocketClient(fakeChannel);
  });

  tearDown(() async {
    await fakeChannel.close();
    client.dispose();
  });

  group('WebSocketClient.connect', () {
    test('transitions to connected status', () async {
      await client.connect();
      expect(client.currentStatus, WebSocketStatus.connected);
    });

    test('is a no-op when already connected', () async {
      await client.connect();
      await client.connect(); // second call should be no-op
      expect(client.currentStatus, WebSocketStatus.connected);
    });

    test('emits connecting then connected status events', () async {
      final statuses = <WebSocketStatus>[];
      // Subscribe BEFORE connecting to capture all events
      final sub = client.status.listen(statuses.add);

      await client.connect();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(statuses, contains(WebSocketStatus.connecting));
      expect(statuses, contains(WebSocketStatus.connected));
      await sub.cancel();
    });
  });

  group('WebSocketClient._onMessage', () {
    test('parses JSON string and emits to messages stream', () async {
      await client.connect();

      final completer = Completer<Map<String, dynamic>>();
      client.messages.first.then(completer.complete);

      fakeChannel.addMessage(json.encode({'type': 'test', 'data': 'hello'}));

      final message = await completer.future;
      expect(message['type'], 'test');
      expect(message['data'], 'hello');
    });

    test('handles ping message by not emitting to messages stream', () async {
      await client.connect();

      var messageReceived = false;
      client.messages.listen((_) => messageReceived = true);

      fakeChannel.addMessage(json.encode({'type': 'ping'}));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(messageReceived, isFalse);
      // Should have sent a pong
      expect(fakeChannel.sentMessages, contains(json.encode({'type': 'pong'})));
    });

    test('adds parse error to messages stream on invalid JSON', () async {
      await client.connect();

      final errorCompleter = Completer<Object>();
      client.messages.listen(
        (_) {},
        onError: errorCompleter.complete,
      );

      fakeChannel.addMessage('not valid json {{{{');

      final error = await errorCompleter.future;
      expect(error, isA<WebSocketException>());
    });
  });

  group('WebSocketClient.send', () {
    test('sends JSON-encoded message', () async {
      await client.connect();

      client.send({'type': 'MoveAttempt', 'from': 'e2', 'to': 'e4'});

      expect(
        fakeChannel.sentMessages,
        contains(json.encode({'type': 'MoveAttempt', 'from': 'e2', 'to': 'e4'})),
      );
    });

    test('throws WebSocketException when not connected', () {
      expect(
        () => client.send({'type': 'test'}),
        throwsA(isA<WebSocketException>()),
      );
    });
  });

  group('WebSocketClient.disconnect', () {
    test('transitions to disconnected status', () async {
      await client.connect();
      await client.disconnect();

      expect(client.currentStatus, WebSocketStatus.disconnected);
    });

    test('is no-op for subsequent disconnect calls', () async {
      await client.connect();
      await client.disconnect();
      await client.disconnect(); // should not throw
    });
  });

  group('WebSocketClient._onError', () {
    test('transitions to error status when channel errors', () async {
      await client.connect();

      final statusCompleter = Completer<WebSocketStatus>();
      client.status.listen((s) {
        if (s == WebSocketStatus.error && !statusCompleter.isCompleted) {
          statusCompleter.complete(s);
        }
      });

      fakeChannel.addError('connection failed');

      final status = await statusCompleter.future;
      expect(status, WebSocketStatus.error);
    });
  });

  group('WebSocketClient.dispose', () {
    test('can be disposed after connecting', () async {
      await client.connect();
      // dispose should not throw
      client.dispose();
    });

    test('can be disposed without connecting', () {
      // dispose on fresh client should not throw
      client.dispose();
    });
  });
}
