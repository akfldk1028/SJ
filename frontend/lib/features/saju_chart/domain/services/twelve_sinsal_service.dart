/// 12신살(十二神煞) 계산 서비스
/// 년지/일지를 기준으로 각 지지에 배치되는 12가지 신살 분석
///
/// Phase 10-B: RuleEngine 기반 메서드 추가 (하위 호환성 유지)
/// - 기존 하드코딩 로직: analyzeFromChart(), analyze()
/// - RuleEngine 기반: analyzeWithRuleEngine()
library;

import '../../data/constants/twelve_sinsal.dart';
import '../../data/repositories/rule_repository_impl.dart';
import '../entities/rule.dart';
import '../entities/compiled_rules.dart';
import '../entities/saju_chart.dart';
import '../entities/saju_context.dart';
import 'rule_engine.dart';

// ============================================================================
// 12신살 분석 결과 모델
// ============================================================================

/// 단일 궁성의 12신살 결과
class TwelveSinsalResult {
  /// 궁성 이름 (년지/월지/일지/시지)
  final String pillarName;

  /// 해당 지지
  final String jiji;

  /// 기준 지지 (년지 또는 일지)
  final String baseJi;

  /// 12신살
  final TwelveSinsal sinsal;

  /// 특수 신살 목록
  final List<SpecialSinsal> specialSinsals;

  const TwelveSinsalResult({
    required this.pillarName,
    required this.jiji,
    required this.baseJi,
    required this.sinsal,
    this.specialSinsals = const [],
  });

  /// 길흉 판단
  String get fortuneType => sinsal.fortuneType;

  /// 특수 신살 있는지
  bool get hasSpecialSinsal => specialSinsals.isNotEmpty;

  @override
  String toString() => '$pillarName: ${sinsal.korean}';
}

/// 사주 전체 12신살 분석 결과
class TwelveSinsalAnalysisResult {
  /// 년지 12신살 결과
  final TwelveSinsalResult yearResult;

  /// 월지 12신살 결과
  final TwelveSinsalResult monthResult;

  /// 일지 12신살 결과
  final TwelveSinsalResult dayResult;

  /// 시지 12신살 결과 (시간 모를 경우 null)
  final TwelveSinsalResult? hourResult;

  /// 기준 지지 (년지 또는 일지)
  final String baseJi;

  /// 기준 유형 (년지/일지)
  final String baseType;

  /// 일간 (특수 신살 계산용)
  final String dayGan;

  const TwelveSinsalAnalysisResult({
    required this.yearResult,
    required this.monthResult,
    required this.dayResult,
    this.hourResult,
    required this.baseJi,
    required this.baseType,
    required this.dayGan,
  });

  /// 모든 결과 리스트
  List<TwelveSinsalResult> get allResults => [
        yearResult,
        monthResult,
        dayResult,
        if (hourResult != null) hourResult!,
      ];

  /// 길한 신살 개수
  int get goodSinsalCount =>
      allResults.where((r) => r.fortuneType == '길').length;

  /// 흉한 신살 개수
  int get badSinsalCount =>
      allResults.where((r) => r.fortuneType == '흉').length;

  /// 길흉혼합 신살 개수
  int get mixedSinsalCount =>
      allResults.where((r) => r.fortuneType == '길흉혼합').length;

  /// 특정 신살 찾기
  TwelveSinsalResult? findSinsal(TwelveSinsal target) {
    for (final result in allResults) {
      if (result.sinsal == target) return result;
    }
    return null;
  }

  /// 역마살 있는 궁
  TwelveSinsalResult? get yeokmaResult =>
      findSinsal(TwelveSinsal.yeokma);

  /// 도화살(연살) 있는 궁
  TwelveSinsalResult? get dohwaResult =>
      findSinsal(TwelveSinsal.yeonsal);

  /// 화개살 있는 궁
  TwelveSinsalResult? get hwagaeResult =>
      findSinsal(TwelveSinsal.hwagae);

  /// 장성살 있는 궁
  TwelveSinsalResult? get jangsungResult =>
      findSinsal(TwelveSinsal.jangsung);

