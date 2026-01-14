/// # Dart 궁합 계산기
///
/// ## 개요
/// 두 사람의 사주 데이터를 기반으로 궁합을 계산합니다.
/// Gemini API 호출 없이 Dart 로직으로 즉시 계산하여 속도가 빠릅니다.
///
/// ## 파일 위치
/// `frontend/lib/AI/services/compatibility_calculator.dart`
///
/// ## v4.0 아키텍처 변경
/// - 기존: Gemini가 사주 계산 + 궁합 분석 (느리고 부정확)
/// - 변경: GPT-5.2가 사주 계산 (saju_analyses) → Dart가 궁합 계산 (빠르고 정확)
///
/// ## 계산 요소
/// - 천간합 (5가지): 갑기합토, 을경합금, 병신합수, 정임합목, 무계합화
/// - 지지 육합 (6가지): 자축합토, 인해합목, 묘술합화, 진유합금, 사신합수, 오미합화
/// - 지지 삼합/반합 (4가지): 인오술합화, 해묘미합목, 사유축합금, 신자진합수
/// - 지지 방합 (4가지): 인묘진합목, 사오미합화, 신유술합금, 해자축합수
/// - 지지 충 (6가지): 자오충, 축미충, 인신충, 묘유충, 진술충, 사해충
/// - 지지 형: 삼형살(인사신, 축술미), 자묘형, 자형
/// - 지지 해 (6가지): 술유해, 신해해, 미자해, 축오해, 인사해, 묘진해
/// - 지지 파 (6가지): 유자파, 축진파, 인해파, 묘오파, 신사파, 술미파
/// - 원진 (6가지): 자미, 축오, 인사, 묘진, 신해, 유술
/// - 오행 상생상극

// ═══════════════════════════════════════════════════════════════════════════
// 헬퍼 익스텐션
// ═══════════════════════════════════════════════════════════════════════════

/// Iterable 확장 메서드
extension IterableExtension<T> on Iterable<T> {
  /// 조건을 만족하는 첫 번째 요소 반환 (없으면 null)
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 천간 (10 Heavenly Stems)
// ═══════════════════════════════════════════════════════════════════════════

/// 천간 열거형
enum Cheongan {
  gap('갑', '甲', '木', true),
  eul('을', '乙', '木', false),
  byeong('병', '丙', '火', true),
  jeong('정', '丁', '火', false),
  mu('무', '戊', '土', true),
  gi('기', '己', '土', false),
  gyeong('경', '庚', '金', true),
  sin('신', '辛', '金', false),
  im('임', '壬', '水', true),
  gye('계', '癸', '水', false);

  final String korean;
  final String hanja;
  final String oheng;
  final bool isYang; // 양(true) / 음(false)

  const Cheongan(this.korean, this.hanja, this.oheng, this.isYang);

  /// 한글(한자) 형식에서 파싱 (예: "갑(甲)" → Cheongan.gap)
  static Cheongan? fromKoreanHanja(String? value) {
    if (value == null || value.isEmpty) return null;
    final korean = value.split('(').first.trim();
    return Cheongan.values.firstWhereOrNull((e) => e.korean == korean);
  }

  /// 한글만으로 파싱 (예: "갑" → Cheongan.gap)
  static Cheongan? fromKorean(String? value) {
    if (value == null || value.isEmpty) return null;
    return Cheongan.values.firstWhereOrNull((e) => e.korean == value.trim());
  }

  /// 한글(한자) 형식으로 변환
  String toKoreanHanja() => '$korean($hanja)';
}

// ═══════════════════════════════════════════════════════════════════════════
// 지지 (12 Earthly Branches)
// ═══════════════════════════════════════════════════════════════════════════

/// 지지 열거형
enum Jiji {
  ja('자', '子', '水', true),
  chuk('축', '丑', '土', false),
  in_('인', '寅', '木', true),
  myo('묘', '卯', '木', false),
  jin('진', '辰', '土', true),
  sa('사', '巳', '火', false),
  o('오', '午', '火', true),
  mi('미', '未', '土', false),
  sin_('신', '申', '金', true),
  yu('유', '酉', '金', false),
  sul('술', '戌', '土', true),
  hae('해', '亥', '水', false);

  final String korean;
  final String hanja;
  final String oheng;
  final bool isYang;

  const Jiji(this.korean, this.hanja, this.oheng, this.isYang);

  /// 한글(한자) 형식에서 파싱 (예: "자(子)" → Jiji.ja)
  static Jiji? fromKoreanHanja(String? value) {
    if (value == null || value.isEmpty) return null;
    final korean = value.split('(').first.trim();
    return Jiji.values.firstWhereOrNull((e) => e.korean == korean);
  }

  /// 한글만으로 파싱
  static Jiji? fromKorean(String? value) {
    if (value == null || value.isEmpty) return null;
    return Jiji.values.firstWhereOrNull((e) => e.korean == value.trim());
  }

