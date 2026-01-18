/// # Fortune Input Data 정의
///
/// ## 개요
/// 운세 분석에 필요한 공통 입력 데이터 클래스
/// saju_base + saju_analyses 기반 파생 운세 분석에 사용
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/common/fortune_input_data.dart`
///
/// ## v2.0 개선사항
/// - saju_analyses 테이블 데이터 추가 (yongsin, hapchung, day_strength)
/// - 용신/기신 기반 정확한 운세 분석 지원
/// - 합충 분석을 위한 원국 지지 정보 포함

/// 운세 분석 입력 데이터
///
/// ## 필수 데이터
/// - profileName: 프로필 이름
/// - birthDate: 생년월일 (양력)
/// - birthTime: 태어난 시간 (시주)
/// - gender: 성별
/// - sajuBaseContent: saju_base 분석 결과 (AI 해석)
///
/// ## 중요 데이터 (정확도 향상)
/// - sajuAnalyses: saju_analyses 테이블 데이터 (만세력 계산 결과)
///   - yongsin: 용신/희신/기신/구신
///   - hapchung: 합충형파해
///   - day_strength: 일간 강약
///
/// ## 선택 데이터
/// - sajuOrigin: saju_base.content 내 원국 데이터
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

  /// saju_base 분석 결과 (AI 해석)
  /// - 성격, 적성, 재물운, 건강운 등 종합 분석
  /// - 모든 파생 운세의 기반 데이터
  final Map<String, dynamic> sajuBaseContent;

  /// saju_analyses 테이블 데이터 (만세력 계산 결과)
  /// - 용신/기신: 운세 정확도의 핵심!
  /// - 합충형파해: 년/월 상호작용 분석
  /// - 일간 강약: 신강/신약 판단
  final Map<String, dynamic>? sajuAnalyses;

  /// 만세력 원본 데이터 (saju_base.content 내)
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
    this.sajuAnalyses,
    this.sajuOrigin,
    this.targetYear,
    this.targetMonth,
  });

  /// saju_base + saju_analyses에서 FortuneInputData 생성
  ///
  /// [profileName] 프로필 이름
  /// [birthDate] 생년월일
  /// [birthTime] 태어난 시간
  /// [gender] 성별
  /// [sajuBaseContent] saju_base의 content JSON (AI 해석)
  /// [sajuAnalyses] saju_analyses 테이블 데이터 (만세력 계산 결과)
  factory FortuneInputData.fromSajuBase({
    required String profileName,
    required String birthDate,
    String? birthTime,
    required String gender,
    required Map<String, dynamic> sajuBaseContent,
    Map<String, dynamic>? sajuAnalyses,
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
      sajuAnalyses: sajuAnalyses,
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
      if (sajuAnalyses != null) 'saju_analyses': sajuAnalyses,
      if (targetYear != null) 'target_year': targetYear,
      if (targetMonth != null) 'target_month': targetMonth,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // saju_analyses 데이터 접근 (정확도 향상용)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 용신 정보 (가장 중요!)
  /// - yongsin: 용신 (필요한 오행)
  /// - huisin: 희신 (도움 오행)
  /// - gisin: 기신 (해로운 오행)
  /// - gusin: 구신 (매우 해로운 오행)
  Map<String, dynamic>? get yongsin =>
      sajuAnalyses?['yongsin'] as Map<String, dynamic>?;

  /// 용신 오행 (예: "금(金)")
  String? get yongsinElement => yongsin?['yongsin'] as String?;

  /// 희신 오행 (예: "토(土)")
  String? get huisinElement => yongsin?['huisin'] as String?;

  /// 기신 오행 (예: "화(火)")
  String? get gisinElement => yongsin?['gisin'] as String?;

  /// 구신 오행 (예: "목(木)")
  String? get gusinElement => yongsin?['gusin'] as String?;

  /// 합충형파해 정보
  Map<String, dynamic>? get hapchung =>
      sajuAnalyses?['hapchung'] as Map<String, dynamic>?;

  /// 일간 강약 정보
  /// - score: 점수 (0-100)
  /// - type: 신강/신약/중화
  /// - reason: 판단 근거
  Map<String, dynamic>? get dayStrength =>
      sajuAnalyses?['day_strength'] as Map<String, dynamic>?;

  /// 신강/신약 여부
  bool? get isSingang => dayStrength?['type'] == '신강';

  /// 일간 강약 점수 (0-100)
  int? get dayStrengthScore => dayStrength?['score'] as int?;

  /// 대운 정보
  Map<String, dynamic>? get daeun =>
      sajuAnalyses?['daeun'] as Map<String, dynamic>?;

  /// 현재 세운 정보
  Map<String, dynamic>? get currentSeun =>
      sajuAnalyses?['current_seun'] as Map<String, dynamic>?;

  // ═══════════════════════════════════════════════════════════════════════════
  // 사주 팔자 (천간/지지)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 년간 (예: "甲")
  String? get yearGan => sajuAnalyses?['year_gan'] as String?;

  /// 년지 (예: "子")
  String? get yearJi => sajuAnalyses?['year_ji'] as String?;

  /// 월간 (예: "丙")
  String? get monthGan => sajuAnalyses?['month_gan'] as String?;

  /// 월지 (예: "寅")
  String? get monthJi => sajuAnalyses?['month_ji'] as String?;

  /// 일간 (예: "戊") - 본인을 나타냄
  String? get dayGan => sajuAnalyses?['day_gan'] as String?;

  /// 일지 (예: "午") - 합충 분석의 핵심
  String? get dayJi => sajuAnalyses?['day_ji'] as String?;

  /// 시간 (예: "癸")
  String? get hourGan => sajuAnalyses?['hour_gan'] as String?;

  /// 시지 (예: "亥")
  String? get hourJi => sajuAnalyses?['hour_ji'] as String?;

  /// 사주 팔자 테이블 문자열
  String get sajuPaljaTable {
    if (sajuAnalyses == null) return '(원국 정보 없음)';

    return '''
| 구분 | 천간 | 지지 |
|------|------|------|
| 년주 | ${yearGan ?? '-'} | ${yearJi ?? '-'} |
| 월주 | ${monthGan ?? '-'} | ${monthJi ?? '-'} |
| 일주 | ${dayGan ?? '-'} (일간) | ${dayJi ?? '-'} |
| 시주 | ${hourGan ?? '-'} | ${hourJi ?? '-'} |''';
  }

  /// 용신/기신 정보 문자열
  String get yongsinInfo {
    if (yongsin == null) return '(용신 정보 없음)';

    return '''
- 용신(필요 오행): ${yongsinElement ?? '-'}
- 희신(도움 오행): ${huisinElement ?? '-'}
- 기신(해로운 오행): ${gisinElement ?? '-'}
- 구신(매우 해로운 오행): ${gusinElement ?? '-'}''';
  }

  /// 일간 강약 정보 문자열
  String get dayStrengthInfo {
    if (dayStrength == null) return '(일간 강약 정보 없음)';

    return '''
- 점수: ${dayStrengthScore ?? '-'}점
- 유형: ${dayStrength?['type'] ?? '-'}
- 해석: ${dayStrength?['reason'] ?? '-'}''';
  }

  @override
  String toString() {
    return 'FortuneInputData(name: $profileName, birth: $birthDate, target: $targetPeriodString)';
  }
}
