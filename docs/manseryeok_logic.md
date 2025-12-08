# 만세력(萬歲曆) 로직 구조

> 만톡 앱의 사주팔자 계산 엔진 기술 문서
> 작성일: 2025-12-08

---

## 1. 개요

만세력은 사주팔자(四柱八字)를 계산하기 위한 역법 시스템입니다.
생년월일시를 입력받아 **년주, 월주, 일주, 시주** 4개의 기둥을 계산합니다.

### 핵심 개념

| 용어 | 설명 |
|------|------|
| **천간(天干)** | 10개: 갑을병정무기경신임계 |
| **지지(地支)** | 12개: 자축인묘진사오미신유술해 |
| **60갑자** | 천간(10) × 지지(12)의 최소공배수 = 60개 조합 |
| **사주팔자** | 4개 기둥 × 2글자(천간+지지) = 8글자 |

---

## 2. 폴더 구조

```
frontend/lib/features/saju_chart/
│
├── data/
│   ├── constants/                    # 상수 데이터
│   │   ├── cheongan_jiji.dart        # ⭐ 핵심: 천간/지지/오행 (JSON 기반)
│   │   ├── gapja_60.dart             # 60갑자 리스트
│   │   ├── solar_term_table.dart     # 24절기 시각 테이블
│   │   ├── dst_periods.dart          # 서머타임 적용 기간
│   │   ├── jijanggan_table.dart      # 지장간 테이블
│   │   ├── sipsin_relations.dart     # 십신 관계 테이블
│   │   └── lunar_data/               # 음력 데이터 (1900-2100)
│   │       ├── lunar_table.dart
│   │       ├── lunar_table_1900_1949.dart
│   │       ├── lunar_table_1950_1999.dart
│   │       ├── lunar_table_2000_2050.dart
│   │       └── lunar_table_2051_2100.dart
│   │
│   └── models/                       # JSON 모델 클래스
│       ├── cheongan_model.dart       # 천간 모델
│       ├── jiji_model.dart           # 지지 모델
│       ├── oheng_model.dart          # 오행 모델
│       ├── pillar_model.dart         # 기둥 모델
│       └── saju_chart_model.dart     # 사주 차트 모델
│
├── domain/
│   ├── entities/                     # 핵심 엔티티
│   │   ├── pillar.dart               # 기둥 (천간+지지 한 쌍)
│   │   ├── saju_chart.dart           # 사주 차트 (4기둥)
│   │   ├── lunar_date.dart           # 음력 날짜
│   │   ├── solar_term.dart           # 24절기 enum
│   │   ├── daeun.dart                # 대운
│   │   ├── yongsin.dart              # 용신
│   │   ├── gyeokguk.dart             # 격국
│   │   ├── sinsal.dart               # 신살
│   │   ├── day_strength.dart         # 일간 강약
│   │   └── saju_analysis.dart        # 통합 분석 결과
│   │
│   └── services/                     # 계산 서비스
│       ├── saju_calculation_service.dart   # ⭐ 메인: 사주 계산
│       ├── lunar_solar_converter.dart      # 음양력 변환
│       ├── solar_term_service.dart         # 절기 계산
│       ├── true_solar_time_service.dart    # 진태양시 보정
│       ├── dst_service.dart                # 서머타임 보정
│       ├── jasi_service.dart               # 야자시/조자시 처리
│       ├── yongsin_service.dart            # 용신 분석
│       ├── daeun_service.dart              # 대운 계산
│       ├── day_strength_service.dart       # 일간 강약 판단
│       ├── gyeokguk_service.dart           # 격국 판단
│       ├── sinsal_service.dart             # 신살 계산
│       └── saju_analysis_service.dart      # 통합 분석
│
└── presentation/
    ├── providers/                    # Riverpod 상태관리
    │   ├── saju_chart_provider.dart
    │   └── saju_chart_provider.g.dart
    ├── screens/
    │   └── saju_chart_screen.dart
    └── widgets/
        ├── pillar_display.dart       # 기둥 표시 (한자+한글)
        ├── pillar_column_widget.dart # 기둥 컬럼
        ├── saju_mini_card.dart       # 미니 카드
        ├── saju_detail_sheet.dart    # 상세 바텀시트
        └── saju_info_header.dart     # 정보 헤더
```

---

## 3. 데이터 구조 (Dictionary Map)

### 3.1 JSON 기반 통합 데이터

`cheongan_jiji.dart`에서 모든 천간/지지/오행 데이터를 JSON으로 관리합니다.

