# Manseryeok Calculator Agent (만세력 계산기)

> 사주팔자 계산의 모든 복잡한 로직을 처리하는 전문 에이전트

---

## 역할

생년월일시 입력을 받아 정확한 사주팔자(년주, 월주, 일주, 시주)를 계산

---

## 호출 시점

- 프로필 저장 시 사주 계산
- 채팅 세션 시작 시 사주 정보 조회
- 대운/세운 계산 필요 시

---

## 핵심 계산 모듈

### 1. 기초 데이터 (Constants)

```dart
// core/constants/saju_constants.dart

/// 천간 (天干) - 10개
const List<String> CHEONGAN = [
  '갑', '을', '병', '정', '무', '기', '경', '신', '임', '계'
];

/// 지지 (地支) - 12개
const List<String> JIJI = [
  '자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해'
];

/// 오행 매핑
const Map<String, String> OHENG = {
  '갑': '목', '을': '목',
  '병': '화', '정': '화',
  '무': '토', '기': '토',
  '경': '금', '신': '금',
  '임': '수', '계': '수',
  // 지지
  '인': '목', '묘': '목',
  '사': '화', '오': '화',
  '진': '토', '술': '토', '축': '토', '미': '토',
  '신': '금', '유': '금',
  '해': '수', '자': '수',
};

/// 60갑자
const List<String> GAPJA_60 = [
  '갑자', '을축', '병인', '정묘', '무진', '기사',
  '경오', '신미', '임신', '계유', '갑술', '을해',
  // ... 60개 전체
];
```

### 2. 음양력 변환

```dart
/// 음양력 변환 서비스
class LunarSolarConverter {
  /// 양력 → 음력
  LunarDate solarToLunar(DateTime solarDate);

  /// 음력 → 양력
  DateTime lunarToSolar(LunarDate lunarDate);

  /// 윤달 여부 확인
  bool isLeapMonth(int year, int month);
}

/// 음력 날짜 모델
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
}
```

### 3. 절입시간 (24절기)

```dart
/// 절기 계산 서비스
class SolarTermService {
  /// 해당 연도의 절기 시각 조회
  /// 천문연구원 API 또는 내장 테이블 사용
  Future<Map<SolarTerm, DateTime>> getSolarTerms(int year);

  /// 특정 날짜가 어느 월주에 속하는지 판단
  /// 절입시간 기준으로 월주 변경
  int getMonthPillarIndex(DateTime dateTime);
}

/// 24절기
enum SolarTerm {
  ipchun,    // 입춘 (1)
  usoo,      // 우수
  gyeongchip,// 경칩 (2)
  chunbun,   // 춘분
  cheongmyeong, // 청명 (3)
  gogu,      // 곡우
  ipha,      // 입하 (4)
  soman,     // 소만
  mangjong,  // 망종 (5)
  haji,      // 하지
  soseo,     // 소서 (6)
  daeseo,    // 대서
  ipchu,     // 입추 (7)
  cheoseo,   // 처서
  baekro,    // 백로 (8)
  chubeun,   // 추분
  hanro,     // 한로 (9)
  sanggang,  // 상강
  ipdong,    // 입동 (10)
  soseol,    // 소설
  daeseol,   // 대설 (11)
  dongji,    // 동지
  sohan,     // 소한 (12)
  daehan,    // 대한
}

/// 절기→월주 매핑 (절입 기준)
/// 입춘~경칩전 = 인월(1월)
/// 경칩~청명전 = 묘월(2월)
/// ...
```

### 4. 진태양시 보정

```dart
/// 진태양시 계산 서비스
class TrueSolarTimeService {
  /// 지역별 경도 보정
  /// 한국 표준시(KST)는 동경 135도 기준
  /// 실제 한반도는 약 126~131도

  static const Map<String, double> CITY_LONGITUDE = {
    '서울': 126.98,
    '부산': 129.03,
    '대구': 128.60,
    '인천': 126.70,
    '광주': 126.85,
    '대전': 127.38,
    '울산': 129.31,
    '제주': 126.53,
    '창원': 128.68,
    // 기본값
    'default': 127.0,
  };

  /// 진태양시 계산
  /// 1. 경도 보정: (135 - 실제경도) × 4분
  /// 2. 균시차 적용 (선택적)
  DateTime calculateTrueSolarTime({
    required DateTime localTime,
    required String city,
    bool applyEquationOfTime = false,
  }) {
    final longitude = CITY_LONGITUDE[city] ?? CITY_LONGITUDE['default']!;
    final correction = (135 - longitude) * 4; // 분 단위
    return localTime.subtract(Duration(minutes: correction.round()));
  }
}
```

