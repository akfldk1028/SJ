import '../../data/constants/jijanggan_table.dart';
import '../../data/constants/sipsin_relations.dart';
import '../entities/day_strength.dart';
import '../entities/saju_chart.dart';

/// 일간 강약 분석 서비스
/// Phase 38: 비율 기준 등급 결정 방식 (삼주/사주 일관성 유지)
///
/// 점수 가중치:
/// - 사주(시간 있음): 100점 만점
///   천간: 연간 10점, 월간 10점, 시간 10점 = 30점
///   지지: 연지 10점, 월지 30점, 일지 15점, 시지 15점 = 70점
///
/// - 삼주(시간 모름): 75점 만점
///   천간: 연간 10점, 월간 10점 = 20점
///   지지: 연지 10점, 월지 30점, 일지 15점 = 55점
///
/// 등급 결정: 점수/만점 비율로 결정 (시간 유무와 관계없이 일관된 등급)
/// - 88%+ = 극왕, 75-87% = 태강, 63-74% = 신강, 50-62% = 중화신강
/// - 38-49% = 중화신약, 26-37% = 신약, 13-25% = 태약, 0-12% = 극약
class DayStrengthService {
  /// 사주로부터 일간 강약 분석
  DayStrength analyze(SajuChart chart) {
    final dayMaster = chart.dayPillar.gan;
    final dayOheng = cheonganToOheng[dayMaster]!;

    // 1. 십신 분포 계산 (천간 + 지장간 정기)
    final sipsinDistribution = _calculateSipsinDistribution(chart, dayMaster);

    // 2. 득령 판단 (월지 정기가 일간을 생하거나 같은 오행)
    final deukryeong = _checkDeukryeong(dayOheng, chart.monthPillar.ji);

    // 3. 득지 판단 (일지 정기가 일간을 생하거나 같은 오행)
    final deukji = _checkDeukji(dayOheng, chart.dayPillar.ji);

    // 4. 득시 판단 (시지 정기가 일간을 생하거나 같은 오행)
    final deuksi = chart.hourPillar != null
        ? _checkDeuksi(dayOheng, chart.hourPillar!.ji)
        : false;

    // 5. 년지 득실 판단 (Phase 37 추가)
    final deuknyeonji = _checkDeuknyeonji(dayOheng, chart.yearPillar.ji);

    // 6. 득세 판단 (천간에서 비겁/인성 개수 - 포스텔러 기준)
    // 포스텔러는 천간만 세는 것으로 추정 (지장간 제외)
    final ganBigeopInseong = _countGanBigeopInseong(chart, dayMaster);
    final deukse = ganBigeopInseong >= 2; // 천간에서 비겁/인성 2개 이상

    // 7. 월령 득실 상태
    final monthStatus = _checkMonthStatus(dayOheng, chart.monthPillar.ji);

    // 8. 점수 계산 (Phase 38: 비율 기준 등급 결정)
    final (rawScore, maxScore) = _calculateScoreV3(
      chart: chart,
      dayMaster: dayMaster,
      deukryeong: deukryeong,
      deukji: deukji,
      deuksi: deuksi,
      deuknyeonji: deuknyeonji,
    );

    // 9. 비율 기준 등급 결정 (삼주/사주 일관성 유지)
    final ratio = rawScore / maxScore;
    final level = _determineLevelByRatio(ratio);

    // UI 표시용 점수 (100점 만점 환산)
    final score = (ratio * 100).round().clamp(0, 100);

    // 세부 정보
    final bigeopCount = sipsinDistribution[SipSinCategory.bigeop] ?? 0;
    final inseongCount = sipsinDistribution[SipSinCategory.inseong] ?? 0;
    final jaeseongCount = sipsinDistribution[SipSinCategory.jaeseong] ?? 0;
    final gwanseongCount = sipsinDistribution[SipSinCategory.gwanseong] ?? 0;
    final siksangCount = sipsinDistribution[SipSinCategory.siksang] ?? 0;

    return DayStrength(
      score: score,
      level: level,
      monthScore: deukryeong ? 20 : (monthStatus == MonthStatus.silwol ? -10 : 0),
      bigeopScore: bigeopCount * 5,
      inseongScore: inseongCount * 5,
      exhaustionScore: (jaeseongCount + gwanseongCount + siksangCount) * 3,
      details: DayStrengthDetails(
        monthStatus: monthStatus,
        bigeopCount: bigeopCount,
        inseongCount: inseongCount,
        jaeseongCount: jaeseongCount,
        gwanseongCount: gwanseongCount,
        siksangCount: siksangCount,
      ),
      // 새로운 필드들
      deukryeong: deukryeong,
      deukji: deukji,
      deuksi: deuksi,
      deukse: deukse,
    );
  }

