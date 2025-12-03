/// 진태양시 계산 서비스
/// 지역별 경도 차이에 따른 시간 보정
class TrueSolarTimeService {
  /// 한국 주요 도시의 경도
  /// 한국 표준시(KST)는 동경 135도 기준
  /// 실제 한반도는 약 126~131도
  static const Map<String, double> cityLongitude = {
    '서울': 126.98,
    '부산': 129.03,
    '대구': 128.60,
    '인천': 126.70,
    '광주': 126.85,
    '대전': 127.38,
    '울산': 129.31,
    '세종': 127.29,
    '제주': 126.53,
    '창원': 128.68,
    '수원': 127.03,
    '성남': 127.14,
    '고양': 126.83,
    '용인': 127.18,
    '청주': 127.49,
    '전주': 127.15,
    '포항': 129.37,
    '강릉': 128.88,
    '춘천': 127.73,
    '원주': 127.95,
    '제천': 128.19,
    '평택': 127.11,
    '김해': 128.89,
    '진주': 128.11,
    '여수': 127.66,
    '목포': 126.39,
    // 기본값
    'default': 127.0,
  };

  /// 표준 경도 (동경 135도)
  static const double standardLongitude = 135.0;

  /// 진태양시 계산
  /// 1. 경도 보정: (135 - 실제경도) × 4분
  /// 2. 균시차 적용 (선택적, 정밀 계산 시 사용)
  ///
  /// [localTime] 입력된 출생 시각 (지방시)
  /// [city] 출생 도시명
  /// [applyEquationOfTime] 균시차 적용 여부 (기본: false)
  DateTime calculateTrueSolarTime({
    required DateTime localTime,
    required String city,
    bool applyEquationOfTime = false,
  }) {
    final longitude = cityLongitude[city] ?? cityLongitude['default']!;

    // 경도 보정 계산
    // 경도 1도 차이 = 4분 시간 차이
    final correctionMinutes = (standardLongitude - longitude) * 4;

    // 보정된 시간
    DateTime correctedTime = localTime.subtract(
      Duration(minutes: correctionMinutes.round()),
    );

    // 균시차 적용 (선택적)
    if (applyEquationOfTime) {
      final equationMinutes = _calculateEquationOfTime(localTime);
      correctedTime = correctedTime.add(
        Duration(minutes: equationMinutes.round()),
      );
    }

    return correctedTime;
  }

  /// 균시차 계산 (Equation of Time)
  /// 태양의 실제 위치와 평균 위치의 차이로 인한 시간 보정
  /// 연중 -16분 ~ +14분 범위에서 변화
  ///
  /// 정밀한 계산을 위해서는 천문학적 계산 필요
  /// 현재는 간단한 근사 공식 사용
  double _calculateEquationOfTime(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;

    // 간단한 근사 공식
    // E = 9.87 * sin(2B) - 7.53 * cos(B) - 1.5 * sin(B)
    // B = (360/365) * (dayOfYear - 81) degrees
    final b = (360.0 / 365.0) * (dayOfYear - 81) * (3.14159 / 180.0);

    final equationMinutes = 9.87 * _sin(2 * b) - 7.53 * _cos(b) - 1.5 * _sin(b);

    return equationMinutes;
  }

  double _sin(double radians) {
    // Dart의 math 라이브러리 sin 사용을 위한 헬퍼
    return radians.sin();
  }

  double _cos(double radians) {
    // Dart의 math 라이브러리 cos 사용을 위한 헬퍼
    return radians.cos();
  }

  /// 도시명으로 경도 조회
  static double getLongitude(String city) {
    return cityLongitude[city] ?? cityLongitude['default']!;
  }

  /// 경도 보정 시간 계산 (분 단위)
  static double getLongitudeCorrectionMinutes(String city) {
    final longitude = getLongitude(city);
    return (standardLongitude - longitude) * 4;
  }
}

/// double에 대한 sin, cos 확장 메서드
extension _TrigonometryExtension on double {
  double sin() {
    // Taylor series approximation for sin
    double x = this;
    // Normalize to -π to π
    while (x > 3.14159) {
      x -= 2 * 3.14159;
    }
    while (x < -3.14159) {
      x += 2 * 3.14159;
    }

    // Taylor series: sin(x) ≈ x - x³/3! + x⁵/5! - x⁷/7!
    final x2 = x * x;
    return x * (1 - x2 / 6 * (1 - x2 / 20 * (1 - x2 / 42)));
  }

  double cos() {
    // cos(x) = sin(x + π/2)
    return (this + 3.14159 / 2).sin();
  }
}