  /// 12신살 요약
  String get summary {
    final parts = <String>[];

    // 길한 신살
    if (jangsungResult != null) {
      parts.add('장성살(${jangsungResult!.pillarName})');
    }
    final bananResult = findSinsal(TwelveSinsal.banan);
    if (bananResult != null) {
      parts.add('반안살(${bananResult.pillarName})');
    }

    // 길흉혼합
    if (yeokmaResult != null) {
      parts.add('역마살(${yeokmaResult!.pillarName})');
    }
    if (dohwaResult != null) {
      parts.add('도화살(${dohwaResult!.pillarName})');
    }
    if (hwagaeResult != null) {
      parts.add('화개살(${hwagaeResult!.pillarName})');
    }

    if (parts.isEmpty) {
      return '주요 신살 없음';
    }
    return parts.join(', ');
  }
}

// ============================================================================
// 12신살 계산 서비스
// ============================================================================

/// 12신살 계산 서비스
class TwelveSinsalService {
  /// 사주 차트에서 12신살 분석 (일지 기준)
  /// 현대 명리학에서는 일지 기준이 더 적중률이 높은 것으로 인식됨
  /// 참고: https://namu.wiki/w/사주팔자/신살
  static TwelveSinsalAnalysisResult analyzeFromChart(
    SajuChart chart, {
    bool useYearJi = false, // true: 년지 기준, false: 일지 기준 (기본값: 일지)
  }) {
    final baseJi = useYearJi ? chart.yearPillar.ji : chart.dayPillar.ji;
    final dayGan = chart.dayPillar.gan;

    return TwelveSinsalAnalysisResult(
      yearResult: _analyzeSinsal(
        pillarName: '년지',
        jiji: chart.yearPillar.ji,
        baseJi: baseJi,
        dayGan: dayGan,
      ),
      monthResult: _analyzeSinsal(
        pillarName: '월지',
        jiji: chart.monthPillar.ji,
        baseJi: baseJi,
        dayGan: dayGan,
      ),
      dayResult: _analyzeSinsal(
        pillarName: '일지',
        jiji: chart.dayPillar.ji,
        baseJi: baseJi,
        dayGan: dayGan,
      ),
      hourResult: chart.hourPillar != null
          ? _analyzeSinsal(
              pillarName: '시지',
              jiji: chart.hourPillar!.ji,
              baseJi: baseJi,
              dayGan: dayGan,
            )
          : null,
      baseJi: baseJi,
      baseType: useYearJi ? '년지' : '일지',
      dayGan: dayGan,
    );
  }

  /// 개별 파라미터로 12신살 분석
  static TwelveSinsalAnalysisResult analyze({
    required String yearJi,
    required String monthJi,
    required String dayGan,
    required String dayJi,
    String? hourJi,
    bool useYearJi = false, // 기본값: 일지 기준 (현대 명리학)
  }) {
    final baseJi = useYearJi ? yearJi : dayJi;

    return TwelveSinsalAnalysisResult(
      yearResult: _analyzeSinsal(
        pillarName: '년지',
        jiji: yearJi,
        baseJi: baseJi,
        dayGan: dayGan,
      ),
      monthResult: _analyzeSinsal(
        pillarName: '월지',
        jiji: monthJi,
        baseJi: baseJi,
        dayGan: dayGan,
      ),
      dayResult: _analyzeSinsal(
        pillarName: '일지',
        jiji: dayJi,
        baseJi: baseJi,
        dayGan: dayGan,
      ),
      hourResult: hourJi != null
          ? _analyzeSinsal(
              pillarName: '시지',
              jiji: hourJi,
              baseJi: baseJi,
              dayGan: dayGan,
            )
          : null,
      baseJi: baseJi,
      baseType: useYearJi ? '년지' : '일지',
      dayGan: dayGan,
    );
  }

  /// 단일 지지의 12신살 분석
  static TwelveSinsalResult _analyzeSinsal({
    required String pillarName,
    required String jiji,
    required String baseJi,
    required String dayGan,
  }) {
    final sinsal = calculateSinsal(baseJi, jiji) ?? TwelveSinsal.geopsal;
    final specialSinsals = _findSpecialSinsals(dayGan, jiji);

    return TwelveSinsalResult(
      pillarName: pillarName,
      jiji: jiji,
      baseJi: baseJi,
      sinsal: sinsal,
      specialSinsals: specialSinsals,
    );
  }

  /// 특수 신살 찾기
  static List<SpecialSinsal> _findSpecialSinsals(String dayGan, String jiji) {
    final specialList = <SpecialSinsal>[];

    // 양인살 확인
    if (isYangIn(dayGan, jiji)) {
      specialList.add(SpecialSinsal.yangin);
    }

    // 천을귀인 확인
    if (isCheonEulGwin(dayGan, jiji)) {
      specialList.add(SpecialSinsal.cheoneulgwin);
    }

    return specialList;
  }

