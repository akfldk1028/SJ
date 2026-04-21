import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/gender.dart';
import '../../domain/entities/saju_profile.dart';
import '../../domain/entities/relationship_type.dart';

part 'saju_profile_model.freezed.dart';
part 'saju_profile_model.g.dart';

/// 사주 프로필 데이터 모델
///
/// Entity를 확장하여 JSON/Hive 직렬화 기능 추가
/// Hive TypeAdapter를 사용하지 않고 Map으로 저장
@freezed
abstract class SajuProfileModel with _$SajuProfileModel {
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
    @Default('me') String relationType, // RelationshipType enum name (deprecated)
    /// 프로필 유형: 'primary' (본인) | 'other' (관계인)
    /// DB의 profile_type 컬럼에 매핑
    @Default('primary') String profileType,
    String? memo,
    /// UI/AI 응답 언어 (ko, ja, en)
    @Default('ko') String locale,
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
      relationType: RelationshipType.values.byName(relationType),
      profileType: profileType,
      memo: memo,
      locale: locale,
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
      relationType: entity.relationType.name,
      profileType: entity.profileType,
      memo: entity.memo,
      locale: entity.locale,
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
      'relationType': relationType,
      'profileType': profileType,
      'memo': memo,
      'locale': locale,
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
      relationType: (map['relationType'] as String?) ?? 'me',
      profileType: (map['profileType'] as String?) ?? 'primary',
      memo: map['memo'] as String?,
      locale: (map['locale'] as String?) ?? 'ko',
    );
  }

  /// Supabase 테이블에 저장할 Map으로 변환
  ///
  /// saju_profiles 테이블 스키마에 맞춤
  /// [userId]는 Supabase auth.uid()
  Map<String, dynamic> toSupabaseMap(String userId) {
    // 일주 기반 zodiac identity 계산
    final zodiac = _computeZodiac(birthDate);

    return {
      'id': id,
      'user_id': userId,
      'display_name': displayName,
      'relation_type': relationType,
      'profile_type': profileType, // NEW: 'primary' | 'other'
      'memo': memo,
      'birth_date': birthDate.toIso8601String().split('T')[0], // DATE 형식
      'birth_time_minutes': birthTimeMinutes,
      'birth_time_unknown': birthTimeUnknown,
      'is_lunar': isLunar,
      'is_leap_month': isLeapMonth,
      'gender': gender,
      'birth_city': birthCity,
      'time_correction': timeCorrection,
      'use_ya_jasi': useYaJasi,
      'locale': locale,
      // zodiac identity (일주 기반)
      'zodiac_animal': zodiac['animal'],
      'zodiac_element': zodiac['element'],
      'zodiac_ganji': zodiac['ganji'],
      // is_primary 컬럼 삭제됨 - profile_type으로 대체
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  /// birthDate → 일주 기반 zodiac 계산 (ZodiacIdentity 의존 없이 순수 계산)
  static Map<String, String> _computeZodiac(DateTime birthDate) {
    const cheongan = ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계'];
    const jiji = ['자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해'];
    const animals = ['rat', 'ox', 'tiger', 'rabbit', 'dragon', 'snake',
                     'horse', 'sheep', 'monkey', 'rooster', 'dog', 'pig'];
    const elements = {
      '갑': 'wood', '을': 'wood', '병': 'fire', '정': 'fire',
      '무': 'earth', '기': 'earth', '경': 'metal', '신': 'metal',
      '임': 'water', '계': 'water',
    };

    final baseDate = DateTime(1900, 1, 1);
    final daysDiff = birthDate.difference(baseDate).inDays;
    int dayIndex = (10 + daysDiff) % 60;
    if (dayIndex < 0) dayIndex += 60;

    final gan = cheongan[dayIndex % 10];
    final ji = jiji[dayIndex % 12];

    return {
      'animal': animals[dayIndex % 12],
      'element': elements[gan] ?? 'earth',
      'ganji': '$gan$ji',
    };
  }

  /// Supabase 응답에서 생성
  static SajuProfileModel fromSupabaseMap(Map<String, dynamic> map) {
    return SajuProfileModel(
      id: map['id'] as String,
      displayName: map['display_name'] as String,
      gender: map['gender'] as String,
      birthDate: DateTime.parse(map['birth_date'] as String),
      isLunar: map['is_lunar'] as bool? ?? false,
      isLeapMonth: map['is_leap_month'] as bool? ?? false,
      birthTimeMinutes: map['birth_time_minutes'] as int?,
      birthTimeUnknown: map['birth_time_unknown'] as bool? ?? false,
      useYaJasi: map['use_ya_jasi'] as bool? ?? true,
      birthCity: map['birth_city'] as String,
      timeCorrection: map['time_correction'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isActive: (map['profile_type'] as String?) == 'primary', // profile_type → isActive
      relationType: map['relation_type'] as String? ?? 'me',
      profileType: map['profile_type'] as String? ?? 'primary',
      memo: map['memo'] as String?,
      locale: map['locale'] as String? ?? 'ko',
    );
  }

  // === 헬퍼 메서드 ===

  /// 본인 프로필 여부
  bool get isPrimaryProfile => profileType == 'primary';

  /// 관계인 프로필 여부
  bool get isOtherProfile => profileType == 'other';
}
