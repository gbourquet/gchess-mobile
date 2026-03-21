class MoveSummaryDTO {
  final String from;
  final String to;
  final int moveNumber;
  final String? promotion;
  final int? timeSpentMs;

  const MoveSummaryDTO({
    required this.from,
    required this.to,
    required this.moveNumber,
    this.promotion,
    this.timeSpentMs,
  });

  factory MoveSummaryDTO.fromJson(Map<String, dynamic> json) => MoveSummaryDTO(
        from: json['from'] as String,
        to: json['to'] as String,
        moveNumber: (json['moveNumber'] as num).toInt(),
        promotion: json['promotion'] as String?,
        timeSpentMs: (json['timeSpentMs'] as num?)?.toInt(),
      );

  String toUci() => promotion != null ? '$from-$to-$promotion' : '$from-$to';
}
