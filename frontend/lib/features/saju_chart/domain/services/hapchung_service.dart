/// 합충형파해(合沖刑破害) 분석 서비스
/// 사주팔자의 천간/지지 간 관계를 종합 분석
///
/// Phase 10 서비스 전환: RuleEngine 기반 메서드 추가 (하위 호환성 유지)
/// - 기존 하드코딩 로직: analyzeSaju()
/// - RuleEngine 기반: analyzeWithRuleEngine()
library;

import '../../data/constants/hapchung_relations.dart';
import '../../data/repositories/rule_repository_impl.dart';
import '../entities/rule.dart';
import '../entities/compiled_rules.dart';
import '../entities/saju_chart.dart';
import '../entities/saju_context.dart';
import 'rule_engine.dart';

// ============================================================================
// 분석 결과 모델
// ============================================================================

/// 천간 관계 분석 결과
class CheonganRelationResult {
  final String gan1;
  final String gan2;
  final String pillar1; // 년/월/일/시
  final String pillar2;
  final CheonganRelationType type;
  final String description;

  const CheonganRelationResult({
    required this.gan1,
    required this.gan2,
    required this.pillar1,
    required this.pillar2,
    required this.type,
    required this.description,
  });

  @override
  String toString() => '$pillar1($gan1) - $pillar2($gan2): ${type.korean}';
}

/// 지지 관계 분석 결과
class JijiRelationResult {
  final String ji1;
  final String ji2;
  final String pillar1; // 년/월/일/시
  final String pillar2;
  final JijiRelationType type;
  final String description;

  const JijiRelationResult({
    required this.ji1,
    required this.ji2,
    required this.pillar1,
    required this.pillar2,
    required this.type,
    required this.description,
  });

  @override
  String toString() => '$pillar1($ji1) - $pillar2($ji2): ${type.korean}';
}

/// 반합 타입
enum SamhapHalfType {
  full('완전삼합', '完全三合'), // 3개 모두 있음
  halfWithWangji('반합(왕지)', '半合(旺支)'), // 왕지 포함 2개
  halfLoose('반합', '半合'); // 왕지 없이 2개 (포스텔러 기준)

  final String korean;
  final String hanja;

  const SamhapHalfType(this.korean, this.hanja);
}

/// 삼합 분석 결과
class SamhapResult {
  final List<String> jijis;
  final List<String> pillars;
  final String resultOheng;
  final String description;
  final bool isFullSamhap; // 완전 삼합 여부 (하위 호환)
  final SamhapHalfType halfType; // 반합 타입 (Phase 41 추가)

  const SamhapResult({
    required this.jijis,
    required this.pillars,
    required this.resultOheng,
    required this.description,
    required this.isFullSamhap,
    this.halfType = SamhapHalfType.full,
  });

  /// 표시용 라벨 (삼합/반합(왕지)/반합)
  String get displayLabel => halfType.korean;
}

/// 방합 분석 결과
class BanghapResult {
  final List<String> jijis;
  final List<String> pillars;
  final String resultOheng;
  final String season;
  final String direction;
  final String description;
  final bool isFullBanghap; // 완전 방합 여부 (Phase 41 추가)

  const BanghapResult({
    required this.jijis,
    required this.pillars,
    required this.resultOheng,
    required this.season,
    required this.direction,
    required this.description,
    this.isFullBanghap = true,
  });

  /// 표시용 라벨 (방합/반방합)
  String get displayLabel => isFullBanghap ? '방합' : '반방합';
}

/// 종합 분석 결과
class HapchungAnalysisResult {
  // 천간 관계
  final List<CheonganRelationResult> cheonganHaps;
  final List<CheonganRelationResult> cheonganChungs;

  // 지지 관계
  final List<JijiRelationResult> jijiYukhaps;
  final List<SamhapResult> jijiSamhaps;
  final List<BanghapResult> jijiBanghaps;
  final List<JijiRelationResult> jijiChungs;
  final List<JijiRelationResult> jijiHyungs;
  final List<JijiRelationResult> jijiPas;
  final List<JijiRelationResult> jijiHaes;
  final List<JijiRelationResult> wonjins;

