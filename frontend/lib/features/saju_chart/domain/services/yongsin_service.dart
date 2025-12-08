import '../../data/constants/sipsin_relations.dart';
import '../entities/day_strength.dart';
import '../entities/saju_chart.dart';
import '../entities/yongsin.dart';
import 'day_strength_service.dart';

/// 용신(用神) 선정 서비스
/// fortuneteller 로직 참고: 억부법 기반
class YongSinService {
  final DayStrengthService _dayStrengthService;

  YongSinService({DayStrengthService? dayStrengthService})
      : _dayStrengthService = dayStrengthService ?? DayStrengthService();

  /// 사주로부터 용신 선정
  YongSinResult selectYongSin(SajuChart chart) {
    final dayMaster = chart.dayPillar.gan;
    final dayOheng = cheonganToOheng[dayMaster];

    // dayMaster가 유효하지 않은 경우 기본값 반환
    if (dayOheng == null) {
      return YongSinResult(
        yongsin: Oheng.mok,
        heesin: Oheng.su,
        gisin: Oheng.geum,
        gusin: Oheng.hwa,
        hansin: Oheng.to,
        reason: '일간 정보 부족',
        method: YongSinMethod.eokbu,
      );
    }

    // 일간 강약 분석
    final dayStrength = _dayStrengthService.analyze(chart);

    // 억부법 기반 용신 선정
    if (dayStrength.isStrong) {
      // 신강: 설기하거나 극하는 오행이 용신
      return _selectForStrong(dayOheng, dayStrength);
    } else if (dayStrength.isWeak) {
      // 신약: 생조하거나 돕는 오행이 용신
      return _selectForWeak(dayOheng, dayStrength);
    } else {
      // 중화: 가장 약한 오행 보강
      return _selectForNeutral(chart, dayOheng, dayStrength);
    }
  }

  /// 신강 사주의 용신 선정
  /// 설기: 식상(내가 생하는 오행), 재성(내가 극하는 오행)
  YongSinResult _selectForStrong(Oheng dayOheng, DayStrength strength) {
    // 용신: 식상 (설기) 또는 재성 (극)
    // 비겁이 너무 많으면 재성, 인성이 많으면 식상
    final Oheng yongsin;
    final String reason;

    if (strength.details.bigeopCount > strength.details.inseongCount) {
      // 비겁이 많으면 재성으로 극
      yongsin = getExhaustingOheng(getExhaustingOheng(dayOheng)); // 내가 극하는 오행
      reason = '신강 사주 - 비겁 과다로 재성(${yongsin.korean})으로 극제';
    } else {
      // 인성이 많으면 식상으로 설기
      yongsin = getExhaustingOheng(dayOheng); // 내가 생하는 오행
      reason = '신강 사주 - 인성 과다로 식상(${yongsin.korean})으로 설기';
    }

    return YongSinResult(
      yongsin: yongsin,
      heesin: getGeneratingOheng(yongsin),
      gisin: getOvercomingOheng(yongsin),
      gusin: getExhaustingOheng(yongsin),
      hansin: getGeneratingOheng(getOvercomingOheng(yongsin)),
      reason: reason,
      method: YongSinMethod.eokbu,
    );
  }

  /// 신약 사주의 용신 선정
  /// 생조: 인성(나를 생하는 오행), 비겁(같은 오행)
  YongSinResult _selectForWeak(Oheng dayOheng, DayStrength strength) {
    // 용신: 인성 (생조) 또는 비겁 (조력)
    final Oheng yongsin;
    final String reason;

    // 인성이 있으면 인성, 없으면 비겁
    if (strength.details.inseongCount > 0) {
      yongsin = getGeneratingOheng(dayOheng); // 나를 생하는 오행
      reason = '신약 사주 - 인성(${yongsin.korean})으로 생조';
    } else {
      yongsin = dayOheng; // 같은 오행 (비겁)
      reason = '신약 사주 - 비겁(${yongsin.korean})으로 조력';
    }

    return YongSinResult(
      yongsin: yongsin,
      heesin: getGeneratingOheng(yongsin),
      gisin: getOvercomingOheng(yongsin),
      gusin: getExhaustingOheng(yongsin),
      hansin: getGeneratingOheng(getOvercomingOheng(yongsin)),
      reason: reason,
      method: YongSinMethod.eokbu,
    );
  }

  /// 중화 사주의 용신 선정
  /// 가장 약한 오행을 보강
  YongSinResult _selectForNeutral(
    SajuChart chart,
    Oheng dayOheng,
    DayStrength strength,
  ) {
    // 오행 분포 계산
    final ohengCount = _countOheng(chart);

    // 가장 약한 오행 찾기
    Oheng weakest = Oheng.mok;
    int minCount = ohengCount[Oheng.mok] ?? 0;

    for (final entry in ohengCount.entries) {
      if (entry.value < minCount) {
        minCount = entry.value;
        weakest = entry.key;
      }
    }

    return YongSinResult(
      yongsin: weakest,
      heesin: getGeneratingOheng(weakest),
      gisin: getOvercomingOheng(weakest),
      gusin: getExhaustingOheng(weakest),
      hansin: getGeneratingOheng(getOvercomingOheng(weakest)),
      reason: '중화 사주 - 가장 약한 ${weakest.korean} 보강',
      method: YongSinMethod.eokbu,
    );
  }

  /// 오행 분포 계산
  Map<Oheng, int> _countOheng(SajuChart chart) {
    final count = <Oheng, int>{};

    // 천간 오행
    final gans = [
      chart.yearPillar.gan,
      chart.monthPillar.gan,
      chart.dayPillar.gan,
      if (chart.hourPillar != null) chart.hourPillar!.gan,
    ];

    for (final gan in gans) {
      final oheng = cheonganToOheng[gan];
      if (oheng != null) {
        count[oheng] = (count[oheng] ?? 0) + 1;
      }
    }

    // 지지 오행
    final jis = [
      chart.yearPillar.ji,
      chart.monthPillar.ji,
      chart.dayPillar.ji,
      if (chart.hourPillar != null) chart.hourPillar!.ji,
    ];

    for (final ji in jis) {
      final oheng = jijiToOheng[ji];
      if (oheng != null) {
        count[oheng] = (count[oheng] ?? 0) + 1;
      }
    }

    // 빠진 오행 0으로 초기화
    for (final oheng in Oheng.values) {
      count[oheng] ??= 0;
    }

    return count;
  }
}
