import '../../data/constants/cheongan_jiji.dart';
import '../entities/lunar_date.dart';
import '../entities/pillar.dart';
import '../entities/saju_chart.dart';
import 'dst_service.dart';
import 'jasi_service.dart';
import 'lunar_solar_converter.dart';
import 'solar_term_service.dart';
import 'true_solar_time_service.dart';

/// 사주팔자 계산 통합 서비스
class SajuCalculationService {
  final LunarSolarConverter _lunarConverter;
  final SolarTermService _solarTermService;
  final TrueSolarTimeService _trueSolarTimeService;
  final DSTService _dstService;
  final JasiService _jasiService;

  SajuCalculationService({
    LunarSolarConverter? lunarConverter,
    SolarTermService? solarTermService,
    TrueSolarTimeService? trueSolarTimeService,
    DSTService? dstService,
    JasiService? jasiService,
  })  : _lunarConverter = lunarConverter ?? LunarSolarConverter(),
        _solarTermService = solarTermService ?? SolarTermService(),
        _trueSolarTimeService =
            trueSolarTimeService ?? TrueSolarTimeService(),
        _dstService = dstService ?? DSTService(),
        _jasiService = jasiService ?? JasiService();

  /// 사주팔자 계산 (메인 메서드)
  ///
  /// [birthDateTime] 출생 일시
  /// [birthCity] 출생 도시 (진태양시 보정용)
  /// [isLunarCalendar] 음력 여부
  /// [isLeapMonth] 윤달 여부 (음력일 때만 유효)
  /// [jasiMode] 자시 처리 모드 (기본: 야자시)
  /// [birthTimeUnknown] 출생시간 모름 여부
  SajuChart calculate({
    required DateTime birthDateTime,
    required String birthCity,
    required bool isLunarCalendar,
    bool isLeapMonth = false,
    JasiMode jasiMode = JasiMode.yaJasi,
    bool birthTimeUnknown = false,
  }) {
    // 1. 음력이면 양력으로 변환
    DateTime solarDateTime = birthDateTime;
    if (isLunarCalendar) {
      solarDateTime = _lunarConverter.lunarToSolar(
        LunarDate(
          year: birthDateTime.year,
          month: birthDateTime.month,
          day: birthDateTime.day,
          isLeapMonth: isLeapMonth,
        ),
      );
      // 시간 정보 복사
      solarDateTime = DateTime(
        solarDateTime.year,
        solarDateTime.month,
        solarDateTime.day,
        birthDateTime.hour,
        birthDateTime.minute,
      );
    }

    // 2. 서머타임 보정
    solarDateTime = _dstService.adjustForDST(solarDateTime);

    // 3. 진태양시 보정
    final trueSolarTime = _trueSolarTimeService.calculateTrueSolarTime(
      localTime: solarDateTime,
      city: birthCity,
    );

    // 4. 야자시/조자시 처리
    final adjustedDateTime = _jasiService.adjustForJasi(
      dateTime: trueSolarTime,
      mode: jasiMode,
    );

    // 5. 절기 정보 조회
    final solarTerms = _solarTermService.getSolarTerms(adjustedDateTime.year);

    // 6. 사주 계산
    final yearPillar = _calculateYearPillar(
      birthDateTime: adjustedDateTime,
      ipchunDateTime: solarTerms?['ipchun'],
    );

    final monthPillar = _calculateMonthPillar(
      birthDateTime: adjustedDateTime,
      yearPillar: yearPillar,
    );

    final dayPillar = _calculateDayPillar(adjustedDateTime);

    final Pillar? hourPillar = birthTimeUnknown
        ? null
        : _calculateHourPillar(
            hour: adjustedDateTime.hour,
            dayPillar: dayPillar,
          );

    return SajuChart(
      yearPillar: yearPillar,
      monthPillar: monthPillar,
      dayPillar: dayPillar,
      hourPillar: hourPillar,
      birthDateTime: birthDateTime,
      correctedDateTime: adjustedDateTime,
      birthCity: birthCity,
      isLunarCalendar: isLunarCalendar,
    );
  }

