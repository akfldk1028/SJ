// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saju_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SajuProfileModel _$SajuProfileModelFromJson(Map<String, dynamic> json) =>
    _SajuProfileModel(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      gender: json['gender'] as String,
      birthDate: DateTime.parse(json['birthDate'] as String),
      isLunar: json['isLunar'] as bool,
      isLeapMonth: json['isLeapMonth'] as bool? ?? false,
      birthTimeMinutes: (json['birthTimeMinutes'] as num?)?.toInt(),
      birthTimeUnknown: json['birthTimeUnknown'] as bool? ?? false,
      useYaJasi: json['useYaJasi'] as bool? ?? true,
      birthCity: json['birthCity'] as String,
      timeCorrection: (json['timeCorrection'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? false,
      relationType: json['relationType'] as String? ?? 'me',
      profileType: json['profileType'] as String? ?? 'primary',
      memo: json['memo'] as String?,
    );

Map<String, dynamic> _$SajuProfileModelToJson(_SajuProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'gender': instance.gender,
      'birthDate': instance.birthDate.toIso8601String(),
      'isLunar': instance.isLunar,
      'isLeapMonth': instance.isLeapMonth,
      'birthTimeMinutes': instance.birthTimeMinutes,
      'birthTimeUnknown': instance.birthTimeUnknown,
      'useYaJasi': instance.useYaJasi,
      'birthCity': instance.birthCity,
      'timeCorrection': instance.timeCorrection,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isActive': instance.isActive,
      'relationType': instance.relationType,
      'profileType': instance.profileType,
      'memo': instance.memo,
    };
