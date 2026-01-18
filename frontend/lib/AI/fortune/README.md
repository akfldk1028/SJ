# Fortune 모듈 (운세 분석)

> **버전**: v1.0
> **작성일**: 2026-01-18
> **담당**: JH_AI
> **상태**: ✅ 구현 완료

---

## 1. 개요

saju_base(평생운세)를 **기반 데이터**로 활용하는 파생 운세 분석 모듈.

### 핵심 원칙
```
saju_base 없음 → 로딩/대기 상태 → saju_base 완료 대기
saju_base 있음 → 운세 분석 실행
```

---

## 2. 폴더 구조

```
frontend/lib/AI/fortune/
│
├── README.md                    # 이 파일
│
├── fortune_coordinator.dart     # 통합 조율 서비스
│   ├── checkSajuBaseReady()     # saju_base 존재 확인
│   ├── waitForSajuBase()        # saju_base 완료 대기
│   └── analyzeAllFortunes()     # 전체 운세 일괄 분석
│
├── common/
│   ├── fortune_state.dart       # 상태 정의 (loading, ready, error)
│   ├── fortune_input_data.dart  # 공통 입력 데이터
│   └── korea_date_utils.dart    # 한국 시간(KST) 유틸리티
│
├── yearly_2026/                 # 2026 신년운세
│   ├── yearly_2026_prompt.dart
│   ├── yearly_2026_queries.dart
│   ├── yearly_2026_mutations.dart
│   └── yearly_2026_service.dart
│
├── monthly/                     # 이번달 운세
│   ├── monthly_prompt.dart
│   ├── monthly_queries.dart
│   ├── monthly_mutations.dart
│   └── monthly_service.dart
│
└── yearly_2025/                 # 2025 회고
    ├── yearly_2025_prompt.dart
    ├── yearly_2025_queries.dart
    ├── yearly_2025_mutations.dart
    └── yearly_2025_service.dart
```

---

## 3. 의존성 흐름

```
┌──────────────────────────────────────────────────────────────┐
│                     UI Layer                                  │
│              (HomeScreen, FortuneCard)                       │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────────┐
│                fortune_coordinator.dart                       │
│                                                              │
│  1. checkSajuBaseReady(profileId)                            │
│     └── saju_base 캐시 조회                                   │
│         ├── 없음 → FortuneState.waitingForSajuBase           │
│         └── 있음 → FortuneState.ready                        │
│                                                              │
│  2. analyzeAllFortunes(profileId)                            │
│     └── saju_base 있을 때만 실행                              │
│         ├── yearly_2026_service.analyze()                    │
│         ├── monthly_service.analyze()                        │
│         └── yearly_2025_service.analyze()                    │
└───────────────────────┬──────────────────────────────────────┘
                        │
          ┌─────────────┼─────────────┐
          ▼             ▼             ▼
   ┌────────────┐ ┌────────────┐ ┌────────────┐
   │yearly_2026 │ │  monthly   │ │yearly_2025 │
   │  _service  │ │  _service  │ │  _service  │
   └─────┬──────┘ └─────┬──────┘ └─────┬──────┘
         │              │              │
         ▼              ▼              ▼
   ┌────────────┐ ┌────────────┐ ┌────────────┐
   │  _queries  │ │  _queries  │ │  _queries  │
   │ _mutations │ │ _mutations │ │ _mutations │
   └────────────┘ └────────────┘ └────────────┘
         │              │              │
         └──────────────┴──────────────┘
                        │
                        ▼
              ┌─────────────────┐
              │  ai_summaries   │
              │    (Supabase)   │
              └─────────────────┘
```

---

## 4. 상태 흐름 (FortuneState)

```dart
enum FortuneState {
  /// 초기 상태
  initial,

  /// saju_base 분석 대기 중
  /// - saju_base가 없거나 분석 중일 때
  /// - UI: 스켈레톤 로딩 + "평생 운세 분석 중..." 메시지
  waitingForSajuBase,

  /// saju_base 준비 완료, 운세 분석 가능
  /// - 운세 캐시 확인 후 분석 실행
  ready,

  /// 운세 분석 진행 중
  /// - GPT-5-mini API 호출 중
  /// - UI: 프로그레스 바
  analyzing,

  /// 분석 완료
  /// - 결과 표시 가능
  completed,

  /// 에러 발생
  error,
}
```

---

## 5. SummaryType 매핑

| 폴더 | summary_type | target_year | target_month | 캐시 만료 |
|------|--------------|-------------|--------------|----------|
| `yearly_2026/` | `yearly_fortune_2026` | 2026 | null | 30일 |
| `monthly/` | `monthly_fortune` | 동적 | 동적 | 7일 |
| `yearly_2025/` | `yearly_fortune_2025` | 2025 | null | 무기한 |

### 5.1 한국 시간(KST) 기준

- 모든 날짜/시간 처리는 **한국 시간(UTC+9)** 기준
- `common/korea_date_utils.dart` 유틸리티 사용
- 월 전환 시점: 한국 시간 기준 매월 1일 00:00

```dart
// 현재 한국 연/월 조회
final year = KoreaDateUtils.currentYear;   // 한국 시간 기준
final month = KoreaDateUtils.currentMonth; // 한국 시간 기준

// 만료 시간 계산 (한국 시간 기준)
final expiry = KoreaDateUtils.calculateExpiry(Duration(days: 7));
```