  /// 한글(한자) 형식으로 변환
  String toKoreanHanja() => '$korean($hanja)';
}

// ═══════════════════════════════════════════════════════════════════════════
// 오행 (Five Elements)
// ═══════════════════════════════════════════════════════════════════════════

/// 오행 열거형
enum Oheng {
  wood('木', '목'),
  fire('火', '화'),
  earth('土', '토'),
  metal('金', '금'),
  water('水', '수');

  final String hanja;
  final String korean;

  const Oheng(this.hanja, this.korean);

  /// 상생 관계 (나를 생해주는 오행)
  Oheng get generateMe {
    switch (this) {
      case Oheng.wood:
        return Oheng.water; // 수생목
      case Oheng.fire:
        return Oheng.wood; // 목생화
      case Oheng.earth:
        return Oheng.fire; // 화생토
      case Oheng.metal:
        return Oheng.earth; // 토생금
      case Oheng.water:
        return Oheng.metal; // 금생수
    }
  }

  /// 상생 관계 (내가 생해주는 오행)
  Oheng get iGenerate {
    switch (this) {
      case Oheng.wood:
        return Oheng.fire; // 목생화
      case Oheng.fire:
        return Oheng.earth; // 화생토
      case Oheng.earth:
        return Oheng.metal; // 토생금
      case Oheng.metal:
        return Oheng.water; // 금생수
      case Oheng.water:
        return Oheng.wood; // 수생목
    }
  }

  /// 상극 관계 (나를 극하는 오행)
  Oheng get controlMe {
    switch (this) {
      case Oheng.wood:
        return Oheng.metal; // 금극목
      case Oheng.fire:
        return Oheng.water; // 수극화
      case Oheng.earth:
        return Oheng.wood; // 목극토
      case Oheng.metal:
        return Oheng.fire; // 화극금
      case Oheng.water:
        return Oheng.earth; // 토극수
    }
  }

  /// 상극 관계 (내가 극하는 오행)
  Oheng get iControl {
    switch (this) {
      case Oheng.wood:
        return Oheng.earth; // 목극토
      case Oheng.fire:
        return Oheng.metal; // 화극금
      case Oheng.earth:
        return Oheng.water; // 토극수
      case Oheng.metal:
        return Oheng.wood; // 금극목
      case Oheng.water:
        return Oheng.fire; // 수극화
    }
  }

