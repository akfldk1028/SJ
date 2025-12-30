import '../../data/constants/jijanggan_table.dart';
import '../../data/constants/sipsin_relations.dart';
import '../entities/day_strength.dart';
import '../entities/saju_chart.dart';

/// 일간 강약 분석 서비스
/// 포스텔러 로직 참고: 득령/득지/득시/득세 기반 점수 계산
/// 8단계: 극약(0-12), 태약(13-25), 신약(26-37), 중화신약(38-49),
///        중화신강(50-62), 신강(63-74), 태강(75-87), 극왕(88-100)
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

    // 5. 득세 판단 (천간에서 비겁/인성 개수 - 포스텔러 기준)
    // 포스텔러는 천간만 세는 것으로 추정 (지장간 제외)
    final ganBigeopInseong = _countGanBigeopInseong(chart, dayMaster);
    final deukse = ganBigeopInseong >= 2; // 천간에서 비겁/인성 2개 이상

    // 6. 월령 득실 상태
    final monthStatus = _checkMonthStatus(dayOheng, chart.monthPillar.ji);

    // 7. 점수 계산 (포스텔러 기준)
    final score = _calculateScore(
      deukryeong: deukryeong,
      deukji: deukji,
      deuksi: deuksi,
      deukse: deukse,
      sipsinDistribution: sipsinDistribution,
    );

    // 8. 8단계 등급 결정
    final level = _determineLevel8(score);

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

  /// 점수 계산 (포스텔러/사주플러스 기준 - 50점 중심)
  /// 득령/득지/득시/득세 + 십신 분포로 점수 결정
  int _calculateScore({
    required bool deukryeong,
    required bool deukji,
    required bool deuksi,
    required bool deukse,
    required Map<SipSinCategory, int> sipsinDistribution,
  }) {
    // 기본 점수 50 (중화 기준)
    double score = 50.0;

    // 득령: +12점 / -8점 (가장 중요 - 월령은 사주의 50% 영향)
    if (deukryeong) {
      score += 12;
    } else {
      score -= 8;
    }

    // 득지: +8점 / -5점 (일지는 본인의 근본)
    if (deukji) {
      score += 8;
    } else {
      score -= 5;
    }

    // 득시: +4점 / -2점 (시간은 보조적)
    if (deuksi) {
      score += 4;
    } else {
      score -= 2;
    }

    // 득세: +6점 / -4점 (세력의 힘)
    if (deukse) {
      score += 6;
    } else {
      score -= 4;
    }

    // 십신 분포에 따른 미세 조정 (±5점 이내)
    final bigeopCount = sipsinDistribution[SipSinCategory.bigeop] ?? 0;
    final inseongCount = sipsinDistribution[SipSinCategory.inseong] ?? 0;
    final jaeseongCount = sipsinDistribution[SipSinCategory.jaeseong] ?? 0;
    final gwanseongCount = sipsinDistribution[SipSinCategory.gwanseong] ?? 0;
    final siksangCount = sipsinDistribution[SipSinCategory.siksang] ?? 0;

    // 비겁/인성 보너스 (최대 +5점)
    // 비겁+인성이 3개 초과시 보너스
    final supportCount = bigeopCount + inseongCount;
    score += ((supportCount - 3) * 1.5).clamp(-3.0, 5.0);

    // 설기(재관식상) - 많을수록 감점 (최대 -5점)
    // 재성+관성+식상이 많으면 일간의 기운을 빼앗음
    final drainCount = jaeseongCount + gwanseongCount + siksangCount;
    if (drainCount > 3) {
      score -= ((drainCount - 3) * 1.5).clamp(0.0, 5.0);
    }

    return score.round().clamp(0, 100);
  }

  /// 8단계 등급 결정 (포스텔러 기준)
  DayStrengthLevel _determineLevel8(int score) {
    if (score >= 88) return DayStrengthLevel.geukwang;    // 극왕
    if (score >= 75) return DayStrengthLevel.taegang;     // 태강
    if (score >= 63) return DayStrengthLevel.singang;     // 신강
    if (score >= 50) return DayStrengthLevel.junghwaSingang; // 중화신강
    if (score >= 38) return DayStrengthLevel.junghwaSinyak;  // 중화신약
    if (score >= 26) return DayStrengthLevel.sinyak;      // 신약
    if (score >= 13) return DayStrengthLevel.taeyak;      // 태약
    return DayStrengthLevel.geukyak;                       // 극약
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
