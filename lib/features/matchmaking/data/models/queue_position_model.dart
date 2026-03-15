import 'package:json_annotation/json_annotation.dart';
import 'package:gchess_mobile/features/matchmaking/domain/entities/queue_position.dart';

part 'queue_position_model.g.dart';

@JsonSerializable()
class QueuePositionModel extends QueuePosition {
  const QueuePositionModel({required super.position});

  factory QueuePositionModel.fromJson(Map<String, dynamic> json) =>
      _$QueuePositionModelFromJson(json);

  Map<String, dynamic> toJson() => _$QueuePositionModelToJson(this);
}