```json
{
  "cheongan": [
    {"hangul": "갑", "hanja": "甲", "oheng": "목", "eum_yang": "양", "order": 0},
    {"hangul": "을", "hanja": "乙", "oheng": "목", "eum_yang": "음", "order": 1},
    {"hangul": "병", "hanja": "丙", "oheng": "화", "eum_yang": "양", "order": 2},
    {"hangul": "정", "hanja": "丁", "oheng": "화", "eum_yang": "음", "order": 3},
    {"hangul": "무", "hanja": "戊", "oheng": "토", "eum_yang": "양", "order": 4},
    {"hangul": "기", "hanja": "己", "oheng": "토", "eum_yang": "음", "order": 5},
    {"hangul": "경", "hanja": "庚", "oheng": "금", "eum_yang": "양", "order": 6},
    {"hangul": "신", "hanja": "辛", "oheng": "금", "eum_yang": "음", "order": 7},
    {"hangul": "임", "hanja": "壬", "oheng": "수", "eum_yang": "양", "order": 8},
    {"hangul": "계", "hanja": "癸", "oheng": "수", "eum_yang": "음", "order": 9}
  ],
  "jiji": [
    {"hangul": "자", "hanja": "子", "oheng": "수", "eum_yang": "양", "animal": "쥐",    "month": 11, "hour_start": 23, "hour_end": 1,  "order": 0},
    {"hangul": "축", "hanja": "丑", "oheng": "토", "eum_yang": "음", "animal": "소",    "month": 12, "hour_start": 1,  "hour_end": 3,  "order": 1},
    {"hangul": "인", "hanja": "寅", "oheng": "목", "eum_yang": "양", "animal": "호랑이", "month": 1,  "hour_start": 3,  "hour_end": 5,  "order": 2},
    {"hangul": "묘", "hanja": "卯", "oheng": "목", "eum_yang": "음", "animal": "토끼",  "month": 2,  "hour_start": 5,  "hour_end": 7,  "order": 3},
    {"hangul": "진", "hanja": "辰", "oheng": "토", "eum_yang": "양", "animal": "용",    "month": 3,  "hour_start": 7,  "hour_end": 9,  "order": 4},
    {"hangul": "사", "hanja": "巳", "oheng": "화", "eum_yang": "음", "animal": "뱀",    "month": 4,  "hour_start": 9,  "hour_end": 11, "order": 5},
    {"hangul": "오", "hanja": "午", "oheng": "화", "eum_yang": "양", "animal": "말",    "month": 5,  "hour_start": 11, "hour_end": 13, "order": 6},
    {"hangul": "미", "hanja": "未", "oheng": "토", "eum_yang": "음", "animal": "양",    "month": 6,  "hour_start": 13, "hour_end": 15, "order": 7},
    {"hangul": "신", "hanja": "申", "oheng": "금", "eum_yang": "양", "animal": "원숭이", "month": 7,  "hour_start": 15, "hour_end": 17, "order": 8},
    {"hangul": "유", "hanja": "酉", "oheng": "금", "eum_yang": "음", "animal": "닭",    "month": 8,  "hour_start": 17, "hour_end": 19, "order": 9},
    {"hangul": "술", "hanja": "戌", "oheng": "토", "eum_yang": "양", "animal": "개",    "month": 9,  "hour_start": 19, "hour_end": 21, "order": 10},
    {"hangul": "해", "hanja": "亥", "oheng": "수", "eum_yang": "음", "animal": "돼지",  "month": 10, "hour_start": 21, "hour_end": 23, "order": 11}
  ],
  "oheng": [
    {"name": "목", "hanja": "木", "color": "#4CAF50", "season": "봄",     "direction": "동"},
    {"name": "화", "hanja": "火", "color": "#F44336", "season": "여름",   "direction": "남"},
    {"name": "토", "hanja": "土", "color": "#FF9800", "season": "환절기", "direction": "중앙"},
    {"name": "금", "hanja": "金", "color": "#FFD700", "season": "가을",   "direction": "서"},
    {"name": "수", "hanja": "水", "color": "#2196F3", "season": "겨울",   "direction": "북"}
  ]
}
```

### 3.2 싱글톤 데이터 저장소

