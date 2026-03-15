import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../error/exceptions.dart';

enum WebSocketStatus {
  connecting,
  connected,
  disconnected,
  reconnecting,
  error,
}

class WebSocketClient {
  WebSocketChannel? _channel;
  final String url;
  final Map<String, String>? headers;
  final Iterable<String>? protocols;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<WebSocketStatus>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<WebSocketStatus> get status => _statusController.stream;

  WebSocketStatus _currentStatus = WebSocketStatus.disconnected;
  WebSocketStatus get currentStatus => _currentStatus;

  bool _isManualDisconnect = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const List<int> _backoffDelays = [1, 2, 4, 8, 30]; // seconds

  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  StreamSubscription? _channelSubscription;

  WebSocketClient({
    required this.url,
    this.headers,
    this.protocols,
  });

  Future<void> connect() async {
    if (_currentStatus == WebSocketStatus.connected ||
        _currentStatus == WebSocketStatus.connecting) {
      return;
    }

    try {
      _isManualDisconnect = false;
      _updateStatus(WebSocketStatus.connecting);

      final uri = Uri.parse(url);
      debugPrint('🔌 WebSocket connecting to: $uri');
      if (protocols != null) {
        debugPrint('🔌 WebSocket protocols: $protocols');
      }
      _channel = createChannel(uri, protocols: protocols);

      _channelSubscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _updateStatus(WebSocketStatus.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();
    } catch (e) {
      _updateStatus(WebSocketStatus.error);
      _scheduleReconnect();
      throw WebSocketException('Failed to connect: $e');
    }
  }

  void _onMessage(dynamic message) {
    try {
      if (message is String) {
        debugPrint('📨 WebSocket received: $message');
        final decoded = json.decode(message) as Map<String, dynamic>;

        // Handle heartbeat/ping messages
        if (decoded['type'] == 'ping') {
          send({'type': 'pong'});
          return;
        }

        _messageController.add(decoded);
      }
    } catch (e) {
      _messageController.addError(WebSocketException('Failed to parse message: $e'));
    }
  }

  void _onError(dynamic error) {
    _updateStatus(WebSocketStatus.error);
    _messageController.addError(WebSocketException('WebSocket error: $error'));

    if (!_isManualDisconnect) {
      _scheduleReconnect();
    }
  }

  void _onDone() {
    _updateStatus(WebSocketStatus.disconnected);
    _stopHeartbeat();

    if (!_isManualDisconnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isManualDisconnect || _reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _updateStatus(WebSocketStatus.reconnecting);

    final delay = _backoffDelays[_reconnectAttempts.clamp(0, _backoffDelays.length - 1)];
    _reconnectAttempts++;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      connect();
    });
  }

  void _startHeartbeat() {
    // Heartbeat disabled for now - backend doesn't support ping/pong yet
    // _heartbeatTimer?.cancel();
    // _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
    //   if (_currentStatus == WebSocketStatus.connected) {
    //     send({'type': 'ping'});
    //   }
    // });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void send(Map<String, dynamic> message) {
    if (_currentStatus != WebSocketStatus.connected) {
      throw WebSocketException('Cannot send message: WebSocket not connected');
    }

    try {
      final encoded = json.encode(message);
      debugPrint('📤 WebSocket sending: $encoded');
      _channel?.sink.add(encoded);
    } catch (e) {
      throw WebSocketException('Failed to send message: $e');
    }
  }

  void _updateStatus(WebSocketStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  Future<void> disconnect() async {
    _isManualDisconnect = true;
    _reconnectTimer?.cancel();
    _stopHeartbeat();

    await _channelSubscription?.cancel();
    await _channel?.sink.close();

    _channel = null;
    _channelSubscription = null;
    _reconnectAttempts = 0;

    _updateStatus(WebSocketStatus.disconnected);
  }

  @visibleForTesting
  WebSocketChannel createChannel(Uri uri, {Iterable<String>? protocols}) =>
      WebSocketChannel.connect(uri, protocols: protocols);

  void dispose() {
    _isManualDisconnect = true;
    _reconnectTimer?.cancel();
    _stopHeartbeat();

    _channelSubscription?.cancel();
    _channel?.sink.close();

    _messageController.close();
    _statusController.close();
  }
}