  const HapchungAnalysisResult({
    this.cheonganHaps = const [],
    this.cheonganChungs = const [],
    this.jijiYukhaps = const [],
    this.jijiSamhaps = const [],
    this.jijiBanghaps = const [],
    this.jijiChungs = const [],
    this.jijiHyungs = const [],
    this.jijiPas = const [],
    this.jijiHaes = const [],
    this.wonjins = const [],
  });

  /// 합의 총 개수
  int get totalHaps =>
      cheonganHaps.length +
      jijiYukhaps.length +
      jijiSamhaps.length +
      jijiBanghaps.length;

  /// 충의 총 개수
  int get totalChungs => cheonganChungs.length + jijiChungs.length;

  /// 흉살의 총 개수 (형, 파, 해, 원진)
  int get totalNegatives =>
      jijiHyungs.length + jijiPas.length + jijiHaes.length + wonjins.length;

  /// 관계가 있는지 여부
  bool get hasRelations =>
      totalHaps > 0 || totalChungs > 0 || totalNegatives > 0;
}

// ============================================================================
// 합충형파해 분석 서비스
// ============================================================================

class HapchungService {
  /// 사주 전체 합충형파해 분석
  /// [yearGan] 년간, [monthGan] 월간, [dayGan] 일간, [hourGan] 시간
  /// [yearJi] 년지, [monthJi] 월지, [dayJi] 일지, [hourJi] 시지
  static HapchungAnalysisResult analyzeSaju({
    required String yearGan,
    required String monthGan,
    required String dayGan,
    required String hourGan,
    required String yearJi,
    required String monthJi,
    required String dayJi,
    required String hourJi,
  }) {
    final gans = [
      (yearGan, '년'),
      (monthGan, '월'),
      (dayGan, '일'),
      (hourGan, '시'),
    ];

    final jis = [
      (yearJi, '년'),
      (monthJi, '월'),
      (dayJi, '일'),
      (hourJi, '시'),
    ];

    // 천간 분석
    final cheonganHaps = <CheonganRelationResult>[];
    final cheonganChungs = <CheonganRelationResult>[];

    for (var i = 0; i < gans.length; i++) {
      for (var j = i + 1; j < gans.length; j++) {
        final gan1 = gans[i].$1;
        final gan2 = gans[j].$1;
        final pillar1 = gans[i].$2;
        final pillar2 = gans[j].$2;

        // 천간합 확인
        if (isCheonganHap(gan1, gan2)) {
          final hapInfo = getCheonganHapInfo(gan1, gan2);
          cheonganHaps.add(CheonganRelationResult(
            gan1: gan1,
            gan2: gan2,
            pillar1: pillar1,
            pillar2: pillar2,
            type: CheonganRelationType.hap,
            description: hapInfo?.description ?? '$gan1$gan2 합',
          ));
        }

        // 천간충 확인
        if (isCheonganChung(gan1, gan2)) {
          cheonganChungs.add(CheonganRelationResult(
            gan1: gan1,
            gan2: gan2,
            pillar1: pillar1,
            pillar2: pillar2,
            type: CheonganRelationType.chung,
            description: '$gan1$gan2충',
          ));
        }
      }
    }

    // 지지 분석
    final jijiYukhaps = <JijiRelationResult>[];
    final jijiChungs = <JijiRelationResult>[];
    final jijiHyungs = <JijiRelationResult>[];
    final jijiPas = <JijiRelationResult>[];
    final jijiHaes = <JijiRelationResult>[];
    final wonjins = <JijiRelationResult>[];

    for (var i = 0; i < jis.length; i++) {
      for (var j = i + 1; j < jis.length; j++) {
        final ji1 = jis[i].$1;
        final ji2 = jis[j].$1;
        final pillar1 = jis[i].$2;
        final pillar2 = jis[j].$2;

        // 육합 확인
        if (isJijiYukhap(ji1, ji2)) {
          final yukhapInfo = getJijiYukhapInfo(ji1, ji2);
          jijiYukhaps.add(JijiRelationResult(
            ji1: ji1,
            ji2: ji2,
            pillar1: pillar1,
            pillar2: pillar2,
            type: JijiRelationType.yukhap,
            description: yukhapInfo?.description ?? '$ji1$ji2 육합',
          ));
        }

        // 충 확인
        if (isJijiChung(ji1, ji2)) {
          jijiChungs.add(JijiRelationResult(
            ji1: ji1,
            ji2: ji2,
            pillar1: pillar1,
            pillar2: pillar2,
            type: JijiRelationType.chung,
            description: '$ji1$ji2충',
          ));
        }

        // 형 확인
        final hyungInfo = findJijiHyung(ji1, ji2);
        if (hyungInfo != null) {
          jijiHyungs.add(JijiRelationResult(
            ji1: ji1,
            ji2: ji2,
            pillar1: pillar1,
            pillar2: pillar2,
            type: JijiRelationType.hyung,
            description: hyungInfo.description,
          ));
        }

        // 파 확인
        if (isJijiPa(ji1, ji2)) {
          jijiPas.add(JijiRelationResult(
            ji1: ji1,
            ji2: ji2,
            pillar1: pillar1,
            pillar2: pillar2,
            type: JijiRelationType.pa,
            description: '$ji1$ji2파',
          ));
        }

        // 해 확인
        if (isJijiHae(ji1, ji2)) {
          jijiHaes.add(JijiRelationResult(
            ji1: ji1,
            ji2: ji2,
            pillar1: pillar1,
            pillar2: pillar2,
            type: JijiRelationType.hae,
            description: '$ji1$ji2해',
          ));
        }

        // 원진 확인
        if (isWonjin(ji1, ji2)) {
          wonjins.add(JijiRelationResult(
            ji1: ji1,
            ji2: ji2,
            pillar1: pillar1,
            pillar2: pillar2,
            type: JijiRelationType.wonjin,
            description: '$ji1$ji2원진',
          ));
        }
      }
    }

    // 삼합 분석 (3개 이상의 지지)
    final jijiSamhaps = _analyzeSamhap(jis);

    // 방합 분석 (3개 이상의 지지)
    final jijiBanghaps = _analyzeBanghap(jis);

    return HapchungAnalysisResult(
      cheonganHaps: cheonganHaps,
      cheonganChungs: cheonganChungs,
      jijiYukhaps: jijiYukhaps,
      jijiSamhaps: jijiSamhaps,
      jijiBanghaps: jijiBanghaps,
      jijiChungs: jijiChungs,
      jijiHyungs: jijiHyungs,
      jijiPas: jijiPas,
      jijiHaes: jijiHaes,
      wonjins: wonjins,
    );
  }