---

## 6. 사용 예시

### 6.1 Coordinator 사용

```dart
import 'package:mantok/AI/fortune/fortune_coordinator.dart';

// 상태 확인
final state = await fortuneCoordinator.checkSajuBaseReady(profileId);

if (state == FortuneState.waitingForSajuBase) {
  // saju_base 분석 대기 UI 표시
  showLoadingWithMessage('평생 운세 분석 중...');

  // saju_base 완료 대기 (폴링)
  await fortuneCoordinator.waitForSajuBase(profileId);
}

// 모든 운세 분석 실행
final results = await fortuneCoordinator.analyzeAllFortunes(
  userId: userId,
  profileId: profileId,
);
```

### 6.2 개별 서비스 사용

```dart
import 'package:mantok/AI/fortune/yearly_2026/yearly_2026_service.dart';

// 2026 신년운세만 분석
final result = await yearly2026Service.analyze(
  userId: userId,
  profileId: profileId,
  sajuBaseContent: sajuBase.content,
);
```

---

## 7. 파일별 역할

### 7.1 *_prompt.dart
- PromptTemplate 상속
- systemPrompt, buildUserPrompt() 정의
- 모델/토큰/캐시 설정

### 7.2 *_queries.dart
- 캐시 조회: `getCached(profileId)`
- 상태 확인: `exists(profileId)`

### 7.3 *_mutations.dart
- 결과 저장: `save(userId, profileId, content, ...)`
- Upsert 패턴 사용

### 7.4 *_service.dart
- 오케스트레이션: 캐시 확인 → API 호출 → 저장
- `analyze()` 메인 메서드
- 에러 처리 및 로깅

---

## 8. 관련 파일

| 파일 | 역할 |
|------|------|
| `AI/core/ai_constants.dart` | GPT-5-mini 모델/가격, SummaryType |
| `AI/data/queries.dart` | saju_base 캐시 조회 (참조) |
| `AI/services/ai_api_service.dart` | OpenAI API 호출 |
| `AI/prompts/prompt_template.dart` | 프롬프트 베이스 클래스 |
| `sql/migrations/20260118_add_fortune_summary_types.sql` | Supabase 마이그레이션 |

---

## 9. 모델 및 비용

### 9.1 GPT-5-mini 선택 이유

| 항목 | GPT-5.2 (saju_base) | GPT-5-mini (운세) |
|------|---------------------|-------------------|
| **Input** | $1.75 / 1M | **$0.25 / 1M** |
| **Output** | $14.00 / 1M | **$2.00 / 1M** |
| **성능** | 100% | 80% (충분) |
| **속도** | 100-150초 | **5-15초** |
| **용도** | 복잡한 원국 분석 | saju_base 기반 요약/확장 |

**결론**: saju_base가 이미 상세 분석을 완료했으므로, 파생 운세는 GPT-5-mini로 충분.

### 9.2 예상 비용 (프롬프트당)

| 프롬프트 | Input 토큰 | Output 토큰 | **총 비용** |
|---------|-----------|------------|------------|
| yearly_fortune_2026 | ~3000 | ~2000 | **$0.00475** |
| monthly_fortune | ~2000 | ~1000 | **$0.0025** |
| yearly_fortune_2025 | ~2500 | ~1500 | **$0.003625** |

**사용자당 연간 예상 비용**: ~$0.05 (매우 저렴)

---

## 10. Supabase 마이그레이션

```sql
-- sql/migrations/20260118_add_fortune_summary_types.sql 실행

-- 1. summary_type CHECK 제약 조건 업데이트
ALTER TABLE ai_summaries
DROP CONSTRAINT IF EXISTS ai_summaries_summary_type_check;

ALTER TABLE ai_summaries
ADD CONSTRAINT ai_summaries_summary_type_check
CHECK (summary_type IN (
  'saju_base',
  'daily_fortune',
  'monthly_fortune',
  'yearly_fortune',
  'yearly_fortune_2026',  -- 신규
  'yearly_fortune_2025',  -- 신규
  'question_answer',
  'compatibility'
));

-- 2. target_year, target_month 필드 추가
ALTER TABLE ai_summaries
ADD COLUMN IF NOT EXISTS target_year SMALLINT;

ALTER TABLE ai_summaries
ADD COLUMN IF NOT EXISTS target_month SMALLINT;

-- 3. 복합 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_ai_summaries_profile_summary_year_month
ON ai_summaries (profile_id, summary_type, target_year, target_month);
```

### 10.1 쿼리 예시

```sql
-- 2026년 1월 월운 조회
SELECT * FROM ai_summaries
WHERE profile_id = 'xxx'
  AND summary_type = 'monthly_fortune'
  AND target_year = 2026
  AND target_month = 1;

-- 2026 신년운세 조회
SELECT * FROM ai_summaries
WHERE profile_id = 'xxx'
  AND summary_type = 'yearly_fortune_2026'
  AND target_year = 2026;
```

---

## 11. 변경 이력

| 날짜 | 버전 | 변경 내용 |
|------|------|---------|
| 2026-01-18 | v1.0 | 초안 작성 및 구현 완료 |
