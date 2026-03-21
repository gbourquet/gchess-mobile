import 'package:chess/chess.dart' as chess_lib;

class GameRecord {
  final String gameId;
  final String playerId;
  final String whiteUsername;
  final String blackUsername;
  final String whitePlayerId;
  final String blackPlayerId;
  final String result;
  final String? winner;
  final List<String> uciHistory;
  final List<String> sanHistory;
  final List<String> fenHistory;
  final String finalFen;
  final int? totalTimeSeconds;
  final int? incrementSeconds;
  final DateTime playedAt;
  // From backend summary (used when sanHistory is not yet loaded)
  final int? rawMoveCount;
  final int? whiteTimeRemainingMs;
  final int? blackTimeRemainingMs;
  final List<int?>? moveTimes;

  const GameRecord({
    required this.gameId,
    required this.playerId,
    required this.whiteUsername,
    required this.blackUsername,
    required this.whitePlayerId,
    required this.blackPlayerId,
    required this.result,
    this.winner,
    required this.uciHistory,
    required this.sanHistory,
    required this.fenHistory,
    required this.finalFen,
    this.totalTimeSeconds,
    this.incrementSeconds,
    required this.playedAt,
    this.rawMoveCount,
    this.whiteTimeRemainingMs,
    this.blackTimeRemainingMs,
    this.moveTimes,
  });

  bool get isPlayerWhite => whitePlayerId == playerId;

  String get opponentUsername =>
      isPlayerWhite ? blackUsername : whiteUsername;

  static GameRecord fromGame({
    required String gameId,
    required String playerId,
    required String whiteUsername,
    required String blackUsername,
    required String whitePlayerId,
    required String blackPlayerId,
    required String result,
    required String? winner,
    required List<String> uciHistory,
    required String finalFen,
    int? totalTimeSeconds,
    int? incrementSeconds,
    required DateTime playedAt,
    int? whiteTimeRemainingMs,
    int? blackTimeRemainingMs,
    List<int?>? moveTimes,
  }) {
    final chess = chess_lib.Chess();
    final sanList = <String>[];
    final fenList = <String>[];

    for (final uci in uciHistory) {
      final parts = uci.split('-');
      if (parts.length < 2) continue;
      final from = parts[0];
      final to = parts[1];
      final promotion = parts.length >= 3 ? parts[2] : null;

      String san = uci;
      final verboseMoves = chess.moves({'square': from, 'verbose': true});
      for (final m in verboseMoves) {
        if (m is Map && m['to'] == to) {
          san = m['san'] as String? ?? uci;
          break;
        }
      }

      final moveMap = <String, dynamic>{'from': from, 'to': to};
      if (promotion != null) moveMap['promotion'] = promotion;
      if (chess.move(moveMap)) {
        sanList.add(san);
        fenList.add(chess.fen);
      }
    }

    return GameRecord(
      gameId: gameId,
      playerId: playerId,
      whiteUsername: whiteUsername,
      blackUsername: blackUsername,
      whitePlayerId: whitePlayerId,
      blackPlayerId: blackPlayerId,
      result: result,
      winner: winner,
      uciHistory: uciHistory,
      sanHistory: sanList,
      fenHistory: fenList,
      finalFen: finalFen,
      totalTimeSeconds: totalTimeSeconds,
      incrementSeconds: incrementSeconds,
      playedAt: playedAt,
      whiteTimeRemainingMs: whiteTimeRemainingMs,
      blackTimeRemainingMs: blackTimeRemainingMs,
      moveTimes: moveTimes,
    );
  }

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'playerId': playerId,
        'whiteUsername': whiteUsername,
        'blackUsername': blackUsername,
        'whitePlayerId': whitePlayerId,
        'blackPlayerId': blackPlayerId,
        'result': result,
        'winner': winner,
        'uciHistory': uciHistory,
        'sanHistory': sanHistory,
        'fenHistory': fenHistory,
        'finalFen': finalFen,
        'totalTimeSeconds': totalTimeSeconds,
        'incrementSeconds': incrementSeconds,
        'playedAt': playedAt.toIso8601String(),
        'whiteTimeRemainingMs': whiteTimeRemainingMs,
        'blackTimeRemainingMs': blackTimeRemainingMs,
        'moveTimes': moveTimes,
      };

  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
        gameId: json['gameId'] as String,
        playerId: json['playerId'] as String,
        whiteUsername: json['whiteUsername'] as String,
        blackUsername: json['blackUsername'] as String,
        whitePlayerId: json['whitePlayerId'] as String,
        blackPlayerId: json['blackPlayerId'] as String,
        result: json['result'] as String,
        winner: json['winner'] as String?,
        uciHistory: List<String>.from(json['uciHistory'] as List),
        sanHistory: List<String>.from(json['sanHistory'] as List),
        fenHistory: List<String>.from(json['fenHistory'] as List),
        finalFen: json['finalFen'] as String,
        totalTimeSeconds: json['totalTimeSeconds'] as int?,
        incrementSeconds: json['incrementSeconds'] as int?,
        playedAt: DateTime.parse(json['playedAt'] as String),
        whiteTimeRemainingMs: json['whiteTimeRemainingMs'] as int?,
        blackTimeRemainingMs: json['blackTimeRemainingMs'] as int?,
        moveTimes: (json['moveTimes'] as List?)?.cast<int?>(),
      );
}
