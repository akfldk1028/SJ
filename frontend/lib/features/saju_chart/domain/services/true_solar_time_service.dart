import 'dart:math' as math;

/// 진태양시 계산 서비스
/// 지역별 경도 차이에 따른 시간 보정
class TrueSolarTimeService {
  /// 한국 주요 도시의 경도
  /// 한국 표준시(KST)는 동경 135도 기준
  /// 실제 한반도는 약 126~131도
  static const Map<String, double> cityLongitude = {
    '서울': 126.98,
    '서울특별시': 126.98,
    '부산': 129.03,
    '부산광역시': 129.03,
    '대구': 128.60,
    '대구광역시': 128.60,
    '인천': 126.70,
    '인천광역시': 126.70,
    '광주': 126.85,
    '광주광역시': 126.85,
    '대전': 127.38,
    '대전광역시': 127.38,
    '울산': 129.31,
    '울산광역시': 129.31,
    '세종': 127.29,
    '세종특별자치시': 127.29,
    '제주': 126.53,
    '제주특별자치도': 126.53,
    '제주시': 126.53,
    '창원': 128.68,
    '창원시': 128.68,
    '수원': 127.03,
    '수원시': 127.03,
    '성남': 127.14,
    '성남시': 127.14,
    '고양': 126.83,
    '고양시': 126.83,
    '용인': 127.18,
    '용인시': 127.18,
    '청주': 127.49,
    '청주시': 127.49,
    '전주': 127.15,
    '전주시': 127.15,
    '포항': 129.37,
    '포항시': 129.37,
    '강릉': 128.88,
    '강릉시': 128.88,
    '춘천': 127.73,
    '춘천시': 127.73,
    '원주': 127.95,
    '원주시': 127.95,
    '제천': 128.19,
    '제천시': 128.19,
    '평택': 127.11,
    '평택시': 127.11,
    '김해': 128.89,
    '김해시': 128.89,
    '진주': 128.11,
    '진주시': 128.11,
    '여수': 127.66,
    '여수시': 127.66,
    '목포': 126.39,
    '목포시': 126.39,
    // ═══════════════════════════════════════════════════════════════
    // 해외 17개 지원 언어 수도 (경도)
    // ═══════════════════════════════════════════════════════════════
    '도쿄': 139.69,     // ja — UTC+9
    '오사카': 135.50,
    '베이징': 116.39,   // zh — UTC+8
    '상하이': 121.47,
    '하노이': 105.85,   // vi — UTC+7
    '방콕': 100.50,     // th — UTC+7
    '자카르타': 106.85,  // id — UTC+7
    '쿠알라룸푸르': 101.69, // ms — UTC+8
    '양곤': 96.17,      // my — UTC+6:30
    '파리': 2.35,       // fr — UTC+1
    '베를린': 13.40,    // de — UTC+1
    '마드리드': -3.70,  // es — UTC+1 (CET)
    '리스본': -9.14,    // pt — UTC+0
    '로마': 12.50,      // it — UTC+1
    '뉴델리': 77.21,    // hi — UTC+5:30
    '리야드': 46.72,    // ar — UTC+3
    '모스크바': 37.62,  // ru — UTC+3
    '런던': -0.12,      // en — UTC+0
    // 기본값
    'default': 127.0,
  };

  /// 도시별 표준 자오선 (시간대 기준 경도)
  /// 진태양시 = (표준자오선 - 도시경도) × 4분
  static const Map<String, double> cityStandardMeridian = {
    // 한국 도시: KST = UTC+9 = 135°E
    '서울': 135.0, '서울특별시': 135.0,
    '부산': 135.0, '부산광역시': 135.0,
    '대구': 135.0, '대구광역시': 135.0,
    '인천': 135.0, '인천광역시': 135.0,
    '광주': 135.0, '광주광역시': 135.0,
    '대전': 135.0, '대전광역시': 135.0,
    '울산': 135.0, '울산광역시': 135.0,
    '세종': 135.0, '세종특별자치시': 135.0,
    '제주': 135.0, '제주특별자치도': 135.0, '제주시': 135.0,
    '창원': 135.0, '창원시': 135.0,
    '수원': 135.0, '수원시': 135.0,
    '성남': 135.0, '성남시': 135.0,
    '고양': 135.0, '고양시': 135.0,
    '용인': 135.0, '용인시': 135.0,
    '청주': 135.0, '청주시': 135.0,
    '전주': 135.0, '전주시': 135.0,
    '포항': 135.0, '포항시': 135.0,
    '강릉': 135.0, '강릉시': 135.0,
    '춘천': 135.0, '춘천시': 135.0,
    '원주': 135.0, '원주시': 135.0,
    '제천': 135.0, '제천시': 135.0,
    '평택': 135.0, '평택시': 135.0,
    '김해': 135.0, '김해시': 135.0,
    '진주': 135.0, '진주시': 135.0,
    '여수': 135.0, '여수시': 135.0,
    '목포': 135.0, '목포시': 135.0,
    // 해외 수도
    '도쿄': 135.0, '오사카': 135.0,          // JST = UTC+9
    '베이징': 120.0, '상하이': 120.0,         // CST = UTC+8
    '하노이': 105.0,                          // ICT = UTC+7
    '방콕': 105.0,                            // ICT = UTC+7
    '자카르타': 105.0,                         // WIB = UTC+7
    '쿠알라룸푸르': 120.0,                      // MYT = UTC+8
    '양곤': 97.5,                             // MMT = UTC+6:30
    '파리': 15.0, '베를린': 15.0,              // CET = UTC+1
    '마드리드': 15.0, '로마': 15.0,             // CET = UTC+1
    '리스본': 0.0,                             // WET = UTC+0
    '뉴델리': 82.5,                            // IST = UTC+5:30
    '리야드': 45.0,                            // AST = UTC+3
    '모스크바': 45.0,                           // MSK = UTC+3
    '런던': 0.0,                               // GMT = UTC+0
  };