  /// 년주 계산
  /// 절기 기준: 입춘 이후부터 새해
  Pillar _calculateYearPillar({
    required DateTime birthDateTime,
    required DateTime? ipchunDateTime,
  }) {
    // 입춘 전이면 전년도로 계산
    int year = birthDateTime.year;
    if (ipchunDateTime != null && birthDateTime.isBefore(ipchunDateTime)) {
      year = birthDateTime.year - 1;
    }

    // 년간 계산: (년도 - 4) % 10
    final ganIndex = (year - 4) % 10;

    // 년지 계산: (년도 - 4) % 12
    final jiIndex = (year - 4) % 12;

    return Pillar(
      gan: cheongan[ganIndex < 0 ? ganIndex + 10 : ganIndex],
      ji: jiji[jiIndex < 0 ? jiIndex + 12 : jiIndex],
    );
  }

  /// 월주 계산
  /// 절기 기준: 절입시간에 따라 월 결정
  Pillar _calculateMonthPillar({
    required DateTime birthDateTime,
    required Pillar yearPillar,
  }) {
    // 절입시간으로 월 결정 (0~11: 인월~축월)
    final monthIndex = _solarTermService.getMonthPillarIndex(birthDateTime);

    // 월간 계산: 년간에 따른 월간 시작점
    // 갑기년 → 병인월 시작 (병=2)
    // 을경년 → 무인월 시작 (무=4)
    // 병신년 → 경인월 시작 (경=6)
    // 정임년 → 임인월 시작 (임=8)
    // 무계년 → 갑인월 시작 (갑=0)
    final yearGanIndex = cheongan.indexOf(yearPillar.gan);
    final monthGanStart = ((yearGanIndex % 5) * 2 + 2) % 10;
    final ganIndex = (monthGanStart + monthIndex) % 10;

    // 월지: 인월(1월)부터 시작 → index 2
    final jiIndex = (monthIndex + 2) % 12;

    return Pillar(
      gan: cheongan[ganIndex],
      ji: jiji[jiIndex],
    );
  }

  /// 일주 계산
  /// 기준일: 1900년 1월 1일 = 계사일 (癸巳)
  Pillar _calculateDayPillar(DateTime birthDate) {
    // 기준일: 1900년 1월 1일
    final baseDate = DateTime(1900, 1, 1);
    // 포스텔러 검증 완료:
    // - 1990-02-15 → 신해(辛亥, 인덱스 47) ✓
    // - 1997-11-29 → 을해(乙亥, 인덱스 11) ✓
    const baseDayIndex = 10;

    // 일수 차이 계산
    final daysDiff = birthDate.difference(baseDate).inDays;

    // 60갑자 순환
    int dayIndex = (baseDayIndex + daysDiff) % 60;
    if (dayIndex < 0) dayIndex += 60;

    // 천간과 지지 분리
    final ganIndex = dayIndex % 10;
    final jiIndex = dayIndex % 12;

    return Pillar(
      gan: cheongan[ganIndex],
      ji: jiji[jiIndex],
    );
  }

  /// 시주 계산
  /// 2시간 단위로 시주 결정
  Pillar _calculateHourPillar({
    required int hour,
    required Pillar dayPillar,
  }) {
    // 시지 결정 (2시간 단위)
    // 자시: 23:00-01:00 (index 0)
    // 축시: 01:00-03:00 (index 1)
    // 인시: 03:00-05:00 (index 2)
    // ...
    final jiIndex = ((hour + 1) ~/ 2) % 12;

    // 시간 계산: 일간에 따른 시작점
    // 갑기일 → 갑자시 시작 (갑=0)
    // 을경일 → 병자시 시작 (병=2)
    // 병신일 → 무자시 시작 (무=4)
    // 정임일 → 경자시 시작 (경=6)
    // 무계일 → 임자시 시작 (임=8)
    final dayGanIndex = cheongan.indexOf(dayPillar.gan);
    final hourGanStart = (dayGanIndex % 5) * 2;
    final ganIndex = (hourGanStart + jiIndex) % 10;

    return Pillar(
      gan: cheongan[ganIndex],
      ji: jiji[jiIndex],
    );
  }
}
