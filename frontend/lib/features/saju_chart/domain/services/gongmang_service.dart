/// 공망(空亡) 계산 서비스
/// 일주를 기준으로 공망 지지를 찾고 사주 내 공망 여부 분석
///
/// Phase 26 업데이트 (2024-12-31):
/// - 진공(眞空): 일간 음양 = 공망지지 음양 → 작용력 100%
/// - 반공(半空): 일간 음양 ≠ 공망지지 음양 → 작용력 50%
/// - 해공(解空): 충/합/형으로 공망 해소
/// - 탈공(脫空): 대운/세운에서 공망 지지 채워짐
library;

import 'package:easy_localization/easy_localization.dart';
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

  /// 공망 유형 (진공/반공/해공/탈공)
  final GongmangType? type;

  /// 공망 유형 상세 결과 (Phase 26)
  final GongmangTypeResult? typeResult;

  /// 해석
  final String interpretation;

  const GongmangResult({
    required this.pillarName,
    required this.jiji,
    required this.isGongmang,
    this.type,
    this.typeResult,
    required this.interpretation,
  });

  /// 공망 작용 강도 (0~100)
  int get effectStrength => type?.effectStrength ?? 0;

  /// 해공 여부
  bool get isResolved => type?.isResolved ?? true;

  @override
  String toString() {
    if (!isGongmang) return '$pillarName($jiji): 정상';
    final typeStr = type?.korean ?? '공망';
    return '$pillarName($jiji): $typeStr ($effectStrength%)';
  }
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
    if (!hasGongmang) return 'saju_detail.gongmang_no_gongmang_summary'.tr();

    final pillars = gongmangPillars.join(', ');
    return 'saju_detail.gongmang_with_pillars_summary'.tr(namedArgs: {'pillars': pillars});
  }

  // ============================================================================
  // Phase 26: 진공/반공/해공 관련 속성
  // ============================================================================

  /// 진공인 궁성들 (공망 작용 100%)
  List<GongmangResult> get jinGongResults =>
      allResults.where((r) => r.type == GongmangType.jinGong).toList();

  /// 반공인 궁성들 (공망 작용 50%)
  List<GongmangResult> get banGongResults =>
      allResults.where((r) => r.type == GongmangType.banGong).toList();

  /// 해공/탈공으로 해소된 궁성들
  List<GongmangResult> get resolvedResults =>
      allResults.where((r) => r.type?.isResolved ?? false).toList();

  /// 실제 작용하는 공망 (해공/탈공 제외)
  List<GongmangResult> get activeGongmangResults =>
      allResults.where((r) => r.isGongmang && !(r.type?.isResolved ?? true)).toList();

  /// 진공 개수
  int get jinGongCount => jinGongResults.length;

  /// 반공 개수
  int get banGongCount => banGongResults.length;

  /// 해소된 공망 개수
  int get resolvedCount => resolvedResults.length;

  /// 실제 작용하는 공망 개수
  int get activeGongmangCount => activeGongmangResults.length;

  /// 전체 공망 작용 강도 평균 (0~100)
  int get averageEffectStrength {
    final gongmangList = allResults.where((r) => r.isGongmang).toList();
    if (gongmangList.isEmpty) return 0;
    final total = gongmangList.fold<int>(0, (sum, r) => sum + r.effectStrength);
    return total ~/ gongmangList.length;
  }

  /// 상세 요약 (Phase 26)
  String get detailedSummary {
    if (!hasGongmang) {
      return 'saju_detail.gongmang_no_gongmang_summary'.tr();
    }

    final parts = <String>[];

    if (jinGongCount > 0) {
      final pillars = jinGongResults.map((r) => r.pillarName).join(', ');
      parts.add('${GongmangType.jinGong.korean}: $pillars');
    }

    if (banGongCount > 0) {
      final pillars = banGongResults.map((r) => r.pillarName).join(', ');
      parts.add('${GongmangType.banGong.korean}: $pillars');
    }

    if (resolvedCount > 0) {
      final pillars = resolvedResults.map((r) => r.pillarName).join(', ');
      final types = resolvedResults.map((r) => r.type?.korean ?? '').toSet().join('/');
      parts.add('$types: $pillars');
    }

    return parts.join(' | ');
  }

  /// 공망 상태 해석 (Phase 26)
  String get gongmangStatusInterpretation {
    if (!hasGongmang) {
      return 'saju_detail.gongmang_none_status'.tr();
    }

    final buffer = StringBuffer();

    // 진공
    if (jinGongCount > 0) {
      buffer.writeln('saju_detail.gongmang_jingong_header'.tr());
      buffer.writeln('saju_detail.gongmang_jingong_desc'.tr());
      for (final r in jinGongResults) {
        buffer.writeln('• ${r.pillarName}(${r.jiji}): ${r.interpretation}');
      }
      buffer.writeln();
    }

    // 반공
    if (banGongCount > 0) {
      buffer.writeln('saju_detail.gongmang_bangong_header'.tr());
      buffer.writeln('saju_detail.gongmang_bangong_desc'.tr());
      for (final r in banGongResults) {
        buffer.writeln('• ${r.pillarName}(${r.jiji}): ${r.interpretation}');
      }
      buffer.writeln();
    }

    // 해공/탈공
    if (resolvedCount > 0) {
      buffer.writeln('saju_detail.gongmang_haegong_header'.tr());
      buffer.writeln('saju_detail.gongmang_haegong_desc'.tr());
      for (final r in resolvedResults) {
        buffer.writeln('• ${r.pillarName}(${r.jiji}): ${r.typeResult?.reason ?? 'saju_detail.gongmang_resolved'.tr()}');
      }
    }

    return buffer.toString().trim();
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
  /// [dayGan] 일간
  /// [dayJi] 일지
  /// [yearJi] 년지
  /// [monthJi] 월지
  /// [hourJi] 시지 (시간 모를 경우 null)
  /// [currentDaeunJi] 현재 대운의 지지 (옵션)
  /// [currentSaeunJi] 현재 세운의 지지 (옵션)
  static GongmangAnalysisResult analyze({
    required String dayGan,
    required String dayJi,
    required String yearJi,
    required String monthJi,
    String? hourJi,
    String? currentDaeunJi,
    String? currentSaeunJi,
  }) {
    final dayGapja = '$dayGan$dayJi';
    final gongmang = getGongmangByGapja(dayGapja);
    final gongmangJijis = [gongmang.gongmang1, gongmang.gongmang2];

    // 모든 지지 리스트 (해공 판단에 사용)
    final allJijis = [
      yearJi,
      monthJi,
      dayJi,
      if (hourJi != null) hourJi,
    ];

    return GongmangAnalysisResult(
      gongmangJijis: gongmangJijis,
      sunInfo: gongmang,
      yearResult: _analyzeGongmangAdvanced(
        pillarName: '년지',
        jiji: yearJi,
        dayGan: dayGan,
        dayJi: dayJi,
        gongmangJijis: gongmangJijis,
        allJijis: allJijis,
        currentDaeunJi: currentDaeunJi,
        currentSaeunJi: currentSaeunJi,
      ),
      monthResult: _analyzeGongmangAdvanced(
        pillarName: '월지',
        jiji: monthJi,
        dayGan: dayGan,
        dayJi: dayJi,
        gongmangJijis: gongmangJijis,
        allJijis: allJijis,
        currentDaeunJi: currentDaeunJi,
        currentSaeunJi: currentSaeunJi,
      ),
      hourResult: hourJi != null
          ? _analyzeGongmangAdvanced(
              pillarName: '시지',
              jiji: hourJi,
              dayGan: dayGan,
              dayJi: dayJi,
              gongmangJijis: gongmangJijis,
              allJijis: allJijis,
              currentDaeunJi: currentDaeunJi,
              currentSaeunJi: currentSaeunJi,
            )
          : null,
      dayGapja: dayGapja,
    );
  }

  /// 단일 궁성 공망 분석 (Phase 26 개선된 버전)
  /// 진공/반공/해공/탈공 유형을 정확히 판단
  static GongmangResult _analyzeGongmangAdvanced({
    required String pillarName,
    required String jiji,
    required String dayGan,
    required String dayJi,
    required List<String> gongmangJijis,
    required List<String> allJijis,
    String? currentDaeunJi,
    String? currentSaeunJi,
  }) {
    final isGongmang = gongmangJijis.contains(jiji);

    if (!isGongmang) {
      return GongmangResult(
        pillarName: pillarName,
        jiji: jiji,
        isGongmang: false,
        type: null,
        typeResult: null,
        interpretation: 'saju_detail.gongmang_none_interp'.tr(),
      );
    }

    // 진공/반공/해공/탈공 상세 판단
    final typeResult = determineGongmangTypeAdvanced(
      dayGan: dayGan,
      dayJi: dayJi,
      targetJi: jiji,
      allJijis: allJijis,
      currentDaeunJi: currentDaeunJi,
      currentSaeunJi: currentSaeunJi,
    );

    return GongmangResult(
      pillarName: pillarName,
      jiji: jiji,
      isGongmang: true,
      type: typeResult.type,
      typeResult: typeResult,
      interpretation: _getInterpretationAdvanced(
        pillarName,
        typeResult,
      ),
    );
  }

  /// 궁성별 + 공망유형별 해석 (Phase 26)
  static String _getInterpretationAdvanced(
    String pillarName,
    GongmangTypeResult typeResult,
  ) {
    final type = typeResult.type;
    final baseInterpretation = _getBaseInterpretation(pillarName);

    // 해공/탈공이면 공망 작용이 해소됨
    if (type.isResolved) {
      return '$baseInterpretation 그러나 ${typeResult.reason}';
    }

    // 진공/반공
    final strengthDesc = type == GongmangType.jinGong
        ? 'saju_detail.gongmang_jingong_strength'.tr()
        : 'saju_detail.gongmang_bangong_strength'.tr();

    return '$baseInterpretation $strengthDesc - ${typeResult.reason}';
  }

  /// 궁성별 기본 해석
  static String _getBaseInterpretation(String pillarName) {
    return switch (pillarName) {
      '년지' => 'saju_detail.gongmang_base_nyeonji'.tr(),
      '월지' => 'saju_detail.gongmang_base_wolji'.tr(),
      '시지' => 'saju_detail.gongmang_base_siji'.tr(),
      _ => 'saju_detail.gongmang_base_default'.tr(),
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

  /// 공망 상세 해석 (i18n)
  static String getDetailedInterpretation(GongmangResult result) {
    if (!result.isGongmang) return '';

    final baseMeaning = switch (result.pillarName) {
      '년지' => 'saju_detail.gongmang_nyeonji'.tr(),
      '월지' => 'saju_detail.gongmang_wolji'.tr(),
      '시지' => 'saju_detail.gongmang_siji'.tr(),
      _ => '',
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
      return 'saju_detail.gongmang_fortune_none'.tr();
    } else if (gongmangCount == 1) {
      final gongmangPillar =
          results.firstWhere((r) => r.isGongmang).pillarName;
      return 'saju_detail.gongmang_fortune_single'.tr(namedArgs: {'pillar': gongmangPillar});
    } else {
      return 'saju_detail.gongmang_fortune_multi'.tr();
    }
  }
}
