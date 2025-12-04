import '../../data/constants/sipsin_relations.dart';
import 'daeun.dart';
import 'day_strength.dart';
import 'gyeokguk.dart';
import 'pillar.dart';
import 'saju_chart.dart';
import 'sinsal.dart';
import 'yongsin.dart';

/// 사주 종합 분석 결과
/// 포스텔러처럼 상세한 만세력 정보 제공
class SajuAnalysis {
  /// 기본 사주 차트
  final SajuChart chart;

  /// 일간 강약 분석
  final DayStrength dayStrength;

  /// 격국 분석
  final GyeokGukResult gyeokguk;

  /// 용신 분석
  final YongSinResult yongsin;

  /// 신살 목록
  final List<SinSalResult> sinsalList;

  /// 대운 분석
  final DaeUnResult? daeun;

  /// 현재 세운
  final SeUn? currentSeun;

  /// 4주의 십신 정보
  final SajuSipsinInfo sipsinInfo;

  /// 4주의 지장간 정보
  final SajuJiJangGanInfo jijangganInfo;

  /// 오행 분포
  final OhengDistribution ohengDistribution;

  const SajuAnalysis({
    required this.chart,
    required this.dayStrength,
    required this.gyeokguk,
    required this.yongsin,
    required this.sinsalList,
    this.daeun,
    this.currentSeun,
    required this.sipsinInfo,
    required this.jijangganInfo,
    required this.ohengDistribution,
  });

  /// 길신 목록
  List<SinSalResult> get luckySinsals =>
      sinsalList.where((s) => s.sinsal.type == SinSalType.lucky).toList();

  /// 흉신 목록
  List<SinSalResult> get unluckySinsals =>
      sinsalList.where((s) => s.sinsal.type == SinSalType.unlucky).toList();
}

/// 4주의 십신 정보
class SajuSipsinInfo {
  /// 년간 십신
  final SipSin yearGanSipsin;

  /// 월간 십신
  final SipSin monthGanSipsin;

  /// 시간 십신 (시간 모르면 null)
  final SipSin? hourGanSipsin;

  /// 년지 정기 십신
  final SipSin yearJiSipsin;

  /// 월지 정기 십신
  final SipSin monthJiSipsin;

  /// 일지 정기 십신
  final SipSin dayJiSipsin;

  /// 시지 정기 십신 (시간 모르면 null)
  final SipSin? hourJiSipsin;

  const SajuSipsinInfo({
    required this.yearGanSipsin,
    required this.monthGanSipsin,
    this.hourGanSipsin,
    required this.yearJiSipsin,
    required this.monthJiSipsin,
    required this.dayJiSipsin,
    this.hourJiSipsin,
  });
}

/// 4주의 지장간 정보
class SajuJiJangGanInfo {
  /// 년지 지장간
  final List<JiJangGanItem> yearJi;

  /// 월지 지장간
  final List<JiJangGanItem> monthJi;

  /// 일지 지장간
  final List<JiJangGanItem> dayJi;

  /// 시지 지장간 (시간 모르면 빈 리스트)
  final List<JiJangGanItem> hourJi;

  const SajuJiJangGanInfo({
    required this.yearJi,
    required this.monthJi,
    required this.dayJi,
    required this.hourJi,
  });
}

/// 지장간 아이템
class JiJangGanItem {
  final String gan;
  final SipSin sipsin;
  final int strength;
  final String type; // 정기/중기/여기

  const JiJangGanItem({
    required this.gan,
    required this.sipsin,
    required this.strength,
    required this.type,
  });
}

/// 오행 분포
class OhengDistribution {
  final int mok; // 목
  final int hwa; // 화
  final int to; // 토
  final int geum; // 금
  final int su; // 수

  const OhengDistribution({
    required this.mok,
    required this.hwa,
    required this.to,
    required this.geum,
    required this.su,
  });

  /// 총 개수
  int get total => mok + hwa + to + geum + su;

  /// 가장 많은 오행
  Oheng get strongest {
    final map = {
      Oheng.mok: mok,
      Oheng.hwa: hwa,
      Oheng.to: to,
      Oheng.geum: geum,
      Oheng.su: su,
    };
    return map.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// 가장 적은 오행
  Oheng get weakest {
    final map = {
      Oheng.mok: mok,
      Oheng.hwa: hwa,
      Oheng.to: to,
      Oheng.geum: geum,
      Oheng.su: su,
    };
    return map.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
  }

  /// 없는 오행 목록
  List<Oheng> get missingOheng {
    final missing = <Oheng>[];
    if (mok == 0) missing.add(Oheng.mok);
    if (hwa == 0) missing.add(Oheng.hwa);
    if (to == 0) missing.add(Oheng.to);
    if (geum == 0) missing.add(Oheng.geum);
    if (su == 0) missing.add(Oheng.su);
    return missing;
  }
}