```dart
class CheonganJijiData {
  static CheonganJijiData? _instance;

  // 리스트 데이터
  final List<CheonganModel> cheonganList;  // 천간 10개
  final List<JijiModel> jijiList;          // 지지 12개
  final List<OhengModel> ohengList;        // 오행 5개

  // O(1) 조회용 Map 캐시
  final Map<String, CheonganModel> _cheonganByHangul;  // '갑' → Model
  final Map<String, CheonganModel> _cheonganByHanja;   // '甲' → Model
  final Map<String, JijiModel> _jijiByHangul;          // '자' → Model
  final Map<String, JijiModel> _jijiByHanja;           // '子' → Model
  final Map<String, OhengModel> _ohengByName;          // '목' → Model

  // 싱글톤 접근
  static CheonganJijiData get instance {
    _instance ??= _parseFromJson(_cheonganJijiJson);
    return _instance!;
  }
}
```

### 3.3 제공되는 API

#### 리스트 API
```dart
List<String> cheongan  // ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계']
List<String> jiji      // ['자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해']
```

#### Map API (한글 키 → 값)
```dart
Map<String, String> cheonganHanja   // {'갑': '甲', '을': '乙', ...}
Map<String, String> cheonganOheng   // {'갑': '목', '을': '목', ...}
Map<String, String> cheonganEumYang // {'갑': '양', '을': '음', ...}

Map<String, String> jijiHanja       // {'자': '子', '축': '丑', ...}
Map<String, String> jijiOheng       // {'자': '수', '축': '토', ...}
Map<String, String> jijiAnimal      // {'자': '쥐', '축': '소', ...}
Map<String, String> jijiEumYang     // {'자': '양', '축': '음', ...}

Map<String, String> ohengHanja      // {'목': '木', '화': '火', ...}
Map<String, String> ohengColor      // {'목': '#4CAF50', ...}
```

#### 조회 메서드
```dart
// 한글 → 모델
CheonganModel? getCheonganByHangul(String hangul)
JijiModel? getJijiByHangul(String hangul)

// 한자 → 모델 (역방향 조회)
CheonganModel? getCheonganByHanja(String hanja)
JijiModel? getJijiByHanja(String hanja)

// 인덱스 → 모델
CheonganModel getCheonganByIndex(int index)  // index % 10
JijiModel getJijiByIndex(int index)          // index % 12

// 시간 → 지지
JijiModel? getJijiByHour(int hour)  // 23시 → 자(子)

// 헬퍼 함수
String? getOheng(String char, {bool isCheongan = true})
String? toHanja(String hangul, {bool isCheongan = true})
String? toHangul(String hanja, {bool isCheongan = true})
int? getCheonganIndex(String hangul)
int? getJijiIndex(String hangul)
```

---

## 4. 사주 계산 알고리즘

### 4.1 계산 흐름도

```
┌─────────────────────────────────────────────────────────────┐
│                        입력                                  │
│  - 생년월일시 (DateTime)                                     │
│  - 출생도시 (String)                                         │
│  - 음력/양력 여부                                            │
│  - 야자시/조자시 모드                                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    1단계: 날짜 보정                          │
├─────────────────────────────────────────────────────────────┤
│  ① 음력 → 양력 변환 (LunarSolarConverter)                   │
│  ② 서머타임 보정 (DSTService)                               │
│     - 1948-1951, 1955-1960, 1987-1988 기간                  │
│  ③ 진태양시 보정 (TrueSolarTimeService)                     │
│     - 서울: -30분, 부산: -26분 등                            │
│  ④ 야자시/조자시 처리 (JasiService)                         │
│     - 23:00-01:00 구간 날짜 처리                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    2단계: 4주 계산                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 년주(年柱) 계산                                      │    │
│  │ - 입춘 기준: 입춘 이전이면 전년도                    │    │
│  │ - 년간: (년도 - 4) % 10                              │    │
│  │ - 년지: (년도 - 4) % 12                              │    │
│  └─────────────────────────────────────────────────────┘    │
│                              │                               │
│                              ▼                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 월주(月柱) 계산                                      │    │
│  │ - 절기 기준: 절입시간에 따라 월 결정                 │    │
│  │ - 월간: 년간에 따른 시작점 + 월 인덱스               │    │
│  │   갑기년→병인월, 을경년→무인월, 병신년→경인월       │    │
│  │   정임년→임인월, 무계년→갑인월                       │    │
│  │ - 월지: 인월(1월)부터 시작                           │    │
│  └─────────────────────────────────────────────────────┘    │
│                              │                               │
│                              ▼                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 일주(日柱) 계산                                      │    │
│  │ - 기준일: 1900년 1월 1일                             │    │
│  │ - 기준 인덱스: 10 (검증 완료)                        │    │
│  │ - 일수 차이로 60갑자 순환 계산                       │    │
│  │ - 간지 분리: index % 10, index % 12                  │    │
│  └─────────────────────────────────────────────────────┘    │
│                              │                               │
│                              ▼                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 시주(時柱) 계산                                      │    │
│  │ - 2시간 단위로 시지 결정                             │    │
│  │ - 시간: 일간에 따른 시작점                           │    │
│  │   갑기일→갑자시, 을경일→병자시, 병신일→무자시       │    │
│  │   정임일→경자시, 무계일→임자시                       │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        출력                                  │
│  SajuChart {                                                 │
│    yearPillar:  Pillar(gan: '경', ji: '오')  // 년주        │
│    monthPillar: Pillar(gan: '무', ji: '인')  // 월주        │
│    dayPillar:   Pillar(gan: '신', ji: '해')  // 일주 (나)   │
│    hourPillar:  Pillar(gan: '임', ji: '진')  // 시주        │
│  }                                                           │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 핵심 계산 공식

#### 년주 계산
```dart
// 입춘 전이면 전년도로 계산
int year = birthDateTime.year;
if (birthDateTime.isBefore(ipchunDateTime)) {
  year = year - 1;
}

