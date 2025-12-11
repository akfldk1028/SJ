/// 공망(空亡) 계산 서비스
/// 일주를 기준으로 공망 지지를 찾고 사주 내 공망 여부 분석
library;

import '../../data/constants/gongmang_table.dart';
import '../entities/saju_chart.dart';

// ============================================================================
// 공망 분석 결과 모델
// ============================================================================

/// 단일 궁성의 공망 결과
class GongmangResult {
  /// 궁성 이름 (년지/월지/시지)
  final String pillarName;

  /// 해당 지지
  final String jiji;

  /// 공망 여부
  final bool isGongmang;

  /// 공망 유형 (진공/반공/탈공)
  final GongmangType? type;

  /// 해석
  final String interpretation;

  const GongmangResult({
    required this.pillarName,
    required this.jiji,
    required this.isGongmang,
    this.type,
    required this.interpretation,
  });

  @override
  String toString() => '$pillarName($jiji): ${isGongmang ? "공망" : "정상"}';
}

/// 사주 전체 공망 분석 결과
class GongmangAnalysisResult {
  /// 일주 기준 공망 지지 2개
  final List<String> gongmangJijis;

  /// 공망이 속한 순(旬)
  final Gongmang sunInfo;

  /// 년지 공망 결과
  final GongmangResult yearResult;

  /// 월지 공망 결과
  final GongmangResult monthResult;

  /// 시지 공망 결과 (시간 모를 경우 null)
  final GongmangResult? hourResult;

  /// 일간+일지
  final String dayGapja;

  const GongmangAnalysisResult({
    required this.gongmangJijis,
    required this.sunInfo,
    required this.yearResult,
    required this.monthResult,
    this.hourResult,
    required this.dayGapja,
  });

  /// 모든 결과 리스트
  List<GongmangResult> get allResults => [
        yearResult,
        monthResult,
        if (hourResult != null) hourResult!,
      ];

  /// 공망인 궁성 개수
  int get gongmangCount => allResults.where((r) => r.isGongmang).length;

  /// 공망이 있는지 여부
  bool get hasGongmang => gongmangCount > 0;

  /// 공망 궁성 이름들
  List<String> get gongmangPillars =>
      allResults.where((r) => r.isGongmang).map((r) => r.pillarName).toList();

  /// 공망 요약
  String get summary {
    if (!hasGongmang) return '공망 없음 - 모든 궁성이 충실합니다.';

    final pillars = gongmangPillars.join(', ');
    return '$pillars에 공망 - 해당 궁의 기운이 약화됩니다.';
  }
}

// ============================================================================
// 공망 계산 서비스
// ============================================================================

/// 공망 계산 서비스
class GongmangService {
  /// 사주 차트에서 공망 분석
  static GongmangAnalysisResult analyzeFromChart(SajuChart chart) {
    final dayGan = chart.dayPillar.gan;
    final dayJi = chart.dayPillar.ji;

    return analyze(
      dayGan: dayGan,
      dayJi: dayJi,
      yearJi: chart.yearPillar.ji,
      monthJi: chart.monthPillar.ji,
      hourJi: chart.hourPillar?.ji,
    );
  }

  /// 개별 파라미터로 공망 분석
  static GongmangAnalysisResult analyze({
    required String dayGan,
    required String dayJi,
    required String yearJi,
    required String monthJi,
    String? hourJi,
  }) {
    final dayGapja = '$dayGan$dayJi';
    final gongmang = getGongmangByGapja(dayGapja);
    final gongmangJijis = [gongmang.gongmang1, gongmang.gongmang2];

    return GongmangAnalysisResult(
      gongmangJijis: gongmangJijis,
      sunInfo: gongmang,
      yearResult: _analyzeGongmang(
        pillarName: '년지',
        jiji: yearJi,
        gongmangJijis: gongmangJijis,
      ),
      monthResult: _analyzeGongmang(
        pillarName: '월지',
        jiji: monthJi,
        gongmangJijis: gongmangJijis,
      ),
      hourResult: hourJi != null
          ? _analyzeGongmang(
              pillarName: '시지',
              jiji: hourJi,
              gongmangJijis: gongmangJijis,
            )
          : null,
      dayGapja: dayGapja,
    );
  }