  /// 삼합 분석 (포스텔러 기준 - 느슨한 반합 포함)
  static List<SamhapResult> _analyzeSamhap(List<(String, String)> jis) {
    final results = <SamhapResult>[];
    final jijiSet = jis.map((e) => e.$1).toSet();

    // 완전 삼합 확인
    for (final samhap in jijiSamhapList) {
      if (samhap.matches(jijiSet)) {
        final matchingPillars = jis
            .where((j) =>
                j.$1 == samhap.ji1 || j.$1 == samhap.ji2 || j.$1 == samhap.ji3)
            .map((j) => j.$2)
            .toList();

        results.add(SamhapResult(
          jijis: [samhap.ji1, samhap.ji2, samhap.ji3],
          pillars: matchingPillars,
          resultOheng: samhap.resultOheng,
          description: samhap.description,
          isFullSamhap: true,
          halfType: SamhapHalfType.full,
        ));
      }
    }

    // 반합 확인 - 포스텔러 기준 (느슨한 해석: 왕지 없어도 2개면 인정)
    // 완전 삼합이 있어도 다른 조합의 반합은 추가로 표시
    final foundFullSamhapOhengs = results.map((r) => r.resultOheng).toSet();

    for (var i = 0; i < jis.length; i++) {
      for (var j = i + 1; j < jis.length; j++) {
        // 포스텔러 기준: 왕지 없어도 2개면 반합
        final (halfSamhap, halfType) =
            findJijiHalfSamhapWithType(jis[i].$1, jis[j].$1);

        if (halfSamhap != null && halfType != null) {
          // 이미 완전 삼합이 있는 오행은 반합 생략
          if (foundFullSamhapOhengs.contains(halfSamhap.resultOheng)) continue;

          // 같은 지지 조합의 반합이 이미 있는지 확인 (중복 방지)
          final pairKey = {jis[i].$1, jis[j].$1};
          final alreadyExists = results.any((r) =>
              !r.isFullSamhap && r.jijis.toSet().containsAll(pairKey));
          if (alreadyExists) continue;

          final samhapHalfType = halfType == 'half_with_wangji'
              ? SamhapHalfType.halfWithWangji
              : SamhapHalfType.halfLoose;

          results.add(SamhapResult(
            jijis: [jis[i].$1, jis[j].$1],
            pillars: [jis[i].$2, jis[j].$2],
            resultOheng: halfSamhap.resultOheng,
            description:
                '${jis[i].$1}${jis[j].$1} 반합(${halfSamhap.resultOheng}국)',
            isFullSamhap: false,
            halfType: samhapHalfType,
          ));
        }
      }
    }

    return results;
  }

