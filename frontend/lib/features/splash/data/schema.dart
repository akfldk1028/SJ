/// Splash Pre-fetch 스키마 정의
///
/// Splash 화면에서 Pre-fetch하는 데이터 정의
/// - Primary 프로필
/// - 사주 분석
/// - 최근 채팅 세션 (optional)
library;

// ============================================================================
// Pre-fetch 대상 테이블 (참조용)
// ============================================================================

/// saju_profiles 테이블
const String profilesTable = 'saju_profiles';

/// saju_analyses 테이블
const String analysesTable = 'saju_analyses';

/// chat_sessions 테이블
const String sessionsTable = 'chat_sessions';

// ============================================================================
// Pre-fetch 컬럼 정의
// ============================================================================

/// Primary 프로필 조회용 컬럼
const String primaryProfileColumns = '''
  id,
  user_id,
  display_name,
  gender,
  birth_date,
  birth_time_minutes,
  birth_time_unknown,
  is_lunar,
  is_leap_month,
  birth_city,
  time_correction,
  use_ya_jasi,
  is_primary,
  relation_type,
  memo,
  created_at,
  updated_at
''';

/// 사주 분석 핵심 컬럼 (AI 컨텍스트용)
const String coreAnalysisColumns = '''
  id,
  profile_id,
  year_gan,
  year_ji,
  month_gan,
  month_ji,
  day_gan,
  day_ji,
  hour_gan,
  hour_ji,
  corrected_datetime,
  oheng_distribution,
  day_strength,
  yongsin,
  gyeokguk,
  sipsin_info,
  ai_summary
''';

/// 사주 분석 전체 컬럼
const String fullAnalysisColumns = '''
  id,
  profile_id,
  year_gan,
  year_ji,
  month_gan,
  month_ji,
  day_gan,
  day_ji,
  hour_gan,
  hour_ji,
  corrected_datetime,
  oheng_distribution,
  day_strength,
  yongsin,
  gyeokguk,
  sipsin_info,
  jijanggan_info,
  sinsal_list,
  daeun,
  current_seun,
  twelve_unsung,
  twelve_sinsal,
  gilseong,
  ai_summary,
  calculated_at,
  updated_at
''';

/// 최근 세션 조회용 컬럼
const String recentSessionColumns = '''
  id,
  profile_id,
  title,
  chat_type,
  message_count,
  last_message_preview,
  updated_at
''';

// ============================================================================
// Pre-fetch 결과 타입
// ============================================================================

/// Pre-fetch 상태
enum PrefetchStatus {
  /// 로딩 중
  loading,

  /// 완료 - 데이터 있음
  hasData,

  /// 완료 - 신규 사용자 (프로필 없음)
  noProfile,

  /// 완료 - 분석 없음 (프로필은 있음)
  noAnalysis,

  /// 실패
  error,

  /// 오프라인
  offline,
}
