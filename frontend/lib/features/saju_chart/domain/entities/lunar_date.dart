/// 음력 날짜
class LunarDate {
  final int year;
  final int month;
  final int day;
  final bool isLeapMonth;

  const LunarDate({
    required this.year,
    required this.month,
    required this.day,
    this.isLeapMonth = false,
  });

  /// 음력 날짜 문자열 (예: "2024년 윤4월 15일")
  String get formatted {
    final leapPrefix = isLeapMonth ? '윤' : '';
    return '$year년 $leapPrefix$month월 $day일';
  }

  @override
  String toString() => formatted;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LunarDate &&
        other.year == year &&
        other.month == month &&
        other.day == day &&
        other.isLeapMonth == isLeapMonth;
  }

  @override
  int get hashCode => Object.hash(year, month, day, isLeapMonth);
}