  /// 방합 분석 (포스텔러 기준 - 반방합 포함)
  static List<BanghapResult> _analyzeBanghap(List<(String, String)> jis) {
    final results = <BanghapResult>[];
    final jijiSet = jis.map((e) => e.$1).toSet();

    // 완전 방합 확인
    for (final banghap in jijiBanghapList) {
      if (banghap.matches(jijiSet)) {
        final matchingPillars = jis
            .where((j) =>
                j.$1 == banghap.ji1 ||
                j.$1 == banghap.ji2 ||
                j.$1 == banghap.ji3)
            .map((j) => j.$2)
            .toList();

        results.add(BanghapResult(
          jijis: [banghap.ji1, banghap.ji2, banghap.ji3],
          pillars: matchingPillars,
          resultOheng: banghap.resultOheng,
          season: banghap.season,
          direction: banghap.direction,
          description: banghap.description,
          isFullBanghap: true,
        ));
      }
    }

    // 반방합 확인 - 포스텔러 기준 (2개면 반방합)
    final foundFullBanghapOhengs = results.map((r) => r.resultOheng).toSet();

    for (var i = 0; i < jis.length; i++) {
      for (var j = i + 1; j < jis.length; j++) {
        final halfBanghap = findJijiHalfBanghap(jis[i].$1, jis[j].$1);

        if (halfBanghap != null) {
          // 이미 완전 방합이 있는 오행은 반방합 생략
          if (foundFullBanghapOhengs.contains(halfBanghap.resultOheng)) continue;

          // 같은 지지 조합의 반방합이 이미 있는지 확인 (중복 방지)
          final pairKey = {jis[i].$1, jis[j].$1};
          final alreadyExists = results.any((r) =>
              !r.isFullBanghap && r.jijis.toSet().containsAll(pairKey));
          if (alreadyExists) continue;

          results.add(BanghapResult(
            jijis: [jis[i].$1, jis[j].$1],
            pillars: [jis[i].$2, jis[j].$2],
            resultOheng: halfBanghap.resultOheng,
            season: halfBanghap.season,
            direction: halfBanghap.direction,
            description:
                '${jis[i].$1}${jis[j].$1} 반방합(${halfBanghap.direction}방 ${halfBanghap.resultOheng})',
            isFullBanghap: false,
          ));
        }
      }
    }

    return results;
  }

  /// 두 지지 간의 모든 관계 조회
  static List<JijiRelationType> getJijiRelations(String ji1, String ji2) {
    return analyzeJijiRelations(ji1, ji2);
  }

  /// 두 천간 간의 모든 관계 조회
  static List<CheonganRelationType> getCheonganRelations(
      String gan1, String gan2) {
    return analyzeCheonganRelations(gan1, gan2);
  }

  // ============================================================================
  // RuleEngine 기반 메서드 (Phase 10 추가)
  // ============================================================================

  /// RuleRepository 인스턴스 (싱글톤)
  static final ruleRepository = RuleRepositoryImpl();

