/// Profile 스키마 정의
///
/// Supabase saju_profiles 테이블 스키마 매핑

/// 테이블명
const String profilesTable = 'saju_profiles';

/// 컬럼명 상수
abstract class ProfileColumns {
  static const String id = 'id';
  static const String userId = 'user_id';
  static const String displayName = 'display_name';
  static const String relationType = 'relation_type';
  static const String memo = 'memo';
  static const String birthDate = 'birth_date';
  static const String birthTimeMinutes = 'birth_time_minutes';
  static const String birthTimeUnknown = 'birth_time_unknown';
  static const String isLunar = 'is_lunar';
  static const String isLeapMonth = 'is_leap_month';
  static const String gender = 'gender';
  static const String birthCity = 'birth_city';
  static const String timeCorrection = 'time_correction';
  static const String useYaJasi = 'use_ya_jasi';
  static const String isPrimary = 'is_primary';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

/// SELECT에 사용할 컬럼 목록
const String profileSelectColumns = '''
  id,
  user_id,
  display_name,
  relation_type,
  memo,
  birth_date,
  birth_time_minutes,
  birth_time_unknown,
  is_lunar,
  is_leap_month,
  gender,
  birth_city,
  time_correction,
  use_ya_jasi,
  is_primary,
  created_at,
  updated_at
''';

/// 관계 타입 Enum
enum RelationTypeDb {
  me('me'),
  family('family'),
  friend('friend'),
  lover('lover'),
  spouse('spouse'),
  child('child'),
  other('other');

  final String value;
  const RelationTypeDb(this.value);
}

/// 성별 Enum
enum GenderDb {
  male('male'),
  female('female');

  final String value;
  const GenderDb(this.value);
}
