import '../../data/constants/jijanggan_table.dart';
import '../../data/constants/sipsin_relations.dart';
import '../entities/daeun.dart';
import '../entities/saju_analysis.dart';
import '../entities/saju_chart.dart';
import 'daeun_service.dart';
import 'day_strength_service.dart';
import 'gyeokguk_service.dart';
import 'sinsal_service.dart';
import 'yongsin_service.dart';

/// 사주 종합 분석 서비스
/// 포스텔러처럼 상세한 만세력 정보 제공
class SajuAnalysisService {
  final DayStrengthService _dayStrengthService;
  final GyeokGukService _gyeokgukService;
  final YongSinService _yongsinService;
  final SinSalService _sinsalService;
  final DaeUnService _daeunService;

  SajuAnalysisService({
    DayStrengthService? dayStrengthService,
    GyeokGukService? gyeokgukService,
    YongSinService? yongsinService,
    SinSalService? sinsalService,
    DaeUnService? daeunService,
  })  : _dayStrengthService = dayStrengthService ?? DayStrengthService(),
        _gyeokgukService = gyeokgukService ?? GyeokGukService(),
        _yongsinService = yongsinService ?? YongSinService(),
        _sinsalService = sinsalService ?? SinSalService(),
        _daeunService = daeunService ?? DaeUnService();

  /// 사주 종합 분석
  /// [chart] 사주 차트
  /// [gender] 성별 (대운 계산용, 선택)
  /// [currentYear] 현재 연도 (세운 계산용, 선택)
  SajuAnalysis analyze({
    required SajuChart chart,
    Gender? gender,
    int? currentYear,
  }) {
    final dayMaster = chart.dayPillar.gan;

    // 1. 일간 강약 분석
    final dayStrength = _dayStrengthService.analyze(chart);

    // 2. 격국 분석
    final gyeokguk = _gyeokgukService.analyze(chart);

    // 3. 용신 분석
    final yongsin = _yongsinService.selectYongSin(chart);

    // 4. 신살 분석
    final sinsalList = _sinsalService.findSinSals(chart);

    // 5. 대운 분석 (성별 필요)
    DaeUnResult? daeun;
    if (gender != null) {
      daeun = _daeunService.calculate(
        chart: chart,
        gender: gender,
        birthDateTime: chart.birthDateTime,
      );
    }

    // 6. 현재 세운 (현재 연도 필요)
    SeUn? currentSeun;
    if (currentYear != null) {
      currentSeun = _daeunService.calculateSeUn(
        currentYear,
        chart.birthDateTime.year,
      );
    }

    // 7. 십신 정보
    final sipsinInfo = _buildSipsinInfo(chart, dayMaster);

    // 8. 지장간 정보
    final jijangganInfo = _buildJiJangGanInfo(chart, dayMaster);

    // 9. 오행 분포
    final ohengDistribution = _buildOhengDistribution(chart);

    return SajuAnalysis(
      chart: chart,
      dayStrength: dayStrength,
      gyeokguk: gyeokguk,
      yongsin: yongsin,
      sinsalList: sinsalList,
      daeun: daeun,
      currentSeun: currentSeun,
      sipsinInfo: sipsinInfo,
      jijangganInfo: jijangganInfo,
      ohengDistribution: ohengDistribution,
    );
  }

  /// 십신 정보 구축
  SajuSipsinInfo _buildSipsinInfo(SajuChart chart, String dayMaster) {
    return SajuSipsinInfo(
      yearGanSipsin: calculateSipSin(dayMaster, chart.yearPillar.gan),
      monthGanSipsin: calculateSipSin(dayMaster, chart.monthPillar.gan),
      hourGanSipsin: chart.hourPillar != null
          ? calculateSipSin(dayMaster, chart.hourPillar!.gan)
          : null,
      yearJiSipsin:
          calculateSipSin(dayMaster, getJeongGi(chart.yearPillar.ji) ?? '갑'),
      monthJiSipsin:
          calculateSipSin(dayMaster, getJeongGi(chart.monthPillar.ji) ?? '갑'),
      dayJiSipsin:
          calculateSipSin(dayMaster, getJeongGi(chart.dayPillar.ji) ?? '갑'),
      hourJiSipsin: chart.hourPillar != null
          ? calculateSipSin(
              dayMaster, getJeongGi(chart.hourPillar!.ji) ?? '갑')
          : null,
    );
  }

  /// 지장간 정보 구축
  SajuJiJangGanInfo _buildJiJangGanInfo(SajuChart chart, String dayMaster) {
    return SajuJiJangGanInfo(
      yearJi: _buildJiJangGanItems(chart.yearPillar.ji, dayMaster),
      monthJi: _buildJiJangGanItems(chart.monthPillar.ji, dayMaster),
      dayJi: _buildJiJangGanItems(chart.dayPillar.ji, dayMaster),
      hourJi: chart.hourPillar != null
          ? _buildJiJangGanItems(chart.hourPillar!.ji, dayMaster)
          : [],
    );
  }

  /// 지지별 지장간 아이템 목록
  List<JiJangGanItem> _buildJiJangGanItems(String ji, String dayMaster) {
    final jijanggan = getJiJangGan(ji);
    final items = <JiJangGanItem>[];

    for (final jjg in jijanggan) {
      items.add(JiJangGanItem(
        gan: jjg.gan,
        sipsin: calculateSipSin(dayMaster, jjg.gan),
        strength: jjg.strength,
        type: _getJiJangGanTypeName(jjg.type),
      ));
    }

    return items;
  }

  String _getJiJangGanTypeName(JiJangGanType type) {
    switch (type) {
      case JiJangGanType.jeongGi:
        return '정기';
      case JiJangGanType.jungGi:
        return '중기';
      case JiJangGanType.yeoGi:
        return '여기';
    }
  }

  /// 오행 분포 계산
  OhengDistribution _buildOhengDistribution(SajuChart chart) {
    int mok = 0, hwa = 0, to = 0, geum = 0, su = 0;

    void countOheng(Oheng? oheng) {
      if (oheng == null) return;
      switch (oheng) {
        case Oheng.mok:
          mok++;
          break;
        case Oheng.hwa:
          hwa++;
          break;
        case Oheng.to:
          to++;
          break;
        case Oheng.geum:
          geum++;
          break;
        case Oheng.su:
          su++;
          break;
      }
    }

    // 천간 오행
    countOheng(cheonganToOheng[chart.yearPillar.gan]);
    countOheng(cheonganToOheng[chart.monthPillar.gan]);
    countOheng(cheonganToOheng[chart.dayPillar.gan]);
    if (chart.hourPillar != null) {
      countOheng(cheonganToOheng[chart.hourPillar!.gan]);
    }

    // 지지 오행
    countOheng(jijiToOheng[chart.yearPillar.ji]);
    countOheng(jijiToOheng[chart.monthPillar.ji]);
    countOheng(jijiToOheng[chart.dayPillar.ji]);
    if (chart.hourPillar != null) {
      countOheng(jijiToOheng[chart.hourPillar!.ji]);
    }

    return OhengDistribution(
      mok: mok,
      hwa: hwa,
      to: to,
      geum: geum,
      su: su,
    );
  }
}
