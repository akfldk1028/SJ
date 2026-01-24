/// Compatibility Analyses 스키마 정의
///
/// Supabase compatibility_analyses 테이블 스키마 매핑

/// 테이블명
const String compatibilityAnalysesTable = 'compatibility_analyses';

/// 컬럼명 상수
abstract class CompatibilityColumns {
  static const String id = 'id';
  static const String profile1Id = 'profile1_id';
  static const String profile2Id = 'profile2_id';
  static const String analysisType = 'analysis_type';
  static const String relationType = 'relation_type';
  static const String overallScore = 'overall_score';
  static const String categoryScores = 'category_scores';
  static const String sajuAnalysis = 'saju_analysis';
  static const String summary = 'summary';
  static const String analysisContent = 'analysis_content';
  static const String strengths = 'strengths';
  static const String challenges = 'challenges';
  static const String advice = 'advice';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  // AI 모델 정보
  static const String modelProvider = 'model_provider';
  static const String modelName = 'model_name';
  static const String tokensUsed = 'tokens_used';
  static const String processingTimeMs = 'processing_time_ms';

  // 인연 사주 정보
  static const String targetYearGan = 'target_year_gan';
  static const String targetYearJi = 'target_year_ji';
  static const String targetMonthGan = 'target_month_gan';
  static const String targetMonthJi = 'target_month_ji';
  static const String targetDayGan = 'target_day_gan';
  static const String targetDayJi = 'target_day_ji';
  static const String targetHourGan = 'target_hour_gan';
  static const String targetHourJi = 'target_hour_ji';
  static const String targetOhengDistribution = 'target_oheng_distribution';
  static const String targetHapchung = 'target_hapchung';
  static const String targetSinsalList = 'target_sinsal_list';
  static const String targetTwelveUnsung = 'target_twelve_unsung';
  static const String targetGilseong = 'target_gilseong';
  static const String targetDayMaster = 'target_day_master';

  // 합충형해파
  static const String ownerHapchung = 'owner_hapchung';
  static const String pairHapchung = 'pair_hapchung';
}

/// SELECT에 사용할 컬럼 목록
const String compatibilitySelectColumns = '''
  id,
  profile1_id,
  profile2_id,
  analysis_type,
  relation_type,
  overall_score,
  category_scores,
  saju_analysis,
  summary,
  analysis_content,
  strengths,
  challenges,
  advice,
  created_at,
  updated_at,
  model_provider,
  model_name,
  tokens_used,
  processing_time_ms,
  owner_hapchung,
  pair_hapchung
''';

/// 상세 정보 포함 SELECT (인연 사주 정보 포함)
const String compatibilityDetailSelectColumns = '''
  id,
  profile1_id,
  profile2_id,
  analysis_type,
  relation_type,
  overall_score,
  category_scores,
  saju_analysis,
  summary,
  analysis_content,
  strengths,
  challenges,
  advice,
  created_at,
  updated_at,
  model_provider,
  model_name,
  tokens_used,
  processing_time_ms,
  target_year_gan,
  target_year_ji,
  target_month_gan,
  target_month_ji,
  target_day_gan,
  target_day_ji,
  target_hour_gan,
  target_hour_ji,
  target_oheng_distribution,
  target_hapchung,
  target_sinsal_list,
  target_twelve_unsung,
  target_gilseong,
  target_day_master,
  owner_hapchung,
  pair_hapchung
''';

/// JOIN하여 프로필 정보까지 가져오는 SELECT
const String compatibilityWithProfilesSelectColumns = '''
  id,
  profile1_id,
  profile2_id,
  analysis_type,
  relation_type,
  overall_score,
  category_scores,
  saju_analysis,
  summary,
  strengths,
  challenges,
  advice,
  created_at,
  updated_at,
  pair_hapchung,
  profile1:saju_profiles!compatibility_analyses_profile1_id_fkey (
    id,
    display_name,
    birth_date,
    gender
  ),
  profile2:saju_profiles!compatibility_analyses_profile2_id_fkey (
    id,
    display_name,
    birth_date,
    gender
  )
''';

/// 분석 유형 Enum
enum CompatibilityAnalysisType {
  general('general', '일반'),
  love('love', '연애'),
  business('business', '사업'),
  friendship('friendship', '우정'),
  family('family', '가족');

  final String value;
  final String displayName;

  const CompatibilityAnalysisType(this.value, this.displayName);

  /// DB 값으로부터 Enum 찾기
  static CompatibilityAnalysisType fromValue(String value) {
    return CompatibilityAnalysisType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CompatibilityAnalysisType.general,
    );
  }
}
