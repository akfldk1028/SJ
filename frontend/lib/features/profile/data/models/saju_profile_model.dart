import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/gender.dart';
import '../../domain/entities/saju_profile.dart';

part 'saju_profile_model.freezed.dart';
part 'saju_profile_model.g.dart';

/// 사주 프로필 데이터 모델
///
/// Entity를 확장하여 JSON/Hive 직렬화 기능 추가
/// Hive TypeAdapter를 사용하지 않고 Map으로 저장
@freezed
class SajuProfileModel with _$SajuProfileModel {
  const factory SajuProfileModel({
    required String id,
    required String displayName,
    required String gender, // Gender enum을 문자열로 저장
    required DateTime birthDate,
    required bool isLunar,
    @Default(false) bool isLeapMonth,
    int? birthTimeMinutes,
    @Default(false) bool birthTimeUnknown,
    @Default(true) bool useYaJasi,
    required String birthCity,
    @Default(0) int timeCorrection,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool isActive,
  }) = _SajuProfileModel;

  const SajuProfileModel._();

  /// JSON 직렬화
  factory SajuProfileModel.fromJson(Map<String, dynamic> json) =>
      _$SajuProfileModelFromJson(json);

  /// Entity로 변환
  SajuProfile toEntity() {
    return SajuProfile(
      id: id,
      displayName: displayName,
      gender: Gender.fromString(gender),
      birthDate: birthDate,
      isLunar: isLunar,
      isLeapMonth: isLeapMonth,
      birthTimeMinutes: birthTimeMinutes,
      birthTimeUnknown: birthTimeUnknown,
      useYaJasi: useYaJasi,
      birthCity: birthCity,
      timeCorrection: timeCorrection,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
    );
  }

  /// Entity에서 생성
  static SajuProfileModel fromEntity(SajuProfile entity) {
    return SajuProfileModel(
      id: entity.id,
      displayName: entity.displayName,
      gender: entity.gender.name,
      birthDate: entity.birthDate,
      isLunar: entity.isLunar,
      isLeapMonth: entity.isLeapMonth,
      birthTimeMinutes: entity.birthTimeMinutes,
      birthTimeUnknown: entity.birthTimeUnknown,
      useYaJasi: entity.useYaJasi,
      birthCity: entity.birthCity,
      timeCorrection: entity.timeCorrection,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isActive: entity.isActive,
    );
  }

  /// Hive에 저장할 Map으로 변환
  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'displayName': displayName,
      'gender': gender,
      'birthDate': birthDate.millisecondsSinceEpoch,
      'isLunar': isLunar,
      'isLeapMonth': isLeapMonth,
      'birthTimeMinutes': birthTimeMinutes,
      'birthTimeUnknown': birthTimeUnknown,
      'useYaJasi': useYaJasi,
      'birthCity': birthCity,
      'timeCorrection': timeCorrection,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }

  /// Hive Map에서 생성
  static SajuProfileModel fromHiveMap(Map<dynamic, dynamic> map) {
    return SajuProfileModel(
      id: map['id'] as String,
      displayName: map['displayName'] as String,
      gender: map['gender'] as String,
      birthDate: DateTime.fromMillisecondsSinceEpoch(map['birthDate'] as int),
      isLunar: map['isLunar'] as bool,
      isLeapMonth: (map['isLeapMonth'] as bool?) ?? false,
      birthTimeMinutes: map['birthTimeMinutes'] as int?,
      birthTimeUnknown: (map['birthTimeUnknown'] as bool?) ?? false,
      useYaJasi: (map['useYaJasi'] as bool?) ?? true,
      birthCity: map['birthCity'] as String,
      timeCorrection: (map['timeCorrection'] as int?) ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      isActive: (map['isActive'] as bool?) ?? false,
    );
  }
}