// 년간: (년도 - 4) % 10
final ganIndex = (year - 4) % 10;

// 년지: (년도 - 4) % 12
final jiIndex = (year - 4) % 12;

return Pillar(gan: cheongan[ganIndex], ji: jiji[jiIndex]);
```

#### 월주 계산
```dart
// 월간 시작점 (년간에 따라 결정)
// 갑기년 → 병인월 시작 (병=2)
// 을경년 → 무인월 시작 (무=4)
// 병신년 → 경인월 시작 (경=6)
// 정임년 → 임인월 시작 (임=8)
// 무계년 → 갑인월 시작 (갑=0)
final yearGanIndex = cheongan.indexOf(yearPillar.gan);
final monthGanStart = ((yearGanIndex % 5) * 2 + 2) % 10;
final ganIndex = (monthGanStart + monthIndex) % 10;

// 월지: 인월(1월)부터 시작 → index 2
final jiIndex = (monthIndex + 2) % 12;
```

#### 일주 계산
```dart
// 기준일: 1900년 1월 1일
final baseDate = DateTime(1900, 1, 1);
const baseDayIndex = 10;  // 포스텔러 검증 완료

// 일수 차이 계산
final daysDiff = birthDate.difference(baseDate).inDays;

// 60갑자 순환
int dayIndex = (baseDayIndex + daysDiff) % 60;
if (dayIndex < 0) dayIndex += 60;

// 천간과 지지 분리
final ganIndex = dayIndex % 10;
final jiIndex = dayIndex % 12;
```

#### 시주 계산
```dart
// 시지 결정 (2시간 단위)
// 자시: 23:00-01:00 (index 0)
// 축시: 01:00-03:00 (index 1)
// ...
final jiIndex = ((hour + 1) ~/ 2) % 12;

// 시간 시작점 (일간에 따라 결정)
// 갑기일 → 갑자시 시작 (갑=0)
// 을경일 → 병자시 시작 (병=2)
// 병신일 → 무자시 시작 (무=4)
// 정임일 → 경자시 시작 (경=6)
// 무계일 → 임자시 시작 (임=8)
final dayGanIndex = cheongan.indexOf(dayPillar.gan);
final hourGanStart = (dayGanIndex % 5) * 2;
final ganIndex = (hourGanStart + jiIndex) % 10;
```

---

## 5. 보정 서비스

### 5.1 진태양시 보정 (TrueSolarTimeService)

한국 표준시(KST)는 동경 135도 기준이지만, 실제 한반도는 약 127도입니다.
지역별 경도 차이에 따른 시간 보정이 필요합니다.

```dart
// 도시별 보정값 (분)
final Map<String, int> cityCorrections = {
  '서울': -30,
  '부산': -26,
  '대구': -27,
  '인천': -31,
  '광주': -33,
  '대전': -30,
  '울산': -25,
  '세종': -30,
  '제주': -35,
  // ... 25개 도시
};
```

### 5.2 서머타임 보정 (DSTService)

한국의 서머타임(일광절약시간제) 적용 기간:

| 기간 | 적용 |
|------|------|
| 1948-1951 | +1시간 |
| 1955-1960 | +1시간 |
| 1987-1988 | +1시간 |

### 5.3 야자시/조자시 처리 (JasiService)

23:00-01:00 자시(子時) 구간의 날짜 처리:

| 모드 | 설명 |
|------|------|
| **야자시** | 23:00-24:00을 당일로 계산 (기본값) |
| **조자시** | 00:00-01:00을 익일로 계산 |

---

## 6. 엔티티 구조

### 6.1 Pillar (기둥)

```dart
class Pillar {
  final String gan;  // 천간 (갑, 을, 병, ...)
  final String ji;   // 지지 (자, 축, 인, ...)

