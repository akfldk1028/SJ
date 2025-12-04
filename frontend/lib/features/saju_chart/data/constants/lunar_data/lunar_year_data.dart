/// 음력 연도 데이터 클래스
/// 각 연도의 음력 정보를 담는 불변 데이터 구조
class LunarYearData {
  /// 연도
  final int year;

  /// 윤달 위치 (0=없음, 1~12=해당 월 다음이 윤달)
  final int leapMonth;

  /// 각 월의 일수 (평년 12개, 윤년 13개)
  /// 29(소월) 또는 30(대월)
  final List<int> monthDays;

  /// 음력 1월 1일의 양력 날짜 (기준점)
  final DateTime solarNewYear;

  const LunarYearData({
    required this.year,
    required this.leapMonth,
    required this.monthDays,
    required this.solarNewYear,
  });

  /// 해당 연도의 총 일수
  int get totalDays => monthDays.fold(0, (sum, days) => sum + days);

  /// 윤년 여부
  bool get isLeapYear => leapMonth > 0;

  /// 총 월수 (평년 12, 윤년 13)
  int get totalMonths => monthDays.length;
}
