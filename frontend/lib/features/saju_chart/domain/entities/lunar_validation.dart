/// 음력 날짜 검증 결과
class LunarValidationResult {
  /// 검증 통과 여부
  final bool isValid;

  /// 에러 메시지 (검증 실패 시)
  final String? errorMessage;

  /// 해당 연도 윤달 정보
  final LeapMonthInfo? leapMonthInfo;

  const LunarValidationResult({
    required this.isValid,
    this.errorMessage,
    this.leapMonthInfo,
  });

  /// 성공 결과 생성
  factory LunarValidationResult.valid({LeapMonthInfo? leapMonthInfo}) {
    return LunarValidationResult(
      isValid: true,
      leapMonthInfo: leapMonthInfo,
    );
  }

  /// 실패 결과 생성
  factory LunarValidationResult.invalid(String message,
      {LeapMonthInfo? leapMonthInfo}) {
    return LunarValidationResult(
      isValid: false,
      errorMessage: message,
      leapMonthInfo: leapMonthInfo,
    );
  }
}

/// 연도별 윤달 정보
class LeapMonthInfo {
  /// 연도
  final int year;

  /// 윤달 유무
  final bool hasLeapMonth;

  /// 윤달 월 (없으면 0)
  final int leapMonth;

  /// 윤달 일수 (29 또는 30)
  final int leapMonthDays;

  const LeapMonthInfo({
    required this.year,
    required this.hasLeapMonth,
    required this.leapMonth,
    required this.leapMonthDays,
  });

  /// 윤달 없음
  factory LeapMonthInfo.none(int year) {
    return LeapMonthInfo(
      year: year,
      hasLeapMonth: false,
      leapMonth: 0,
      leapMonthDays: 0,
    );
  }

  /// 정보 문자열 (예: "2001년 윤4월 (30일)")
  String get formatted {
    if (!hasLeapMonth) {
      return '$year년은 윤달이 없습니다';
    }
    return '$year년 윤$leapMonth월 ($leapMonthDays일)';
  }

  @override
  String toString() => formatted;
}