  /// 특정 기준 지지의 12신살 전체 맵 조회
  static Map<String, TwelveSinsal> getSinsalMap(String baseJi) {
    return buildSinsalMap(baseJi);
  }

  /// 특정 신살이 있는 지지 조회
  static String? findJijiWithSinsal(String baseJi, TwelveSinsal target) {
    return findJijiBySinsal(baseJi, target);
  }

  /// 역마살 지지 조회
  static String? getYeokmaJiji(String baseJi) {
    return getYeokmaJi(baseJi);
  }

  /// 도화살 지지 조회
  static String? getDohwaJiji(String baseJi) {
    return getDohwaJi(baseJi);
  }

  /// 화개살 지지 조회
  static String? getHwagaeJiji(String baseJi) {
    return getHwagaeJi(baseJi);
  }

  /// 장성살 지지 조회
  static String? getJangsungJiji(String baseJi) {
    return getJangsungJi(baseJi);
  }

  /// 12신살 상세 해석
  static String getDetailedInterpretation(TwelveSinsal sinsal) {
    return switch (sinsal) {
      TwelveSinsal.geopsal => '''
겁살(劫煞)은 재물 손실과 도난을 주의해야 하는 신살입니다.
- 갑작스러운 재물 손실 주의
- 투자나 보증에 신중해야 함
- 도둑, 사기 조심
''',
      TwelveSinsal.jaesal => '''
재살(災煞)은 재앙과 사고를 주의해야 하는 신살입니다.
- 예기치 못한 재난 주의
- 안전사고에 유의
- 보험 등 대비 필요
''',
      TwelveSinsal.cheonsal => '''
천살(天煞)은 하늘에서 오는 재앙의 신살입니다.
- 자연재해, 날씨 변화 주의
- 예기치 못한 사건 발생 가능
- 하늘의 뜻에 순응하는 자세 필요
''',
      TwelveSinsal.jisal => '''
지살(地煞)은 땅과 관련된 재앙의 신살입니다.
- 이사, 이동에 주의
- 부동산 거래 신중
- 지진, 함몰 등 지면 관련 주의
''',
      TwelveSinsal.yeonsal => '''
연살(年煞)은 도화살이라고도 하며 이성 관계의 신살입니다.
- 이성에게 매력적으로 보임
- 연애, 결혼운에 영향
- 바람기나 색정 문제 주의
- 예술적 감각이 뛰어남
''',
      TwelveSinsal.wolsal => '''
월살(月煞)은 고독과 외로움의 신살입니다.
- 혼자 있는 시간이 많음
- 독립심이 강함
- 고독을 즐기는 성향
- 가족과 떨어져 살 수 있음
''',
      TwelveSinsal.mangshin => '''
망신(亡身)은 체면 손상의 신살입니다.
- 명예나 체면이 손상될 수 있음
- 창피당할 일 주의
- 실수나 실언에 조심
- 평판 관리 필요
''',
      TwelveSinsal.jangsung => '''
장성(將星)은 권위와 리더십의 길한 신살입니다.
- 지도자적 자질이 있음
- 권위와 명예 획득
- 조직을 이끄는 능력
- 군인, 경찰, 관리직 적합
''',
      TwelveSinsal.banan => '''
반안(攀鞍)은 안정과 승진의 길한 신살입니다.
- 안장에 오르듯 승진
- 안정적인 출세
- 높은 자리에 오름
- 사회적 성공 가능
''',
      TwelveSinsal.yeokma => '''
역마(驛馬)는 이동과 변동의 신살입니다.
- 이동, 출장이 많음
- 해외 인연
- 변화가 많은 삶
- 무역, 운송, 여행업 적합
- 한 곳에 정착하기 어려움
''',
      TwelveSinsal.yukhae => '''
육해(六害)는 육친 갈등의 신살입니다.
- 가족 간 갈등 주의
- 친척과의 불화
- 가정 문제 발생 가능
- 육친의 도움 받기 어려움
''',
      TwelveSinsal.hwagae => '''
화개(華蓋)는 예술과 종교의 신살입니다.
- 예술적 재능이 뛰어남
- 종교나 철학에 관심
- 학문 탐구 능력
- 고독하지만 깊은 내면
- 예술가, 종교인 적합
''',
    };
  }

