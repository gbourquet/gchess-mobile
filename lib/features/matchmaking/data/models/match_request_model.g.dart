// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchRequestModel _$MatchRequestModelFromJson(Map<String, dynamic> json) =>
    MatchRequestModel(
      type: json['type'] as String? ?? 'JoinQueue',
      totalTimeMinutes: (json['totalTimeMinutes'] as num?)?.toInt() ?? 0,
      incrementSeconds: (json['incrementSeconds'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MatchRequestModelToJson(MatchRequestModel instance) =>
    <String, dynamic>{
      'type': instance.type,
      'totalTimeMinutes': instance.totalTimeMinutes,
      'incrementSeconds': instance.incrementSeconds,
    };
