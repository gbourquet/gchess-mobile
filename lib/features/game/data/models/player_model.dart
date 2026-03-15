import 'package:json_annotation/json_annotation.dart';
import 'package:gchess_mobile/features/game/domain/entities/player.dart';

part 'player_model.g.dart';

@JsonSerializable()
class PlayerModel extends Player {
  const PlayerModel({
    required super.playerId,
    required super.userId,
    required super.username,
    required super.color,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) =>
      _$PlayerModelFromJson(json);

  Map<String, dynamic> toJson() => _$PlayerModelToJson(this);
}
