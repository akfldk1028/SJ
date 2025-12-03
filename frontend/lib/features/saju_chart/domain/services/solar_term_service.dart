import '../../data/constants/solar_term_table.dart';

/// 24절기 계산 서비스
class SolarTermService {
  /// 해당 연도의 절기 시각 조회
  /// 내장 테이블 사용 (2024-2025년만 지원)
  /// TODO: 전체 연도 지원을 위해 천문연구원 API 또는 정밀 계산 추가
  Map<String, DateTime>? getSolarTerms(int year) {
    final yearData = solarTermTable[year];
    if (yearData == null) return null;

    return yearData.map((key, value) => MapEntry(key, value.dateTime));
  }

  /// 특정 날짜 시각이 어느 월주에 속하는지 판단
  /// 절입시간 기준으로 월주 변경
  /// 반환값: 0(인월) ~ 11(축월)
  int getMonthPillarIndex(DateTime dateTime) {
    final year = dateTime.year;
    final solarTerms = getSolarTerms(year);
    final prevYearTerms = getSolarTerms(year - 1);
    final nextYearTerms = getSolarTerms(year + 1);

    if (solarTerms == null) {
      // 테이블에 없는 연도는 간단히 양력 월로 대체 (부정확)
      return _approximateMonthIndex(dateTime.month);
    }

    // 입춘 전인지 확인 (전년도 12월 축월)
    final ipchunTime = solarTerms['ipchun'];
    if (ipchunTime != null && dateTime.isBefore(ipchunTime)) {
      // 전년도 대한~입춘 사이는 축월(12월)
      if (prevYearTerms != null) {
        final prevDaehan = prevYearTerms['daehan'];
        if (prevDaehan != null && !dateTime.isBefore(prevDaehan)) {
          return 11; // 축월
        }
      }
      // 전년도 소한~대한 사이도 축월
      return 11;
    }

    // 절기 순서대로 검사
    for (int i = 0; i < solarTermOrder.length - 1; i++) {
      final currentTerm = solarTermOrder[i];
      final nextTerm = solarTermOrder[i + 1];

      DateTime? currentTime;
      DateTime? nextTime;

      // 현재 절기 시각
      if (currentTerm == 'sohan' || currentTerm == 'daehan') {
        currentTime = nextYearTerms?[currentTerm];
      } else {
        currentTime = solarTerms[currentTerm];
      }

      // 다음 절기 시각
      if (nextTerm == 'sohan' || nextTerm == 'daehan') {
        nextTime = nextYearTerms?[nextTerm];
      } else {
        nextTime = solarTerms[nextTerm];
      }

      if (currentTime == null) continue;

      // 현재 절기 이후이고, 다음 절기 전이면 해당 월
      if (!dateTime.isBefore(currentTime)) {
        if (nextTime == null || dateTime.isBefore(nextTime)) {
          final monthIndex = solarTermToMonthIndex[currentTerm];
          if (monthIndex != null) return monthIndex;
        }
      }
    }

    // 기본값: 대한 이후면 축월
    return 11;
  }

  /// 절기 테이블이 없는 경우 근사값 계산
  /// 부정확하므로 실제 사용 시 주의 필요
  int _approximateMonthIndex(int solarMonth) {
    // 양력 월을 음력 월로 근사 변환
    // 입춘(2월 초) = 인월(0) 시작
    const monthMap = {
      1: 11, // 1월 = 축월
      2: 0, // 2월 = 인월
      3: 1, // 3월 = 묘월
      4: 2, // 4월 = 진월
      5: 3, // 5월 = 사월
      6: 4, // 6월 = 오월
      7: 5, // 7월 = 미월
      8: 6, // 8월 = 신월
      9: 7, // 9월 = 유월
      10: 8, // 10월 = 술월
      11: 9, // 11월 = 해월
      12: 10, // 12월 = 자월
    };
    return monthMap[solarMonth] ?? 0;
  }

  /// 해당 날짜의 절기 이름 반환 (정확한 날짜인 경우만)
  String? getSolarTermName(DateTime dateTime) {
    final year = dateTime.year;
    final solarTerms = getSolarTerms(year);
    if (solarTerms == null) return null;

    for (final entry in solarTerms.entries) {
      final termTime = entry.value;
      if (termTime.year == dateTime.year &&
          termTime.month == dateTime.month &&
          termTime.day == dateTime.day) {
        return entry.key;
      }
    }
    return null;
  }
}