  /// 단일 궁성 공망 분석
  static GongmangResult _analyzeGongmang({
    required String pillarName,
    required String jiji,
    required List<String> gongmangJijis,
  }) {
    final isGongmang = gongmangJijis.contains(jiji);

    return GongmangResult(
      pillarName: pillarName,
      jiji: jiji,
      isGongmang: isGongmang,
      type: isGongmang ? GongmangType.jinGong : null,
      interpretation: _getInterpretation(pillarName, isGongmang),
    );
  }

  /// 궁성별 공망 해석
  static String _getInterpretation(String pillarName, bool isGongmang) {
    if (!isGongmang) return '공망 없음';

    return switch (pillarName) {
      '년지' => '조상운과 유년기 운이 약함, 조상의 도움을 받기 어려움',
      '월지' => '부모운과 형제운이 약함, 가업 계승이 어려울 수 있음',
      '시지' => '자녀운과 말년운이 약함, 노후 준비에 신경 써야 함',
      _ => '해당 궁의 기운이 비어있음',
    };
  }

  /// 일주로 공망 지지 조회 (간단 버전)
  static List<String> getGongmangJijis(String dayGan, String dayJi) {
    return getDayGongmang(dayGan, dayJi);
  }

  /// 특정 지지가 공망인지 확인
  static bool isGongmang({
    required String dayGan,
    required String dayJi,
    required String targetJi,
  }) {
    return isGongmangJi(dayGan, dayJi, targetJi);
  }

  /// 공망 유형 판단 (운에 따라)
  static GongmangType getGongmangType({
    required String dayGan,
    required String dayJi,
    required String targetJi,
    String? daeunJi,
    String? saeunJi,
  }) {
    return determineGongmangType(
      dayGan: dayGan,
      dayJi: dayJi,
      targetJi: targetJi,
      currentDaeunJi: daeunJi,
      currentSaeunJi: saeunJi,
    );
  }

  /// 공망 상세 해석
  static String getDetailedInterpretation(GongmangResult result) {
    if (!result.isGongmang) {
      return '${result.pillarName}에는 공망이 없어 해당 궁성의 기운이 온전합니다.';
    }

    final baseMeaning = switch (result.pillarName) {
      '년지' => '''
년지 공망은 조상과 유년기를 담당하는 궁이 비어있음을 의미합니다.
- 조상의 덕이 부족하여 스스로 일어서야 함
- 고향을 떠나 타향에서 발전하는 경우가 많음
- 유년 시절 어려움을 겪을 수 있으나 자수성가의 기운
''',
      '월지' => '''
월지 공망은 부모와 형제를 담당하는 궁이 비어있음을 의미합니다.
- 부모의 도움을 받기 어렵거나 일찍 독립함
- 가업을 계승하기보다 새로운 길을 개척함
- 형제와의 인연이 약하거나 멀리 살게 됨
''',
      '시지' => '''
시지 공망은 자녀와 말년을 담당하는 궁이 비어있음을 의미합니다.
- 자녀와의 인연이 약하거나 늦게 얻음
- 말년에 의지할 곳이 부족할 수 있음
- 노후 준비를 철저히 해야 함
''',
      _ => '해당 궁의 기운이 비어있습니다.',
    };

    return baseMeaning;
  }

  /// 일주의 순(旬) 정보 조회
  static Gongmang getSunInfo(String dayGan, String dayJi) {
    return getGongmang(dayGan, dayJi);
  }

  /// 공망의 길흉 판단
  static String getGongmangFortune(List<GongmangResult> results) {
    final gongmangCount =
        results.where((r) => r.isGongmang).length;

    if (gongmangCount == 0) {
      return '공망 없음: 모든 궁성이 충실하여 안정적입니다.';
    } else if (gongmangCount == 1) {
      final gongmangPillar =
          results.firstWhere((r) => r.isGongmang).pillarName;
      return '단일 공망: $gongmangPillar에 공망이 있어 해당 분야에서 노력이 필요합니다.';
    } else {
      return '다중 공망: 여러 궁에 공망이 있어 자기 힘으로 일어서야 합니다. '
          '다만 공망은 비어있기에 새로운 가능성을 채울 수 있습니다.';
    }
  }
}
