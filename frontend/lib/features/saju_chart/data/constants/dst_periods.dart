/// 한국 서머타임 (일광절약시간) 적용 기간
/// DST (Daylight Saving Time) 보정용

/// 날짜 범위
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange(this.start, this.end);

  /// 주어진 날짜가 이 범위에 포함되는지 확인
  bool contains(DateTime date) {
    return !date.isBefore(start) && !date.isAfter(end);
  }
}

/// 한국 서머타임 적용 기간 목록
/// 해당 기간 출생자는 -1시간 보정 필요
final List<DateRange> dstPeriods = [
  // 1948-1951년
  DateRange(DateTime(1948, 6, 1), DateTime(1948, 9, 12, 23, 59, 59)),
  DateRange(DateTime(1949, 4, 3), DateTime(1949, 9, 10, 23, 59, 59)),
  DateRange(DateTime(1950, 4, 1), DateTime(1950, 9, 9, 23, 59, 59)),
  DateRange(DateTime(1951, 5, 6), DateTime(1951, 9, 8, 23, 59, 59)),

  // 1955-1960년
  DateRange(DateTime(1955, 5, 5), DateTime(1955, 9, 8, 23, 59, 59)),
  DateRange(DateTime(1956, 5, 20), DateTime(1956, 9, 29, 23, 59, 59)),
  DateRange(DateTime(1957, 5, 5), DateTime(1957, 9, 21, 23, 59, 59)),
  DateRange(DateTime(1958, 5, 4), DateTime(1958, 9, 20, 23, 59, 59)),
  DateRange(DateTime(1959, 5, 3), DateTime(1959, 9, 19, 23, 59, 59)),
  DateRange(DateTime(1960, 5, 1), DateTime(1960, 9, 17, 23, 59, 59)),

  // 1987-1988년
  DateRange(DateTime(1987, 5, 10), DateTime(1987, 10, 10, 23, 59, 59)),
  DateRange(DateTime(1988, 5, 8), DateTime(1988, 10, 8, 23, 59, 59)),
];

/// 주어진 날짜가 서머타임 적용 기간인지 확인
bool isDSTApplied(DateTime dateTime) {
  return dstPeriods.any((period) => period.contains(dateTime));
}

/// 서머타임 보정
/// 서머타임 기간이면 -1시간 보정
DateTime adjustDST(DateTime dateTime) {
  if (isDSTApplied(dateTime)) {
    return dateTime.subtract(const Duration(hours: 1));
  }
  return dateTime;
}
