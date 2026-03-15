import 'package:gchess_mobile/features/game/data/models/player_model.dart';
import 'package:gchess_mobile/features/game/domain/entities/chess_game.dart';
import 'package:gchess_mobile/features/game/domain/entities/game_status.dart';

class ChessGameModel extends ChessGame {
  const ChessGameModel({
    required super.gameId,
    required super.positionFen,
    required super.moveHistory,
    required super.gameStatus,
    required super.currentSide,
    required super.isCheck,
    required super.whitePlayer,
    required super.blackPlayer,
    super.winner,
    super.totalTimeSeconds,
    super.incrementSeconds,
    super.whiteTimeRemainingMs,
    super.blackTimeRemainingMs,
  });

  factory ChessGameModel.fromJson(Map<String, dynamic> json) {
    final whitePlayer = PlayerModel(
      playerId: json['whitePlayerId'] as String,
      userId: '',
      username: json['whiteUsername'] as String? ?? 'White',
      color: 'WHITE',
    );

    final blackPlayer = PlayerModel(
      playerId: json['blackPlayerId'] as String,
      userId: '',
      username: json['blackUsername'] as String? ?? 'Black',
      color: 'BLACK',
    );

    return ChessGameModel(
      gameId: json['gameId'] as String,
      positionFen: json['positionFen'] as String,
      moveHistory: (json['moveHistory'] as List<dynamic>?)?.map((m) {
        if (m is String) return m;
        final map = m as Map<String, dynamic>;
        return '${map['from']}-${map['to']}';
      }).toList() ?? [],
      gameStatus: GameStatusExtension.fromString(json['gameStatus'] as String),
      currentSide: json['currentSide'] as String,
      isCheck: (json['isCheck'] as bool?) ?? false,
      whitePlayer: whitePlayer,
      blackPlayer: blackPlayer,
      winner: json['winner'] as String?,
      totalTimeSeconds: json['totalTimeSeconds'] as int?,
      incrementSeconds: json['incrementSeconds'] as int?,
      whiteTimeRemainingMs: json['whiteTimeRemainingMs'] as int?,
      blackTimeRemainingMs: json['blackTimeRemainingMs'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'positionFen': positionFen,
      'moveHistory': moveHistory,
      'gameStatus': gameStatus.toApiString(),
      'currentSide': currentSide,
      'isCheck': isCheck,
      'whitePlayer': (whitePlayer as PlayerModel).toJson(),
      'blackPlayer': (blackPlayer as PlayerModel).toJson(),
      if (winner != null) 'winner': winner,
      if (totalTimeSeconds != null) 'totalTimeSeconds': totalTimeSeconds,
      if (incrementSeconds != null) 'incrementSeconds': incrementSeconds,
      if (whiteTimeRemainingMs != null) 'whiteTimeRemainingMs': whiteTimeRemainingMs,
      if (blackTimeRemainingMs != null) 'blackTimeRemainingMs': blackTimeRemainingMs,
    };
  }
}
