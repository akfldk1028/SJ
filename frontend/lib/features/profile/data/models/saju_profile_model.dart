import '../../domain/entities/saju_profile.dart';
import '../../domain/entities/gender.dart';

/// SajuProfile Model
///
/// Entity를 상속하고 JSON 변환 추가
/// Supabase 테이블과 매핑
class SajuProfileModel extends SajuProfile {
  const SajuProfileModel({
    required super.id,
    super.userId,
    required super.displayName,
    required super.birthDate,
    super.birthTimeMinutes,
    super.birthTimeUnknown,
    super.isLunar,
    required super.gender,
    super.birthPlace,
    super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  /// JSON에서 Model 생성
  factory SajuProfileModel.fromJson(Map<String, dynamic> json) {
    return SajuProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      displayName: json['display_name'] as String,
      birthDate: DateTime.parse(json['birth_date'] as String),
      birthTimeMinutes: json['birth_time_minutes'] as int?,
      birthTimeUnknown: json['birth_time_unknown'] as bool? ?? false,
      isLunar: json['is_lunar'] as bool? ?? false,
      gender: Gender.fromString(json['gender'] as String),
      birthPlace: json['birth_place'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Model을 JSON으로 변환 (INSERT/UPDATE용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'display_name': displayName,
      'birth_date': birthDate.toIso8601String().split('T')[0], // DATE 형식
      'birth_time_minutes': birthTimeMinutes,
      'birth_time_unknown': birthTimeUnknown,
      'is_lunar': isLunar,
      'gender': gender.value,
      'birth_place': birthPlace,
      'is_active': isActive,
    };
  }

  /// INSERT용 JSON (id, created_at, updated_at 제외)
  Map<String, dynamic> toInsertJson() {
    final json = toJson();
    json.remove('id'); // DB에서 자동 생성
    json.remove('created_at');
    json.remove('updated_at');
    return json;
  }

  /// UPDATE용 JSON (id, user_id, created_at 제외)
  Map<String, dynamic> toUpdateJson() {
    final json = toJson();
    json.remove('id');
    json.remove('user_id');
    json.remove('created_at');
    json.remove('updated_at');
    return json;
  }

  /// Entity에서 Model 생성
  factory SajuProfileModel.fromEntity(SajuProfile entity) {
    return SajuProfileModel(
      id: entity.id,
      userId: entity.userId,
      displayName: entity.displayName,
      birthDate: entity.birthDate,
      birthTimeMinutes: entity.birthTimeMinutes,
      birthTimeUnknown: entity.birthTimeUnknown,
      isLunar: entity.isLunar,
      gender: entity.gender,
      birthPlace: entity.birthPlace,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Entity로 변환
  SajuProfile toEntity() {
    return SajuProfile(
      id: id,
      userId: userId,
      displayName: displayName,
      birthDate: birthDate,
      birthTimeMinutes: birthTimeMinutes,
      birthTimeUnknown: birthTimeUnknown,
      isLunar: isLunar,
      gender: gender,
      birthPlace: birthPlace,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