### 5. 서머타임 보정

```dart
/// 서머타임 보정 서비스
class DaylightSavingTimeService {
  /// 한국 서머타임 적용 기간
  static const List<DateRange> DST_PERIODS = [
    // 1948-1951
    DateRange(DateTime(1948, 6, 1), DateTime(1948, 9, 12)),
    DateRange(DateTime(1949, 4, 3), DateTime(1949, 9, 10)),
    DateRange(DateTime(1950, 4, 1), DateTime(1950, 9, 9)),
    DateRange(DateTime(1951, 5, 6), DateTime(1951, 9, 8)),
    // 1955-1960
    DateRange(DateTime(1955, 5, 5), DateTime(1955, 9, 8)),
    DateRange(DateTime(1956, 5, 20), DateTime(1956, 9, 29)),
    DateRange(DateTime(1957, 5, 5), DateTime(1957, 9, 21)),
    DateRange(DateTime(1958, 5, 4), DateTime(1958, 9, 20)),
    DateRange(DateTime(1959, 5, 3), DateTime(1959, 9, 19)),
    DateRange(DateTime(1960, 5, 1), DateTime(1960, 9, 17)),
    // 1987-1988
    DateRange(DateTime(1987, 5, 10), DateTime(1987, 10, 10)),
    DateRange(DateTime(1988, 5, 8), DateTime(1988, 10, 8)),
  ];

  /// 서머타임 적용 여부 확인
  bool isDST(DateTime dateTime) {
    return DST_PERIODS.any((range) => range.contains(dateTime));
  }

  /// 서머타임 보정 (1시간 차감)
  DateTime adjustDST(DateTime dateTime) {
    if (isDST(dateTime)) {
      return dateTime.subtract(const Duration(hours: 1));
    }
    return dateTime;
  }
}
```

### 6. 야자시/조자시 처리

```dart
/// 자시 처리 서비스
enum JasiMode {
  yaJasi,  // 야자시: 23:00-24:00 당일
  joJasi,  // 조자시: 00:00-01:00 익일로 처리
}

class JasiService {
  /// 자시 시간대 판단 (23:00 - 01:00)
  bool isJasiHour(int hour) => hour == 23 || hour == 0;

  /// 야자시/조자시 모드에 따른 날짜 조정
  ///
  /// 야자시 모드 (전통):
  /// - 23:00-24:00 → 당일 자시
  /// - 00:00-01:00 → 익일 자시 (일주 변경)
  ///
  /// 조자시 모드 (현대):
  /// - 23:00-24:00 → 익일로 간주 (일주 변경)
  /// - 00:00-01:00 → 당일 자시
  DateTime adjustForJasi({
    required DateTime dateTime,
    required JasiMode mode,
  }) {
    final hour = dateTime.hour;

    if (mode == JasiMode.yaJasi) {
      // 야자시: 23시대는 당일, 0시대는 익일 처리
      if (hour == 0) {
        return dateTime.add(const Duration(days: 1));
      }
    } else {
      // 조자시: 23시대를 익일로 처리
      if (hour == 23) {
        return dateTime.add(const Duration(days: 1));
      }
    }
    return dateTime;
  }
}
```

---

## 핵심 계산: 사주팔자

### 년주 (年柱) 계산

```dart
/// 년주 계산
/// 절기 기준: 입춘 이후부터 새해
Pillar calculateYearPillar({
  required DateTime birthDateTime,
  required DateTime ipchunDateTime, // 해당 연도 입춘 시각
}) {
  // 입춘 전이면 전년도로 계산
  final year = birthDateTime.isBefore(ipchunDateTime)
      ? birthDateTime.year - 1
      : birthDateTime.year;

  // 년간 계산: (년도 - 4) % 10
  final ganIndex = (year - 4) % 10;

  // 년지 계산: (년도 - 4) % 12
  final jiIndex = (year - 4) % 12;

  return Pillar(
    gan: CHEONGAN[ganIndex],
    ji: JIJI[jiIndex],
  );
}
```

