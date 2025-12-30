import '../../data/constants/lunar_data/lunar_table.dart';
import '../entities/lunar_date.dart';
import '../entities/lunar_validation.dart';

/// 음양력 변환 서비스
/// 한국천문연구원 데이터 기반 테이블 룩업 방식 (1900-2100년)
class LunarSolarConverter {
  /// 양력 → 음력 변환
  /// [solarDate] 양력 날짜
  /// 반환: 음력 날짜 (연, 월, 일, 윤달여부)
  LunarDate solarToLunar(DateTime solarDate) {
    final year = solarDate.year;

    // 지원 범위 확인
    if (!isYearSupported(year) && !isYearSupported(year - 1)) {
      throw ArgumentError('지원 범위 외 연도입니다: $year (1900-2100년 지원)');
    }

    // 해당 연도와 전년도 데이터 필요 (연초에는 전년도 음력일 수 있음)
    final currentYearData = getLunarYearData(year);
    final prevYearData = getLunarYearData(year - 1);

    if (currentYearData == null) {
      throw StateError('음력 데이터를 찾을 수 없습니다: $year');
    }

    // 해당 연도의 음력 1월 1일 (양력) 기준
    final lunarNewYear = currentYearData.solarNewYear;

    // 양력 날짜가 음력 설날 이전이면 전년도 음력
    if (solarDate.isBefore(lunarNewYear)) {
      if (prevYearData == null) {
        throw StateError('전년도 음력 데이터를 찾을 수 없습니다: ${year - 1}');
      }
      return _calculateLunarFromPrevYear(solarDate, prevYearData);
    }

    // 음력 설날 이후: 경과 일수로 음력 날짜 계산
    final daysSinceNewYear = solarDate.difference(lunarNewYear).inDays;
    return _calculateLunarDate(year, daysSinceNewYear, currentYearData);
  }

  /// 음력 → 양력 변환
  /// [lunarDate] 음력 날짜
  /// 반환: 양력 DateTime
  DateTime lunarToSolar(LunarDate lunarDate) {
    final year = lunarDate.year;

    // 지원 범위 확인
    if (!isYearSupported(year)) {
      throw ArgumentError('지원 범위 외 연도입니다: $year (1900-2100년 지원)');
    }

    final yearData = getLunarYearData(year);
    if (yearData == null) {
      throw StateError('음력 데이터를 찾을 수 없습니다: $year');
    }

    // 음력 1월 1일부터의 경과 일수 계산
    int totalDays = 0;
    final int targetMonthIndex = _getMonthIndex(
      lunarDate.month,
      lunarDate.isLeapMonth,
      yearData.leapMonth,
    );

    // 해당 월까지의 일수 누적
    for (int i = 0; i < targetMonthIndex; i++) {
      totalDays += yearData.monthDays[i];
    }

    // 해당 월의 일수 추가 (1일부터 시작하므로 -1)
    totalDays += lunarDate.day - 1;

    // 양력 설날에 경과 일수를 더함
    return yearData.solarNewYear.add(Duration(days: totalDays));
  }

  /// 해당 연도에 윤달이 있는지 확인
  bool hasLeapMonth(int year) {
    final yearData = getLunarYearData(year);
    return yearData?.leapMonth != 0;
  }

  /// 해당 연도의 윤달 월 반환 (없으면 0)
  int getLeapMonth(int year) {
    final yearData = getLunarYearData(year);
    return yearData?.leapMonth ?? 0;
  }

  /// 해당 연도/월이 윤달인지 확인
  bool isLeapMonth(int year, int month) {
    final leapMonth = getLeapMonth(year);
    return leapMonth == month;
  }

  /// 음력 월의 일수 반환
  int getLunarMonthDays(int year, int month, {bool isLeapMonth = false}) {
    final yearData = getLunarYearData(year);
    if (yearData == null) return 30; // 기본값

    final monthIndex = _getMonthIndex(month, isLeapMonth, yearData.leapMonth);
    if (monthIndex < 0 || monthIndex >= yearData.monthDays.length) {
      return 30; // 범위 초과 시 기본값
    }

    return yearData.monthDays[monthIndex];
  }

  /// 전년도 데이터로 음력 계산 (연초)
  LunarDate _calculateLunarFromPrevYear(
    DateTime solarDate,
    LunarYearData prevYearData,
  ) {
    // 전년도 음력 설날부터 총 일수
    final daysSincePrevNewYear =
        solarDate.difference(prevYearData.solarNewYear).inDays;

    return _calculateLunarDate(
      prevYearData.year,
      daysSincePrevNewYear,
      prevYearData,
    );
  }