  /// 괴강살 여부 확인
  static bool checkGoeGang(String dayGan, String dayJi) {
    return isGoeGang(dayGan, dayJi);
  }

  /// 양인살 여부 확인
  static bool checkYangIn(String dayGan, String targetJi) {
    return isYangIn(dayGan, targetJi);
  }

  /// 천을귀인 여부 확인
  static bool checkCheonEulGwin(String dayGan, String targetJi) {
    return isCheonEulGwin(dayGan, targetJi);
  }

  // ============================================================================
  // RuleEngine 기반 분석 (Phase 10-B)
  // ============================================================================

  /// RuleEngine 기반 신살 분석
  ///
  /// JSON 룰셋을 사용하여 신살을 분석합니다.
  /// 기존 하드코딩 로직과 병행 사용 가능합니다.
  ///
  /// [chart] 분석할 사주 차트
  /// [gender] 성별 (선택)
  /// 반환: RuleEngine 매칭 결과 리스트
  static Future<RuleEngineSinsalResult> analyzeWithRuleEngine(
    SajuChart chart, {
    String? gender,
  }) async {
    // 1. 컨텍스트 생성
    final context = SajuContext.fromChart(chart, gender: gender);

    // 2. 신살 룰셋 로드
    CompiledRules? compiledRules;
    try {
      compiledRules = await ruleRepository.loadByType(RuleType.sinsal);
    } catch (e) {
      // 룰셋 로드 실패 시 빈 결과 반환
      return RuleEngineSinsalResult(
        matchResults: [],
        context: context,
        error: '신살 룰셋 로드 실패: $e',
      );
    }

    // 3. RuleEngine으로 매칭
    final engine = RuleEngine();
    final matchResults = engine.matchAll(compiledRules, context);

    return RuleEngineSinsalResult(
      matchResults: matchResults,
      context: context,
    );
  }

  /// RuleEngine 기반 특정 신살 검색
  ///
  /// [chart] 분석할 사주 차트
  /// [sinsalId] 찾을 신살 ID (예: "cheon_eul_gwin", "yang_in_sal")
  /// 반환: 매칭된 결과 또는 null
  static Future<RuleMatchResult?> findSinsalById(
    SajuChart chart,
    String sinsalId, {
    String? gender,
  }) async {
    final result = await analyzeWithRuleEngine(chart, gender: gender);

    for (final match in result.matchResults) {
      if (match.rule.id == sinsalId) {
        return match;
      }
    }
    return null;
  }

  /// RuleEngine 기반 길/흉 신살 분류
  ///
  /// [chart] 분석할 사주 차트
  /// 반환: 길흉별로 분류된 신살 결과
  static Future<SinsalByFortuneType> analyzeSinsalByFortune(
    SajuChart chart, {
    String? gender,
  }) async {
    final result = await analyzeWithRuleEngine(chart, gender: gender);

    final good = <RuleMatchResult>[];
    final bad = <RuleMatchResult>[];
    final neutral = <RuleMatchResult>[];

    for (final match in result.matchResults) {
      switch (match.rule.fortuneType) {
        case FortuneType.gil:
          good.add(match);
        case FortuneType.hyung:
          bad.add(match);
        case FortuneType.jung:
          neutral.add(match);
      }
    }

    return SinsalByFortuneType(
      good: good,
      bad: bad,
      neutral: neutral,
    );
  }

  /// 기존 로직과 RuleEngine 결과 비교 (테스트/검증용)
  ///
  /// 두 분석 방식의 결과를 비교하여 일관성을 검증합니다.
  static Future<SinsalComparisonResult> compareWithLegacy(
    SajuChart chart, {
    String? gender,
  }) async {
    // 기존 로직 분석
    final legacyResult = analyzeFromChart(chart);

    // RuleEngine 분석
    final ruleEngineResult = await analyzeWithRuleEngine(chart, gender: gender);

    // 특수신살 비교 (천을귀인, 양인살)
    final legacySpecials = <String>[];
    final ruleEngineSpecials = <String>[];

    // 기존 로직의 특수신살 추출
    for (final result in legacyResult.allResults) {
      for (final special in result.specialSinsals) {
        legacySpecials.add(special.korean);
      }
    }

    // RuleEngine의 특수신살 추출 (category == '특수신살')
    for (final match in ruleEngineResult.matchResults) {
      if (match.rule.category == '특수신살') {
        ruleEngineSpecials.add(match.rule.name);
      }
    }

    return SinsalComparisonResult(
      legacyResult: legacyResult,
      ruleEngineResult: ruleEngineResult,
      legacySpecialSinsals: legacySpecials,
      ruleEngineSpecialSinsals: ruleEngineSpecials,
    );
  }
}

