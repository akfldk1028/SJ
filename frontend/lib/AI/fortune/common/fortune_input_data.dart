/// # Fortune Input Data 정의
///
/// ## 개요
/// 운세 분석에 필요한 공통 입력 데이터 클래스
/// saju_base 기반 파생 운세 분석에 사용
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/common/fortune_input_data.dart`

/// 운세 분석 입력 데이터
///
/// ## 필수 데이터
/// - profileName: 프로필 이름
/// - birthDate: 생년월일 (양력)
/// - birthTime: 태어난 시간 (시주)
/// - gender: 성별
/// - sajuBaseContent: saju_base 분석 결과 (핵심!)
///
/// ## 선택 데이터
/// - sajuOrigin: 만세력 원본 데이터
/// - targetYear: 대상 연도 (년운용)
/// - targetMonth: 대상 월 (월운용)
class FortuneInputData {
  /// 프로필 이름
  final String profileName;

  /// 생년월일 (양력, 'YYYY-MM-DD' 형식)
  final String birthDate;

  /// 태어난 시간 (HH:mm 형식, nullable)
  final String? birthTime;

  /// 성별 ('M' 또는 'F')
  final String gender;

  /// saju_base 분석 결과 (핵심!)
  /// - 성격, 적성, 재물운, 건강운 등 종합 분석
  /// - 모든 파생 운세의 기반 데이터
  final Map<String, dynamic> sajuBaseContent;

  /// 만세력 원본 데이터 (선택)
  /// - 천간/지지/십성/신살 등
  final Map<String, dynamic>? sajuOrigin;

  /// 대상 연도 (년운용)
  final int? targetYear;

  /// 대상 월 (월운용)
  final int? targetMonth;

  const FortuneInputData({
    required this.profileName,
    required this.birthDate,
    this.birthTime,
    required this.gender,
    required this.sajuBaseContent,
    this.sajuOrigin,
    this.targetYear,
    this.targetMonth,
  });

  /// saju_base에서 FortuneInputData 생성
  ///
  /// [profileName] 프로필 이름
  /// [birthDate] 생년월일
  /// [birthTime] 태어난 시간
  /// [gender] 성별
  /// [sajuBaseContent] saju_base의 content JSON
  factory FortuneInputData.fromSajuBase({
    required String profileName,
    required String birthDate,
    String? birthTime,
    required String gender,
    required Map<String, dynamic> sajuBaseContent,
    int? targetYear,
    int? targetMonth,
  }) {
    // saju_origin이 content 내에 있으면 추출
    final sajuOrigin = sajuBaseContent['saju_origin'] as Map<String, dynamic>?;

    return FortuneInputData(
      profileName: profileName,
      birthDate: birthDate,
      birthTime: birthTime,
      gender: gender,
      sajuBaseContent: sajuBaseContent,
      sajuOrigin: sajuOrigin,
      targetYear: targetYear,
      targetMonth: targetMonth,
    );
  }

  /// 성별 한글 표시
  String get genderKorean => gender == 'M' ? '남성' : '여성';

  /// 대상 연도 문자열 (예: '2026년')
  String? get targetYearString =>
      targetYear != null ? '${targetYear}년' : null;

  /// 대상 월 문자열 (예: '1월')
  String? get targetMonthString =>
      targetMonth != null ? '${targetMonth}월' : null;

  /// 대상 기간 문자열 (예: '2026년 1월')
  String? get targetPeriodString {
    if (targetYear == null) return null;
    if (targetMonth != null) {
      return '${targetYear}년 ${targetMonth}월';
    }
    return '${targetYear}년';
  }

  /// JSON 변환 (프롬프트용)
  Map<String, dynamic> toPromptJson() {
    return {
      'profile_name': profileName,
      'birth_date': birthDate,
      if (birthTime != null) 'birth_time': birthTime,
      'gender': genderKorean,
      'saju_base_analysis': sajuBaseContent,
      if (sajuOrigin != null) 'saju_origin': sajuOrigin,
      if (targetYear != null) 'target_year': targetYear,
      if (targetMonth != null) 'target_month': targetMonth,
    };
  }

  @override
  String toString() {
    return 'FortuneInputData(name: $profileName, birth: $birthDate, target: $targetPeriodString)';
  }
}