### 월주 (月柱) 계산

```dart
/// 월주 계산
/// 절기 기준: 절입시간에 따라 월 결정
Pillar calculateMonthPillar({
  required DateTime birthDateTime,
  required Map<SolarTerm, DateTime> solarTerms,
  required Pillar yearPillar,
}) {
  // 절입시간으로 월 결정 (1~12월)
  final monthIndex = _getMonthBySeasonTerm(birthDateTime, solarTerms);

  // 월간 계산: 년간에 따른 월간 시작점 + 월
  // 갑기년 → 병인월 시작 (병=2)
  // 을경년 → 무인월 시작 (무=4)
  // ...
  final yearGanIndex = CHEONGAN.indexOf(yearPillar.gan);
  final monthGanStart = (yearGanIndex % 5) * 2 + 2;
  final ganIndex = (monthGanStart + monthIndex - 1) % 10;

  // 월지: 인월(1월)부터 시작
  final jiIndex = (monthIndex + 1) % 12; // 인(2), 묘(3)...

  return Pillar(
    gan: CHEONGAN[ganIndex],
    ji: JIJI[jiIndex],
  );
}
```

### 일주 (日柱) 계산

```dart
/// 일주 계산
/// 만년력 테이블 또는 공식 사용
Pillar calculateDayPillar(DateTime birthDate) {
  // 기준일: 1900년 1월 1일 = 갑진일 (인덱스 40)
  final baseDate = DateTime(1900, 1, 1);
  final baseDayIndex = 40; // 갑진

  // 일수 차이 계산
  final daysDiff = birthDate.difference(baseDate).inDays;

  // 60갑자 순환
  final dayIndex = (baseDayIndex + daysDiff) % 60;

  return Pillar(
    gan: CHEONGAN[dayIndex % 10],
    ji: JIJI[dayIndex % 12],
  );
}
```

### 시주 (時柱) 계산

```dart
/// 시주 계산
Pillar calculateHourPillar({
  required int hour,
  required Pillar dayPillar,
}) {
  // 시지 결정 (2시간 단위)
  // 자시: 23:00-01:00 (index 0)
  // 축시: 01:00-03:00 (index 1)
  // ...
  final jiIndex = ((hour + 1) ~/ 2) % 12;

  // 시간 계산: 일간에 따른 시작점
  // 갑기일 → 갑자시 시작
  // 을경일 → 병자시 시작
  // 병신일 → 무자시 시작
  // 정임일 → 경자시 시작
  // 무계일 → 임자시 시작
  final dayGanIndex = CHEONGAN.indexOf(dayPillar.gan);
  final hourGanStart = (dayGanIndex % 5) * 2;
  final ganIndex = (hourGanStart + jiIndex) % 10;

  return Pillar(
    gan: CHEONGAN[ganIndex],
    ji: JIJI[jiIndex],
  );
}
```

---

## 통합 계산 서비스

