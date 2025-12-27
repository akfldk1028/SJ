/// Saju Analysis 스키마 정의
///
/// Supabase saju_analyses 테이블 스키마 매핑

/// 테이블명
const String sajuAnalysesTable = 'saju_analyses';

/// 컬럼명 상수
abstract class SajuAnalysisColumns {
  static const String id = 'id';
  static const String profileId = 'profile_id';
  static const String yearGan = 'year_gan';
  static const String yearJi = 'year_ji';
  static const String monthGan = 'month_gan';
  static const String monthJi = 'month_ji';
  static const String dayGan = 'day_gan';
  static const String dayJi = 'day_ji';
  static const String hourGan = 'hour_gan';
  static const String hourJi = 'hour_ji';
  static const String correctedDatetime = 'corrected_datetime';
  static const String ohengDistribution = 'oheng_distribution';
  static const String dayStrength = 'day_strength';
  static const String yongsin = 'yongsin';
  static const String gyeokguk = 'gyeokguk';
  static const String sipsinInfo = 'sipsin_info';
  static const String jijangganInfo = 'jijanggan_info';
  static const String sinsalList = 'sinsal_list';
  static const String daeun = 'daeun';
  static const String currentSeun = 'current_seun';
  static const String twelveUnsung = 'twelve_unsung';
  static const String twelveSinsal = 'twelve_sinsal';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

/// SELECT에 사용할 컬럼 목록
const String sajuAnalysisSelectColumns = '''
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
  created_at,
  updated_at
''';

/// 기본 사주 정보만 조회 (빠른 로딩용)
const String sajuBasicSelectColumns = '''
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
  corrected_datetime
''';

/// AI 분석에 필요한 핵심 데이터
const String sajuAiContextColumns = '''
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
  oheng_distribution,
  day_strength,
  yongsin,
  gyeokguk,
  sipsin_info
''';

/// 오행 타입
enum Oheng {
  wood('목', 'wood'),
  fire('화', 'fire'),
  earth('토', 'earth'),
  metal('금', 'metal'),
  water('수', 'water');

  final String korean;
  final String english;
  const Oheng(this.korean, this.english);
}
