import '../../data/constants/jijanggan_table.dart';
import '../../data/constants/sipsin_relations.dart';
import '../entities/gyeokguk.dart';
import '../entities/saju_chart.dart';

/// 격국(格局) 판정 서비스
/// fortuneteller 로직 참고
class GyeokGukService {
  /// 특수 격국 판정 기준 (60% 이상)
  static const double specialThreshold = 0.6;

  /// 특수 격국 최소 개수
  static const int specialMinCount = 5;

  /// 사주로부터 격국 판정
  GyeokGukResult analyze(SajuChart chart) {
    final dayMaster = chart.dayPillar.gan;

    // 1. 십신 분포 계산
    final sipsinCount = _calculateSipsinCount(chart, dayMaster);
    final totalCount = sipsinCount.values.fold(0, (sum, v) => sum + v);

    // 2. 특수 격국 우선 검사
    final specialResult = _checkSpecialGyeokguk(sipsinCount, totalCount);
    if (specialResult != null) {
      return specialResult;
    }

    // 3. 기본 격국 판정 (월지 정기 기준)
    final monthJeongGi = getJeongGi(chart.monthPillar.ji);
    if (monthJeongGi != null) {
      final monthSipsin = calculateSipSin(dayMaster, monthJeongGi);
      final basicGyeokguk = _sipsinToGyeokguk(monthSipsin);

      if (basicGyeokguk != null) {
        final count = sipsinCount[monthSipsin] ?? 0;
        final strength = ((count / totalCount) * 100).round();

        return GyeokGukResult(
          gyeokguk: basicGyeokguk,
          strength: strength.clamp(0, 100),
          isSpecial: false,
          reason: '월지 정기(${monthJeongGi})가 ${monthSipsin.korean}',
        );
      }
    }

    // 4. 월지 정기로 판정 불가 시, 가장 많은 십신으로 판정
    final dominant = _findDominantSipsin(sipsinCount);
    if (dominant != null) {
      final gyeokguk = _sipsinToGyeokguk(dominant);
      if (gyeokguk != null) {
        final count = sipsinCount[dominant] ?? 0;
        final strength = ((count / totalCount) * 100).round();

        return GyeokGukResult(
          gyeokguk: gyeokguk,
          strength: strength.clamp(0, 100),
          isSpecial: false,
          reason: '최다 십신(${dominant.korean}) 기준',
        );
      }
    }

    // 5. 기본값: 중화격
    return const GyeokGukResult(
      gyeokguk: GyeokGuk.junghwaGyeok,
      strength: 50,
      isSpecial: false,
      reason: '균형 잡힌 사주',
    );
  }

  /// 십신 개수 계산
  Map<SipSin, int> _calculateSipsinCount(SajuChart chart, String dayMaster) {
    final count = <SipSin, int>{};

    // 천간 (년간, 월간, 시간)
    final gans = [
      chart.yearPillar.gan,
      chart.monthPillar.gan,
      if (chart.hourPillar != null) chart.hourPillar!.gan,
    ];

    for (final gan in gans) {
      final sipsin = calculateSipSin(dayMaster, gan);
      count[sipsin] = (count[sipsin] ?? 0) + 1;
    }

    // 지장간 (년지, 월지, 일지, 시지) - 정기만 카운트
    final jis = [
      chart.yearPillar.ji,
      chart.monthPillar.ji,
      chart.dayPillar.ji,
      if (chart.hourPillar != null) chart.hourPillar!.ji,
    ];

    for (final ji in jis) {
      final jeongGi = getJeongGi(ji);
      if (jeongGi != null) {
        final sipsin = calculateSipSin(dayMaster, jeongGi);
        count[sipsin] = (count[sipsin] ?? 0) + 1;
      }
    }

    return count;
  }

  /// 특수 격국 검사
  GyeokGukResult? _checkSpecialGyeokguk(
    Map<SipSin, int> sipsinCount,
    int totalCount,
  ) {
    if (totalCount == 0) return null;

    // 비겁 (비견 + 겁재) 합계
    final bigeopTotal =
        (sipsinCount[SipSin.bigyeon] ?? 0) + (sipsinCount[SipSin.geopjae] ?? 0);
    final bigeopRatio = bigeopTotal / totalCount;

    if (bigeopTotal >= specialMinCount && bigeopRatio >= specialThreshold) {
      return GyeokGukResult(
        gyeokguk: GyeokGuk.jongwangGyeok,
        strength: (bigeopRatio * 100).round(),
        isSpecial: true,
        reason: '비겁이 ${(bigeopRatio * 100).round()}% (${bigeopTotal}개)',
      );
    }

    // 관살 (정관 + 편관) 합계
    final gwanTotal = (sipsinCount[SipSin.jeonggwan] ?? 0) +
        (sipsinCount[SipSin.pyeongwan] ?? 0);
    final gwanRatio = gwanTotal / totalCount;

    if (gwanTotal >= specialMinCount && gwanRatio >= specialThreshold) {
      return GyeokGukResult(
        gyeokguk: GyeokGuk.jongsalGyeok,
        strength: (gwanRatio * 100).round(),
        isSpecial: true,
        reason: '관살이 ${(gwanRatio * 100).round()}% (${gwanTotal}개)',
      );
    }

    // 재성 (정재 + 편재) 합계
    final jaeTotal = (sipsinCount[SipSin.jeongjae] ?? 0) +
        (sipsinCount[SipSin.pyeonjae] ?? 0);
    final jaeRatio = jaeTotal / totalCount;

    if (jaeTotal >= specialMinCount && jaeRatio >= specialThreshold) {
      return GyeokGukResult(
        gyeokguk: GyeokGuk.jongjaeGyeok,
        strength: (jaeRatio * 100).round(),
        isSpecial: true,
        reason: '재성이 ${(jaeRatio * 100).round()}% (${jaeTotal}개)',
      );
    }

    return null;
  }

  /// 가장 많은 십신 찾기
  SipSin? _findDominantSipsin(Map<SipSin, int> sipsinCount) {
    SipSin? dominant;
    int maxCount = 0;

    for (final entry in sipsinCount.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        dominant = entry.key;
      }
    }

    return dominant;
  }

  /// 십신 → 격국 변환
  GyeokGuk? _sipsinToGyeokguk(SipSin sipsin) {
    switch (sipsin) {
      case SipSin.jeonggwan:
        return GyeokGuk.jeonggwanGyeok;
      case SipSin.jeongjae:
        return GyeokGuk.jeongjaeGyeok;
      case SipSin.siksin:
        return GyeokGuk.siksinGyeok;
      case SipSin.jeongin:
        return GyeokGuk.jeonginGyeok;
      case SipSin.sanggwan:
        return GyeokGuk.sanggwanGyeok;
      case SipSin.pyeonin:
        return GyeokGuk.pyeoninGyeok;
      case SipSin.pyeonjae:
        return GyeokGuk.pyeonjaeGyeok;
      case SipSin.pyeongwan:
        return GyeokGuk.chilsalGyeok;
      case SipSin.bigyeon:
        return GyeokGuk.bigyeonGyeok;
      case SipSin.geopjae:
        return GyeokGuk.geopjaeGyeok;
    }
  }
}
