/// Profile Relations 스키마 정의
///
/// Supabase profile_relations 테이블 스키마 매핑
import 'package:easy_localization/easy_localization.dart';

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
/// family_*, romantic_*, friend_*, work_*, other
enum ProfileRelationType {
  // 가족 관계
  familyParent('family_parent', 'profile.relationFamilyParent'),
  familyChild('family_child', 'profile.relationFamilyChild'),
  familySibling('family_sibling', 'profile.relationFamilySibling'),
  familySpouse('family_spouse', 'profile.relationFamilySpouse'),
  familyGrandparent('family_grandparent', 'profile.relationFamilyGrandparent'),
  familyInLaw('family_in_law', 'profile.relationFamilyInLaw'),
  familyOther('family_other', 'profile.relationFamilyOther'),

  // 연인 관계
  romanticPartner('romantic_partner', 'profile.relationRomanticPartner'),
  romanticCrush('romantic_crush', 'profile.relationRomanticCrush'),
  romanticEx('romantic_ex', 'profile.relationRomanticEx'),

  // 친구 관계
  friendClose('friend_close', 'profile.relationFriendClose'),
  friendGeneral('friend_general', 'profile.relationFriendGeneral'),

  // 직장 관계
  workColleague('work_colleague', 'profile.relationWorkColleague'),
  workBoss('work_boss', 'profile.relationWorkBoss'),
  workSubordinate('work_subordinate', 'profile.relationWorkSubordinate'),
  workClient('work_client', 'profile.relationWorkClient'),

  // 기타
  businessPartner('business_partner', 'profile.relationBusinessPartner'),
  mentor('mentor', 'profile.relationMentor'),
  other('other', 'profile.relationOther');

  /// DB에 저장되는 값 (예: 'family_parent')
  final String value;

  /// i18n 키 (예: 'profile.relationFamilyParent')
  final String _i18nKey;

  const ProfileRelationType(this.value, this._i18nKey);

  /// 다국어 표시명 (UI용, .tr() 호출 필요)
  /// 반드시 BuildContext가 있는 위젯 트리 안에서 호출해야 합니다.
  String get displayName => _i18nKey.tr();

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

  /// 카테고리 키 (내부 로직용, 언어 무관)
  /// UI 표시에는 localizedCategoryLabel을 사용
  String get categoryLabel {
    if (value.startsWith('family_')) return 'family';
    if (value.startsWith('romantic_')) return 'romantic';
    if (value.startsWith('friend_')) return 'friend';
    if (value.startsWith('work_')) return 'work';
    return 'other';
  }

  /// 카테고리별 i18n 키 매핑
  static const _categoryI18nKeys = {
    'family': 'profile.categoryFamily',
    'romantic': 'profile.categoryLover',
    'friend': 'profile.categoryFriend',
    'work': 'profile.categoryWork',
    'other': 'profile.categoryOther',
  };

  /// 다국어 카테고리 라벨 (UI용)
  String get localizedCategoryLabel =>
      _categoryI18nKeys[categoryLabel]?.tr() ?? categoryLabel;

  /// 카테고리 키 → 다국어 라벨 변환 (static)
  static String localizedCategory(String categoryKey) =>
      _categoryI18nKeys[categoryKey]?.tr() ?? categoryKey;

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