  /// 문자열에서 오행 파싱
  static Oheng? fromString(String? value) {
    if (value == null) return null;
    return Oheng.values.firstWhereOrNull(
      (e) => e.hanja == value || e.korean == value || e.name == value.toLowerCase(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 합충형해파 계산 로직
// ═══════════════════════════════════════════════════════════════════════════

/// 천간합 (5가지)
/// 갑기합토, 을경합금, 병신합수, 정임합목, 무계합화
class CheonganHap {
  /// 천간합 조합과 결과 오행
  static const Map<Set<Cheongan>, (String, Oheng)> hapPairs = {
    {Cheongan.gap, Cheongan.gi}: ('갑기합토', Oheng.earth),
    {Cheongan.eul, Cheongan.gyeong}: ('을경합금', Oheng.metal),
    {Cheongan.byeong, Cheongan.sin}: ('병신합수', Oheng.water),
    {Cheongan.jeong, Cheongan.im}: ('정임합목', Oheng.wood),
    {Cheongan.mu, Cheongan.gye}: ('무계합화', Oheng.fire),
  };

  /// 두 천간이 합인지 확인
  static (String, Oheng)? checkHap(Cheongan a, Cheongan b) {
    final pair = {a, b};
    return hapPairs[pair];
  }

  /// 두 천간이 합인지만 확인 (이름 반환)
  static String? checkHapName(Cheongan a, Cheongan b) {
    final result = checkHap(a, b);
    return result?.$1;
  }
}

/// 지지 육합 (6가지)
/// 자축합토, 인해합목, 묘술합화, 진유합금, 사신합수, 오미합화
class JijiYukhap {
  static const Map<Set<Jiji>, (String, Oheng)> hapPairs = {
    {Jiji.ja, Jiji.chuk}: ('자축합토', Oheng.earth),
    {Jiji.in_, Jiji.hae}: ('인해합목', Oheng.wood),
    {Jiji.myo, Jiji.sul}: ('묘술합화', Oheng.fire),
    {Jiji.jin, Jiji.yu}: ('진유합금', Oheng.metal),
    {Jiji.sa, Jiji.sin_}: ('사신합수', Oheng.water),
    {Jiji.o, Jiji.mi}: ('오미합화', Oheng.fire), // 또는 토
  };

  static (String, Oheng)? checkHap(Jiji a, Jiji b) {
    final pair = {a, b};
    return hapPairs[pair];
  }

  static String? checkHapName(Jiji a, Jiji b) {
    return checkHap(a, b)?.$1;
  }
}

/// 지지 삼합 (4가지)
/// 인오술합화, 해묘미합목, 사유축합금, 신자진합수
class JijiSamhap {
  static const Map<Set<Jiji>, (String, Oheng)> hapTriples = {
    {Jiji.in_, Jiji.o, Jiji.sul}: ('인오술합화', Oheng.fire),
    {Jiji.hae, Jiji.myo, Jiji.mi}: ('해묘미합목', Oheng.wood),
    {Jiji.sa, Jiji.yu, Jiji.chuk}: ('사유축합금', Oheng.metal),
    {Jiji.sin_, Jiji.ja, Jiji.jin}: ('신자진합수', Oheng.water),
  };

  /// 삼합의 중심(왕지) - 가장 강한 오행
  static const Map<Jiji, (String, Oheng)> centerJiji = {
    Jiji.o: ('오(午) - 화국 왕지', Oheng.fire),
    Jiji.myo: ('묘(卯) - 목국 왕지', Oheng.wood),
    Jiji.yu: ('유(酉) - 금국 왕지', Oheng.metal),
    Jiji.ja: ('자(子) - 수국 왕지', Oheng.water),
  };

  /// 두 지지가 반합인지 확인 (삼합의 2개)
  static String? checkBanhap(Jiji a, Jiji b) {
    final pair = {a, b};
    for (final entry in hapTriples.entries) {
      if (entry.key.containsAll(pair)) {
        final missingJiji = entry.key.difference(pair).first;
        return '${entry.value.$1.substring(0, 3)} 반합 (${missingJiji.korean} 부재)';
      }
    }
    return null;
  }

  /// 세 지지가 삼합인지 확인
  static (String, Oheng)? checkSamhap(Jiji a, Jiji b, Jiji c) {
    final triple = {a, b, c};
    return hapTriples[triple];
  }
}

/// 지지 방합 (4가지)
/// 인묘진합목, 사오미합화, 신유술합금, 해자축합수
class JijiBanghap {
  static const Map<Set<Jiji>, (String, Oheng)> hapTriples = {
    {Jiji.in_, Jiji.myo, Jiji.jin}: ('인묘진합목', Oheng.wood),
    {Jiji.sa, Jiji.o, Jiji.mi}: ('사오미합화', Oheng.fire),
    {Jiji.sin_, Jiji.yu, Jiji.sul}: ('신유술합금', Oheng.metal),
    {Jiji.hae, Jiji.ja, Jiji.chuk}: ('해자축합수', Oheng.water),
  };

  /// 두 지지가 방합의 일부인지 확인
  static String? checkPartialBanghap(Jiji a, Jiji b) {
    final pair = {a, b};
    for (final entry in hapTriples.entries) {
      if (entry.key.containsAll(pair)) {
        return '${entry.value.$1.substring(0, 3)} 방합의 일부';
      }
    }
    return null;
  }
}

/// 지지 육충 (6가지)
/// 자오충, 축미충, 인신충, 묘유충, 진술충, 사해충
class JijiChung {
  static const Map<Set<Jiji>, String> chungPairs = {
    {Jiji.ja, Jiji.o}: '자오충',
    {Jiji.chuk, Jiji.mi}: '축미충',
    {Jiji.in_, Jiji.sin_}: '인신충',
    {Jiji.myo, Jiji.yu}: '묘유충',
    {Jiji.jin, Jiji.sul}: '진술충',
    {Jiji.sa, Jiji.hae}: '사해충',
  };

  /// 충의 심각도 (1-10)
  static const Map<Set<Jiji>, int> chungSeverity = {
    {Jiji.ja, Jiji.o}: 9, // 수화 충돌 - 매우 강함
    {Jiji.in_, Jiji.sin_}: 8, // 목금 충돌 - 강함
    {Jiji.myo, Jiji.yu}: 8, // 목금 충돌 - 강함
    {Jiji.sa, Jiji.hae}: 7, // 화수 충돌 - 강함
    {Jiji.chuk, Jiji.mi}: 5, // 토토 충돌 - 중간
    {Jiji.jin, Jiji.sul}: 5, // 토토 충돌 - 중간
  };

  static String? checkChung(Jiji a, Jiji b) {
    final pair = {a, b};
    return chungPairs[pair];
  }

  static int? getChungSeverity(Jiji a, Jiji b) {
    final pair = {a, b};
    return chungSeverity[pair];
  }
}

/// 지지 형 (삼형살, 자묘형, 자형)
class JijiHyung {
  // 삼형살
  static const Map<Set<Jiji>, String> samhyung = {
    {Jiji.in_, Jiji.sa, Jiji.sin_}: '인사신 삼형살 (무은지형)',
    {Jiji.chuk, Jiji.sul, Jiji.mi}: '축술미 삼형살 (지세지형)',
  };

  // 자묘형 (무례지형)
  static const Set<Jiji> jaMyoHyung = {Jiji.ja, Jiji.myo};

  // 자형 (자기 형벌)
  static const Set<Jiji> jaHyungJiji = {
    Jiji.jin, // 진진자형
    Jiji.o, // 오오자형
    Jiji.yu, // 유유자형
    Jiji.hae, // 해해자형
  };

  /// 두 지지가 형인지 확인
  static String? checkHyung(Jiji a, Jiji b) {
    // 자묘형
    if ({a, b} == jaMyoHyung) return '자묘형 (무례지형)';
    // 자형
    if (a == b && jaHyungJiji.contains(a)) return '${a.korean}${a.korean}자형';
    // 삼형살의 2개
    for (final entry in samhyung.entries) {
      if (entry.key.contains(a) && entry.key.contains(b)) {
        return '${entry.value.split(' ').first} 형 (삼형살 일부)';
      }
    }
    return null;
  }
}

/// 지지 해 (6가지)
/// 술유해, 신해해, 미자해, 축오해, 인사해, 묘진해
class JijiHae {
  static const Map<Set<Jiji>, String> haePairs = {
    {Jiji.sul, Jiji.yu}: '술유해',
    {Jiji.sin_, Jiji.hae}: '신해해',
    {Jiji.mi, Jiji.ja}: '미자해',
    {Jiji.chuk, Jiji.o}: '축오해',
    {Jiji.in_, Jiji.sa}: '인사해',
    {Jiji.myo, Jiji.jin}: '묘진해',
  };

  static String? checkHae(Jiji a, Jiji b) {
    final pair = {a, b};
    return haePairs[pair];
  }
}

/// 지지 파 (6가지)
/// 유자파, 축진파, 인해파, 묘오파, 신사파, 술미파
class JijiPa {
  static const Map<Set<Jiji>, String> paPairs = {
    {Jiji.yu, Jiji.ja}: '유자파',
    {Jiji.chuk, Jiji.jin}: '축진파',
    {Jiji.in_, Jiji.hae}: '인해파',
    {Jiji.myo, Jiji.o}: '묘오파',
    {Jiji.sin_, Jiji.sa}: '신사파',
    {Jiji.sul, Jiji.mi}: '술미파',
  };

  static String? checkPa(Jiji a, Jiji b) {
    final pair = {a, b};
    return paPairs[pair];
  }
}

/// 원진 (12가지)
/// 서로 원수지간
class Wonjin {
  static const Map<Jiji, Jiji> wonjinPairs = {
    Jiji.ja: Jiji.mi, // 자미 원진
    Jiji.chuk: Jiji.o, // 축오 원진
    Jiji.in_: Jiji.sa, // 인사 원진
    Jiji.myo: Jiji.jin, // 묘진 원진
    Jiji.jin: Jiji.myo, // 진묘 원진
    Jiji.sa: Jiji.in_, // 사인 원진
    Jiji.o: Jiji.chuk, // 오축 원진
    Jiji.mi: Jiji.ja, // 미자 원진
    Jiji.sin_: Jiji.hae, // 신해 원진
    Jiji.yu: Jiji.sul, // 유술 원진
    Jiji.sul: Jiji.yu, // 술유 원진
    Jiji.hae: Jiji.sin_, // 해신 원진
  };

  static bool checkWonjin(Jiji a, Jiji b) {
    return wonjinPairs[a] == b;
  }

  static String? getWonjinName(Jiji a, Jiji b) {
    if (checkWonjin(a, b)) {
      return '${a.korean}${b.korean} 원진';
    }
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 궁합 계산 결과
// ═══════════════════════════════════════════════════════════════════════════

/// 합충형해파 분석 결과
class HapchungAnalysis {
  /// 합 (긍정적)
  final List<String> hap;

  /// 충 (부정적 - 가장 강함)
  final List<String> chung;

  /// 형 (부정적)
  final List<String> hyung;

  /// 해 (부정적)
  final List<String> hae;

  /// 파 (부정적)
  final List<String> pa;

  /// 원진 (부정적)
  final List<String> wonjin;

  const HapchungAnalysis({
    required this.hap,
    required this.chung,
    required this.hyung,
    required this.hae,
    required this.pa,
    required this.wonjin,
  });

  /// 긍정적 요소 개수
  int get positiveCount => hap.length;

  /// 부정적 요소 개수
  int get negativeCount =>
      chung.length + hyung.length + hae.length + pa.length + wonjin.length;

  /// JSON 변환
  Map<String, dynamic> toJson() => {
        'hap': hap,
        'chung': chung,
        'hyung': hyung,
        'hae': hae,
        'pa': pa,
        'wonjin': wonjin,
      };
}

/// 궁합 계산 결과
class CompatibilityResult {
  /// 전체 점수 (0-100)
  final int overallScore;

  /// 카테고리별 점수
  final Map<String, int> categoryScores;

  /// 강점 목록
  final List<String> strengths;

  /// 도전/주의점 목록
  final List<String> challenges;

  /// 합충형해파 상세 분석
  final HapchungAnalysis hapchungDetails;

  /// 요약 설명
  final String summary;

  const CompatibilityResult({
    required this.overallScore,
    required this.categoryScores,
    required this.strengths,
    required this.challenges,
    required this.hapchungDetails,
    required this.summary,
  });

  /// JSON 변환
  Map<String, dynamic> toJson() => {
        'overall_score': overallScore,
        'category_scores': categoryScores,
        'strengths': strengths,
        'challenges': challenges,
        'hapchung_details': hapchungDetails.toJson(),
        'summary': summary,
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// 궁합 계산기 메인 클래스
// ═══════════════════════════════════════════════════════════════════════════

/// 궁합 계산기
///
/// 두 사람의 saju_analyses 데이터를 받아 궁합을 계산합니다.
class CompatibilityCalculator {
  /// 두 사람의 사주로 궁합 계산
  ///
  /// ## 파라미터
  /// - `mySaju`: 나의 saju_analyses 데이터 (Map)
  /// - `targetSaju`: 상대의 saju_analyses 데이터 (Map)
  /// - `relationType`: 관계 유형 (romantic_partner, family_parent 등)
  ///
  /// ## 반환
  /// `CompatibilityResult` - 궁합 분석 결과
  CompatibilityResult calculate({
    required Map<String, dynamic> mySaju,
    required Map<String, dynamic> targetSaju,
    required String relationType,
  }) {
    print('[CompatibilityCalculator] 🧮 궁합 계산 시작');
    print('  - relationType: $relationType');

    // 1. 사주 데이터 파싱
    final myParsed = _parseSajuData(mySaju);
    final targetParsed = _parseSajuData(targetSaju);

    print('  - 나의 사주: ${_sajuToString(myParsed)}');
    print('  - 상대 사주: ${_sajuToString(targetParsed)}');

    // 2. 합충형해파 분석
    final hapchungAnalysis = _analyzeHapchung(myParsed, targetParsed);
    print('  - 합: ${hapchungAnalysis.hap.length}개');
    print('  - 충: ${hapchungAnalysis.chung.length}개');
    print('  - 형: ${hapchungAnalysis.hyung.length}개');
    print('  - 해: ${hapchungAnalysis.hae.length}개');
    print('  - 파: ${hapchungAnalysis.pa.length}개');
    print('  - 원진: ${hapchungAnalysis.wonjin.length}개');

    // 3. 오행 상생상극 분석
    final ohengAnalysis = _analyzeOheng(myParsed, targetParsed);

    // 4. 일주 궁합 (일간 기준)
    final iljuAnalysis = _analyzeIlju(myParsed, targetParsed);

    // 5. 점수 계산
    final scores = _calculateScores(
      hapchungAnalysis: hapchungAnalysis,
      ohengAnalysis: ohengAnalysis,
      iljuAnalysis: iljuAnalysis,
      relationType: relationType,
    );

    // 6. 강점/도전 추출
    final strengths = _extractStrengths(hapchungAnalysis, ohengAnalysis, iljuAnalysis);
    final challenges = _extractChallenges(hapchungAnalysis, ohengAnalysis, iljuAnalysis);

    // 7. 요약 생성
    final summary = _generateSummary(
      overallScore: scores['overall']!,
      hapchungAnalysis: hapchungAnalysis,
      relationType: relationType,
    );

    print('[CompatibilityCalculator] ✅ 궁합 계산 완료: ${scores['overall']}점');

    return CompatibilityResult(
      overallScore: scores['overall']!,
      categoryScores: Map<String, int>.from(scores)..remove('overall'),
      strengths: strengths,
      challenges: challenges,
      hapchungDetails: hapchungAnalysis,
      summary: summary,
    );
  }

  /// 사주 데이터 파싱
  _ParsedSaju _parseSajuData(Map<String, dynamic> saju) {
    return _ParsedSaju(
      yearGan: Cheongan.fromKoreanHanja(saju['year_gan'] as String?),
      yearJi: Jiji.fromKoreanHanja(saju['year_ji'] as String?),
      monthGan: Cheongan.fromKoreanHanja(saju['month_gan'] as String?),
      monthJi: Jiji.fromKoreanHanja(saju['month_ji'] as String?),
      dayGan: Cheongan.fromKoreanHanja(saju['day_gan'] as String?),
      dayJi: Jiji.fromKoreanHanja(saju['day_ji'] as String?),
      hourGan: Cheongan.fromKoreanHanja(saju['hour_gan'] as String?),
      hourJi: Jiji.fromKoreanHanja(saju['hour_ji'] as String?),
    );
  }

  /// 사주를 문자열로 변환 (디버깅용)
  String _sajuToString(_ParsedSaju saju) {
    final year = '${saju.yearGan?.korean ?? '?'}${saju.yearJi?.korean ?? '?'}';
    final month = '${saju.monthGan?.korean ?? '?'}${saju.monthJi?.korean ?? '?'}';
    final day = '${saju.dayGan?.korean ?? '?'}${saju.dayJi?.korean ?? '?'}';
    final hour = '${saju.hourGan?.korean ?? '?'}${saju.hourJi?.korean ?? '?'}';
    return '$year $month $day $hour';
  }

  /// 합충형해파 분석
  HapchungAnalysis _analyzeHapchung(_ParsedSaju my, _ParsedSaju target) {
    final hap = <String>[];
    final chung = <String>[];
    final hyung = <String>[];
    final hae = <String>[];
    final pa = <String>[];
    final wonjin = <String>[];

    // 모든 천간 조합 분석
    final myGans = [my.yearGan, my.monthGan, my.dayGan, my.hourGan];
    final targetGans = [target.yearGan, target.monthGan, target.dayGan, target.hourGan];
    final ganLabels = ['년간', '월간', '일간', '시간'];

    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        final myGan = myGans[i];
        final targetGan = targetGans[j];
        if (myGan == null || targetGan == null) continue;

        // 천간합 체크
        final hapResult = CheonganHap.checkHapName(myGan, targetGan);
        if (hapResult != null) {
          hap.add('${ganLabels[i]}↔${ganLabels[j]}: $hapResult');
        }
      }
    }

    // 모든 지지 조합 분석
    final myJis = [my.yearJi, my.monthJi, my.dayJi, my.hourJi];
    final targetJis = [target.yearJi, target.monthJi, target.dayJi, target.hourJi];
    final jiLabels = ['년지', '월지', '일지', '시지'];

    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        final myJi = myJis[i];
        final targetJi = targetJis[j];
        if (myJi == null || targetJi == null) continue;

        // 지지 육합 체크
        final yukhapResult = JijiYukhap.checkHapName(myJi, targetJi);
        if (yukhapResult != null) {
          hap.add('${jiLabels[i]}↔${jiLabels[j]}: $yukhapResult');
        }

        // 반합 체크
        final banhapResult = JijiSamhap.checkBanhap(myJi, targetJi);
        if (banhapResult != null) {
          hap.add('${jiLabels[i]}↔${jiLabels[j]}: $banhapResult');
        }

        // 충 체크
        final chungResult = JijiChung.checkChung(myJi, targetJi);
        if (chungResult != null) {
          chung.add('${jiLabels[i]}↔${jiLabels[j]}: $chungResult');
        }

        // 형 체크
        final hyungResult = JijiHyung.checkHyung(myJi, targetJi);
        if (hyungResult != null) {
          hyung.add('${jiLabels[i]}↔${jiLabels[j]}: $hyungResult');
        }

        // 해 체크
        final haeResult = JijiHae.checkHae(myJi, targetJi);
        if (haeResult != null) {
          hae.add('${jiLabels[i]}↔${jiLabels[j]}: $haeResult');
        }

        // 파 체크
        final paResult = JijiPa.checkPa(myJi, targetJi);
        if (paResult != null) {
          pa.add('${jiLabels[i]}↔${jiLabels[j]}: $paResult');
        }

        // 원진 체크
        if (Wonjin.checkWonjin(myJi, targetJi)) {
          wonjin.add('${jiLabels[i]}↔${jiLabels[j]}: ${myJi.korean}${targetJi.korean} 원진');
        }
      }
    }

    return HapchungAnalysis(
      hap: hap,
      chung: chung,
      hyung: hyung,
      hae: hae,
      pa: pa,
      wonjin: wonjin,
    );
  }

  /// 오행 상생상극 분석
  Map<String, dynamic> _analyzeOheng(_ParsedSaju my, _ParsedSaju target) {
    final myDayGan = my.dayGan;
    final targetDayGan = target.dayGan;

    if (myDayGan == null || targetDayGan == null) {
      return {'compatible': true, 'reason': '일간 정보 없음'};
    }

    final myOheng = Oheng.fromString(myDayGan.oheng);
    final targetOheng = Oheng.fromString(targetDayGan.oheng);

    if (myOheng == null || targetOheng == null) {
      return {'compatible': true, 'reason': '오행 정보 없음'};
    }

    // 상생 관계
    if (myOheng.generateMe == targetOheng || myOheng.iGenerate == targetOheng) {
      return {
        'compatible': true,
        'type': 'sangsaeng',
        'reason': '${myOheng.korean}과 ${targetOheng.korean}은 상생 관계',
      };
    }

    // 동일 오행
    if (myOheng == targetOheng) {
      return {
        'compatible': true,
        'type': 'same',
        'reason': '둘 다 ${myOheng.korean} 오행으로 동질감',
      };
    }

    // 상극 관계
    if (myOheng.controlMe == targetOheng || myOheng.iControl == targetOheng) {
      return {
        'compatible': false,
        'type': 'sanggeuk',
        'reason': '${myOheng.korean}과 ${targetOheng.korean}은 상극 관계',
      };
    }

    return {'compatible': true, 'reason': '특별한 관계 없음'};
  }

  /// 일주 궁합 분석 (일간 + 일지)
  Map<String, dynamic> _analyzeIlju(_ParsedSaju my, _ParsedSaju target) {
    final result = <String, dynamic>{};

    // 일간 합 확인
    if (my.dayGan != null && target.dayGan != null) {
      final ganHap = CheonganHap.checkHapName(my.dayGan!, target.dayGan!);
      if (ganHap != null) {
        result['day_gan_hap'] = ganHap;
      }
    }

    // 일지 합 확인
    if (my.dayJi != null && target.dayJi != null) {
      final jiHap = JijiYukhap.checkHapName(my.dayJi!, target.dayJi!);
      if (jiHap != null) {
        result['day_ji_hap'] = jiHap;
      }

      // 일지 충 확인
      final jiChung = JijiChung.checkChung(my.dayJi!, target.dayJi!);
      if (jiChung != null) {
        result['day_ji_chung'] = jiChung;
      }
    }

    // 일주 쌍합 (일간합 + 일지합)
    if (result.containsKey('day_gan_hap') && result.containsKey('day_ji_hap')) {
      result['ssanghap'] = true;
      result['ssanghap_description'] = '일주 쌍합 - 최고의 궁합';
    }

    return result;
  }

  /// 점수 계산
  Map<String, int> _calculateScores({
    required HapchungAnalysis hapchungAnalysis,
    required Map<String, dynamic> ohengAnalysis,
    required Map<String, dynamic> iljuAnalysis,
    required String relationType,
  }) {
    // 기본 점수 50점에서 시작
    int baseScore = 50;

    // 합 점수 (긍정적)
    int hapScore = 0;
    for (final hap in hapchungAnalysis.hap) {
      if (hap.contains('천간합') || hap.contains('합토') || hap.contains('합금') ||
          hap.contains('합수') || hap.contains('합목') || hap.contains('합화')) {
        hapScore += 8; // 육합/천간합
      } else if (hap.contains('반합')) {
        hapScore += 5; // 반합
      } else {
        hapScore += 3;
      }
    }
    hapScore = hapScore.clamp(0, 35); // 최대 35점

    // 충 점수 (부정적)
    int chungPenalty = hapchungAnalysis.chung.length * 10;
    chungPenalty = chungPenalty.clamp(0, 30);

    // 형 점수 (부정적)
    int hyungPenalty = hapchungAnalysis.hyung.length * 6;
    hyungPenalty = hyungPenalty.clamp(0, 15);

    // 해/파 점수 (부정적)
    int haePaPenalty = (hapchungAnalysis.hae.length + hapchungAnalysis.pa.length) * 4;
    haePaPenalty = haePaPenalty.clamp(0, 15);

    // 원진 점수 (부정적)
    int wonjinPenalty = hapchungAnalysis.wonjin.length * 7;
    wonjinPenalty = wonjinPenalty.clamp(0, 15);

    // 오행 점수
    int ohengScore = 0;
    if (ohengAnalysis['compatible'] == true) {
      if (ohengAnalysis['type'] == 'sangsaeng') {
        ohengScore = 10;
      } else if (ohengAnalysis['type'] == 'same') {
        ohengScore = 5;
      }
    } else {
      ohengScore = -8;
    }

    // 일주 쌍합 보너스
    int iljuBonus = 0;
    if (iljuAnalysis['ssanghap'] == true) {
      iljuBonus = 15; // 일주 쌍합은 최고의 궁합
    } else if (iljuAnalysis.containsKey('day_gan_hap')) {
      iljuBonus = 8;
    } else if (iljuAnalysis.containsKey('day_ji_hap')) {
      iljuBonus = 8;
    }
    if (iljuAnalysis.containsKey('day_ji_chung')) {
      iljuBonus -= 10; // 일지충은 큰 감점
    }

    // 관계 유형별 가중치
    double relationWeight = 1.0;
    if (relationType.startsWith('romantic_')) {
      relationWeight = 1.2; // 연인 궁합은 더 엄격
    } else if (relationType.startsWith('family_')) {
      relationWeight = 1.1;
    } else if (relationType.startsWith('work_')) {
      relationWeight = 0.9; // 비즈니스는 조금 관대
    }

    // 총점 계산
    int totalScore = baseScore +
        hapScore +
        ohengScore +
        iljuBonus -
        ((chungPenalty + hyungPenalty + haePaPenalty + wonjinPenalty) * relationWeight).round();

    // 점수 범위 제한 (15-95)
    totalScore = totalScore.clamp(15, 95);

    // 카테고리별 점수
    return {
      'overall': totalScore,
      'harmony': (50 + hapScore - chungPenalty).clamp(10, 100), // 조화
      'emotional': (50 + iljuBonus + ohengScore - wonjinPenalty).clamp(10, 100), // 감정적
      'stability': (60 - hyungPenalty - haePaPenalty).clamp(10, 100), // 안정성
      'communication': (50 + hapScore ~/ 2 - chungPenalty ~/ 2).clamp(10, 100), // 소통
    };
  }

  /// 강점 추출
  List<String> _extractStrengths(
    HapchungAnalysis hapchung,
    Map<String, dynamic> oheng,
    Map<String, dynamic> ilju,
  ) {
    final strengths = <String>[];

    // 일주 쌍합
    if (ilju['ssanghap'] == true) {
      strengths.add('일주 쌍합: 최고의 인연으로 서로에게 운명적 끌림');
    }

    // 일간합
    if (ilju.containsKey('day_gan_hap')) {
      strengths.add('일간합: 마음이 잘 통하고 서로 이해하는 관계');
    }

    // 일지합
    if (ilju.containsKey('day_ji_hap')) {
      strengths.add('일지합: 일상에서의 조화와 편안함');
    }

    // 합이 많은 경우
    if (hapchung.hap.length >= 3) {
      strengths.add('다양한 합의 관계: 여러 면에서 서로 잘 맞음');
    } else if (hapchung.hap.isNotEmpty) {
      for (final hap in hapchung.hap.take(2)) {
        final parts = hap.split(': ');
        if (parts.length > 1) {
          final hapName = parts[1];
          if (hapName.contains('천간합')) {
            strengths.add('천간합: 정신적 교감이 좋은 관계');
          } else if (hapName.contains('육합')) {
            strengths.add('지지합: 실생활에서의 조화');
          }
        }
      }
    }

    // 오행 상생
    if (oheng['type'] == 'sangsaeng') {
      strengths.add('오행 상생: ${oheng['reason']}');
    }

    // 충이 없는 경우
    if (hapchung.chung.isEmpty && hapchung.wonjin.isEmpty) {
      strengths.add('충/원진 없음: 큰 갈등 요소 없이 안정적');
    }

    return strengths.isEmpty ? ['서로 존중하며 발전하는 관계'] : strengths;
  }

  /// 도전/주의점 추출
  List<String> _extractChallenges(
    HapchungAnalysis hapchung,
    Map<String, dynamic> oheng,
    Map<String, dynamic> ilju,
  ) {
    final challenges = <String>[];

    // 일지충
    if (ilju.containsKey('day_ji_chung')) {
      challenges.add('일지충: 일상에서 마찰이 생길 수 있어 배려 필요');
    }

    // 충
    for (final chung in hapchung.chung.take(2)) {
      final parts = chung.split(': ');
      if (parts.length > 1) {
        final chungName = parts[1];
        if (chungName.contains('자오충')) {
          challenges.add('자오충: 감정적 충돌 주의, 서로 양보 필요');
        } else if (chungName.contains('인신충')) {
          challenges.add('인신충: 의견 충돌 시 대화로 해결');
        } else {
          challenges.add('$chungName: 서로 다른 점을 인정하고 존중');
        }
      }
    }

    // 형
    if (hapchung.hyung.isNotEmpty) {
      challenges.add('형살: 서로에게 상처 주지 않도록 말조심');
    }

    // 원진
    if (hapchung.wonjin.isNotEmpty) {
      challenges.add('원진: 오해가 생기기 쉬우니 소통을 자주');
    }

    // 해/파
    if (hapchung.hae.isNotEmpty || hapchung.pa.isNotEmpty) {
      challenges.add('해/파살: 작은 갈등이 커지지 않도록 관리');
    }

    // 오행 상극
    if (oheng['compatible'] == false) {
      challenges.add('오행 상극: ${oheng['reason']} - 서로 보완 필요');
    }

    return challenges.isEmpty ? ['특별한 주의사항 없음'] : challenges;
  }

  /// 요약 생성
  String _generateSummary({
    required int overallScore,
    required HapchungAnalysis hapchungAnalysis,
    required String relationType,
  }) {
    String relationName;
    if (relationType.startsWith('romantic_')) {
      relationName = '연인';
    } else if (relationType.startsWith('family_')) {
      relationName = '가족';
    } else if (relationType.startsWith('work_')) {
      relationName = '업무';
    } else if (relationType.startsWith('friend_')) {
      relationName = '친구';
    } else {
      relationName = '인연';
    }

    if (overallScore >= 80) {
      return '아주 좋은 $relationName 궁합입니다. 서로에게 긍정적인 영향을 주는 인연으로, 함께할수록 발전합니다.';
    } else if (overallScore >= 65) {
      return '좋은 $relationName 궁합입니다. 서로 잘 맞는 부분이 많아 편안한 관계를 유지할 수 있습니다.';
    } else if (overallScore >= 50) {
      return '보통의 $relationName 궁합입니다. 서로의 다름을 인정하고 노력하면 좋은 관계가 됩니다.';
    } else if (overallScore >= 35) {
      return '노력이 필요한 $relationName 궁합입니다. 서로 이해하고 배려하는 마음이 중요합니다.';
    } else {
      return '도전적인 $relationName 궁합입니다. 인내심을 갖고 소통하면 성장의 기회가 됩니다.';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 내부 클래스
// ═══════════════════════════════════════════════════════════════════════════

/// 파싱된 사주 데이터
class _ParsedSaju {
  final Cheongan? yearGan;
  final Jiji? yearJi;
  final Cheongan? monthGan;
  final Jiji? monthJi;
  final Cheongan? dayGan;
  final Jiji? dayJi;
  final Cheongan? hourGan;
  final Jiji? hourJi;

  const _ParsedSaju({
    this.yearGan,
    this.yearJi,
    this.monthGan,
    this.monthJi,
    this.dayGan,
    this.dayJi,
    this.hourGan,
    this.hourJi,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// 전역 인스턴스
// ═══════════════════════════════════════════════════════════════════════════

/// 전역 궁합 계산기 인스턴스
final compatibilityCalculator = CompatibilityCalculator();
