/// # Fortune Input Data 정의
///
/// ## 개요
/// 운세 분석에 필요한 공통 입력 데이터 클래스
/// saju_analyses(만세력 계산 데이터) 기반 운세 분석에 사용
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/common/fortune_input_data.dart`
///
/// ## v3.0 핵심 변경 (2026-01-20) ⭐
/// - **saju_base 대기 제거!** 140초 → 즉시 시작
/// - sajuBaseContent: required → **optional** (참고용)
/// - sajuAnalyses: optional → **required** (핵심 데이터)
/// - 새 factory: `fromSajuAnalyses()` 추가 (권장)
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
/// - sajuBaseContent: saju_base 분석 결과 (AI 해석) - **선택적** (v3.0)
///
/// ## 핵심 데이터 (필수!)
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

  /// saju_base 분석 결과 (AI 해석) - **선택적 (v3.0)**
  /// - 성격, 적성, 재물운, 건강운 등 종합 분석
  /// - 참고용 데이터 (없어도 운세 분석 가능)
  /// - 핵심 데이터는 sajuAnalyses에서 제공
  final Map<String, dynamic>? sajuBaseContent;

  /// saju_analyses 테이블 데이터 (만세력 계산 결과) - **필수 (v3.0)**
  /// - 용신/기신: 운세 정확도의 핵심!
  /// - 합충형파해: 년/월 상호작용 분석
  /// - 일간 강약: 신강/신약 판단
  /// - 사주팔자: 천간/지지 (년주, 월주, 일주, 시주)
  final Map<String, dynamic> sajuAnalyses;

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
    this.sajuBaseContent, // v3.0: Optional (saju_analyses만으로 운세 분석 가능)
    required this.sajuAnalyses, // v3.0: Required (핵심 만세력 데이터)
    this.sajuOrigin,
    this.targetYear,
    this.targetMonth,
  });

  /// saju_analyses만으로 FortuneInputData 생성 (v3.0 권장)
  ///
  /// saju_base 없이 즉시 운세 분석 가능!
  /// - 140초 대기 없이 바로 분석 시작
  /// - 만세력 계산 결과(saju_analyses)만으로 충분한 정확도
  ///
  /// [profileName] 프로필 이름
  /// [birthDate] 생년월일
  /// [birthTime] 태어난 시간
  /// [gender] 성별
  /// [sajuAnalyses] saju_analyses 테이블 데이터 (만세력 계산 결과)
  factory FortuneInputData.fromSajuAnalyses({
    required String profileName,
    required String birthDate,
    String? birthTime,
    required String gender,
    required Map<String, dynamic> sajuAnalyses,
    int? targetYear,
    int? targetMonth,
  }) {
    return FortuneInputData(
      profileName: profileName,
      birthDate: birthDate,
      birthTime: birthTime,
      gender: gender,
      sajuBaseContent: null, // v3.0: 생략 가능
      sajuAnalyses: sajuAnalyses,
      sajuOrigin: null,
      targetYear: targetYear,
      targetMonth: targetMonth,
    );
  }

  /// saju_base + saju_analyses에서 FortuneInputData 생성 (기존 방식)
  ///
  /// saju_base가 있는 경우 추가 참고 정보로 활용
  ///
  /// [profileName] 프로필 이름
  /// [birthDate] 생년월일
  /// [birthTime] 태어난 시간
  /// [gender] 성별
  /// [sajuBaseContent] saju_base의 content JSON (AI 해석) - Optional
  /// [sajuAnalyses] saju_analyses 테이블 데이터 (만세력 계산 결과)
  factory FortuneInputData.fromSajuBase({
    required String profileName,
    required String birthDate,
    String? birthTime,
    required String gender,
    Map<String, dynamic>? sajuBaseContent,
    required Map<String, dynamic> sajuAnalyses,
    int? targetYear,
    int? targetMonth,
  }) {
    // saju_origin이 content 내에 있으면 추출
    final sajuOrigin = sajuBaseContent?['saju_origin'] as Map<String, dynamic>?;

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
      if (sajuBaseContent != null) 'saju_base_analysis': sajuBaseContent, // v3.0: Optional
      if (sajuOrigin != null) 'saju_origin': sajuOrigin,
      'saju_analyses': sajuAnalyses, // v3.0: Required (핵심 데이터)
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
      sajuAnalyses['yongsin'] as Map<String, dynamic>?;

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
      sajuAnalyses['hapchung'] as Map<String, dynamic>?;

  /// 신살(神煞) 정보
  /// - gilsin: 길신(吉神) 목록
  /// - hyungsin: 흉신(凶神) 목록
  /// - neutral: 중립 신살 목록
  /// - summary: 프롬프트용 요약
  Map<String, dynamic>? get sinsal =>
      sajuAnalyses['sinsal'] as Map<String, dynamic>?;

  /// 십신(十神) 정보
  Map<String, dynamic>? get sipsinInfo =>
      sajuAnalyses['sipsin_info'] as Map<String, dynamic>?;

  /// 일간 강약 정보
  /// - score: 점수 (0-100)
  /// - type: 신강/신약/중화
  /// - reason: 판단 근거
  Map<String, dynamic>? get dayStrength =>
      sajuAnalyses['day_strength'] as Map<String, dynamic>?;

  /// 신강/신약 여부
  bool? get isSingang => dayStrength?['type'] == '신강';

  /// 일간 강약 점수 (0-100)
  int? get dayStrengthScore => dayStrength?['score'] as int?;

  /// 대운 정보
  Map<String, dynamic>? get daeun =>
      sajuAnalyses['daeun'] as Map<String, dynamic>?;

  /// 현재 세운 정보
  Map<String, dynamic>? get currentSeun =>
      sajuAnalyses['current_seun'] as Map<String, dynamic>?;

  // ═══════════════════════════════════════════════════════════════════════════
  // 사주 팔자 (천간/지지)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 년간 (예: "甲")
  String? get yearGan => sajuAnalyses['year_gan'] as String?;

  /// 년지 (예: "子")
  String? get yearJi => sajuAnalyses['year_ji'] as String?;

  /// 월간 (예: "丙")
  String? get monthGan => sajuAnalyses['month_gan'] as String?;

  /// 월지 (예: "寅")
  String? get monthJi => sajuAnalyses['month_ji'] as String?;

  /// 일간 (예: "戊") - 본인을 나타냄
  String? get dayGan => sajuAnalyses['day_gan'] as String?;

  /// 일지 (예: "午") - 합충 분석의 핵심
  String? get dayJi => sajuAnalyses['day_ji'] as String?;

  /// 시간 (예: "癸")
  String? get hourGan => sajuAnalyses['hour_gan'] as String?;

  /// 시지 (예: "亥")
  String? get hourJi => sajuAnalyses['hour_ji'] as String?;

  /// 사주 팔자 테이블 문자열
  String get sajuPaljaTable {
    // v3.0: sajuAnalyses는 이제 required이므로 null 체크 불필요
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

  /// 신살(神煞) 정보 문자열
  String get sinsalInfo {
    if (sinsal == null) return '(신살 정보 없음)';

    // 파싱된 summary가 있으면 사용
    final summary = sinsal?['summary'] as String?;
    if (summary != null && summary.isNotEmpty) {
      return summary;
    }

    // summary 없으면 직접 구성
    final buffer = StringBuffer();
    final gilsin = sinsal?['gilsin'] as String?;
    final hyungsin = sinsal?['hyungsin'] as String?;
    final neutral = sinsal?['neutral'] as String?;

    if (gilsin != null && gilsin.isNotEmpty) {
      buffer.writeln('- 길신(吉神): $gilsin');
    }
    if (hyungsin != null && hyungsin.isNotEmpty) {
      buffer.writeln('- 흉신(凶神): $hyungsin');
    }
    if (neutral != null && neutral.isNotEmpty) {
      buffer.writeln('- 중립: $neutral');
    }

    return buffer.toString().trim();
  }

  /// 합충형파해 정보 문자열
  String get hapchungInfo {
    if (hapchung == null) return '(합충형파해 정보 없음)';

    // 파싱된 summary가 있으면 사용
    final summary = hapchung?['summary'] as String?;
    if (summary != null && summary.isNotEmpty) {
      return summary;
    }

    return '(합충 요약 없음)';
  }

  @override
  String toString() {
    return 'FortuneInputData(name: $profileName, birth: $birthDate, target: $targetPeriodString)';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 일간-세운/월운 십성 관계 계산 (GPT 분석 정확도 향상용)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 천간 → 오행 변환 맵
  static const _ganToElement = {
    '甲': '목', '乙': '목',
    '丙': '화', '丁': '화',
    '戊': '토', '己': '토',
    '庚': '금', '辛': '금',
    '壬': '수', '癸': '수',
  };

  /// 오행 한글 → 한자 변환 맵
  static const _elementToHanja = {
    '목': '木', '화': '火', '토': '土', '금': '金', '수': '水',
  };

  /// 일간의 오행 (예: "목", "화", "토", "금", "수")
  String? get dayGanElement => _ganToElement[dayGan];

  /// 일간의 오행 + 한자 (예: "목(木)")
  String? get dayGanElementFull {
    final element = dayGanElement;
    if (element == null) return null;
    return '$element(${_elementToHanja[element]})';
  }

  /// 일간의 음양 (양/음)
  String? get dayGanYinYang {
    if (dayGan == null) return null;
    const yangGan = {'甲', '丙', '戊', '庚', '壬'};
    return yangGan.contains(dayGan) ? '양' : '음';
  }

  /// 일간 쉬운 설명 (예: "갑목(甲木) - 큰 나무")
  String? get dayGanDescription {
    if (dayGan == null) return null;
    const descriptions = {
      '甲': '갑목(甲木) - 큰 나무, 리더십',
      '乙': '을목(乙木) - 작은 풀, 유연함',
      '丙': '병화(丙火) - 태양, 밝고 활발',
      '丁': '정화(丁火) - 촛불, 따뜻하고 섬세',
      '戊': '무토(戊土) - 큰 산, 든든함',
      '己': '기토(己土) - 논밭, 포용력',
      '庚': '경금(庚金) - 칼/쇠, 결단력',
      '辛': '신금(辛金) - 보석, 예민함',
      '壬': '임수(壬水) - 큰 바다, 지혜',
      '癸': '계수(癸水) - 시냇물, 적응력',
    };
    return descriptions[dayGan];
  }

  /// 특정 오행이 일간에게 어떤 십성인지 계산
  /// [targetElement]: "목", "화", "토", "금", "수" 중 하나
  /// 반환: "비겁", "식상", "재성", "관성", "인성" 중 하나
  String? getSipseongFor(String targetElement) {
    final myElement = dayGanElement;
    if (myElement == null) return null;

    // 오행 순서: 목 → 화 → 토 → 금 → 수 → 목 (상생)
    const elementOrder = ['목', '화', '토', '금', '수'];
    final myIdx = elementOrder.indexOf(myElement);
    final targetIdx = elementOrder.indexOf(targetElement);

    if (myIdx == -1 || targetIdx == -1) return null;

    // 상대적 위치 계산 (상생 순서 기준)
    final diff = (targetIdx - myIdx + 5) % 5;

    // 십성 매핑
    // 0: 같은 오행 = 비겁 (나와 같은 기운)
    // 1: 내가 생하는 오행 = 식상 (내가 표현/발산)
    // 2: 내가 극하는 오행 = 재성 (내가 다스림/재물)
    // 3: 나를 극하는 오행 = 관성 (나를 다스림/직장)
    // 4: 나를 생하는 오행 = 인성 (나를 낳음/배움)
    const sipseongMap = {
      0: '비겁',
      1: '식상',
      2: '재성',
      3: '관성',
      4: '인성',
    };

    return sipseongMap[diff];
  }

  /// 특정 오행이 일간에게 미치는 영향을 쉽게 설명
  String getSipseongExplain(String targetElement) {
    final sipseong = getSipseongFor(targetElement);
    if (sipseong == null) return '(분석 불가)';

    const explanations = {
      '비겁': '나와 같은 기운이에요. 경쟁이 치열해지고 에너지가 넘치지만, 다툼이나 번아웃에 주의하세요.',
      '식상': '내가 표현하고 발산하는 기운이에요. 재능을 펼치고 아이디어가 빛나는 시기입니다.',
      '재성': '내가 다스리는 재물의 기운이에요. 돈 벌 기회가 많지만, 쓸 곳도 많아요.',
      '관성': '나를 다스리는 직장/압박의 기운이에요. 힘들지만 성장하는 시기입니다.',
      '인성': '나를 낳아주는 배움/보호의 기운이에요. 공부운이 좋고 귀인을 만날 수 있어요.',
    };

    return explanations[sipseong] ?? '(설명 없음)';
  }

  /// 세운/월운과 용신/기신의 관계 분석
  /// [seunElement]: 세운/월운의 주요 오행 (예: 2026년 병오 = "화")
  String getYongsinRelation(String seunElement) {
    final buffer = StringBuffer();

    // 용신과의 관계
    final yongsinEl = _extractElement(yongsinElement);
    if (yongsinEl != null) {
      if (yongsinEl == seunElement) {
        buffer.writeln('✅ 용신($yongsinElement)과 세운($seunElement)이 일치합니다!');
        buffer.writeln('   → 올해는 필요한 기운이 들어오는 좋은 해예요.');
      } else {
        final relation = _getElementRelation(seunElement, yongsinEl);
        buffer.writeln('용신($yongsinElement)과 세운($seunElement)의 관계: $relation');
      }
    }

    // 기신과의 관계
    final gisinEl = _extractElement(gisinElement);
    if (gisinEl != null) {
      if (gisinEl == seunElement) {
        buffer.writeln('⚠️ 기신($gisinElement)과 세운($seunElement)이 일치합니다.');
        buffer.writeln('   → 해로운 기운이 들어오는 해이므로 주의가 필요해요.');
      }
    }

    return buffer.toString();
  }

  /// 오행 문자열에서 순수 오행만 추출 (예: "화(火)" → "화")
  String? _extractElement(String? elementStr) {
    if (elementStr == null) return null;
    for (final e in ['목', '화', '토', '금', '수']) {
      if (elementStr.contains(e)) return e;
    }
    return null;
  }

  /// 두 오행의 상생/상극 관계
  String _getElementRelation(String a, String b) {
    const elementOrder = ['목', '화', '토', '금', '수'];
    final aIdx = elementOrder.indexOf(a);
    final bIdx = elementOrder.indexOf(b);
    if (aIdx == -1 || bIdx == -1) return '관계 없음';

    final diff = (bIdx - aIdx + 5) % 5;
    if (diff == 1) return '$a → $b 상생 (도움)';
    if (diff == 4) return '$b → $a 상생 (도움받음)';
    if (diff == 2) return '$a → $b 상극 (제어)';
    if (diff == 3) return '$b → $a 상극 (제어받음)';
    return '같은 오행';
  }

  /// 일간 + 세운 오행 결합 분석 전체 (GPT에 전달용)
  /// [seunElement]: 세운의 주요 오행 (예: 2026년 = "화")
  /// [seunGanji]: 세운 간지 (예: "병오(丙午)")
  String getSeunCombinationAnalysis(String seunElement, String seunGanji) {
    final buffer = StringBuffer();

    buffer.writeln('### 일간과 세운의 결합 분석 (핵심!)');
    buffer.writeln();

    // 1. 일간 정보
    buffer.writeln('**1. 일간 정보**');
    buffer.writeln('- 일간: ${dayGan ?? "-"} (${dayGanDescription ?? "-"})');
    buffer.writeln('- 일간 오행: ${dayGanElementFull ?? "-"}');
    buffer.writeln('- 음양: ${dayGanYinYang ?? "-"}');
    buffer.writeln();

    // 2. 세운 오행이 일간에게 미치는 영향
    final sipseong = getSipseongFor(seunElement);
    buffer.writeln('**2. $seunGanji의 $seunElement(${_elementToHanja[seunElement] ?? seunElement}) 기운이 일간에게 미치는 영향**');
    buffer.writeln('- 십성: $sipseong');
    buffer.writeln('- 의미: ${getSipseongExplain(seunElement)}');
    buffer.writeln();

    // 3. 용신/기신과의 관계
    buffer.writeln('**3. 세운과 용신/기신의 관계**');
    buffer.writeln(getYongsinRelation(seunElement));

    return buffer.toString();
  }
}
