# 운세 프롬프트 설계 문서 v1.0

> **작성일**: 2026-01-18
> **담당**: JH_AI
> **상태**: 설계 완료, 구현 대기

---

## 1. 개요

### 1.1 목표
saju_base(평생운세)를 **기반 데이터**로 활용하여 3가지 새 운세 분석 추가:

| # | 프롬프트 | summary_type | 용도 |
|---|---------|--------------|------|
| 1 | **2026 신년운세** | `yearly_fortune_2026` | 2026년 전체 운세 |
| 2 | **이번달 운세** | `monthly_fortune` | 현재 월 운세 |
| 3 | **다시보는 2025** | `yearly_fortune_2025` | 2025년 회고 운세 |

### 1.2 핵심 원칙
```
┌─────────────────────────────────────────────────────────────┐
│                    saju_base (GPT-5.2)                      │
│                      평생운세 (기반)                          │
│    성격, 적성, 재물운, 건강운, 결혼운 등 종합 분석            │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            │ content 참조
                            ▼
    ┌───────────────────────┼───────────────────────┐
    │                       │                       │
    ▼                       ▼                       ▼
┌─────────┐          ┌─────────┐           ┌─────────┐
│ 2026년  │          │ 이번달  │           │ 2025년  │
│ 신년운세 │          │  운세   │           │  회고   │
│ GPT-5-mini│         │GPT-5-mini│          │GPT-5-mini│
└─────────┘          └─────────┘           └─────────┘
```

---

## 2. 모델 선택

### 2.1 GPT-5-mini 채택 이유

| 항목 | GPT-5.2 (현재 saju_base) | GPT-5-mini (새 프롬프트) |
|------|-------------------------|-------------------------|
| **Input** | $1.75 / 1M | **$0.25 / 1M** |
| **Output** | $14.00 / 1M | **$2.00 / 1M** |
| **성능** | 100% | 80% (충분) |
| **속도** | 100-150초 | **5-15초** |
| **용도** | 복잡한 원국 분석 | saju_base 기반 요약/확장 |

**결론**: saju_base가 이미 상세 분석을 완료했으므로, 파생 운세는 GPT-5-mini로 충분.

### 2.2 ai_constants.dart 추가 항목

```dart
// OpenAIModels 클래스에 추가
static const String gpt5Mini = 'gpt-5-mini';

// OpenAIPricing 클래스에 추가
static const double gpt5MiniInput = 0.25;
static const double gpt5MiniOutput = 2.00;
static const double gpt5MiniCached = 0.025; // 90% 할인
```

---

## 3. 새 SummaryType 정의

```dart
// ai_constants.dart - SummaryType 클래스에 추가

/// 2026년 신년운세
/// - 연 1회 생성 (1월)
/// - saju_base 기반 확장
static const String yearlyFortune2026 = 'yearly_fortune_2026';

/// 이번달 운세
/// - 월 1회 생성 (매월 1일)
/// - saju_base + 월운 분석
static const String monthlyFortune = 'monthly_fortune';

/// 2025년 회고 운세
/// - 1회성 (과거 분석)
/// - saju_base 기반 회고
static const String yearlyFortune2025 = 'yearly_fortune_2025';
```

---

## 4. 파일 구조

```
frontend/lib/AI/
├── core/
│   └── ai_constants.dart          # [수정] GPT-5-mini 추가, SummaryType 추가
│
├── prompts/
│   ├── prompt_template.dart       # [기존] 베이스 클래스
│   ├── saju_base_prompt.dart      # [기존] 평생운세 (GPT-5.2)
│   ├── daily_fortune_prompt.dart  # [기존] 일운 (Gemini)
│   │
│   ├── yearly_fortune_2026_prompt.dart  # [신규] 2026 신년운세
│   ├── monthly_fortune_prompt.dart      # [신규] 이번달 운세
│   └── yearly_fortune_2025_prompt.dart  # [신규] 2025 회고
│
├── data/
│   ├── queries.dart               # [수정] 캐시 조회 메서드 추가
│   └── mutations.dart             # [수정] 저장 메서드 추가
│
└── services/
    └── fortune_analysis_service.dart  # [신규] 운세 분석 전용 서비스
```

---

## 5. 프롬프트 상세 설계

### 5.1 공통 입력 데이터

모든 새 프롬프트는 saju_base의 content를 **필수 입력**으로 받음:

```dart
class FortuneInputData {
  // 기본 프로필 정보
  final String profileName;
  final String birthDate;
  final String gender;

  // saju_base 분석 결과 (핵심!)
  final Map<String, dynamic> sajuBaseContent;

  // 만세력 원본 (saju_origin)
  final Map<String, dynamic> sajuOrigin;

  // 대상 기간 (년/월)
  final int targetYear;
  final int? targetMonth;  // 월운일 때만
}
```

### 5.2 프롬프트별 상세

---

#### 📅 5.2.1 yearly_fortune_2026_prompt.dart

| 항목 | 값 |
|------|-----|
| **summaryType** | `yearly_fortune_2026` |
| **modelName** | `gpt-5-mini` |
| **maxTokens** | 4096 |
| **temperature** | 0.7 |
| **cacheExpiry** | 30일 |

**시스템 프롬프트 핵심:**
```
당신은 사주명리학 전문가입니다.
사용자의 평생 사주 분석(saju_base)을 기반으로 2026년 운세를 분석합니다.

## 분석 기준
1. saju_base의 성격/적성/재물운 등을 2026년 운기와 연결
2. 2026년 병오(丙午)년 천간지지 영향 분석
3. 용신/기신과 세운의 관계
4. 분기별 운기 변화

## 응답 형식
JSON 형식으로 반환
```

**응답 JSON 스키마:**
```json
{
  "year": 2026,
  "yearGanji": "병오(丙午)",
  "overallScore": 75,
  "summary": "2026년 전체 운세 요약 (2-3문장)",

  "quarterly": {
    "q1": {
      "months": "1-3월",
      "score": 70,
      "theme": "새로운 시작",
      "advice": "1분기 조언"
    },
    "q2": { ... },
    "q3": { ... },
    "q4": { ... }
  },

  "categories": {
    "career": { "score": 80, "analysis": "..." },
    "wealth": { "score": 70, "analysis": "..." },
    "love": { "score": 75, "analysis": "..." },
    "health": { "score": 85, "analysis": "..." }
  },

  "luckyElements": {
    "color": "빨강",
    "number": 7,
    "direction": "남쪽"
  },

  "monthlyHighlights": {
    "best": { "month": 6, "reason": "..." },
    "caution": { "month": 10, "reason": "..." }
  },

  "yearAdvice": "2026년 핵심 조언 (3-4문장)"
}
```

---

#### 📆 5.2.2 monthly_fortune_prompt.dart

| 항목 | 값 |
|------|-----|
| **summaryType** | `monthly_fortune` |
| **modelName** | `gpt-5-mini` |
| **maxTokens** | 2048 |
| **temperature** | 0.7 |
| **cacheExpiry** | 7일 |

**생성자:**
```dart
MonthlyFortunePrompt({
  required this.targetYear,
  required this.targetMonth,
});
```

**응답 JSON 스키마:**
```json
{
  "year": 2026,
  "month": 1,
  "monthGanji": "경인(庚寅)",
  "overallScore": 72,
  "summary": "이번달 운세 요약",

  "weekly": {
    "week1": { "score": 70, "focus": "..." },
    "week2": { "score": 75, "focus": "..." },
    "week3": { "score": 68, "focus": "..." },
    "week4": { "score": 80, "focus": "..." }
  },

  "categories": {
    "career": { "score": 75, "tip": "..." },
    "wealth": { "score": 70, "tip": "..." },
    "love": { "score": 72, "tip": "..." },
    "health": { "score": 80, "tip": "..." }
  },

  "luckyDays": [3, 12, 21],
  "cautionDays": [7, 16],

  "monthAdvice": "이번달 핵심 조언"
}
```

---

#### 🔙 5.2.3 yearly_fortune_2025_prompt.dart

| 항목 | 값 |
|------|-----|
| **summaryType** | `yearly_fortune_2025` |
| **modelName** | `gpt-5-mini` |
| **maxTokens** | 3072 |
| **temperature** | 0.7 |
| **cacheExpiry** | 무기한 (과거는 변하지 않음) |

**특징:**
- 과거 분석이므로 **회고/복기** 관점
- "이런 일이 있었을 수 있다" → "이렇게 활용하세요"

**응답 JSON 스키마:**
```json
{
  "year": 2025,
  "yearGanji": "을사(乙巳)",
  "overallScore": 68,
  "summary": "2025년 회고 요약",

  "retrospective": {
    "achievements": ["성취 가능했던 것들"],
    "challenges": ["어려웠던 점들"],
    "lessons": ["배울 수 있는 교훈"]
  },

  "quarterlyReview": {
    "q1": { "theme": "...", "insight": "..." },
    "q2": { ... },
    "q3": { ... },
    "q4": { ... }
  },

  "carryForward": {
    "strengths": "2026년에 가져갈 강점",
    "improvements": "개선할 점",
    "advice": "앞으로의 조언"
  }
}
```