```dart
/// 사주 계산 통합 서비스
class SajuCalculationService {
  final LunarSolarConverter _lunarConverter;
  final SolarTermService _solarTermService;
  final TrueSolarTimeService _trueSolarTimeService;
  final DaylightSavingTimeService _dstService;
  final JasiService _jasiService;

  /// 사주팔자 계산 (메인 메서드)
  Future<SajuChart> calculate({
    required DateTime birthDateTime,
    required String birthCity,
    required bool isLunarCalendar,
    bool isLeapMonth = false,
    JasiMode jasiMode = JasiMode.yaJasi,
  }) async {
    // 1. 음력이면 양력으로 변환
    DateTime solarDateTime = birthDateTime;
    if (isLunarCalendar) {
      solarDateTime = _lunarConverter.lunarToSolar(
        LunarDate(
          year: birthDateTime.year,
          month: birthDateTime.month,
          day: birthDateTime.day,
          isLeapMonth: isLeapMonth,
        ),
      );
    }

    // 2. 서머타임 보정
    solarDateTime = _dstService.adjustDST(solarDateTime);

    // 3. 진태양시 보정
    final trueSolarTime = _trueSolarTimeService.calculateTrueSolarTime(
      localTime: solarDateTime,
      city: birthCity,
    );

    // 4. 야자시/조자시 처리
    final adjustedDateTime = _jasiService.adjustForJasi(
      dateTime: trueSolarTime,
      mode: jasiMode,
    );

    // 5. 절기 정보 조회
    final solarTerms = await _solarTermService.getSolarTerms(
      adjustedDateTime.year,
    );

    // 6. 사주 계산
    final yearPillar = calculateYearPillar(
      birthDateTime: adjustedDateTime,
      ipchunDateTime: solarTerms[SolarTerm.ipchun]!,
    );

    final monthPillar = calculateMonthPillar(
      birthDateTime: adjustedDateTime,
      solarTerms: solarTerms,
      yearPillar: yearPillar,
    );

    final dayPillar = calculateDayPillar(adjustedDateTime);

    final hourPillar = calculateHourPillar(
      hour: adjustedDateTime.hour,
      dayPillar: dayPillar,
    );

    return SajuChart(
      yearPillar: yearPillar,
      monthPillar: monthPillar,
      dayPillar: dayPillar,
      hourPillar: hourPillar,
      birthDateTime: birthDateTime,
      correctedDateTime: adjustedDateTime,
      birthCity: birthCity,
      isLunarCalendar: isLunarCalendar,
    );
  }
}
```

---

## 데이터 모델

```dart
/// 기둥 (년주/월주/일주/시주)
class Pillar {
  final String gan;  // 천간
  final String ji;   // 지지

  const Pillar({required this.gan, required this.ji});

  String get fullName => '$gan$ji';
  String get ganOheng => OHENG[gan]!;
  String get jiOheng => OHENG[ji]!;
}

/// 사주 차트
class SajuChart {
  final Pillar yearPillar;
  final Pillar monthPillar;
  final Pillar dayPillar;
  final Pillar hourPillar;
  final DateTime birthDateTime;
  final DateTime correctedDateTime;
  final String birthCity;
  final bool isLunarCalendar;

  const SajuChart({...});

  /// 사주팔자 문자열
  String get fullSaju =>
    '${yearPillar.fullName} ${monthPillar.fullName} '
    '${dayPillar.fullName} ${hourPillar.fullName}';
}
```

---

## 파일 구조

```
features/saju_chart/
├── data/
│   ├── constants/
│   │   ├── cheongan_jiji.dart      # 천간지지 상수
│   │   ├── gapja_60.dart           # 60갑자
│   │   ├── solar_term_table.dart   # 절기 시각 테이블
│   │   └── dst_periods.dart        # 서머타임 기간
│   ├── datasources/
│   │   └── solar_term_datasource.dart
│   ├── models/
│   │   ├── pillar_model.dart
│   │   └── saju_chart_model.dart
│   └── repositories/
│       └── saju_calculation_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── pillar.dart
│   │   ├── saju_chart.dart
│   │   └── lunar_date.dart
│   ├── services/
│   │   ├── lunar_solar_converter.dart
│   │   ├── solar_term_service.dart
│   │   ├── true_solar_time_service.dart
│   │   ├── dst_service.dart
│   │   ├── jasi_service.dart
│   │   └── saju_calculation_service.dart  # 통합
│   └── repositories/
│       └── saju_calculation_repository.dart
└── presentation/
    ├── providers/
    │   └── saju_chart_provider.dart
    └── widgets/
        ├── pillar_display.dart
        └── saju_summary_card.dart
```

---

## 검증 체크리스트

```
[ ] 천간지지 60갑자 순환 정확성
[ ] 절입시간 기준 월주 전환 정확성
[ ] 진태양시 보정 계산 검증
[ ] 서머타임 기간 데이터 정확성
[ ] 야자시/조자시 옵션 동작 확인
[ ] 음양력 변환 정확성
[ ] 1900-2100년 범위 테스트
[ ] 포스텔러 만세력과 결과 비교
```

---

## 연관 에이전트

- **04_model_generator**: Pillar, SajuChart Entity/Model 생성
- **03_provider_builder**: saju_chart_provider 생성
- **00_widget_tree_guard**: pillar_display 위젯 최적화 검증
- **08_shadcn_ui_builder**: 사주 표시 UI 컴포넌트