// ============================================================================
// RuleEngine 기반 결과 모델
// ============================================================================

/// RuleEngine 기반 신살 분석 결과
class RuleEngineSinsalResult {
  /// 매칭된 룰 결과 리스트
  final List<RuleMatchResult> matchResults;

  /// 분석에 사용된 컨텍스트
  final SajuContext context;

  /// 에러 메시지 (있으면)
  final String? error;

  const RuleEngineSinsalResult({
    required this.matchResults,
    required this.context,
    this.error,
  });

  /// 분석 성공 여부
  bool get isSuccess => error == null;

  /// 매칭된 신살 개수
  int get matchCount => matchResults.length;

  /// 12신살 결과만 필터링
  List<RuleMatchResult> get twelveSinsalResults =>
      matchResults.where((r) => r.rule.category == '12신살').toList();

  /// 특수신살 결과만 필터링
  List<RuleMatchResult> get specialSinsalResults =>
      matchResults.where((r) => r.rule.category == '특수신살').toList();

  /// 길한 신살 결과
  List<RuleMatchResult> get goodResults =>
      matchResults.where((r) => r.rule.fortuneType == FortuneType.gil).toList();

  /// 흉한 신살 결과
  List<RuleMatchResult> get badResults =>
      matchResults.where((r) => r.rule.fortuneType == FortuneType.hyung).toList();

  /// 신살 요약 문자열
  String get summary {
    if (matchResults.isEmpty) return '신살 없음';
    return matchResults.map((r) => r.displayName).join(', ');
  }
}

/// 길흉별 신살 분류 결과
class SinsalByFortuneType {
  /// 길한 신살
  final List<RuleMatchResult> good;

  /// 흉한 신살
  final List<RuleMatchResult> bad;

  /// 중립(혼합) 신살
  final List<RuleMatchResult> neutral;

  const SinsalByFortuneType({
    required this.good,
    required this.bad,
    required this.neutral,
  });

  /// 전체 신살 개수
  int get totalCount => good.length + bad.length + neutral.length;

  /// 길한 신살 비율 (0.0 ~ 1.0)
  double get goodRatio => totalCount > 0 ? good.length / totalCount : 0.0;

  /// 길흉 균형 점수 (-1.0 ~ 1.0, 양수가 길)
  double get balanceScore {
    if (totalCount == 0) return 0.0;
    return (good.length - bad.length) / totalCount;
  }
}

/// 기존 로직과 RuleEngine 비교 결과 (검증용)
class SinsalComparisonResult {
  /// 기존 로직 결과
  final TwelveSinsalAnalysisResult legacyResult;

  /// RuleEngine 결과
  final RuleEngineSinsalResult ruleEngineResult;

  /// 기존 로직에서 찾은 특수신살
  final List<String> legacySpecialSinsals;

  /// RuleEngine에서 찾은 특수신살
  final List<String> ruleEngineSpecialSinsals;

  const SinsalComparisonResult({
    required this.legacyResult,
    required this.ruleEngineResult,
    required this.legacySpecialSinsals,
    required this.ruleEngineSpecialSinsals,
  });

  /// 특수신살 일치 여부
  bool get specialSinsalsMatch {
    final legacySet = legacySpecialSinsals.toSet();
    final ruleEngineSet = ruleEngineSpecialSinsals.toSet();
    return legacySet.containsAll(ruleEngineSet) &&
           ruleEngineSet.containsAll(legacySet);
  }

  /// 불일치 항목
  List<String> get mismatches {
    final result = <String>[];
    final legacySet = legacySpecialSinsals.toSet();
    final ruleEngineSet = ruleEngineSpecialSinsals.toSet();

    // 기존에만 있는 것
    for (final item in legacySet.difference(ruleEngineSet)) {
      result.add('기존만: $item');
    }
    // RuleEngine에만 있는 것
    for (final item in ruleEngineSet.difference(legacySet)) {
      result.add('RuleEngine만: $item');
    }
    return result;
  }
}