  /// JSON 룰셋을 사용하여 합충형파해를 분석합니다.
  /// 기존 하드코딩 로직과 병행 사용 가능합니다.
  ///
  /// [chart] 분석할 사주 차트
  /// [gender] 성별 (선택)
  /// 반환: RuleEngine 매칭 결과 리스트
  static Future<RuleEngineHapchungResult> analyzeWithRuleEngine(
    SajuChart chart, {
    String? gender,
  }) async {
    // 1. 컨텍스트 생성
    final context = SajuContext.fromChart(chart, gender: gender);

    // 2. 합충 룰셋 로드
    CompiledRules? compiledRules;
    try {
      compiledRules = await ruleRepository.loadByType(RuleType.hapchung);
    } catch (e) {
      // 룰셋 로드 실패 시 빈 결과 반환
      return RuleEngineHapchungResult(
        matchResults: [],
        context: context,
        error: '합충 룰셋 로드 실패: $e',
      );
    }

    // 3. RuleEngine으로 매칭
    final engine = RuleEngine();
    final matchResults = engine.matchAll(compiledRules, context);

    return RuleEngineHapchungResult(
      matchResults: matchResults,
      context: context,
    );
  }

  /// RuleEngine 기반 특정 관계 검색
  ///
  /// [chart] 분석할 사주 차트
  /// [relationId] 찾을 관계 ID (예: "cheongan_hap_gapgi", "jiji_chung_jao")
  /// 반환: 매칭된 결과 또는 null
  static Future<RuleMatchResult?> findRelationById(
    SajuChart chart,
    String relationId, {
    String? gender,
  }) async {
    final result = await analyzeWithRuleEngine(chart, gender: gender);

    for (final match in result.matchResults) {
      if (match.rule.id == relationId) {
        return match;
      }
    }
    return null;
  }

  /// RuleEngine 기반 길/흉 관계 분류
  ///
  /// [chart] 분석할 사주 차트
  /// 반환: 길흉별로 분류된 관계 결과
  static Future<HapchungByFortuneType> analyzeByFortune(
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

    return HapchungByFortuneType(
      good: good,
      bad: bad,
      neutral: neutral,
    );
  }

  /// 기존 로직과 RuleEngine 결과 비교 (테스트/검증용)
  ///
  /// 두 분석 방식의 결과를 비교하여 일관성을 검증합니다.
  static Future<HapchungComparisonResult> compareWithLegacy(
    SajuChart chart, {
    String? gender,
  }) async {
    // 기존 로직 분석 (시주가 없으면 빈 문자열 사용)
    final legacyResult = analyzeSaju(
      yearGan: chart.yearPillar.gan,
      monthGan: chart.monthPillar.gan,
      dayGan: chart.dayPillar.gan,
      hourGan: chart.hourPillar?.gan ?? '',
      yearJi: chart.yearPillar.ji,
      monthJi: chart.monthPillar.ji,
      dayJi: chart.dayPillar.ji,
      hourJi: chart.hourPillar?.ji ?? '',
    );

    // RuleEngine 분석
    final ruleEngineResult = await analyzeWithRuleEngine(chart, gender: gender);

    // 기존 로직의 관계 이름 추출
    final legacyRelations = <String>[];

    // 천간합
    for (final hap in legacyResult.cheonganHaps) {
      legacyRelations.add('${hap.gan1}${hap.gan2}합');
    }
    // 천간충
    for (final chung in legacyResult.cheonganChungs) {
      legacyRelations.add('${chung.gan1}${chung.gan2}충');
    }
    // 지지육합
    for (final yukhap in legacyResult.jijiYukhaps) {
      legacyRelations.add('${yukhap.ji1}${yukhap.ji2}육합');
    }
    // 삼합
    for (final samhap in legacyResult.jijiSamhaps) {
      final label = samhap.isFullSamhap ? '삼합' : '반합';
      legacyRelations.add('${samhap.jijis.join("")}$label');
    }
    // 방합
    for (final banghap in legacyResult.jijiBanghaps) {
      legacyRelations.add('${banghap.jijis.join("")}방합');
    }
    // 지지충
    for (final chung in legacyResult.jijiChungs) {
      legacyRelations.add('${chung.ji1}${chung.ji2}충');
    }
    // 형
    for (final hyung in legacyResult.jijiHyungs) {
      legacyRelations.add('${hyung.ji1}${hyung.ji2}형');
    }
    // 파
    for (final pa in legacyResult.jijiPas) {
      legacyRelations.add('${pa.ji1}${pa.ji2}파');
    }
    // 해
    for (final hae in legacyResult.jijiHaes) {
      legacyRelations.add('${hae.ji1}${hae.ji2}해');
    }
    // 원진
    for (final wonjin in legacyResult.wonjins) {
      legacyRelations.add('${wonjin.ji1}${wonjin.ji2}원진');
    }

    // RuleEngine의 관계 이름 추출
    final ruleEngineRelations = <String>[];
    for (final match in ruleEngineResult.matchResults) {
      ruleEngineRelations.add(match.rule.name);
    }

    return HapchungComparisonResult(
      legacyResult: legacyResult,
      ruleEngineResult: ruleEngineResult,
      legacyRelations: legacyRelations,
      ruleEngineRelations: ruleEngineRelations,
    );
  }
}