  /// locale → 기본 도시 매핑 (17개 언어 전부)
  static String defaultCityForLocale(String locale) {
    return switch (locale) {
      'ko' => '서울',
      'ja' => '도쿄',
      'zh' => '베이징',
      'vi' => '하노이',
      'th' => '방콕',
      'id' => '자카르타',
      'ms' => '쿠알라룸푸르',
      'my' => '양곤',
      'fr' => '파리',
      'de' => '베를린',
      'es' => '마드리드',
      'pt' => '리스본',
      'it' => '로마',
      'hi' => '뉴델리',
      'ar' => '리야드',
      'ru' => '모스크바',
      'en' => '런던',
      _ => '서울',
    };
  }

  /// 도시 별칭 매핑
  /// 짧은 이름 → 정식 이름 매핑
  static const Map<String, String> cityAliases = {
    '서울': '서울특별시',
    '부산': '부산광역시',
    '대구': '대구광역시',
    '인천': '인천광역시',
    '광주': '광주광역시',
    '대전': '대전광역시',
    '울산': '울산광역시',
    '세종': '세종특별자치시',
    '제주': '제주특별자치도',
    '제주시': '제주특별자치도',
    '창원': '창원시',
    '수원': '수원시',
    '성남': '성남시',
    '고양': '고양시',
    '용인': '용인시',
    '청주': '청주시',
    '전주': '전주시',
    '포항': '포항시',
    '강릉': '강릉시',
    '춘천': '춘천시',
    '원주': '원주시',
    '제천': '제천시',
    '평택': '평택시',
    '김해': '김해시',
    '진주': '진주시',
    '여수': '여수시',
    '목포': '목포시',
  };

  /// 검색 가능한 도시 목록 (중복 제거, 표시용)
  static List<String> get searchableCities {
    // 광역시/도 우선, 그 다음 시 단위
    final priorityOrder = [
      '서울특별시',
      '부산광역시',
      '대구광역시',
      '인천광역시',
      '광주광역시',
      '대전광역시',
      '울산광역시',
      '세종특별자치시',
      '제주특별자치도',
      '수원시',
      '성남시',
      '고양시',
      '용인시',
      '창원시',
      '청주시',
      '전주시',
      '포항시',
      '강릉시',
      '춘천시',
      '원주시',
      '제천시',
      '평택시',
      '김해시',
      '진주시',
      '여수시',
      '목포시',
    ];
    return priorityOrder;
  }

  /// 도시명 검색 (부분 매칭 + 별칭 지원)
  ///
  /// "부산" 입력 → ["부산광역시"] 반환
  /// "시" 입력 → ["부산광역시", "서울특별시", ...] 반환
  static List<String> searchCities(String query) {
    if (query.isEmpty) {
      return searchableCities;
    }

    final normalizedQuery = query.trim().toLowerCase();
    final results = <String>[];

    // 1. 별칭 검색 (정확 매칭 우선)
    for (final entry in cityAliases.entries) {
      if (entry.key.toLowerCase() == normalizedQuery) {
        if (!results.contains(entry.value)) {
          results.add(entry.value);
        }
      }
    }

    // 2. 부분 매칭
    for (final city in searchableCities) {
      if (city.toLowerCase().contains(normalizedQuery) && !results.contains(city)) {
        results.add(city);
      }
    }

    // 3. 별칭 부분 매칭
    for (final entry in cityAliases.entries) {
      if (entry.key.toLowerCase().contains(normalizedQuery) &&
          !results.contains(entry.value)) {
        results.add(entry.value);
      }
    }

    return results;
  }

  /// 기본 표준 경도 (동경 135도, KST)
  static const double standardLongitude = 135.0;

  /// 진태양시 계산
  /// 1. 경도 보정: (표준자오선 - 실제경도) × 4분
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
    final meridian = cityStandardMeridian[city] ?? standardLongitude;

    // 경도 보정 계산
    // 경도 1도 차이 = 4분 시간 차이
    final correctionMinutes = (meridian - longitude) * 4;

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
    final b = (360.0 / 365.0) * (dayOfYear - 81) * (math.pi / 180.0);

    final equationMinutes =
        9.87 * math.sin(2 * b) - 7.53 * math.cos(b) - 1.5 * math.sin(b);

    return equationMinutes;
  }

  /// 도시명으로 경도 조회
  static double getLongitude(String city) {
    return cityLongitude[city] ?? cityLongitude['default']!;
  }

  /// 경도 보정 시간 계산 (분 단위)
  static double getLongitudeCorrectionMinutes(String city) {
    final longitude = getLongitude(city);
    final meridian = cityStandardMeridian[city] ?? standardLongitude;
    return (meridian - longitude) * 4;
  }

  /// 도시명 정규화 (별칭 → 정식 이름)
  static String normalizeCity(String city) {
    return cityAliases[city] ?? city;
  }
}

