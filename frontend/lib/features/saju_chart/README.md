# 사주팔자 계산 Feature (Saju Chart)

만세력 기반 사주팔자 계산 로직 구현

## 개요

생년월일시 정보를 입력받아 정확한 사주팔자(년주, 월주, 일주, 시주)를 계산합니다.

## 핵심 기능

### 1. 사주팔자 계산
- **년주**: 입춘 기준으로 년도 결정
- **월주**: 24절기 절입시간 기준
- **일주**: 1900년 1월 1일(갑진일) 기준 계산
- **시주**: 2시간 단위, 일간에 따른 시간 결정

### 2. 시간 보정
- **진태양시 보정**: 지역별 경도 차이 반영 (서울 -30분, 부산 -24분 등)
- **서머타임 보정**: 1948-1988년 한국 서머타임 기간 -1시간
- **야자시/조자시**: 23:00-01:00 자시 구간 처리

### 3. 음양력 변환
- 음력 → 양력 변환 (TODO: 정밀 알고리즘 필요)
- 윤달 처리

## 파일 구조

```
saju_chart/
├── data/
│   ├── constants/
│   │   ├── cheongan_jiji.dart      # 천간 10개, 지지 12개, 오행
│   │   ├── gapja_60.dart           # 60갑자 순환
│   │   ├── solar_term_table.dart   # 24절기 시각 테이블 (2024-2025)
│   │   └── dst_periods.dart        # 한국 서머타임 기간
│   └── models/
│       ├── pillar_model.dart       # Pillar JSON 직렬화
│       └── saju_chart_model.dart   # SajuChart JSON 직렬화
├── domain/
│   ├── entities/
│   │   ├── pillar.dart             # 기둥 (천간+지지)
│   │   ├── saju_chart.dart         # 사주 차트 (4기둥)
│   │   ├── lunar_date.dart         # 음력 날짜
│   │   └── solar_term.dart         # 24절기 enum
│   └── services/
│       ├── lunar_solar_converter.dart        # 음양력 변환
│       ├── solar_term_service.dart           # 절기 계산
│       ├── true_solar_time_service.dart      # 진태양시 보정
│       ├── dst_service.dart                  # 서머타임 보정
│       ├── jasi_service.dart                 # 자시 처리
│       └── saju_calculation_service.dart     # 통합 계산 서비스
├── saju_chart.dart              # Export 파일
├── example_usage.dart           # 사용 예제
└── README.md                    # 이 파일
```

## 사용 방법

### 기본 사용

```dart
import 'package:mantok/features/saju_chart/saju_chart.dart';

// 서비스 초기화
final sajuService = SajuCalculationService();

// 사주 계산
final sajuChart = sajuService.calculate(
  birthDateTime: DateTime(1990, 5, 15, 15, 30),
  birthCity: '서울',
  isLunarCalendar: false,
  jasiMode: JasiMode.yaJasi,
  birthTimeUnknown: false,
);

// 결과 사용
print(sajuChart.fullSaju);        // "갑오 기사 병인 병신"
print(sajuChart.dayMaster);       // "병" (일간 = 나)
print(sajuChart.yearPillar.hanja); // "甲午"
```

### 출생시간 모를 때

```dart
final sajuChart = sajuService.calculate(
  birthDateTime: DateTime(1985, 3, 20, 12, 0),
  birthCity: '부산',
  isLunarCalendar: false,
  birthTimeUnknown: true,  // 시주 계산 안 함
);

print(sajuChart.hasUnknownBirthTime); // true
print(sajuChart.hourPillar);          // null
```

### 음력 사주

```dart
final sajuChart = sajuService.calculate(
  birthDateTime: DateTime(1988, 4, 15, 10, 0),
  birthCity: '대전',
  isLunarCalendar: true,  // 음력
  isLeapMonth: false,
);
```

### JSON 직렬화

```dart
// 저장
final json = sajuChart.toJson();
await storage.save(json);

// 복원
final restored = SajuChart.fromJson(json);
```

## 계산 로직 상세

### 년주 계산
```
년간 = (연도 - 4) % 10
년지 = (연도 - 4) % 12
※ 입춘 전이면 전년도로 계산
```

### 월주 계산
```
월지 = 절입시간 기준 (인월=0, 묘월=1, ..., 축월=11)
월간 시작점 = (년간 % 5) × 2
월간 = (월간 시작점 + 월지) % 10
```

### 일주 계산
```
기준일: 1900.1.1 = 갑진일 (index 40)
일수 차이 = (출생일 - 기준일).inDays
일주 index = (40 + 일수 차이) % 60
```

### 시주 계산
```
시지 = ((시간 + 1) / 2) % 12
시간 시작점 = (일간 % 5) × 2
시간 = (시간 시작점 + 시지) % 10
```

## 주의사항

### 절기 테이블
현재 2024-2025년만 내장되어 있습니다. 전체 연도 지원을 위해서는:
- 한국천문연구원 API 연동
- 정밀 천문 계산 라이브러리 사용

### 음양력 변환
현재 임시 구현입니다. 정확한 변환을 위해서는:
- 한국천문연구원 음양력 API
- Korean Lunar Calendar 라이브러리
- 합삭(朔), 중기(中氣) 계산 알고리즘

### 진태양시 보정
- 균시차(Equation of Time) 적용은 선택 사항
- 기본적으로 경도 보정만 적용

## 검증 체크리스트

- [x] 천간지지 60갑자 순환 정확성
- [x] 절입시간 기준 월주 전환 (2024-2025)
- [x] 진태양시 보정 계산
- [x] 서머타임 기간 데이터
- [x] 야자시/조자시 옵션 동작
- [ ] 음양력 변환 정확성 (TODO)
- [ ] 1900-2100년 전체 범위 테스트
- [ ] 포스텔러 만세력과 결과 비교

## TODO

1. **음양력 변환 알고리즘 구현**
   - 한국천문연구원 API 연동
   - 또는 정밀 계산 라이브러리 통합

2. **절기 테이블 확장**
   - 전체 연도 지원 (1900-2100)
   - 천문연구원 API 또는 계산식

3. **대운(大運) 계산**
   - 10년 단위 운세 변화
   - 세운(歲運) 계산

4. **신살(神殺) 계산**
   - 길신, 흉신 판단
   - 특수 성분 분석

5. **테스트 케이스 작성**
   - 유명인 사주 검증
   - 경계 케이스 테스트

## 참고 자료

- 한국천문연구원 음양력 API
- Inflearn 만세력 강의
- GitHub: bikul-manseryeok
- 포스텔러 만세력 2.2 (레퍼런스 앱)

## 라이선스

MIT License - 만톡 프로젝트