  /// 득령 판단 (월지 정기 기준)
  bool _checkDeukryeong(Oheng dayOheng, String monthJi) {
    final jeongGi = getJeongGi(monthJi);
    if (jeongGi == null) return false;

    final jeongGiOheng = cheonganToOheng[jeongGi];
    if (jeongGiOheng == null) return false;

    // 같은 오행이거나 정기가 일간을 생함
    return dayOheng == jeongGiOheng || ohengSangsaeng[jeongGiOheng] == dayOheng;
  }

  /// 득지 판단 (일지 정기 기준)
  bool _checkDeukji(Oheng dayOheng, String dayJi) {
    final jeongGi = getJeongGi(dayJi);
    if (jeongGi == null) return false;

    final jeongGiOheng = cheonganToOheng[jeongGi];
    if (jeongGiOheng == null) return false;

    // 같은 오행이거나 정기가 일간을 생함
    return dayOheng == jeongGiOheng || ohengSangsaeng[jeongGiOheng] == dayOheng;
  }

  /// 득시 판단 (시지 정기 기준)
  bool _checkDeuksi(Oheng dayOheng, String hourJi) {
    final jeongGi = getJeongGi(hourJi);
    if (jeongGi == null) return false;

    final jeongGiOheng = cheonganToOheng[jeongGi];
    if (jeongGiOheng == null) return false;

    // 같은 오행이거나 정기가 일간을 생함
    return dayOheng == jeongGiOheng || ohengSangsaeng[jeongGiOheng] == dayOheng;
  }

  /// 년지 득실 판단 (Phase 37 추가)
  bool _checkDeuknyeonji(Oheng dayOheng, String yearJi) {
    final jeongGi = getJeongGi(yearJi);
    if (jeongGi == null) return false;

    final jeongGiOheng = cheonganToOheng[jeongGi];
    if (jeongGiOheng == null) return false;

    // 같은 오행이거나 정기가 일간을 생함
    return dayOheng == jeongGiOheng || ohengSangsaeng[jeongGiOheng] == dayOheng;
  }

  /// 천간 십신 체크 (비겁/인성 여부)
  bool _isGanSupport(String dayMaster, String targetGan) {
    final sipsin = calculateSipSin(dayMaster, targetGan);
    final category = sipsinToCategory[sipsin]!;
    return category == SipSinCategory.bigeop || category == SipSinCategory.inseong;
  }

