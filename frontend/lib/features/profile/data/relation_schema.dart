/// Profile Relations 스키마 정의
///
/// Supabase profile_relations 테이블 스키마 매핑

/// 테이블명
const String profileRelationsTable = 'profile_relations';

/// 컬럼명 상수
abstract class RelationColumns {
  static const String id = 'id';
  static const String userId = 'user_id';
  static const String fromProfileId = 'from_profile_id';
  static const String toProfileId = 'to_profile_id';
  static const String relationType = 'relation_type';
  static const String displayName = 'display_name';
  static const String memo = 'memo';
  static const String isFavorite = 'is_favorite';
  static const String sortOrder = 'sort_order';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  // === 사주 분석 연결 ===
  static const String fromProfileAnalysisId = 'from_profile_analysis_id';
  static const String toProfileAnalysisId = 'to_profile_analysis_id';
  static const String analysisStatus = 'analysis_status';
  static const String analysisRequestedAt = 'analysis_requested_at';

  // === 궁합 분석 연결 (Phase 51) ===
  static const String compatibilityAnalysisId = 'compatibility_analysis_id';
  static const String analysisCompletedAt = 'analysis_completed_at';
  static const String pairHapchung = 'pair_hapchung';
}

/// SELECT에 사용할 컬럼 목록
const String relationSelectColumns = '''
  id,
  user_id,
  from_profile_id,
  to_profile_id,
  relation_type,
  display_name,
  memo,
  is_favorite,
  sort_order,
  created_at,
  updated_at,
  from_profile_analysis_id,
  to_profile_analysis_id,
  analysis_status,
  analysis_requested_at,
  compatibility_analysis_id,
  analysis_completed_at,
  pair_hapchung
''';

/// JOIN하여 프로필 정보까지 가져오는 SELECT
/// 사주 계산에 필요한 모든 필드 포함
const String relationWithProfileSelectColumns = '''
  id,
  user_id,
  from_profile_id,
  to_profile_id,
  relation_type,
  display_name,
  memo,
  is_favorite,
  sort_order,
  created_at,
  updated_at,
  from_profile_analysis_id,
  to_profile_analysis_id,
  analysis_status,
  analysis_requested_at,
  compatibility_analysis_id,
  analysis_completed_at,
  pair_hapchung,
  to_profile:saju_profiles!profile_relations_to_profile_id_fkey (
    id,
    display_name,
    birth_date,
    gender,
    relation_type,
    birth_time_minutes,
    birth_time_unknown,
    is_lunar,
    is_leap_month,
    birth_city,
    use_ya_jasi
  )
''';

/// 관계 유형 Enum
/// family_*, romantic_*, friend_*, work_*, 기타
enum ProfileRelationType {
  // 가족 관계
  familyParent('family_parent', '부모'),
  familyChild('family_child', '자녀'),
  familySibling('family_sibling', '형제/자매'),
  familySpouse('family_spouse', '배우자'),
  familyGrandparent('family_grandparent', '조부모'),
  familyInLaw('family_in_law', '시가/처가'),
  familyOther('family_other', '기타 가족'),

  // 연인 관계
  romanticPartner('romantic_partner', '연인'),
  romanticCrush('romantic_crush', '호감 상대'),
  romanticEx('romantic_ex', '전 연인'),

  // 친구 관계
  friendClose('friend_close', '친한 친구'),
  friendGeneral('friend_general', '친구'),

  // 직장 관계
  workColleague('work_colleague', '동료'),
  workBoss('work_boss', '상사'),
  workSubordinate('work_subordinate', '부하'),
  workClient('work_client', '거래처/고객'),

  // 기타
  businessPartner('business_partner', '사업 파트너'),
  mentor('mentor', '멘토'),
  other('other', '기타');

  final String value;
  final String displayName;

  const ProfileRelationType(this.value, this.displayName);

  /// DB 값으로부터 Enum 찾기
  static ProfileRelationType fromValue(String value) {
    return ProfileRelationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ProfileRelationType.other,
    );
  }

  /// 카테고리별 그룹핑
  static List<ProfileRelationType> get familyTypes => [
        familyParent,
        familyChild,
        familySibling,
        familySpouse,
        familyGrandparent,
        familyInLaw,
        familyOther,
      ];

  static List<ProfileRelationType> get romanticTypes => [
        romanticPartner,
        romanticCrush,
        romanticEx,
      ];

  static List<ProfileRelationType> get friendTypes => [
        friendClose,
        friendGeneral,
      ];

  static List<ProfileRelationType> get workTypes => [
        workColleague,
        workBoss,
        workSubordinate,
        workClient,
      ];

  static List<ProfileRelationType> get otherTypes => [
        businessPartner,
        mentor,
        other,
      ];

  /// 카테고리 라벨
  String get categoryLabel {
    if (value.startsWith('family_')) return '가족';
    if (value.startsWith('romantic_')) return '연인';
    if (value.startsWith('friend_')) return '친구';
    if (value.startsWith('work_')) return '직장';
    return '기타';
  }

  /// 궁합 분석 타입으로 변환
  String get compatibilityType {
    if (value.startsWith('family_')) return 'family';
    if (value.startsWith('romantic_')) return 'love';
    if (value.startsWith('friend_')) return 'friendship';
    if (value.startsWith('work_') || value == 'business_partner') {
      return 'business';
    }
    return 'general';
  }
}