  // 계산 속성
  String get fullName => '$gan$ji';           // "갑자"
  String get hanja => '${cheonganHanja[gan]}${jijiHanja[ji]}';  // "甲子"
  String get ganOheng => cheonganOheng[gan];  // "목"
  String get jiOheng => jijiOheng[ji];        // "수"
  String get jiAnimal => jijiAnimal[ji];      // "쥐"
}
```

### 6.2 SajuChart (사주 차트)

```dart
class SajuChart {
  final Pillar yearPillar;   // 년주
  final Pillar monthPillar;  // 월주
  final Pillar dayPillar;    // 일주 (일간이 "나")
  final Pillar? hourPillar;  // 시주 (출생시간 모르면 null)

  final DateTime birthDateTime;      // 입력된 출생일시
  final DateTime correctedDateTime;  // 보정된 출생일시
  final String birthCity;            // 출생지
  final bool isLunarCalendar;        // 음력 여부

  // 계산 속성
  String get dayMaster => dayPillar.gan;  // 일간 (나)
  String get fullSaju;       // "갑자 을축 병인 정묘"
  String get fullSajuHanja;  // "甲子 乙丑 丙寅 丁卯"
}
```

---

## 7. 검증 결과

### 7.1 포스텔러 검증

| 생년월일 | 시간 | 도시 | 년주 | 월주 | 일주 | 시주 | 결과 |
|----------|------|------|------|------|------|------|------|
| 1990-02-15 | 09:30 | 서울 | 경오 | 무인 | 신해 | 임진 | ✅ |
| 1997-11-29 | 08:03 | 부산 | 정축 | 신해 | 을해 | 경진 | ✅ |

### 7.2 데이터 정확도

| 항목 | 개수 | 상태 |
|------|------|------|
| 천간 | 10개 | ✅ 갑을병정무기경신임계 |
| 지지 | 12개 | ✅ 자축인묘진사오미신유술해 |
| 60갑자 | 60개 | ✅ 갑자→계해 순환 |
| 오행 | 5개 | ✅ 목화토금수 |
| 한자 매핑 | 22개 | ✅ 양방향 조회 가능 |
| 음양 매핑 | 22개 | ✅ 홀수=양, 짝수=음 |
| 시간대 매핑 | 12개 | ✅ 자시(23-1)~해시(21-23) |
| 띠 매핑 | 12개 | ✅ 쥐~돼지 |

---

## 8. 사용 예시

### 8.1 사주 계산

```dart
final service = SajuCalculationService();

final chart = service.calculate(
  birthDateTime: DateTime(1990, 2, 15, 9, 30),
  birthCity: '서울',
  isLunarCalendar: false,
  jasiMode: JasiMode.yaJasi,
);

print(chart.fullSaju);      // "경오 무인 신해 임진"
print(chart.fullSajuHanja); // "庚午 戊寅 辛亥 壬辰"
print(chart.dayMaster);     // "신" (일간, 나)
```

### 8.2 천간/지지 조회

```dart
// 한글 → 한자
final hanja = cheonganHanja['갑'];  // '甲'

// 한자 → 모델 (역방향)
final model = CheonganJijiData.instance.getCheonganByHanja('甲');
print(model?.hangul);  // '갑'
print(model?.oheng);   // '목'
print(model?.eumYang); // '양'

// 시간 → 지지
final jiji = CheonganJijiData.instance.getJijiByHour(23);
print(jiji?.hangul);  // '자'
print(jiji?.animal);  // '쥐'
```

---

## 9. 향후 확장

- [ ] 대운(大運) 계산 고도화
- [ ] 세운(歲運) 계산
- [ ] 합충형파해(合沖刑破害) 관계
- [ ] 십신(十神) 분석 고도화
- [ ] 격국(格局) 판단 고도화
- [ ] 용신(用神) 분석 고도화

---

## 10. 참고 자료

- 한국천문연구원 음양력 API
- 포스텔러 만세력 2.2 (레퍼런스 앱)
- Inflearn 만세력 강의
- GitHub: bikul-manseryeok 프로젝트