  /// 점수 계산 V3 (Phase 38: 비율 기준 등급 결정)
  ///
  /// 반환: (획득 점수, 만점) 튜플
  /// - 사주(시간 있음): 100점 만점
  /// - 삼주(시간 모름): 75점 만점
  ///
  /// 명리학 원칙: "삼주 내에서 강약을 판단"
  /// 참고: https://brunch.co.kr/@saju/5
  (double, double) _calculateScoreV3({
    required SajuChart chart,
    required String dayMaster,
    required bool deukryeong,
    required bool deukji,
    required bool deuksi,
    required bool deuknyeonji,
  }) {
    double score = 0.0;

    // === 천간 점수 ===
    // 년간 (10점)
    if (_isGanSupport(dayMaster, chart.yearPillar.gan)) {
      score += 10.0;
    }
    // 월간 (10점)
    if (_isGanSupport(dayMaster, chart.monthPillar.gan)) {
      score += 10.0;
    }
    // 시간 (10점) - 시간 모르면 계산에서 제외
    if (chart.hourPillar != null && _isGanSupport(dayMaster, chart.hourPillar!.gan)) {
      score += 10.0;
    }

    // === 지지 점수 ===
    // 월지 (30점 - 가장 중요!)
    if (deukryeong) {
      score += 30.0;
    }

    // 일지 (15점)
    if (deukji) {
      score += 15.0;
    }

    // 시지 (15점) - 시간 모르면 계산에서 제외
    if (deuksi) {
      score += 15.0;
    }

    // 년지 (10점)
    if (deuknyeonji) {
      score += 10.0;
    }

    // 만점 결정: 시간 있음 = 100점, 시간 없음 = 75점
    final maxScore = chart.hourPillar == null ? 75.0 : 100.0;

    return (score, maxScore);
  }

  /// 비율 기준 8단계 등급 결정 (Phase 38)
  ///
  /// 시간 유무와 관계없이 비율로 등급 결정
  /// → 삼주/사주 간 등급 일관성 유지
  DayStrengthLevel _determineLevelByRatio(double ratio) {
    final score = (ratio * 100).round().clamp(0, 100);
    return DayStrengthLevel.fromScore(score);
  }

  /// 십신 분포 계산 (천간 + 지장간 전체)
  /// 지장간은 여기/중기/정기 모두 포함하되, 세력 비율로 가중치 적용
  Map<SipSinCategory, int> _calculateSipsinDistribution(
    SajuChart chart,
    String dayMaster,
  ) {
    final distribution = <SipSinCategory, int>{};

    // 천간 분석 (년간, 월간, 시간) - 일간은 비견으로 포함
    final gans = [
      dayMaster, // 일간 자체도 비견으로 포함 (포스텔러 방식)
      chart.yearPillar.gan,
      chart.monthPillar.gan,
      if (chart.hourPillar != null) chart.hourPillar!.gan,
    ];

    for (final gan in gans) {
      final sipsin = calculateSipSin(dayMaster, gan);
      final category = sipsinToCategory[sipsin]!;
      distribution[category] = (distribution[category] ?? 0) + 1;
    }

    // 지장간 분석 (전체 지장간 포함 - 정기 기준 1개로 카운트)
    // 여기/중기가 있으면 해당 오행이 추가로 영향을 줌
    final jis = [
      chart.yearPillar.ji,
      chart.monthPillar.ji,
      chart.dayPillar.ji,
      if (chart.hourPillar != null) chart.hourPillar!.ji,
    ];

    for (final ji in jis) {
      // 정기 (가장 강한 영향)
      final jeongGi = getJeongGi(ji);
      if (jeongGi != null) {
        final sipsin = calculateSipSin(dayMaster, jeongGi);
        final category = sipsinToCategory[sipsin]!;
        distribution[category] = (distribution[category] ?? 0) + 1;
      }
    }

    return distribution;
  }

  /// 천간에서 비겁/인성 개수 (득세 판단용 - 일간 제외)
  int _countGanBigeopInseong(SajuChart chart, String dayMaster) {
    int count = 0;

    // 년간, 월간, 시간만 체크 (일간 제외)
    final gans = [
      chart.yearPillar.gan,
      chart.monthPillar.gan,
      if (chart.hourPillar != null) chart.hourPillar!.gan,
    ];

    for (final gan in gans) {
      final sipsin = calculateSipSin(dayMaster, gan);
      final category = sipsinToCategory[sipsin]!;
      if (category == SipSinCategory.bigeop || category == SipSinCategory.inseong) {
        count++;
      }
    }

    return count;
  }

  /// 월령 득실 판단
  MonthStatus _checkMonthStatus(Oheng dayOheng, String monthJi) {
    final monthOheng = jijiToOheng[monthJi];
    if (monthOheng == null) return MonthStatus.neutral;

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
}
