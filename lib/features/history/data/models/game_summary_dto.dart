class GameSummaryDTO {
  final String gameId;
  final String whiteUserId;
  final String blackUserId;
  final String whiteUsername;
  final String blackUsername;
  final String status;
  final int moveCount;
  final String? winnerUserId;
  final int? whiteTimeRemainingMs;
  final int? blackTimeRemainingMs;
  final int? totalTimeSeconds;
  final int? incrementSeconds;
  final DateTime? playedAt;

  const GameSummaryDTO({
    required this.gameId,
    required this.whiteUserId,
    required this.blackUserId,
    required this.whiteUsername,
    required this.blackUsername,
    required this.status,
    required this.moveCount,
    this.winnerUserId,
    this.whiteTimeRemainingMs,
    this.blackTimeRemainingMs,
    this.totalTimeSeconds,
    this.incrementSeconds,
    this.playedAt,
  });

  factory GameSummaryDTO.fromJson(Map<String, dynamic> json) => GameSummaryDTO(
        gameId: json['gameId'] as String,
        whiteUserId: json['whiteUserId'] as String,
        blackUserId: json['blackUserId'] as String,
        whiteUsername: json['whiteUsername'] as String? ?? '?',
        blackUsername: json['blackUsername'] as String? ?? '?',
        status: json['status'] as String,
        moveCount: (json['moveCount'] as num).toInt(),
        winnerUserId: json['winnerUserId'] as String?,
        whiteTimeRemainingMs: (json['whiteTimeRemainingMs'] as num?)?.toInt(),
        blackTimeRemainingMs: (json['blackTimeRemainingMs'] as num?)?.toInt(),
        totalTimeSeconds: (json['totalTimeSeconds'] as num?)?.toInt(),
        incrementSeconds: (json['incrementSeconds'] as num?)?.toInt(),
        playedAt: json['playedAt'] != null
            ? DateTime.tryParse(json['playedAt'] as String)
            : null,
      );
}
