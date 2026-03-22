/// 12운성(十二運星) 계산 서비스
/// 천간의 지지에 따른 기운의 강약을 12단계로 분석
library;

import 'package:easy_localization/easy_localization.dart';
import '../../data/constants/twelve_unsung.dart';
import '../entities/saju_chart.dart';

// ============================================================================
// 12운성 분석 결과 모델
// ============================================================================

/// 단일 기둥의 12운성 결과
class UnsungResult {
  /// 위치 (년/월/일/시)
  final String pillarName;

  /// 해당 지지
  final String jiji;

  /// 일간
  final String dayGan;

  /// 12운성
  final TwelveUnsung unsung;

  /// 해석
  final String interpretation;

  const UnsungResult({
    required this.pillarName,
    required this.jiji,
    required this.dayGan,
    required this.unsung,
    required this.interpretation,
  });

  /// 길흉 판단
  String get fortuneType => unsung.fortuneType;

  /// 기운 강도 (0-10)
  int get strength => unsung.strength;

  @override
  String toString() => '$pillarName: ${unsung.korean}(${unsung.hanja})';
}

/// 사주 전체 12운성 분석 결과
class UnsungAnalysisResult {
  /// 년주 운성
  final UnsungResult yearUnsung;

  /// 월주 운성
  final UnsungResult monthUnsung;

  /// 일주 운성
  final UnsungResult dayUnsung;

  /// 시주 운성 (시간 모를 경우 null)
  final UnsungResult? hourUnsung;

  /// 일간 (분석 기준)
  final String dayGan;

  const UnsungAnalysisResult({
    required this.yearUnsung,
    required this.monthUnsung,
    required this.dayUnsung,
    this.hourUnsung,
    required this.dayGan,
  });

  /// 모든 운성 리스트
  List<UnsungResult> get allUnsung => [
        yearUnsung,
        monthUnsung,
        dayUnsung,
        if (hourUnsung != null) hourUnsung!,
      ];

  /// 평균 기운 강도
  double get averageStrength {
    final list = allUnsung;
    return list.map((u) => u.strength).reduce((a, b) => a + b) / list.length;
  }

  /// 가장 강한 운성
  UnsungResult get strongestUnsung {
    return allUnsung.reduce(
        (curr, next) => curr.strength >= next.strength ? curr : next);
  }

  /// 가장 약한 운성
  UnsungResult get weakestUnsung {
    return allUnsung
        .reduce((curr, next) => curr.strength <= next.strength ? curr : next);
  }

  /// 길한 운성 개수
  int get goodUnsungCount =>
      allUnsung.where((u) => u.fortuneType == '길').length;

  /// 흉한 운성 개수
  int get badUnsungCount =>
      allUnsung.where((u) => u.fortuneType == '흉').length;

  /// 운성별 요약
  String get summary {
    final good = goodUnsungCount;
    final bad = badUnsungCount;
    final avg = averageStrength.toStringAsFixed(1);

    if (good >= 3) return 'saju_detail.unsung_summary_strong'.tr(namedArgs: {'avg': avg});
    if (bad >= 3) return 'saju_detail.unsung_summary_weak'.tr(namedArgs: {'avg': avg});
    return 'saju_detail.unsung_summary_balanced'.tr(namedArgs: {'avg': avg});
  }
}

// ============================================================================
// 12운성 계산 서비스
// ============================================================================

/// 12운성 계산 서비스
class UnsungService {
  /// 사주 차트에서 12운성 분석
  static UnsungAnalysisResult analyzeFromChart(SajuChart chart) {
    final dayGan = chart.dayPillar.gan;

    return UnsungAnalysisResult(
      yearUnsung: _calculateUnsung(dayGan, chart.yearPillar.ji, '년주'),
      monthUnsung: _calculateUnsung(dayGan, chart.monthPillar.ji, '월주'),
      dayUnsung: _calculateUnsung(dayGan, chart.dayPillar.ji, '일주'),
      hourUnsung: chart.hourPillar != null
          ? _calculateUnsung(dayGan, chart.hourPillar!.ji, '시주')
          : null,
      dayGan: dayGan,
    );
  }