---

## 6. 데이터 흐름

### 6.1 트리거 시점

| 프롬프트 | 트리거 시점 | 조건 |
|---------|-----------|------|
| yearly_fortune_2026 | 홈 화면 진입 | saju_base 존재 & 2026 운세 미존재 |
| monthly_fortune | 홈 화면 진입 | saju_base 존재 & 이번달 운세 미존재 |
| yearly_fortune_2025 | 사용자 요청 | saju_base 존재 |

### 6.2 서비스 플로우

```
[UI: 홈 화면]
      │
      ▼
[fortune_analysis_service.dart]
      │
      ├── 1. saju_base 캐시 조회 (필수)
      │       └── 없으면 에러 반환
      │
      ├── 2. 대상 운세 캐시 조회
      │       └── 있으면 캐시 반환
      │
      ├── 3. FortuneInputData 구성
      │       ├── profileData
      │       ├── sajuBaseContent  ← saju_base.content
      │       └── sajuOrigin       ← saju_base.content.saju_origin
      │
      ├── 4. 프롬프트 생성 & API 호출
      │       └── GPT-5-mini
      │
      └── 5. 결과 저장
              └── ai_summaries 테이블
```

---

## 7. 구현 순서 (체크리스트)

### Phase 1: 인프라 (ai_constants.dart)
- [ ] GPT-5-mini 모델 상수 추가 (`OpenAIModels.gpt5Mini`)
- [ ] GPT-5-mini 가격 추가 (`OpenAIPricing`)
- [ ] SummaryType 3개 추가
- [ ] CacheExpiry 2개 추가

### Phase 2: 프롬프트 파일 생성
- [ ] yearly_fortune_2026_prompt.dart
- [ ] monthly_fortune_prompt.dart
- [ ] yearly_fortune_2025_prompt.dart

### Phase 3: 데이터 레이어
- [ ] queries.dart - 캐시 조회 메서드 추가
  - `getYearlyFortune2026(profileId)`
  - `getMonthlyFortune(profileId, year, month)`
  - `getYearlyFortune2025(profileId)`
- [ ] mutations.dart - 저장 메서드 추가
  - `saveYearlyFortune2026(...)`
  - `saveMonthlyFortune(...)`
  - `saveYearlyFortune2025(...)`

### Phase 4: 서비스 레이어
- [ ] fortune_analysis_service.dart 생성
  - `analyzeYearlyFortune2026()`
  - `analyzeMonthlyFortune()`
  - `analyzeYearlyFortune2025()`

### Phase 5: Supabase
- [ ] ai_summaries.summary_type CHECK 제약 수정
  - 추가: 'yearly_fortune_2026', 'monthly_fortune', 'yearly_fortune_2025'

### Phase 6: UI 연동
- [ ] 홈 화면에서 트리거
- [ ] 결과 표시 UI

---

## 8. 예상 비용

### 8.1 토큰 추정 (프롬프트당)

| 프롬프트 | Input | Output | 합계 |
|---------|-------|--------|------|
| yearly_fortune_2026 | ~3000 | ~2000 | 5000 |
| monthly_fortune | ~2000 | ~1000 | 3000 |
| yearly_fortune_2025 | ~2500 | ~1500 | 4000 |

### 8.2 비용 계산 (GPT-5-mini 기준)

| 프롬프트 | Input 비용 | Output 비용 | **총 비용** |
|---------|-----------|------------|------------|
| yearly_fortune_2026 | $0.00075 | $0.004 | **$0.00475** |
| monthly_fortune | $0.0005 | $0.002 | **$0.0025** |
| yearly_fortune_2025 | $0.000625 | $0.003 | **$0.003625** |

**사용자당 연간 예상 비용**: ~$0.05 (매우 저렴)

---

## 9. 참고 파일

| 파일 | 용도 |
|------|------|
| `_TEMPLATE.dart` | 프롬프트 템플릿 |
| `saju_base_prompt.dart` | 평생운세 (참고용) |
| `daily_fortune_prompt.dart` | 일운 (참고용) |
| `ai_constants.dart` | 상수 정의 |
| `queries.dart` | 캐시 조회 패턴 |
| `mutations.dart` | 저장 패턴 |
| `saju_analysis_service.dart` | 서비스 패턴 |

---

## 10. 변경 이력

| 날짜 | 버전 | 변경 내용 |
|------|------|---------|
| 2026-01-18 | v1.0 | 초안 작성 |