  /// 경과 일수로 음력 날짜 계산
  LunarDate _calculateLunarDate(
    int lunarYear,
    int daysSinceNewYear,
    LunarYearData yearData,
  ) {
    int remainingDays = daysSinceNewYear;
    int monthIndex = 0;

    // 월별로 일수를 차감하며 해당 월 찾기
    while (monthIndex < yearData.monthDays.length &&
        remainingDays >= yearData.monthDays[monthIndex]) {
      remainingDays -= yearData.monthDays[monthIndex];
      monthIndex++;
    }

    // 월 인덱스가 범위를 벗어나면 다음 연도로 넘어감
    if (monthIndex >= yearData.monthDays.length) {
      // 다음 연도의 첫 월로 처리
      final nextYearData = getLunarYearData(lunarYear + 1);
      if (nextYearData != null) {
        return _calculateLunarDate(lunarYear + 1, remainingDays, nextYearData);
      }
      // 다음 연도 데이터가 없으면 마지막 월의 마지막 날로
      monthIndex = yearData.monthDays.length - 1;
      remainingDays = yearData.monthDays[monthIndex] - 1;
    }

    // 실제 음력 월과 윤달 여부 계산
    final (lunarMonth, isLeap) = _getActualMonth(monthIndex, yearData.leapMonth);

    return LunarDate(
      year: lunarYear,
      month: lunarMonth,
      day: remainingDays + 1, // 1일부터 시작
      isLeapMonth: isLeap,
    );
  }

  /// 월 인덱스로 실제 음력 월과 윤달 여부 반환
  (int month, bool isLeapMonth) _getActualMonth(int monthIndex, int leapMonth) {
    if (leapMonth == 0) {
      // 평년: 인덱스 + 1 = 음력 월
      return (monthIndex + 1, false);
    }

    // 윤년 처리
    if (monthIndex < leapMonth) {
      // 윤달 이전
      return (monthIndex + 1, false);
    } else if (monthIndex == leapMonth) {
      // 윤달
      return (leapMonth, true);
    } else {
      // 윤달 이후
      return (monthIndex, false);
    }
  }

  /// 음력 월과 윤달 여부로 monthDays 배열 인덱스 반환
  int _getMonthIndex(int month, bool isLeapMonth, int yearLeapMonth) {
    if (yearLeapMonth == 0) {
      // 평년
      return month - 1;
    }

    // 윤년
    if (month < yearLeapMonth) {
      return month - 1;
    } else if (month == yearLeapMonth && !isLeapMonth) {
      return month - 1;
    } else if (month == yearLeapMonth && isLeapMonth) {
      return month; // 윤달
    } else {
      return month; // 윤달 이후의 월
    }
  }

  // ============================================================
  // 윤달 유효성 검증 메서드 (Phase 18-A)
  // ============================================================

  /// 음력 날짜 유효성 검증
  /// [lunarDate] 검증할 음력 날짜
  /// 반환: 검증 결과 (유효성, 에러 메시지, 윤달 정보)
  LunarValidationResult validateLunarDate(LunarDate lunarDate) {
    final year = lunarDate.year;
    final month = lunarDate.month;
    final day = lunarDate.day;
    final isLeap = lunarDate.isLeapMonth;

    // 1. 연도 범위 체크
    if (!isYearSupported(year)) {
      return LunarValidationResult.invalid(
        '지원 범위 외 연도입니다 ($year). 1900-2100년만 지원됩니다.',
      );
    }

    final leapMonthInfo = getLeapMonthInfo(year);

    // 2. 월 범위 체크 (1-12)
    if (month < 1 || month > 12) {
      return LunarValidationResult.invalid(
        '월은 1~12 사이여야 합니다.',
        leapMonthInfo: leapMonthInfo,
      );
    }

    // 3. 윤달 유효성 체크
    if (isLeap) {
      if (!leapMonthInfo.hasLeapMonth) {
        return LunarValidationResult.invalid(
          '$year년에는 윤달이 없습니다.',
          leapMonthInfo: leapMonthInfo,
        );
      }
      if (month != leapMonthInfo.leapMonth) {
        return LunarValidationResult.invalid(
          '$year년 윤달은 ${leapMonthInfo.leapMonth}월입니다. ${month}월에는 윤달이 없습니다.',
          leapMonthInfo: leapMonthInfo,
        );
      }
    }

    // 4. 일수 범위 체크
    final maxDays = getLunarMonthDays(year, month, isLeapMonth: isLeap);
    if (day < 1 || day > maxDays) {
      final monthStr = isLeap ? '윤$month월' : '$month월';
      return LunarValidationResult.invalid(
        '$year년 $monthStr은 ${maxDays}일까지입니다.',
        leapMonthInfo: leapMonthInfo,
      );
    }

    // 모든 검증 통과
    return LunarValidationResult.valid(leapMonthInfo: leapMonthInfo);
  }

  /// 해당 연도의 윤달 정보 조회
  /// [year] 조회할 연도
  /// 반환: 윤달 정보 (연도, 윤달 유무, 윤달 월, 윤달 일수)
  LeapMonthInfo getLeapMonthInfo(int year) {
    final yearData = getLunarYearData(year);

    if (yearData == null || yearData.leapMonth == 0) {
      return LeapMonthInfo.none(year);
    }

    // 윤달의 일수는 monthDays 배열에서 leapMonth 인덱스 값
    final leapMonthDays = yearData.monthDays[yearData.leapMonth];

    return LeapMonthInfo(
      year: year,
      hasLeapMonth: true,
      leapMonth: yearData.leapMonth,
      leapMonthDays: leapMonthDays,
    );
  }

  /// 해당 연도에 윤달 체크박스를 활성화할 수 있는지 확인
  /// [year] 연도
  /// [month] 월
  /// 반환: 해당 월이 윤달을 가질 수 있는지 여부
  bool canSelectLeapMonth(int year, int month) {
    final leapMonthInfo = getLeapMonthInfo(year);
    return leapMonthInfo.hasLeapMonth && leapMonthInfo.leapMonth == month;
  }
}