  /// 개별 파라미터로 12운성 분석
  static UnsungAnalysisResult analyze({
    required String dayGan,
    required String yearJi,
    required String monthJi,
    required String dayJi,
    String? hourJi,
  }) {
    return UnsungAnalysisResult(
      yearUnsung: _calculateUnsung(dayGan, yearJi, '년주'),
      monthUnsung: _calculateUnsung(dayGan, monthJi, '월주'),
      dayUnsung: _calculateUnsung(dayGan, dayJi, '일주'),
      hourUnsung: hourJi != null ? _calculateUnsung(dayGan, hourJi, '시주') : null,
      dayGan: dayGan,
    );
  }

  /// 단일 지지의 12운성 계산
  static UnsungResult _calculateUnsung(
    String dayGan,
    String jiji,
    String pillarName,
  ) {
    final unsung = calculateTwelveUnsung(dayGan, jiji);
    final interpretation = _getInterpretation(pillarName, unsung);

    return UnsungResult(
      pillarName: pillarName,
      jiji: jiji,
      dayGan: dayGan,
      unsung: unsung,
      interpretation: interpretation,
    );
  }

  /// 단일 조회 (천간과 지지로)
  static TwelveUnsung getUnsung(String gan, String ji) {
    return calculateTwelveUnsung(gan, ji);
  }

  /// 궁성별 12운성 해석
  static String _getInterpretation(String pillarName, TwelveUnsung unsung) {
    final baseInterpretation = getUnsungInterpretation(unsung);

    // 궁성별 추가 해석
    final pillarMeaning = switch (pillarName) {
      '년주' => 'saju_detail.unsung_pillar_year'.tr(),
      '월주' => 'saju_detail.unsung_pillar_month'.tr(),
      '일주' => 'saju_detail.unsung_pillar_day'.tr(),
      '시주' => 'saju_detail.unsung_pillar_hour'.tr(),
      _ => '',
    };

    return '$pillarMeaning: $baseInterpretation';
  }

  /// 12운성별 통변 해석
  static String getDetailedInterpretation(TwelveUnsung unsung) {
    return switch (unsung) {
      TwelveUnsung.jangSaeng => 'saju_detail.unsung_detail_jangsaeng'.tr(),
      TwelveUnsung.mokYok => 'saju_detail.unsung_detail_mokyok'.tr(),
      TwelveUnsung.gwanDae => 'saju_detail.unsung_detail_gwandae'.tr(),
      TwelveUnsung.geonRok => 'saju_detail.unsung_detail_geonrok'.tr(),
      TwelveUnsung.jeWang => 'saju_detail.unsung_detail_jewang'.tr(),
      TwelveUnsung.soe => 'saju_detail.unsung_detail_soe'.tr(),
      TwelveUnsung.byung => 'saju_detail.unsung_detail_byung'.tr(),
      TwelveUnsung.sa => 'saju_detail.unsung_detail_sa'.tr(),
      TwelveUnsung.myo => 'saju_detail.unsung_detail_myo'.tr(),
      TwelveUnsung.jeol => 'saju_detail.unsung_detail_jeol'.tr(),
      TwelveUnsung.tae => 'saju_detail.unsung_detail_tae'.tr(),
      TwelveUnsung.yang => 'saju_detail.unsung_detail_yang'.tr(),
    };
  }

  /// 특정 천간의 모든 12운성 조회 (테이블 형태)
  static Map<String, TwelveUnsung> getUnsungTable(String gan) {
    return buildTwelveUnsungMap(gan);
  }

  /// 특정 천간이 특정 운성을 갖는 지지들 조회
  static List<String> findJijiByUnsungType(String gan, TwelveUnsung unsung) {
    return findJijiByUnsung(gan, unsung);
  }

  /// 일간의 건록지 조회
  static String? getGeonRokJi(String dayGan) {
    final list = findJijiByUnsung(dayGan, TwelveUnsung.geonRok);
    return list.isNotEmpty ? list.first : null;
  }

  /// 일간의 제왕지 조회
  static String? getJeWangJi(String dayGan) {
    final list = findJijiByUnsung(dayGan, TwelveUnsung.jeWang);
    return list.isNotEmpty ? list.first : null;
  }

  /// 일간의 장생지 조회
  static String? getJangSaengJi(String dayGan) {
    final list = findJijiByUnsung(dayGan, TwelveUnsung.jangSaeng);
    return list.isNotEmpty ? list.first : null;
  }

  /// 일간의 묘지(고지) 조회
  static String? getMyoJi(String dayGan) {
    final list = findJijiByUnsung(dayGan, TwelveUnsung.myo);
    return list.isNotEmpty ? list.first : null;
  }
}
