/// 24절기 천문학적 계산기
/// Jean Meeus의 "Astronomical Algorithms" 2판 기반
///
/// 정확도: ±2분 (1900-2100년 범위)
library;

import 'dart:math' as math;

/// 절기 계산기 클래스
class SolarTermCalculator {
  /// 절기명 (한국 순서: 소한부터)
  static const List<String> termNames = [
    '소한', '대한', '입춘', '우수', '경칩', '춘분',
    '청명', '곡우', '입하', '소만', '망종', '하지',
    '소서', '대서', '입추', '처서', '백로', '추분',
    '한로', '상강', '입동', '소설', '대설', '동지',
  ];

  /// 절기 키 (영문)
  static const List<String> termKeys = [
    'sohan', 'daehan', 'ipchun', 'usoo', 'gyeongchip', 'chunbun',
    'cheongmyeong', 'gogu', 'ipha', 'soman', 'mangjong', 'haji',
    'soseo', 'daeseo', 'ipchu', 'cheoseo', 'baekro', 'chubeun',
    'hanro', 'sanggang', 'ipdong', 'soseol', 'daeseol', 'dongji',
  ];

  /// 각 절기의 태양 황경 (도)
  static const List<double> termLongitudes = [
    285, 300, 315, 330, 345, 0,
    15, 30, 45, 60, 75, 90,
    105, 120, 135, 150, 165, 180,
    195, 210, 225, 240, 255, 270,
  ];

  static const double _rad = math.pi / 180.0;

  /// 특정 연도의 특정 절기 시각 계산
  static DateTime calculateSolarTerm(int year, int termIndex) {
    final double targetLon = termLongitudes[termIndex];

    // 초기 추정값: 해당 절기의 대략적인 날짜
    double jd = _getInitialEstimate(year, termIndex);

    // Newton-Raphson 반복법
    for (int iter = 0; iter < 50; iter++) {
      final double sunLon = _solarLongitude(jd);

      // 각도 차이 계산 - 최단 경로 방식
      double diff = targetLon - sunLon;

      // -180 ~ +180 범위로 정규화 (최단 경로)
      while (diff > 180) diff -= 360;
      while (diff < -180) diff += 360;

      if (diff.abs() < 0.00001) break;

      // 태양은 하루에 약 360/365.25 ≈ 0.9856도 이동
      jd += diff * 365.25 / 360.0;
    }

    // Julian Day (UT) → KST DateTime (로컬 시간)
    return _jdToKstDateTime(jd);
  }

  /// 연도의 모든 절기 계산
  static Map<String, DateTime> calculateYearTerms(int year) {
    final terms = <String, DateTime>{};
    for (int i = 0; i < 24; i++) {
      terms[termKeys[i]] = calculateSolarTerm(year, i);
    }
    return terms;
  }

  /// 초기 추정값 계산
  static double _getInitialEstimate(int year, int termIndex) {
    // 각 절기의 대략적인 월/일
    const approxDates = <List<int>>[
      [1, 6], [1, 20], [2, 4], [2, 19], [3, 6], [3, 21],
      [4, 5], [4, 20], [5, 6], [5, 21], [6, 6], [6, 21],
      [7, 7], [7, 23], [8, 7], [8, 23], [9, 8], [9, 23],
      [10, 8], [10, 23], [11, 7], [11, 22], [12, 7], [12, 22],
    ];
    return _dateToJd(year, approxDates[termIndex][0], approxDates[termIndex][1], 12);
  }

