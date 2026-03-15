import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:gchess_mobile/config/app_config.dart';
import 'package:gchess_mobile/core/error/exceptions.dart';
import 'package:gchess_mobile/core/network/websocket_client.dart';
import 'package:gchess_mobile/core/storage/secure_storage.dart';
import 'package:gchess_mobile/features/game/data/models/chess_game_model.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_move.dart';
import 'package:gchess_mobile/features/game/domain/repositories/game_repository.dart';

abstract class GameWebSocketDataSource {
  Future<void> connect(String gameId);
  Future<void> sendMove(ChessMove move);
  Future<void> resign();
  Future<void> offerDraw();
  Future<void> acceptDraw();
  Future<void> rejectDraw();
  Future<void> claimTimeout();
  Future<void> disconnect();
  Stream<GameStreamEvent> get eventStream;
}

@Singleton(as: GameWebSocketDataSource)
class GameWebSocketDataSourceImpl implements GameWebSocketDataSource {
  final SecureStorage _secureStorage;

  WebSocketClient? _client;
  final _eventController = StreamController<GameStreamEvent>.broadcast();
  StreamSubscription? _messageSubscription;

  GameWebSocketDataSourceImpl(this._secureStorage);

  @override
  Stream<GameStreamEvent> get eventStream => _eventController.stream;

  @override
  Future<void> connect(String gameId) async {
    try {
      if (_client != null &&
          _client!.currentStatus == WebSocketStatus.connected) {
        return;
      }

      final token = await _secureStorage.getToken();
      if (token == null || token.isEmpty) {
        throw AuthenticationException('No auth token found');
      }

      final wsUri = Uri.parse('${AppConfig.websocketUrl}/ws/game/$gameId')
          .replace(queryParameters: {'token': token});
      _client = createClient(wsUri.toString(), ['Bearer $token']);

      _messageSubscription = _client!.messages.listen(
        _handleMessage,
        onError: (error) =>
            _eventController.add(GameErrorEvent('WebSocket error: $error')),
      );

      await _client!.connect();
    } catch (e) {
      throw WebSocketException('Failed to connect to game: $e');
    }
  }

  void _handleMessage(Map<String, dynamic> message) {
    try {
      final type = message['type'] as String?;
      print('🎮 WebSocket message received: $type');
      print('📦 Full message: $message');

      switch (type) {
        case 'GameStateSync':
          final game = ChessGameModel.fromJson(message);
          print(
            '♟️  GameStateSync: currentSide=${game.currentSide}, white=${game.whitePlayer.username}, black=${game.blackPlayer.username}',
          );
          _eventController.add(GameStateSyncEvent(game));
          break;

        case 'MoveExecuted':
          print(
            '✅ MoveExecuted: ${message['move']['from']}->${message['move']['to']}, nextSide=${message['currentSide']}',
          );
          _eventController.add(
            MoveExecutedEvent(
              move: ChessMove(
                from: message['move']['from'] as String,
                to: message['move']['to'] as String,
                promotion: message['move']['promotion'] as String?,
              ),
              newPositionFen: message['newPositionFen'] as String,
              gameStatus: message['gameStatus'] as String,
              currentSide: message['currentSide'] as String,
              isCheck: message['isCheck'] as bool,
              whiteTimeRemainingMs: message['whiteTimeRemainingMs'] as int?,
              blackTimeRemainingMs: message['blackTimeRemainingMs'] as int?,
            ),
          );
          break;

        case 'MoveRejected':
          _eventController.add(
            MoveRejectedEvent(message['reason'] as String? ?? 'Move rejected'),
          );
          break;

        case 'PlayerDisconnected':
          _eventController.add(
            PlayerDisconnectedEvent(message['playerId'] as String),
          );
          break;

        case 'PlayerReconnected':
          _eventController.add(
            PlayerReconnectedEvent(message['playerId'] as String),
          );
          break;

        case 'GameResigned':
          _eventController.add(
            GameResignedEvent(
              resignedPlayerId: message['resignedPlayerId'] as String,
              gameStatus: message['gameStatus'] as String,
            ),
          );
          break;

        case 'DrawOffered':
          _eventController.add(
            DrawOfferedEvent(
              offeredByPlayerId: message['offeredByPlayerId'] as String,
            ),
          );
          break;

        case 'DrawAccepted':
          _eventController.add(
            DrawAcceptedEvent(
              acceptedByPlayerId: message['acceptedByPlayerId'] as String,
              gameStatus: message['gameStatus'] as String,
            ),
          );
          break;

        case 'DrawRejected':
          _eventController.add(
            DrawRejectedEvent(
              rejectedByPlayerId: message['rejectedByPlayerId'] as String,
            ),
          );
          break;

        case 'TimeoutConfirmed':
          _eventController.add(
            TimeoutConfirmedEvent(
              loserPlayerId: message['loserPlayerId'] as String,
              gameStatus: message['gameStatus'] as String,
            ),
          );
          break;

        case 'TimeoutClaimRejected':
          _eventController.add(
            TimeoutClaimRejectedEvent(
              remainingMs: message['remainingMs'] as int,
            ),
          );
          break;

        case 'GameError':
          _eventController.add(
            GameErrorEvent(message['message'] as String? ?? 'Game error'),
          );
          break;
      }
    } catch (e) {
      _eventController.add(GameErrorEvent('Failed to parse message: $e'));
    }
  }

