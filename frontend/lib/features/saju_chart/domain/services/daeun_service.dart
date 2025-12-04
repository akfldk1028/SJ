import '../../data/constants/cheongan_jiji.dart';
import '../../data/constants/sipsin_relations.dart';
import '../entities/daeun.dart';
import '../entities/pillar.dart';
import '../entities/saju_chart.dart';
import 'solar_term_service.dart';

/// 대운(大運) 계산 서비스
/// 10년 주기의 운 흐름 계산
class DaeUnService {
  final SolarTermService _solarTermService;

  DaeUnService({SolarTermService? solarTermService})
      : _solarTermService = solarTermService ?? SolarTermService();

  /// 대운 계산
  /// [chart] 사주 차트
  /// [gender] 성별
  /// [birthDateTime] 출생 일시
  DaeUnResult calculate({
    required SajuChart chart,
    required Gender gender,
    required DateTime birthDateTime,
  }) {
    // 1. 순행/역행 결정
    // 남자 양년생 또는 여자 음년생 → 순행
    // 남자 음년생 또는 여자 양년생 → 역행
    final yearGan = chart.yearPillar.gan;
    final isYearGanYang = cheonganToEumYang[yearGan] == EumYang.yang;

    final isForward = (gender == Gender.male && isYearGanYang) ||
        (gender == Gender.female && !isYearGanYang);

    // 2. 대운수 계산 (절입일까지의 일수 / 3)
    final startAge = _calculateStartAge(birthDateTime, isForward);

    // 3. 대운 목록 생성
    final daeUnList = _generateDaeUnList(
      monthPillar: chart.monthPillar,
      isForward: isForward,
      startAge: startAge,
      count: 10, // 10개 대운
    );

    return DaeUnResult(
      startAge: startAge,
      isForward: isForward,
      daeUnList: daeUnList,
      gender: gender,
      isYearGanYang: isYearGanYang,
    );
  }

  /// 대운수(대운 시작 나이) 계산
  /// 출생일로부터 다음(또는 이전) 절입일까지의 일수를 3으로 나눔
  int _calculateStartAge(DateTime birthDateTime, bool isForward) {
    final year = birthDateTime.year;
    final solarTerms = _solarTermService.getSolarTerms(year);
    final nextYearTerms = _solarTermService.getSolarTerms(year + 1);
    final prevYearTerms = _solarTermService.getSolarTerms(year - 1);

    if (solarTerms == null) {
      // 절기 데이터가 없으면 기본값 5세
      return 5;
    }

    // 절입 절기 목록 (입춘, 경칩, 청명, 입하, 망종, 소서, 입추, 백로, 한로, 입동, 대설, 소한)
    const jeolipTerms = [
      'ipchun',
      'gyeongchip',
      'cheongmyeong',
      'ipha',
      'mangjong',
      'soseo',
      'ipchu',
      'baekro',
      'hanro',
      'ipdong',
      'daeseol',
      'sohan',
    ];

    // 모든 절입 시각 수집 (이전 연도, 현재 연도, 다음 연도)
    final allTermDates = <DateTime>[];

    for (final term in jeolipTerms) {
      if (prevYearTerms != null && prevYearTerms[term] != null) {
        allTermDates.add(prevYearTerms[term]!);
      }
      if (solarTerms[term] != null) {
        allTermDates.add(solarTerms[term]!);
      }
      if (nextYearTerms != null && nextYearTerms[term] != null) {
        allTermDates.add(nextYearTerms[term]!);
      }
    }

    allTermDates.sort();

    // 순행: 다음 절입일 찾기
    // 역행: 이전 절입일 찾기
    DateTime? targetDate;

    if (isForward) {
      // 출생일 이후 첫 절입일
      for (final date in allTermDates) {
        if (date.isAfter(birthDateTime)) {
          targetDate = date;
          break;
        }
      }
    } else {
      // 출생일 이전 마지막 절입일
      for (int i = allTermDates.length - 1; i >= 0; i--) {
        if (allTermDates[i].isBefore(birthDateTime)) {
          targetDate = allTermDates[i];
          break;
        }
      }
    }

    if (targetDate == null) {
      return 5; // 기본값
    }

    // 일수 계산 후 3으로 나눔 (1일 = 4개월, 3일 = 1년)
    final daysDiff = birthDateTime.difference(targetDate).inDays.abs();
    final startAge = (daysDiff / 3).round();

    // 최소 1세, 최대 10세
    return startAge.clamp(1, 10);
  }

  /// 대운 목록 생성
  List<DaeUn> _generateDaeUnList({
    required Pillar monthPillar,
    required bool isForward,
    required int startAge,
    required int count,
  }) {
    final result = <DaeUn>[];

    // 월주의 천간/지지 인덱스
    int ganIndex = cheongan.indexOf(monthPillar.gan);
    int jiIndex = jiji.indexOf(monthPillar.ji);

    for (int i = 0; i < count; i++) {
      // 순행이면 +1, 역행이면 -1
      if (isForward) {
        ganIndex = (ganIndex + 1) % 10;
        jiIndex = (jiIndex + 1) % 12;
      } else {
        ganIndex = (ganIndex - 1 + 10) % 10;
        jiIndex = (jiIndex - 1 + 12) % 12;
      }

      final pillar = Pillar(
        gan: cheongan[ganIndex],
        ji: jiji[jiIndex],
      );

      final daeUnStartAge = startAge + (i * 10);

      result.add(DaeUn(
        pillar: pillar,
        startAge: daeUnStartAge,
        endAge: daeUnStartAge + 9,
        order: i + 1,
      ));
    }

    return result;
  }

  /// 세운 계산
  /// [year] 해당 연도
  /// [birthYear] 출생 연도
  SeUn calculateSeUn(int year, int birthYear) {
    // 년주 계산 공식
    final ganIndex = (year - 4) % 10;
    final jiIndex = (year - 4) % 12;

    return SeUn(
      pillar: Pillar(
        gan: cheongan[ganIndex < 0 ? ganIndex + 10 : ganIndex],
        ji: jiji[jiIndex < 0 ? jiIndex + 12 : jiIndex],
      ),
      year: year,
      age: year - birthYear + 1, // 한국식 나이
    );
  }

  /// 특정 범위의 세운 목록 생성
  List<SeUn> generateSeUnList({
    required int birthYear,
    required int startYear,
    required int endYear,
  }) {
    final result = <SeUn>[];

    for (int year = startYear; year <= endYear; year++) {
      result.add(calculateSeUn(year, birthYear));
    }

    return result;
  }

  /// 현재 대운 찾기
  DaeUn? findCurrentDaeUn(DaeUnResult daeUnResult, int currentAge) {
    for (final daeUn in daeUnResult.daeUnList) {
      if (currentAge >= daeUn.startAge && currentAge <= daeUn.endAge) {
        return daeUn;
      }
    }
    return null;
  }
}