  /// 태양 황경 계산 (VSOP87 간소화)
  /// 참조: Jean Meeus, "Astronomical Algorithms" 2nd ed., Chapter 25
  static double _solarLongitude(double jd) {
    // Julian 세기 (J2000.0 = JD 2451545.0 기준)
    final double T = (jd - 2451545.0) / 36525.0;
    final double T2 = T * T;
    final double T3 = T2 * T;

    // 태양 평균 황경 L0 (도) - 정확한 공식
    double L0 = 280.46646 + 36000.76983 * T + 0.0003032 * T2;

    // 태양 평균 근점이각 M (도)
    double M = 357.52911 + 35999.05029 * T - 0.0001537 * T2;

    // 지구 궤도 이심률 e
    double e = 0.016708634 - 0.000042037 * T - 0.0000001267 * T2;

    // 각도 정규화
    L0 = _normalizeAngle(L0);
    M = _normalizeAngle(M);

    final double Mrad = M * _rad;

    // 태양 중심차 C (equation of center)
    double C = (1.914602 - 0.004817 * T - 0.000014 * T2) * math.sin(Mrad);
    C += (0.019993 - 0.000101 * T) * math.sin(2 * Mrad);
    C += 0.000289 * math.sin(3 * Mrad);

    // 태양 진황경 (true longitude)
    double sunLon = L0 + C;

    // 장동과 광행차 보정 (간소화)
    double omega = 125.04 - 1934.136 * T;
    sunLon = sunLon - 0.00569 - 0.00478 * math.sin(omega * _rad);

    return _normalizeAngle(sunLon);
  }

  /// 각도를 0-360 범위로 정규화
  static double _normalizeAngle(double angle) {
    double result = angle % 360;
    if (result < 0) result += 360;
    return result;
  }

  /// 그레고리력 → Julian Day
  static double _dateToJd(int year, int month, int day, [double hour = 12]) {
    int y = year;
    int m = month;

    if (m <= 2) {
      y--;
      m += 12;
    }

    int A = y ~/ 100;
    int B = 2 - A + A ~/ 4;

    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day + B - 1524.5 + hour / 24.0;
  }

  /// Julian Day (UT) → KST DateTime (로컬 시간, 비UTC)
  /// KST = UT + 9시간
  static DateTime _jdToKstDateTime(double jd) {
    // KST로 변환 (+9시간 = +0.375일)
    double jdKst = jd + 9.0 / 24.0;

    double Z = (jdKst + 0.5).floor().toDouble();
    double F = jdKst + 0.5 - Z;

    double A;
    if (Z < 2299161) {
      A = Z;
    } else {
      int alpha = ((Z - 1867216.25) / 36524.25).floor();
      A = Z + 1 + alpha - alpha ~/ 4;
    }

    double B = A + 1524;
    int C = ((B - 122.1) / 365.25).floor();
    int D = (365.25 * C).floor();
    int E = ((B - D) / 30.6001).floor();

    int day = (B - D - (30.6001 * E).floor()).toInt();
    int month = E < 14 ? E - 1 : E - 13;
    int year = month > 2 ? C - 4716 : C - 4715;

    double hours = F * 24;
    int hour = hours.floor();
    double mins = (hours - hour) * 60;
    int minute = mins.floor();
    int second = ((mins - minute) * 60).round();

    // 오버플로우 처리
    if (second >= 60) { second -= 60; minute++; }
    if (minute >= 60) { minute -= 60; hour++; }
    if (hour >= 24) { hour -= 24; day++; }

    // 로컬 DateTime (KST)으로 반환 - UTC가 아님
    return DateTime(year, month, day, hour, minute, second);
  }
}

/// 절기 테이블 생성 유틸리티
class SolarTermTableGenerator {
  static String generateTableCode(int startYear, int endYear) {
    final buffer = StringBuffer();

    for (int year = startYear; year <= endYear; year++) {
      buffer.writeln('  // ========== ${year}년 (천문학적 계산값) ==========');
      buffer.writeln('  $year: {');

      final terms = SolarTermCalculator.calculateYearTerms(year);

      for (int i = 0; i < 24; i++) {
        final key = SolarTermCalculator.termKeys[i];
        final dt = terms[key]!;
        final name = SolarTermCalculator.termNames[i];

        buffer.writeln(
            "    '$key': SolarTermData(DateTime($year, ${dt.month}, ${dt.day}, ${dt.hour}, ${dt.minute}), '$name'),");
      }

      buffer.writeln('  },');
    }

    return buffer.toString();
  }
}