/// 길흉별 합충형파해 분류 결과
class HapchungByFortuneType {
  /// 길한 관계 (합)
  final List<RuleMatchResult> good;

  /// 흉한 관계 (충, 형, 파, 해, 원진)
  final List<RuleMatchResult> bad;

  /// 중립 관계
  final List<RuleMatchResult> neutral;

  const HapchungByFortuneType({
    required this.good,
    required this.bad,
    required this.neutral,
  });

  /// 전체 관계 개수
  int get total => good.length + bad.length + neutral.length;

  /// 길한 관계 비율
  double get goodRatio => total == 0 ? 0 : good.length / total;

  /// 흉한 관계 비율
  double get badRatio => total == 0 ? 0 : bad.length / total;
}

// ============================================================================
// 해석 유틸리티
// ============================================================================

/// 합충형파해 해석 도우미
class HapchungInterpreter {
  /// 천간합 해석
  static String interpretCheonganHap(CheonganRelationResult result) {
    final hapInfo = getCheonganHapInfo(result.gan1, result.gan2);
    if (hapInfo == null) return '';

    return '${result.pillar1}주와 ${result.pillar2}주의 천간이 합하여 '
        '${hapInfo.result.korean}으로 변화할 수 있습니다.';
  }

  /// 천간충 해석
  static String interpretCheonganChung(CheonganRelationResult result) {
    return '${result.pillar1}주와 ${result.pillar2}주의 천간이 충돌하여 '
        '해당 궁의 기운이 불안정해질 수 있습니다.';
  }

  /// 지지육합 해석
  static String interpretJijiYukhap(JijiRelationResult result) {
    final yukhapInfo = getJijiYukhapInfo(result.ji1, result.ji2);
    if (yukhapInfo == null) return '';

    return '${result.pillar1}주와 ${result.pillar2}주가 육합하여 '
        '${yukhapInfo.resultOheng}의 기운이 강화됩니다.';
  }

  /// 지지충 해석
  static String interpretJijiChung(JijiRelationResult result) {
    final meanings = {
      '자오': '물과 불의 대립, 감정적 갈등',
      '축미': '토의 충돌, 재물/부동산 문제',
      '인신': '목과 금의 대립, 직장/이동 변화',
      '묘유': '목과 금의 대립, 인간관계 갈등',
      '진술': '토의 충돌, 문서/소송 주의',
      '사해': '화와 수의 대립, 건강/사고 주의',
    };

    final key1 = '${result.ji1}${result.ji2}';
    final key2 = '${result.ji2}${result.ji1}';
    final meaning = meanings[key1] ?? meanings[key2] ?? '기운의 충돌';

    return '${result.pillar1}주와 ${result.pillar2}주의 충: $meaning';
  }

  /// 삼합 해석
  static String interpretSamhap(SamhapResult result) {
    if (result.isFullSamhap) {
      return '${result.pillars.join(", ")}주가 삼합하여 '
          '${result.resultOheng}의 기운이 크게 강화됩니다.';
    } else {
      return '${result.pillars.join(", ")}주가 반합하여 '
          '${result.resultOheng}의 기운이 부분적으로 강화됩니다.';
    }
  }

