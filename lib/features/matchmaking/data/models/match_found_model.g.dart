// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_found_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchFoundModel _$MatchFoundModelFromJson(Map<String, dynamic> json) =>
    MatchFoundModel(
      gameId: json['gameId'] as String,
      playerId: json['playerId'] as String,
      yourColor: json['yourColor'] as String,
      opponentUserId: json['opponentUserId'] as String,
    );

Map<String, dynamic> _$MatchFoundModelToJson(MatchFoundModel instance) =>
    <String, dynamic>{
      'gameId': instance.gameId,
      'playerId': instance.playerId,
      'yourColor': instance.yourColor,
      'opponentUserId': instance.opponentUserId,
    };
