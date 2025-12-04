import '../../data/constants/jijanggan_table.dart';
import '../../data/constants/sipsin_relations.dart';
import '../entities/day_strength.dart';
import '../entities/saju_chart.dart';

/// 일간 강약 분석 서비스
/// fortuneteller 로직 참고: 월령 40점, 비겁 25점, 인성 20점, 재관식상 감점
class DayStrengthService {
  /// 기본 점수
  static const int baseScore = 50;

  /// 월령 점수 (가장 중요)
  static const int monthMaxScore = 40;

  /// 비겁 점수
  static const int bigeopMaxScore = 25;

  /// 인성 점수
  static const int inseongMaxScore = 20;

  /// 재관식상 최대 감점
  static const int exhaustMaxPenalty = 15;

  /// 사주로부터 일간 강약 분석
  DayStrength analyze(SajuChart chart) {
    final dayMaster = chart.dayPillar.gan;

    // 1. 십신 분포 계산
    final sipsinDistribution = _calculateSipsinDistribution(chart, dayMaster);

    // 2. 월령 득실 판단
    final monthStatus = _checkMonthStatus(dayMaster, chart.monthPillar.ji);
    final monthScore = _calculateMonthScore(monthStatus);

    // 3. 비겁 점수
    final bigeopCount = sipsinDistribution[SipSinCategory.bigeop] ?? 0;
    final bigeopScore = _calculateBigeopScore(bigeopCount);

    // 4. 인성 점수
    final inseongCount = sipsinDistribution[SipSinCategory.inseong] ?? 0;
    final inseongScore = _calculateInseongScore(inseongCount);

    // 5. 재관식상 감점
    final jaeseongCount = sipsinDistribution[SipSinCategory.jaeseong] ?? 0;
    final gwanseongCount = sipsinDistribution[SipSinCategory.gwanseong] ?? 0;
    final siksangCount = sipsinDistribution[SipSinCategory.siksang] ?? 0;
    final exhaustTotal = jaeseongCount + gwanseongCount + siksangCount;
    final exhaustionScore = _calculateExhaustionPenalty(exhaustTotal);

    // 6. 총점 계산
    final totalScore =
        baseScore + monthScore + bigeopScore + inseongScore - exhaustionScore;
    final clampedScore = totalScore.clamp(0, 100);

    // 7. 강약 등급 결정
    final level = _determineLevel(clampedScore);

    return DayStrength(
      score: clampedScore,
      level: level,
      monthScore: monthScore,
      bigeopScore: bigeopScore,
      inseongScore: inseongScore,
      exhaustionScore: exhaustionScore,
      details: DayStrengthDetails(
        monthStatus: monthStatus,
        bigeopCount: bigeopCount,
        inseongCount: inseongCount,
        jaeseongCount: jaeseongCount,
        gwanseongCount: gwanseongCount,
        siksangCount: siksangCount,
      ),
    );
  }

  /// 십신 분포 계산 (천간 + 지장간)
  Map<SipSinCategory, int> _calculateSipsinDistribution(
    SajuChart chart,
    String dayMaster,
  ) {
    final distribution = <SipSinCategory, int>{};

    // 천간 분석 (년간, 월간, 시간) - 일간은 나 자신이므로 제외
    final gans = [
      chart.yearPillar.gan,
      chart.monthPillar.gan,
      if (chart.hourPillar != null) chart.hourPillar!.gan,
    ];

    for (final gan in gans) {
      final sipsin = calculateSipSin(dayMaster, gan);
      final category = sipsinToCategory[sipsin]!;
      distribution[category] = (distribution[category] ?? 0) + 1;
    }

    // 지장간 분석 (년지, 월지, 일지, 시지)
    final jis = [
      chart.yearPillar.ji,
      chart.monthPillar.ji,
      chart.dayPillar.ji,
      if (chart.hourPillar != null) chart.hourPillar!.ji,
    ];

    for (final ji in jis) {
      final jijanggan = getJiJangGan(ji);
      for (final jjg in jijanggan) {
        // 정기만 1점, 중기/여기는 0.5점으로 계산 (반올림)
        final sipsin = calculateSipSin(dayMaster, jjg.gan);
        final category = sipsinToCategory[sipsin]!;
        final weight = jjg.type == JiJangGanType.jeongGi ? 1 : 0;
        distribution[category] = (distribution[category] ?? 0) + weight;
      }
    }

    return distribution;
  }

  /// 월령 득실 판단
  MonthStatus _checkMonthStatus(String dayMaster, String monthJi) {
    final dayOheng = cheonganToOheng[dayMaster];
    final monthOheng = jijiToOheng[monthJi];

    if (dayOheng == null || monthOheng == null) {
      return MonthStatus.neutral;
    }

    // 같은 오행 또는 월지가 일간을 생함 → 득월
    if (dayOheng == monthOheng || ohengSangsaeng[monthOheng] == dayOheng) {
      return MonthStatus.deukwol;
    }

    // 월지가 일간을 극함 또는 일간이 월지를 생함(설기) → 실월
    if (ohengSanggeuk[monthOheng] == dayOheng ||
        ohengSangsaeng[dayOheng] == monthOheng) {
      return MonthStatus.silwol;
    }

    return MonthStatus.neutral;
  }

  /// 월령 점수 계산
  int _calculateMonthScore(MonthStatus status) {
    switch (status) {
      case MonthStatus.deukwol:
        return monthMaxScore; // +40점
      case MonthStatus.neutral:
        return monthMaxScore ~/ 2; // +20점
      case MonthStatus.silwol:
        return -20; // -20점
    }
  }

  /// 비겁 점수 계산
  int _calculateBigeopScore(int count) {
    if (count >= 4) return bigeopMaxScore; // +25점
    if (count >= 2) return 15; // +15점
    if (count >= 1) return 5; // +5점
    return -10; // -10점 (비겁 없음)
  }

  /// 인성 점수 계산
  int _calculateInseongScore(int count) {
    if (count >= 3) return inseongMaxScore; // +20점
    if (count >= 2) return 15; // +15점
    if (count >= 1) return 5; // +5점
    return 0; // 0점
  }

  /// 재관식상 감점 계산
  int _calculateExhaustionPenalty(int count) {
    if (count >= 6) return exhaustMaxPenalty; // -15점
    if (count >= 4) return 5; // -5점
    return 0;
  }

  /// 강약 등급 결정
  DayStrengthLevel _determineLevel(int score) {
    if (score >= 80) return DayStrengthLevel.veryStrong;
    if (score >= 65) return DayStrengthLevel.strong;
    if (score >= 40) return DayStrengthLevel.medium;
    if (score >= 25) return DayStrengthLevel.weak;
    return DayStrengthLevel.veryWeak;
  }
}
