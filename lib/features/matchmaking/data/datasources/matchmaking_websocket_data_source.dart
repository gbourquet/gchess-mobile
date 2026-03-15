import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:gchess_mobile/config/app_config.dart';
import 'package:gchess_mobile/core/error/exceptions.dart';
import 'package:gchess_mobile/core/network/websocket_client.dart';
import 'package:gchess_mobile/core/storage/secure_storage.dart';
import 'package:gchess_mobile/features/matchmaking/data/models/match_found_model.dart';
import 'package:gchess_mobile/features/matchmaking/data/models/match_request_model.dart';
import 'package:gchess_mobile/features/matchmaking/data/models/queue_position_model.dart';
import 'package:gchess_mobile/features/matchmaking/domain/repositories/matchmaking_repository.dart';

abstract class MatchmakingWebSocketDataSource {
  Future<void> connect();
  Future<void> joinQueue(MatchRequestModel request);
  Future<void> leaveQueue();
  Future<void> disconnect();
  Stream<MatchmakingStreamEvent> get eventStream;
}

@Singleton(as: MatchmakingWebSocketDataSource)
class MatchmakingWebSocketDataSourceImpl
    implements MatchmakingWebSocketDataSource {
  final SecureStorage _secureStorage;

  WebSocketClient? _client;
  final _eventController = StreamController<MatchmakingStreamEvent>.broadcast();

  StreamSubscription? _messageSubscription;

  MatchmakingWebSocketDataSourceImpl(this._secureStorage);

  @override
  Stream<MatchmakingStreamEvent> get eventStream => _eventController.stream;

  @override
  Future<void> connect() async {
    try {
      if (_client != null &&
          _client!.currentStatus == WebSocketStatus.connected) {
        return;
      }

      final token = await _secureStorage.getToken();
      if (token == null || token.isEmpty) {
        throw AuthenticationException('No auth token found');
      }

      final wsUri = Uri.parse('${AppConfig.websocketUrl}/ws/matchmaking')
          .replace(queryParameters: {'token': token});
      _client = WebSocketClient(
        url: wsUri.toString(),
        protocols: ['Bearer $token'],
      );

      _messageSubscription = _client!.messages.listen(
        _handleMessage,
        onError: (error) {
          _eventController
              .add(MatchmakingErrorEvent('WebSocket error: $error'));
        },
      );

      await _client!.connect();
    } catch (e) {
      throw WebSocketException('Failed to connect to matchmaking: $e');
    }
  }

  void _handleMessage(Map<String, dynamic> message) {
    try {
      final type = message['type'] as String?;

      switch (type) {
        case 'QueuePositionUpdate':
          final position = QueuePositionModel.fromJson(message);
          _eventController.add(QueuePositionEvent(position));
          break;

        case 'MatchFound':
          final matchResult = MatchFoundModel.fromJson(message);
          _eventController.add(MatchFoundEvent(matchResult));
          break;

        case 'MatchmakingError':
          final errorMessage = message['message'] as String? ?? 'Unknown error';
          _eventController.add(MatchmakingErrorEvent(errorMessage));
          break;

        case 'AuthSuccess':
          // Authentication successful, nothing to do
          break;

        case 'AuthFailed':
          final errorMessage =
              message['reason'] as String? ?? 'Authentication failed';
          _eventController.add(MatchmakingErrorEvent(errorMessage));
          break;

        default:
          // Unknown message type, ignore
          break;
      }
    } catch (e) {
      _eventController.add(MatchmakingErrorEvent('Failed to parse message: $e'));
    }
  }

  @override
  Future<void> joinQueue(MatchRequestModel request) async {
    if (_client == null ||
        _client!.currentStatus != WebSocketStatus.connected) {
      throw WebSocketException('Not connected to matchmaking');
    }

    try {
      _client!.send(request.toJson());
    } catch (e) {
      throw WebSocketException('Failed to join queue: $e');
    }
  }

  @override
  Future<void> leaveQueue() async {
    if (_client == null ||
        _client!.currentStatus != WebSocketStatus.connected) {
      throw WebSocketException('Not connected to matchmaking');
    }

    try {
      _client!.send({'type': 'LeaveQueue'});
    } catch (e) {
      throw WebSocketException('Failed to leave queue: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    await _messageSubscription?.cancel();
    await _client?.disconnect();
    _client = null;
    _messageSubscription = null;
  }

  void dispose() {
    _messageSubscription?.cancel();
    _client?.dispose();
    _eventController.close();
  }
}
