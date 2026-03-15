import 'package:json_annotation/json_annotation.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/match_request.dart';

part 'match_request_model.g.dart';

@JsonSerializable()
class MatchRequestModel {
  final String type;
  final int? totalTimeMinutes;
  final int? incrementSeconds;

  MatchRequestModel({
    this.type = 'JoinQueue',
    this.totalTimeMinutes = 0,
    this.incrementSeconds = 0,
  });

  factory MatchRequestModel.fromEntity(MatchRequest entity) {
    return MatchRequestModel(
      totalTimeMinutes: entity.totalTimeMinutes,
      incrementSeconds: entity.incrementSeconds,
    );
  }

  factory MatchRequestModel.fromJson(Map<String, dynamic> json) =>
      _$MatchRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$MatchRequestModelToJson(this);
}
