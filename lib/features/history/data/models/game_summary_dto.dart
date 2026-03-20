class GameSummaryDTO {
  final String gameId;
  final String whiteUserId;
  final String blackUserId;
  final String status;
  final int moveCount;

  const GameSummaryDTO({
    required this.gameId,
    required this.whiteUserId,
    required this.blackUserId,
    required this.status,
    required this.moveCount,
  });

  factory GameSummaryDTO.fromJson(Map<String, dynamic> json) => GameSummaryDTO(
        gameId: json['gameId'] as String,
        whiteUserId: json['whiteUserId'] as String,
        blackUserId: json['blackUserId'] as String,
        status: json['status'] as String,
        moveCount: (json['moveCount'] as num).toInt(),
      );
}