  /// 방합 해석
  static String interpretBanghap(BanghapResult result) {
    return '${result.pillars.join(", ")}주가 방합하여 '
        '${result.season}(${result.direction}방) ${result.resultOheng}의 기운이 매우 강합니다.';
  }
}

// ============================================================================
// RuleEngine 기반 결과 모델
// ============================================================================

/// RuleEngine 기반 합충형파해 분석 결과
class RuleEngineHapchungResult {
  /// 매칭된 룰 결과 리스트
  final List<RuleMatchResult> matchResults;

  /// 분석에 사용된 컨텍스트
  final SajuContext context;

  /// 에러 메시지 (있으면)
  final String? error;

  const RuleEngineHapchungResult({
    required this.matchResults,
    required this.context,
    this.error,
  });

  /// 분석 성공 여부
  bool get isSuccess => error == null;

  /// 매칭된 관계 개수
  int get matchCount => matchResults.length;

  // ============================================================================
  // 카테고리별 필터링 헬퍼
  // ============================================================================

  /// 천간합 결과만 필터링
  List<RuleMatchResult> get cheonganHapResults =>
      matchResults.where((r) => r.rule.category == '천간합').toList();

  /// 천간충 결과만 필터링
  List<RuleMatchResult> get cheonganChungResults =>
      matchResults.where((r) => r.rule.category == '천간충').toList();

  /// 지지육합 결과만 필터링
  List<RuleMatchResult> get jijiYukhapResults =>
      matchResults.where((r) => r.rule.category == '지지육합').toList();

  /// 삼합 결과만 필터링
  List<RuleMatchResult> get samhapResults =>
      matchResults.where((r) => r.rule.category == '삼합').toList();

  /// 방합 결과만 필터링
  List<RuleMatchResult> get banghapResults =>
      matchResults.where((r) => r.rule.category == '방합').toList();

  /// 지지충 결과만 필터링
  List<RuleMatchResult> get jijiChungResults =>
      matchResults.where((r) => r.rule.category == '충').toList();

  /// 형 결과만 필터링
  List<RuleMatchResult> get hyungResults =>
      matchResults.where((r) => r.rule.category == '형').toList();

  /// 파 결과만 필터링
  List<RuleMatchResult> get paResults =>
      matchResults.where((r) => r.rule.category == '파').toList();

  /// 해 결과만 필터링
  List<RuleMatchResult> get haeResults =>
      matchResults.where((r) => r.rule.category == '해').toList();

  /// 원진 결과만 필터링
  List<RuleMatchResult> get wonjinResults =>
      matchResults.where((r) => r.rule.category == '원진').toList();

  // ============================================================================
  // 길흉별 분류
  // ============================================================================

  /// 길한 관계 결과 (합)
  List<RuleMatchResult> get goodResults =>
      matchResults.where((r) => r.rule.fortuneType == FortuneType.gil).toList();

  /// 흉한 관계 결과 (충, 형, 파, 해, 원진)
  List<RuleMatchResult> get badResults =>
      matchResults.where((r) => r.rule.fortuneType == FortuneType.hyung).toList();

  /// 중립 관계 결과
  List<RuleMatchResult> get neutralResults =>
      matchResults.where((r) => r.rule.fortuneType == FortuneType.jung).toList();

  // ============================================================================
  // 집계
  // ============================================================================

  /// 합의 총 개수
  int get totalHaps =>
      cheonganHapResults.length +
      jijiYukhapResults.length +
      samhapResults.length +
      banghapResults.length;

  /// 충의 총 개수
  int get totalChungs => cheonganChungResults.length + jijiChungResults.length;

  /// 흉살의 총 개수 (형, 파, 해, 원진)
  int get totalNegatives =>
      hyungResults.length +
      paResults.length +
      haeResults.length +
      wonjinResults.length;

  /// 관계 요약 문자열
  String get summary {
    if (matchResults.isEmpty) return '합충형파해 관계 없음';
    return matchResults.map((r) => r.displayName).join(', ');
  }
}

/// 합충형파해 비교 결과 (하드코딩 vs RuleEngine)
class HapchungComparisonResult {
  /// 기존 하드코딩 분석 결과
  final HapchungAnalysisResult legacyResult;

