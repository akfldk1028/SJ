import '../../data/constants/jijanggan_table.dart';
import '../../data/constants/sipsin_relations.dart';
import '../entities/day_strength.dart';
import '../entities/saju_chart.dart';

/// 일간 강약 분석 서비스
/// Phase 37: 표준 명리학 점수 계산 방식으로 개선
///
/// 점수 가중치 (총 100점):
/// - 천간: 연간 10점, 월간 10점, 시간 10점 = 30점
/// - 지지: 연지 10점, 월지 30점, 일지 15점, 시지 15점 = 70점
/// - 비겁/인성이면 해당 점수 획득, 아니면 0점
/// - 50점 이상 = 신강, 50점 미만 = 신약
///
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

    // 5. 년지 득실 판단 (Phase 37 추가)
    final deuknyeonji = _checkDeuknyeonji(dayOheng, chart.yearPillar.ji);

    // 6. 득세 판단 (천간에서 비겁/인성 개수 - 포스텔러 기준)
    // 포스텔러는 천간만 세는 것으로 추정 (지장간 제외)
    final ganBigeopInseong = _countGanBigeopInseong(chart, dayMaster);
    final deukse = ganBigeopInseong >= 2; // 천간에서 비겁/인성 2개 이상

    // 7. 월령 득실 상태
    final monthStatus = _checkMonthStatus(dayOheng, chart.monthPillar.ji);

    // 8. 점수 계산 (Phase 37: 표준 명리학 방식)
    final score = _calculateScoreV2(
      chart: chart,
      dayMaster: dayMaster,
      dayOheng: dayOheng,
      deukryeong: deukryeong,
      deukji: deukji,
      deuksi: deuksi,
      deuknyeonji: deuknyeonji,
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

  /// 점수 계산 V2 (Phase 37: 표준 명리학 점수 계산 방식)
  ///
  /// 가중치 기반 점수 계산 (총 100점):
  /// - 천간: 연간 10점, 월간 10점, 시간 10점 = 30점
  /// - 지지: 연지 10점, 월지 30점, 일지 15점, 시지 15점 = 70점
  /// - 비겁/인성이면 해당 점수 획득, 아니면 0점
  /// - 50점 이상 = 신강, 50점 미만 = 신약
  int _calculateScoreV2({
    required SajuChart chart,
    required String dayMaster,
    required Oheng dayOheng,
    required bool deukryeong,
    required bool deukji,
    required bool deuksi,
    required bool deuknyeonji,
    required Map<SipSinCategory, int> sipsinDistribution,
  }) {
    double score = 0.0;

    // === 천간 점수 (30점) ===
    // 년간 (10점)
    if (_isGanSupport(dayMaster, chart.yearPillar.gan)) {
      score += 10.0;
    }
    // 월간 (10점)
    if (_isGanSupport(dayMaster, chart.monthPillar.gan)) {
      score += 10.0;
    }
    // 시간 (10점) - 시간 모르면 0점
    if (chart.hourPillar != null && _isGanSupport(dayMaster, chart.hourPillar!.gan)) {
      score += 10.0;
    }

    // === 지지 점수 (70점) ===
    // 월지 (30점 - 가장 중요!)
    if (deukryeong) {
      score += 30.0;
    }

    // 일지 (15점)
    if (deukji) {
      score += 15.0;
    }

    // 시지 (15점) - 시간 모르면 시지 점수 없음
    if (deuksi) {
      score += 15.0;
    }

    // 년지 (10점)
    if (deuknyeonji) {
      score += 10.0;
    }

    // === 시간 모름 보정 ===
    // 시간을 모르면 최대 점수가 75점(10+10+30+15+10)이므로
    // 비율 조정하여 100점 만점으로 환산
    if (chart.hourPillar == null) {
      // 시간 모름: 75점 만점 → 100점 만점으로 환산
      score = (score / 75.0) * 100.0;
    }

    return score.round().clamp(0, 100);
  }

  /// 점수 계산 (Phase 37: 표준 명리학 점수 계산 방식)
  ///
  /// 가중치 기반 점수 계산:
  /// - 천간: 연간 10점, 월간 10점, 시간 10점 = 30점
  /// - 지지: 연지 10점, 월지 30점, 일지 15점, 시지 15점 = 70점
  /// - 비겁/인성이면 해당 점수 획득, 아니면 0점
  /// - 총 100점 중 50점 이상 = 신강, 50점 미만 = 신약
  int _calculateScore({
    required bool deukryeong,
    required bool deukji,
    required bool deuksi,
    required bool deukse,
    required Map<SipSinCategory, int> sipsinDistribution,
  }) {
    // === 새로운 가중치 기반 점수 계산 ===
    // 이 점수는 0-100 사이로 계산됨
    double score = 0.0;

    // 득령 (월지 30점 - 가장 중요!)
    // 월지가 비겁/인성이면 30점 획득
    if (deukryeong) {
      score += 30.0;
    }

    // 득지 (일지 15점)
    if (deukji) {
      score += 15.0;
    }

    // 득시 (시지 15점)
    if (deuksi) {
      score += 15.0;
    }

    // 년지 (10점) - 득세와 별개로 년지 정기도 확인
    // 득세가 true면 천간에서 비겁/인성이 2개 이상이므로 년간/월간 포함
    // 년지는 별도로 체크해야 하지만, 현재 구조에서는 득세로 대체
    // 추가 점수: 득세면 천간 비겁/인성이 있으므로 일부 점수 부여
    if (deukse) {
      score += 20.0; // 천간 비겁/인성 2개 = 약 20점 (10+10)
    }

    // 년지 점수 (별도 계산 필요하나, 간략화하여 십신 분포로 추정)
    final bigeopCount = sipsinDistribution[SipSinCategory.bigeop] ?? 0;
    final inseongCount = sipsinDistribution[SipSinCategory.inseong] ?? 0;
    final jaeseongCount = sipsinDistribution[SipSinCategory.jaeseong] ?? 0;
    final gwanseongCount = sipsinDistribution[SipSinCategory.gwanseong] ?? 0;
    final siksangCount = sipsinDistribution[SipSinCategory.siksang] ?? 0;

    // 비겁+인성 세력에 따른 추가 점수 (0-20점)
    // 비겁+인성이 많을수록 신강, 재관식상이 많을수록 신약
    final supportCount = bigeopCount + inseongCount;
    final drainCount = jaeseongCount + gwanseongCount + siksangCount;

    // 세력 비율에 따른 점수 조정
    final totalCount = supportCount + drainCount;
    if (totalCount > 0) {
      // supportCount / totalCount 비율로 0-20점 배분
      // 비겁+인성이 전체의 50% 이상이면 신강 쪽으로
      final supportRatio = supportCount / totalCount;
      score += (supportRatio * 20.0); // 최대 20점 추가
    }

    // 점수 범위 조정: 0-100 → 경계선 조정
    // 현재 득령+득지+득시+득세+세력 = 최대 30+15+15+20+20 = 100점
    // 최소 = 0점 (모두 실령, 실지, 실시, 실세, 재관식상만)

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
