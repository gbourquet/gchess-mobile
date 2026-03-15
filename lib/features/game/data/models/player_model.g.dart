// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlayerModel _$PlayerModelFromJson(Map<String, dynamic> json) => PlayerModel(
  playerId: json['playerId'] as String,
  userId: json['userId'] as String,
  username: json['username'] as String,
  color: json['color'] as String,
);

Map<String, dynamic> _$PlayerModelToJson(PlayerModel instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'userId': instance.userId,
      'username': instance.username,
      'color': instance.color,
    };