  @override
  Future<void> sendMove(ChessMove move) async {
    if (_client == null ||
        _client!.currentStatus != WebSocketStatus.connected) {
      throw WebSocketException('Not connected to game');
    }

    try {
      final message = {
        'type': 'MoveAttempt',
        'from': move.from,
        'to': move.to,
        if (move.promotion != null) 'promotion': move.promotion,
      };
      _client!.send(message);
    } catch (e) {
      throw WebSocketException('Failed to send move: $e');
    }
  }

  @override
  Future<void> resign() async {
    if (_client == null ||
        _client!.currentStatus != WebSocketStatus.connected) {
      throw WebSocketException('Not connected to game');
    }

    try {
      _client!.send({'type': 'Resign'});
    } catch (e) {
      throw WebSocketException('Failed to resign: $e');
    }
  }

  @override
  Future<void> offerDraw() async {
    if (_client == null ||
        _client!.currentStatus != WebSocketStatus.connected) {
      throw WebSocketException('Not connected to game');
    }

    try {
      _client!.send({'type': 'OfferDraw'});
    } catch (e) {
      throw WebSocketException('Failed to offer draw: $e');
    }
  }

  @override
  Future<void> acceptDraw() async {
    if (_client == null ||
        _client!.currentStatus != WebSocketStatus.connected) {
      throw WebSocketException('Not connected to game');
    }

    try {
      _client!.send({'type': 'AcceptDraw'});
    } catch (e) {
      throw WebSocketException('Failed to accept draw: $e');
    }
  }

  @override
  Future<void> rejectDraw() async {
    if (_client == null ||
        _client!.currentStatus != WebSocketStatus.connected) {
      throw WebSocketException('Not connected to game');
    }

    try {
      _client!.send({'type': 'RejectDraw'});
    } catch (e) {
      throw WebSocketException('Failed to reject draw: $e');
    }
  }

  @override
  Future<void> claimTimeout() async {
    if (_client == null ||
        _client!.currentStatus != WebSocketStatus.connected) {
      throw WebSocketException('Not connected to game');
    }

    try {
      _client!.send({'type': 'ClaimTimeout'});
    } catch (e) {
      throw WebSocketException('Failed to claim timeout: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    await _messageSubscription?.cancel();
    await _client?.disconnect();
    _client = null;
    _messageSubscription = null;
  }

  @visibleForTesting
  WebSocketClient createClient(String url, List<String> protocols) =>
      WebSocketClient(url: url, protocols: protocols);

  void dispose() {
    _messageSubscription?.cancel();
    _client?.dispose();
    _eventController.close();
  }
}
