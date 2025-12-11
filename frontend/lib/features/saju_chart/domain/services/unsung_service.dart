/// 12운성(十二運星) 계산 서비스
/// 천간의 지지에 따른 기운의 강약을 12단계로 분석
library;

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

    if (good >= 3) return '전반적으로 기운이 왕성합니다 (평균강도: $avg)';
    if (bad >= 3) return '전반적으로 기운이 약합니다 (평균강도: $avg)';
    return '기운의 균형이 적절합니다 (평균강도: $avg)';
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
      '년주' => '조상운/유년기',
      '월주' => '부모운/청년기',
      '일주' => '본인/중년기',
      '시주' => '자녀운/말년기',
      _ => '',
    };

    return '$pillarMeaning: $baseInterpretation';
  }

  /// 12운성별 통변 해석
  static String getDetailedInterpretation(TwelveUnsung unsung) {
    return switch (unsung) {
      TwelveUnsung.jangSaeng =>
        '장생은 새로 태어나는 기운입니다. 창의성이 뛰어나고 새로운 시작에 유리합니다. '
            '독립심이 강하고 자수성가하는 경향이 있습니다.',
      TwelveUnsung.mokYok =>
        '목욕은 씻김과 정화의 단계입니다. 감성적이고 예술적 기질이 있으나 '
            '불안정하고 변화가 많을 수 있습니다. 도화적 성격이 나타날 수 있습니다.',
      TwelveUnsung.gwanDae =>
        '관대는 관을 쓰는 성인의 단계입니다. 사회적 인정을 받고 자신감이 충만합니다. '
            '책임감이 강하고 명예를 중시합니다.',
      TwelveUnsung.geonRok =>
        '건록은 녹을 세우는 단계로 가장 활발한 시기입니다. 실력을 발휘하고 '
            '재물을 모으기에 좋습니다. 직장운이나 사업운이 강합니다.',
      TwelveUnsung.jeWang =>
        '제왕은 황제처럼 최고 전성기의 기운입니다. 리더십이 강하고 주도적입니다. '
            '다만 너무 강해서 독선적이거나 외로울 수 있습니다.',
      TwelveUnsung.soe =>
        '쇠는 쇠퇴가 시작되는 단계입니다. 전성기를 지나 내면의 성숙을 이루는 시기입니다. '
            '경험에서 오는 지혜가 있습니다.',
      TwelveUnsung.byung =>
        '병은 기력이 약해지는 단계입니다. 내향적이고 깊은 사색을 하는 시기입니다. '
            '건강 관리에 신경 써야 합니다.',
      TwelveUnsung.sa =>
        '사는 기운이 정지하는 단계입니다. 완고하고 고집이 있으나 '
            '한 분야에 깊이 파고드는 집중력이 있습니다.',
      TwelveUnsung.myo =>
        '묘는 무덤으로 잠재된 에너지의 창고입니다. 비밀스러운 능력과 '
            '재물을 저장하는 힘이 있습니다. 고집이 세고 비밀이 많습니다.',
      TwelveUnsung.jeol =>
        '절은 끊어지고 단절되는 단계입니다. 기존 것이 종료되고 '
            '완전히 새로운 시작을 준비하는 시기입니다.',
      TwelveUnsung.tae =>
        '태는 잉태의 단계로 새 생명이 준비되는 시기입니다. '
            '새로운 가능성과 계획이 싹트는 단계입니다.',
      TwelveUnsung.yang =>
        '양은 양육되는 단계입니다. 점진적으로 성장하며 '
            '보호와 양육을 받는 시기입니다.',
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
