import 'package:json_annotation/json_annotation.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_result.dart';

part 'match_found_model.g.dart';

@JsonSerializable()
class MatchFoundModel extends MatchResult {
  const MatchFoundModel({
    required super.gameId,
    required super.playerId,
    required super.yourColor,
    required super.opponentUserId,
  });

  factory MatchFoundModel.fromJson(Map<String, dynamic> json) =>
      _$MatchFoundModelFromJson(json);

  Map<String, dynamic> toJson() => _$MatchFoundModelToJson(this);
}
