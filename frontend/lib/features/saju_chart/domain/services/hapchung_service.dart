/// 합충형파해(合沖刑破害) 분석 서비스
/// 사주팔자의 천간/지지 간 관계를 종합 분석
library;

import '../../data/constants/hapchung_relations.dart';

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

/// 삼합 분석 결과
class SamhapResult {
  final List<String> jijis;
  final List<String> pillars;
  final String resultOheng;
  final String description;
  final bool isFullSamhap; // 완전 삼합 여부

  const SamhapResult({
    required this.jijis,
    required this.pillars,
    required this.resultOheng,
    required this.description,
    required this.isFullSamhap,
  });
}

/// 방합 분석 결과
class BanghapResult {
  final List<String> jijis;
  final List<String> pillars;
  final String resultOheng;
  final String season;
  final String direction;
  final String description;

  const BanghapResult({
    required this.jijis,
    required this.pillars,
    required this.resultOheng,
    required this.season,
    required this.direction,
    required this.description,
  });
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

  /// 삼합 분석
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
        ));
      }
    }

    // 반합 확인 (완전 삼합이 없을 때만)
    if (results.isEmpty) {
      for (var i = 0; i < jis.length; i++) {
        for (var j = i + 1; j < jis.length; j++) {
          final halfSamhap = findJijiHalfSamhap(jis[i].$1, jis[j].$1);
          if (halfSamhap != null) {
            results.add(SamhapResult(
              jijis: [jis[i].$1, jis[j].$1],
              pillars: [jis[i].$2, jis[j].$2],
              resultOheng: halfSamhap.resultOheng,
              description: '${jis[i].$1}${jis[j].$1} 반합(${halfSamhap.resultOheng}국)',
              isFullSamhap: false,
            ));
          }
        }
      }
    }

    return results;
  }

  /// 방합 분석
  static List<BanghapResult> _analyzeBanghap(List<(String, String)> jis) {
    final results = <BanghapResult>[];
    final jijiSet = jis.map((e) => e.$1).toSet();

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
        ));
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