  /// RuleEngine 기반 분석 결과
  final RuleEngineHapchungResult ruleEngineResult;

  /// 기존 로직의 관계 목록 (이름)
  final List<String> legacyRelations;

  /// RuleEngine의 관계 목록 (이름)
  final List<String> ruleEngineRelations;

  const HapchungComparisonResult({
    required this.legacyResult,
    required this.ruleEngineResult,
    required this.legacyRelations,
    required this.ruleEngineRelations,
  });

  /// 이름 정규화 (공백 제거, 용어 통일, 순서 정렬)
  static String _normalizeName(String name) {
    var normalized = name
        .replaceAll(' ', '') // 공백 제거
        .replaceAll('육합', '합') // 육합 → 합
        .replaceAll('반합', '합'); // 반합 → 합 (비교용)

    // 천간/지지 순서 정렬 (ㄱㄴㄷ순)
    final patterns = [
      ['임병', '병임'],
      ['임신', '신임'],
      ['계정', '정계'],
      ['경갑', '갑경'],
      ['신을', '을신'],
      ['해진', '진해'],
      ['해신', '신해'],
      ['인신', '신인'],
      ['미축', '축미'],
      ['오자', '자오'],
    ];
    for (final pair in patterns) {
      if (normalized.contains(pair[0])) {
        normalized = normalized.replaceFirst(pair[0], pair[1]);
      }
    }

    return normalized;
  }

  /// 정규화된 이름 비교로 일치하는 관계 (개선된 비교)
  List<String> get normalizedMatchedRelations {
    final legacyNormalized = legacyRelations.map(_normalizeName).toSet();
    final matched = <String>[];
    for (final r in ruleEngineRelations) {
      if (legacyNormalized.contains(_normalizeName(r))) {
        matched.add(r);
      }
    }
    return matched;
  }

  /// 일치하는 관계 (원본 이름 비교)
  List<String> get matchedRelations {
    final legacySet = legacyRelations.toSet();
    return ruleEngineRelations.where((r) => legacySet.contains(r)).toList();
  }

  /// 기존 로직에만 있는 관계
  List<String> get onlyInLegacy {
    final ruleEngineSet = ruleEngineRelations.toSet();
    return legacyRelations.where((r) => !ruleEngineSet.contains(r)).toList();
  }

  /// RuleEngine에만 있는 관계
  List<String> get onlyInRuleEngine {
    final legacySet = legacyRelations.toSet();
    return ruleEngineRelations.where((r) => !legacySet.contains(r)).toList();
  }

  /// 기존 로직에만 있는 관계 (정규화 비교)
  List<String> get normalizedOnlyInLegacy {
    final ruleEngineNormalized = ruleEngineRelations.map(_normalizeName).toSet();
    return legacyRelations
        .where((r) => !ruleEngineNormalized.contains(_normalizeName(r)))
        .toList();
  }

  /// RuleEngine에만 있는 관계 (정규화 비교)
  List<String> get normalizedOnlyInRuleEngine {
    final legacyNormalized = legacyRelations.map(_normalizeName).toSet();
    return ruleEngineRelations
        .where((r) => !legacyNormalized.contains(_normalizeName(r)))
        .toList();
  }

  /// 완전 일치 여부
  bool get isFullyMatched =>
      onlyInLegacy.isEmpty && onlyInRuleEngine.isEmpty;

  /// 정규화 비교로 완전 일치 여부
  bool get isNormalizedFullyMatched =>
      normalizedOnlyInLegacy.isEmpty && normalizedOnlyInRuleEngine.isEmpty;

  /// 일치율 (0.0 ~ 1.0) - 원본 이름 비교
  double get matchRate {
    final total = legacyRelations.length + ruleEngineRelations.length;
    if (total == 0) return 1.0;
    return (matchedRelations.length * 2) / total;
  }

  /// 정규화된 일치율 (0.0 ~ 1.0) - 이름 형식 차이 허용
  double get normalizedMatchRate {
    final total = legacyRelations.length + ruleEngineRelations.length;
    if (total == 0) return 1.0;
    return (normalizedMatchedRelations.length * 2) / total;
  }
}
