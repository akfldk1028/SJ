# Fortune 모듈 (운세 분석)

> **버전**: v6.0
> **작성일**: 2026-01-20
> **담당**: JH_AI
> **상태**: ✅ 구현 완료 (v6.0 성능 개선 - saju_base 대기 제거!)

---

## 1. 개요

saju_analyses(만세력 계산 데이터)를 **핵심 데이터**로 활용하는 운세 분석 모듈.

### v6.0 핵심 변경 ⭐
```
Before (v5.x): saju_base(GPT-5.2) 대기 (140초!) → 운세 분석 시작
After  (v6.0): saju_analyses(즉시) → 바로 운세 분석 시작! ⚡
```

### 아키텍처 원칙
```
프로필 저장 시 saju_analyses 자동 계산 (즉시)
  → 운세 분석 요청 시 saju_analyses만 조회
  → 140초 대기 없이 즉시 운세 분석 실행!
```

---

## 2. 폴더 구조

```
frontend/lib/AI/fortune/
│
├── README.md                    # 이 파일
│
├── fortune_coordinator.dart     # 통합 조율 서비스 (v6.0)
│   ├── analyzeAllFortunes()     # 전체 운세 일괄 분석 (즉시 시작!)
│   ├── checkSajuBaseReady()     # @deprecated (v6.0)
│   └── waitForSajuBase()        # @deprecated (v6.0)
│
├── common/
│   ├── fortune_state.dart         # 상태 정의 (loading, ready, error)
│   ├── fortune_input_data.dart    # 공통 입력 데이터 + getter
│   ├── saju_analyses_queries.dart # ⭐ saju_analyses 조회 + 파싱 (NEW!)
│   └── korea_date_utils.dart      # 한국 시간(KST) 유틸리티
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

## 3. 의존성 흐름 (v6.0)

```
┌──────────────────────────────────────────────────────────────┐
│                     UI Layer                                  │
│              (HomeScreen, FortuneCard)                       │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────────┐
│                fortune_coordinator.dart (v6.0)                │
│                                                              │
│  analyzeAllFortunes(profileId) - 즉시 시작! ⚡                │
│     │                                                        │
│     ├── 1. SajuAnalysesQueries.getForFortuneInput()         │
│     │      └── saju_analyses 조회 (즉시 사용 가능!)          │
│     │      └── 합충/신살/용신/팔자 파싱                      │
│     │                                                        │
│     ├── 2. FortuneInputData.fromSajuAnalyses() 구성         │
│     │      └── saju_base 대기 없음! (140초 절약)             │
│     │                                                        │
│     └── 3. 병렬 운세 분석 시작                               │
│            ├── yearly_2026_service.analyze()                 │
│            ├── monthly_service.analyze()                     │
│            └── yearly_2025_service.analyze()                 │
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
| `yearly_2026/` | `yearly_fortune_2026` | 2026 | null | **2026-12-31까지** |
| `monthly/` | `monthly_fortune` | 동적 | 동적 | **해당 월 말일까지** |
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
// 월운: 해당 월 말일까지
final monthlyExpiry = KoreaDateUtils.expiryEndOfMonth(year, month);
// 예: 2026년 1월 → "2026-01-31T14:59:59.000Z" (UTC 기준, KST 23:59:59)

// 신년운세: 해당 연도 말일까지
final yearlyExpiry = KoreaDateUtils.expiryEndOfYear(2026);
// → "2026-12-31T14:59:59.000Z" (UTC 기준, KST 23:59:59)
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

## 11. 프롬프트 상세 (수정 시 참조)

### 11.0 ⭐ saju_base 프롬프트 (기반 데이터)

> **중요**: 모든 운세 분석의 기반이 되는 핵심 프롬프트!
> 이 프롬프트 결과물이 yearly_2026, monthly, yearly_2025의 입력 데이터가 됩니다.

**파일 경로**: `frontend/lib/AI/prompts/saju_base_prompt.dart`

**모델**: GPT-5.2 (최고 성능, $1.75/$14.00 per 1M tokens)

**캐시 만료**: 무기한 (프로필 변경 없으면 재생성 불필요)

**System Prompt 핵심**:
```
당신은 한국 전통 사주명리학 분야 30년 경력의 최고 전문가입니다.
원국(原局)을 철저히 분석하여 정확하고 깊이 있는 사주 해석을 제공합니다.

## 분석 방법론 (반드시 순서대로)
1단계: 원국 구조 분석
2단계: 십성(十星) 분석
3단계: 신살(神殺) & 길성(吉星) 해석
4단계: 합충형파해(合沖刑破害) 분석
5단계: 12운성 분석
6단계: 종합 해석 (재물/연애/결혼/사업/직장/건강)
7단계: 전통 vs AI시대 해석 비교
```

**합충형파해 강도 기준** (프롬프트에 포함됨):
| 유형 | 강도 순서 |
|------|----------|
| **합(合)** | 방합(★5) > 삼합(★4) > 반합(★3) > 육합(★2) |
| **충(沖)** | 왕지충(★5 묘유/자오) > 생지충(★4 인신/사해) > 고지충(★3) |
| **형(刑)** | 삼형(★5) > 상형(★3) > 자묘형(★2) > 자형(★1) |

**응답 JSON 스키마** (주요 필드):
```json
{
  "saju_origin": {
    "saju": { "year": {}, "month": {}, "day": {}, "hour": {} },
    "oheng": { "wood": 0, "fire": 0, "earth": 0, "metal": 0, "water": 0 },
    "yongsin": { "yongsin": "", "huisin": "", "gisin": "" },
    "singang_singak": { "is_singang": true, "score": 0, "level": "" },
    "gyeokguk": { "name": "", "description": "" },
    "hapchung": { "summary": "", "total_haps": 0, "total_chungs": 0 }
  },
  "summary": "사주 특성 요약",
  "personality": { "core_traits": [], "strengths": [], "weaknesses": [] },
  "wealth": { "overall_tendency": "", "earning_style": "" },
  "love": { "attraction_style": "", "dating_pattern": "" },
  "marriage": { "spouse_palace_analysis": "", "marriage_timing": "" },
  "career": { "suitable_fields": [], "work_style": "" },
  "business": { "entrepreneurship_aptitude": "" },
  "health": { "vulnerable_organs": [], "lifestyle_advice": [] },
  "lucky_elements": { "colors": [], "directions": [], "numbers": [] },
  "modern_interpretation": { "career_in_ai_era": {}, "wealth_in_ai_era": {} }
}
```

**운세 분석에서 사용하는 saju_base 필드**:
- `personality` → 성격/적성 기반 운세 해석
- `wealth` → 재물운 파생
- `career` → 직업운 파생
- `health` → 건강운 파생
- `love` → 애정운 파생
- `saju_origin.yongsin` → 용신/기신과 세운 관계 분석

---

### 11.1 2026 신년운세 프롬프트

**파일 경로**: `frontend/lib/AI/fortune/yearly_2026/yearly_2026_prompt.dart`

**System Prompt 핵심**:
```
당신은 사주명리학 전문가입니다.
사용자의 평생 사주 분석(saju_base)을 기반으로 2026년 병오(丙午)년 신년운세를 분석합니다.

## 분석 기준
1. saju_base의 성격/적성/재물운/건강운 등을 2026년 운기와 연결
2. 2026년 병오(丙午)년 천간지지 영향 분석
   - 병(丙): 태양의 불, 밝음, 열정, 에너지
   - 오(午): 말, 정오, 극양, 활동성
3. 용신/기신과 세운의 관계
4. 분기별 운기 변화
5. 사용자의 대운/세운 흐름 고려
```

**응답 JSON 스키마**:
```json
{
  "year": 2026,
  "yearGanji": "병오(丙午)",
  "overallScore": 75,
  "summary": "2026년 전체 운세 요약",
  "quarterly": {
    "q1": { "months": "1-3월", "score": 70, "theme": "", "advice": "" },
    "q2": { "months": "4-6월", "score": 75, "theme": "", "advice": "" },
    "q3": { "months": "7-9월", "score": 80, "theme": "", "advice": "" },
    "q4": { "months": "10-12월", "score": 72, "theme": "", "advice": "" }
  },
  "categories": {
    "career": { "score": 80, "analysis": "" },
    "wealth": { "score": 70, "analysis": "" },
    "love": { "score": 75, "analysis": "" },
    "health": { "score": 85, "analysis": "" }
  },
  "luckyElements": { "color": "", "number": 7, "direction": "" },
  "monthlyHighlights": {
    "best": { "month": 6, "reason": "" },
    "caution": { "month": 10, "reason": "" }
  },
  "yearAdvice": "2026년 핵심 조언"
}
```

---

### 11.2 이번달 운세 프롬프트

**파일 경로**: `frontend/lib/AI/fortune/monthly/monthly_prompt.dart`

**System Prompt 핵심**:
```
당신은 사주명리학 전문가입니다.
사용자의 평생 사주 분석(saju_base)을 기반으로 {year}년 {month}월 운세를 분석합니다.

## 분석 기준
1. saju_base의 성격/적성/재물운 등을 이번달 운기와 연결
2. 해당 월의 간지 영향 분석
3. 주간별 운기 변화
4. 길일/흉일 도출
5. 실생활에 적용 가능한 구체적 조언
```

**월별 간지 (2026년 병오년 기준)**:
| 월 | 간지 |
|----|------|
| 1월 | 경인(庚寅) |
| 2월 | 신묘(辛卯) |
| 3월 | 임진(壬辰) |
| 4월 | 계사(癸巳) |
| 5월 | 갑오(甲午) |
| 6월 | 을미(乙未) |
| 7월 | 병신(丙申) |
| 8월 | 정유(丁酉) |
| 9월 | 무술(戊戌) |
| 10월 | 기해(己亥) |
| 11월 | 경자(庚子) |
| 12월 | 신축(辛丑) |

**응답 JSON 스키마**:
```json
{
  "year": 2026,
  "month": 1,
  "monthGanji": "경인(庚寅)",
  "overallScore": 72,
  "summary": "이번달 운세 요약",
  "weekly": {
    "week1": { "dates": "1-7일", "score": 70, "focus": "" },
    "week2": { "dates": "8-14일", "score": 75, "focus": "" },
    "week3": { "dates": "15-21일", "score": 68, "focus": "" },
    "week4": { "dates": "22-말일", "score": 80, "focus": "" }
  },
  "categories": {
    "career": { "score": 75, "tip": "" },
    "wealth": { "score": 70, "tip": "" },
    "love": { "score": 72, "tip": "" },
    "health": { "score": 80, "tip": "" }
  },
  "luckyDays": [3, 12, 21],
  "cautionDays": [7, 16],
  "monthAdvice": "이번달 핵심 조언"
}
```

---

### 11.3 2025 회고 운세 프롬프트

**파일 경로**: `frontend/lib/AI/fortune/yearly_2025/yearly_2025_prompt.dart`

**System Prompt 핵심**:
```
당신은 사주명리학 전문가입니다.
사용자의 평생 사주 분석(saju_base)을 기반으로 2025년 을사(乙巳)년을 **회고/복기** 관점에서 분석합니다.

## 분석 기준
1. 2025년 을사(乙巳)년의 특징
   - 을(乙): 음목, 유연함, 성장, 적응
   - 사(巳): 뱀, 지혜, 변화, 숨은 기회
2. saju_base와 2025년 운기의 상호작용
3. 2025년에 있었을 만한 경험들 추론
4. 그 경험에서 배울 수 있는 교훈
5. 2026년으로 이어지는 연결고리

## 특별 지침
- 과거 분석이므로 "~했을 것이다", "~경험했을 수 있다" 형태로 작성
- 맹목적 예측이 아닌, 사주 원리에 기반한 합리적 추론
```

**응답 JSON 스키마**:
```json
{
  "year": 2025,
  "yearGanji": "을사(乙巳)",
  "overallScore": 68,
  "summary": "2025년 회고 요약",
  "retrospective": {
    "achievements": ["성취1", "성취2", "성취3"],
    "challenges": ["도전1", "도전2", "도전3"],
    "lessons": ["교훈1", "교훈2", "교훈3"]
  },
  "quarterlyReview": {
    "q1": { "months": "1-3월", "theme": "", "insight": "" },
    "q2": { "months": "4-6월", "theme": "", "insight": "" },
    "q3": { "months": "7-9월", "theme": "", "insight": "" },
    "q4": { "months": "10-12월", "theme": "", "insight": "" }
  },
  "carryForward": {
    "strengths": "2026년에 가져갈 강점",
    "improvements": "개선하면 좋을 점",
    "advice": "앞으로의 조언"
  }
}
```

---

### 11.4 프롬프트 수정 체크리스트

프롬프트 수정 시 확인 사항:

- [ ] `systemPrompt` 수정 → 분석 기준/톤앤매너 변경
- [ ] `buildUserPrompt()` 수정 → JSON 스키마 변경
- [ ] JSON 스키마 변경 시 → UI 컴포넌트도 함께 수정 필요
- [ ] `maxTokens` 조정 → 응답 길이 제한
- [ ] `temperature` 조정 → 창의성 (0.7 권장)

---

## 12. 프롬프트 개선 설계 (v2.0)

### 12.1 문제점 분석

| 항목 | 현재 문제 | 개선 방향 |
|------|----------|----------|
| **정확도** | saju_base만 참조, 원국 데이터 미사용 | saju_analyses 테이블의 yongsin, hapchung 활용 |
| **응답 길이** | "2-3문장"으로 너무 짧음 | 카테고리별 3-5문장 상세 설명 |
| **maxTokens** | 하드코딩 (4096, 2048) | TokenLimits 상수 사용 (8192, 4096) |
| **개인화** | 일반적 설명 | 용신/기신 상호작용 기반 맞춤 분석 |

### 12.2 핵심 개선 - saju_analyses 데이터 활용

**saju_analyses 테이블의 주요 필드:**

```sql
-- 운세 정확도의 핵심 데이터
yongsin JSONB      -- 용신/희신/기신/구신 (가장 중요!)
hapchung JSONB     -- 합충형파해 (년/월 상호작용)
day_strength JSONB -- 신강/신약 (일간 강약)
daeun JSONB        -- 대운 정보
current_seun JSONB -- 현재 세운
```

### 12.3 용신/기신 기반 분석 로직

```
2026년 병오(丙午)년 = 화(火) 에너지 강한 해

사용자 용신이 화(火)인 경우:
  → 올해 화 기운이 용신을 도움
  → 원하던 일이 풀리는 좋은 해
  → 예상 점수: 85-95점

사용자 기신이 화(火)인 경우:
  → 올해 화 기운이 기신을 강화
  → 조심해야 하는 해, 과욕 금물
  → 예상 점수: 55-65점

사용자 용신이 수(水)인 경우:
  → 화(火)가 수(水)를 극함 (火克水)
  → 용신이 억제되어 힘든 해
  → 예상 점수: 50-60점
```

### 12.4 합충 분석 로직

```
사용자 일지가 子(자)인 경우:
  → 2026년 午(오)와 子午衝(자오충)
  → 큰 변화의 해: 이사, 이직, 관계 변동

사용자 일지가 寅(인)인 경우:
  → 2026년 午(오)와 寅午戌 삼합 가능
  → 협력/파트너십 운 상승
```

### 12.5 설계 문서 위치

각 운세 타입별 상세 설계 문서:

| 파일 | 설명 |
|------|------|
| `yearly_2026/PROMPT_DESIGN.md` | 2026 신년운세 프롬프트 설계 |
| `monthly/PROMPT_DESIGN.md` | 이번달 운세 프롬프트 설계 |
| `yearly_2025/PROMPT_DESIGN.md` | 2025 회고 운세 프롬프트 설계 |

### 12.6 구현 체크리스트

- [ ] FortuneInputData 확장 (saju_analyses 데이터 포함)
- [ ] _formatSajuBase() → _formatFullSajuData() 개선
- [ ] yongsin, hapchung 포맷팅 메서드 추가
- [ ] 시스템 프롬프트 개선 (용신/기신 분석 강조)
- [ ] JSON 스키마 개선 (상세 설명 필드)
- [ ] maxTokens를 TokenLimits 상수로 변경

---

## 13. 일간+세운 십성 결합 분석 (v5.0)

> **핵심 개선**: GPT가 정확한 운세 분석을 하려면 **세운 오행이 일간에게 어떤 십성인지** 직접 계산해서 전달해야 합니다.

### 13.1 문제점

기존 프롬프트의 문제:
```
❌ "2026년 병오(丙午)년은 화(火) 에너지가 강한 해입니다. 분석해주세요."
→ GPT가 사용자 일간과의 관계를 정확히 파악하기 어려움
```

개선된 프롬프트:
```
✅ "2026년 병오(丙午)년의 화(火)가 일간 을(乙)목에게 '식상'입니다."
→ GPT가 식상의 의미(표현, 창작, 발산)를 바탕으로 정확한 분석 가능
```

### 13.2 FortuneInputData 헬퍼 메서드

**파일**: `common/fortune_input_data.dart`

```dart
/// 천간 → 오행 변환
static const _ganToElement = {
  '甲': '목', '乙': '목', '丙': '화', '丁': '화', '戊': '토',
  '己': '토', '庚': '금', '辛': '금', '壬': '수', '癸': '수',
};

/// 일간의 오행 반환
String? get dayGanElement => _ganToElement[dayGan];

/// 특정 오행이 일간에게 어떤 십성인지 계산
/// 예: 일간이 乙(목)이고 targetElement가 '화'면 → '식상' 반환
String? getSipseongFor(String targetElement) {
  final myElement = dayGanElement;
  if (myElement == null) return null;

  const elementOrder = ['목', '화', '토', '금', '수'];
  final myIdx = elementOrder.indexOf(myElement);
  final targetIdx = elementOrder.indexOf(targetElement);

  if (myIdx == -1 || targetIdx == -1) return null;

  // 상생 순서 기반 십성 계산
  final diff = (targetIdx - myIdx + 5) % 5;
  const sipseongMap = {
    0: '비겁',   // 같은 오행 → 비견/겁재
    1: '식상',   // 내가 생하는 오행 → 식신/상관
    2: '재성',   // 내가 극하는 오행 → 편재/정재
    3: '관성',   // 나를 극하는 오행 → 편관/정관
    4: '인성',   // 나를 생하는 오행 → 편인/정인
  };
  return sipseongMap[diff];
}

/// 십성 설명 반환
String? getSipseongExplain(String targetElement) {
  final sipseong = getSipseongFor(targetElement);
  const explains = {
    '비겁': '나와 같은 기운 - 경쟁, 협력, 형제자매운',
    '식상': '내가 표현하는 기운 - 창작, 발산, 자녀운, 재물 생산',
    '재성': '내가 다스리는 기운 - 재물, 아버지, 여자의 남편',
    '관성': '나를 다스리는 기운 - 직장, 명예, 규율, 남자의 자녀',
    '인성': '나를 생하는 기운 - 학업, 어머니, 문서, 자격증',
  };
  return explains[sipseong];
}

/// 용신/기신과의 관계 분석
String getYongsinRelation(String seunElement) {
  // yongsin 필드의 yongsin/gisin과 seunElement 비교
  // 용신이면 "세운이 용신을 돕습니다" 등 반환
}

/// 전체 결합 분석 (GPT에 전달용)
String getSeunCombinationAnalysis(String seunElement, String seunGanji) {
  final buffer = StringBuffer();
  buffer.writeln('### 일간과 세운의 결합 분석 (핵심!)');
  buffer.writeln('');
  buffer.writeln('**1. 일간 정보**');
  buffer.writeln('- 일간: ${dayGan ?? "?"} (${dayGanElement ?? "?"}일간)');
  buffer.writeln('');
  buffer.writeln('**2. 세운($seunGanji)의 $seunElement 오행이 일간에게 미치는 영향**');
  buffer.writeln('- 십성: ${getSipseongFor(seunElement) ?? "?"}');
  buffer.writeln('- 의미: ${getSipseongExplain(seunElement) ?? "?"}');
  buffer.writeln('');
  buffer.writeln('**3. 용신/기신과의 관계**');
  buffer.writeln(getYongsinRelation(seunElement));
  return buffer.toString();
}
```

### 13.3 프롬프트 적용 예시

**yearly_2026_prompt.dart** (userPrompt 부분):
```dart
---
## ⭐ 2026년 병오(丙午)와 나의 오행 결합 분석 ⭐
${inputData.getSeunCombinationAnalysis('화', '병오(丙午)')}
---

**⭐ 핵심: 일간(${inputData.dayGan}) + 세운(화) = ${inputData.getSipseongFor('화')} 관계를 중심으로 분석!**

**분석 시 반드시 포함할 요소:**
1. **십성 중심 분석**: ${inputData.dayGanElement}일간에게 화(火)가 **${inputData.getSipseongFor('화')}**이므로...
```

### 13.4 십성별 운세 해석 가이드

| 십성 | 영역별 영향 |
|------|----------|
| **비겁** | 직장: 경쟁/협력 증가, 재물: 분산/공유, 연애: 경쟁자 등장 |
| **식상** | 직장: 아이디어/창작, 재물: 생산/수익, 연애: 매력 발산, 건강: 에너지 소모 |
| **재성** | 직장: 실적/성과, 재물: 수입 증가, 연애: 만남/인연, 건강: 과로 주의 |
| **관성** | 직장: 승진/책임, 재물: 규제/세금, 연애: 책임감, 건강: 압박/스트레스 |
| **인성** | 직장: 학습/자격증, 재물: 안정/보호, 연애: 보호 본능, 건강: 회복력 |

### 13.5 적용된 프롬프트 파일

| 파일 | 세운 | 변경 내용 |
|------|------|---------|
| `yearly_2026_prompt.dart` | 병오(화) | `getSeunCombinationAnalysis('화', '병오(丙午)')` 추가 |
| `yearly_2025_prompt.dart` | 을사(화) | `getSeunCombinationAnalysis('화', '을사(乙巳)')` 추가 |
| `monthly_prompt.dart` | 월별 동적 | `_formatMonthlyCombination()` 메서드 추가 |

---

## 14. 변경 이력

| 날짜 | 버전 | 변경 내용 |
|------|------|---------|
| 2026-01-18 | v1.0 | 초안 작성 및 구현 완료 |
| 2026-01-18 | v1.1 | 프롬프트 상세 문서화 추가 |
| 2026-01-18 | v1.2 | 캐시 만료 정책 수정 (신년운세: 연말까지, 월운: 월말까지) |
| 2026-01-18 | v2.0 | 프롬프트 개선 설계 추가 (yongsin/hapchung 활용, 상세 응답) |
| 2026-01-18 | v5.0 | **일간+세운 십성 결합 분석** - FortuneInputData에 헬퍼 메서드 추가, 모든 프롬프트에 적용 |
| 2026-01-20 | v5.1 | **AI 프롬프트-Provider 타입 매칭 규칙** 문서화 추가 |
| 2026-01-20 | v5.2 | **saju_analyses 통합** - SajuAnalysesQueries 추가, 합충/신살 파싱, 프롬프트에 신살 정보 포함 |
| 2026-01-20 | v6.0 | **⭐ 성능 대폭 개선!** saju_base 140초 대기 제거, saju_analyses만으로 즉시 운세 분석 |

---

## 15. ⚠️ AI 프롬프트-Provider 타입 매칭 규칙 (필수!)

> **핵심 원칙**: AI 프롬프트의 JSON 출력 스키마와 Provider의 `fromJson()` 파싱은 **100% 동일**해야 합니다.

### 15.1 왜 중요한가?

```
AI 프롬프트 (JSON 스키마)  →  Supabase 저장  →  Provider (fromJson)  →  UI 화면

⚠️ 중간에 타입이 달라지면:
   - 런타임 에러 발생
   - 데이터 누락
   - UI에서 빈 화면 표시
```

### 15.2 체크 방법

**프롬프트 파일 (예: yearly_2026_prompt.dart)**:
```dart
// buildUserPrompt() 내의 JSON 스키마 확인
'''
{
  "yearInfo": {
    "alias": "string",
    "napeum": "string",
    "napeumExplain": "string",
    ...
  },
  "overview": {
    "keyword": "string",
    "score": "number",
    "summary": "string",
    "keyPoint": "string"
  },
  ...
}
'''
```

**Provider 파일 (예: new_year_fortune_provider.dart)**:
```dart
// fromJson() 파싱 확인
factory NewYearFortuneData.fromJson(Map<String, dynamic> json) {
  final yearInfoJson = json['yearInfo'] as Map<String, dynamic>? ?? {};
  final yearInfo = YearInfoSection(
    alias: yearInfoJson['alias'] as String? ?? '',
    napeum: yearInfoJson['napeum'] as String? ?? '',
    napeumExplain: yearInfoJson['napeumExplain'] as String? ?? '',
    ...
  );
  // ✅ 프롬프트 JSON 스키마와 1:1 매칭!
}
```

### 15.3 타입 매칭 규칙

| 프롬프트 JSON 타입 | Provider Dart 타입 |
|------------------|-------------------|
| `"string"` | `String` |
| `"number"` (정수) | `int` |
| `"number"` (소수) | `double` |
| `["string"]` | `List<String>` |
| `["number"]` | `List<int>` |
| `{}` (객체) | `Map<String, dynamic>` 또는 커스텀 클래스 |

### 15.4 프롬프트 수정 시 체크리스트

프롬프트 JSON 스키마를 변경할 때 **반드시** 아래 파일도 수정:

| 프롬프트 파일 | Provider 파일 | Screen 파일 |
|--------------|--------------|------------|
| `yearly_2026_prompt.dart` | `new_year_fortune_provider.dart` | `new_year_fortune_screen.dart` |
| `monthly_prompt.dart` | `monthly_fortune_provider.dart` | `monthly_fortune_screen.dart` |
| `yearly_2025_prompt.dart` | `yearly_2025_fortune_provider.dart` | `yearly_2025_fortune_screen.dart` |

### 15.5 실제 매칭 예시

**2026 신년운세 타입 매칭**:

| 섹션 | 프롬프트 필드 | Provider 클래스 |
|------|-------------|----------------|
| `yearInfo` | `alias`, `napeum`, `napeumExplain`, `twelveUnsung`, `unsungExplain`, `mainSinsal`, `sinsalExplain` | `YearInfoSection` |
| `personalAnalysis` | `ilgan`, `ilganExplain`, `fireEffect`, `yongshinMatch`, `hapchungEffect`, `sinsalEffect` | `PersonalAnalysisSection` |
| `overview` | `keyword`, `score`, `summary`, `keyPoint` | `OverviewSection` |
| `categories` | `title`, `icon`, `score`, `summary`, `reading`, `bestMonths`, `cautionMonths`, `actionTip`, `focusAreas` | `CategorySection` |
| `timeline` | `q1`, `q2`, `q3`, `q4` (각각 `period`, `theme`, `score`, `reading`) | `TimelineSection`, `QuarterSection` |
| `lucky` | `colors`, `numbers`, `direction`, `items` | `LuckySection` |
| `closing` | `yearMessage`, `finalAdvice` | `ClosingSection` |

### 15.6 흔한 실수와 해결

```
❌ 실수 1: 프롬프트에 새 필드 추가했는데 Provider 미수정
   → 해결: Provider의 fromJson()에 해당 필드 파싱 추가

❌ 실수 2: 프롬프트에서 배열 → 객체로 변경했는데 Provider는 그대로
   → 해결: List<String> → 커스텀 클래스로 변경

❌ 실수 3: 프롬프트 필드명 오타 (overview vs overView)
   → 해결: 프롬프트와 Provider에서 동일한 camelCase 사용

❌ 실수 4: Screen에서 존재하지 않는 필드 참조
   → 해결: Provider 클래스의 실제 필드명 확인 후 사용
```

### 15.7 검증 명령어

```bash
# 1. 프롬프트 JSON 스키마 확인
grep -A 50 "JSON 스키마" yearly_2026_prompt.dart

# 2. Provider fromJson 확인
grep -A 100 "fromJson" new_year_fortune_provider.dart

# 3. 두 파일 비교하여 필드명 일치 확인
```

---

**⚠️ 기억하세요**: AI 프롬프트를 수정하면 반드시 Provider와 Screen도 함께 수정!

---

## 16. saju_analyses 통합 (v5.2)

> **핵심**: saju_analyses 테이블의 합충/신살/용신 데이터를 파싱하여 프롬프트에 전달

### 16.1 데이터 흐름

```
┌─────────────────────────────────────────────────────────────────┐
│                    saju_analyses 테이블                          │
│  day_gan, day_ji, yongsin, hapchung, sinsal_list, twelve_sinsal │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│            SajuAnalysesQueries.getForFortuneInput()             │
│                                                                 │
│  _parseHapchung() → 합충 요약 (summary)                          │
│  _parseSinsal()   → 길신/흉신/중립 분류                          │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│               FortuneCoordinator.analyzeAllFortunes()            │
│                                                                 │
│  final sajuAnalyses = await _sajuAnalysesQueries.getForFortuneInput();
│  final inputData = FortuneInputData.fromSajuBase(               │
│    sajuAnalyses: sajuAnalyses,  // ← 파싱된 데이터 전달          │
│  );                                                             │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FortuneInputData getter                       │
│                                                                 │
│  hapchung    → sajuAnalyses?['hapchung']   (파싱된 Map)         │
│  sinsal      → sajuAnalyses?['sinsal']     (파싱된 Map)         │
│  sinsalInfo  → sinsal?['summary']          (프롬프트용 문자열)  │
│  hapchungInfo→ hapchung?['summary']        (프롬프트용 문자열)  │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     각 프롬프트 사용                              │
│                                                                 │
│  ## 신살(神煞)                                                   │
│  ${inputData.sinsalInfo}                                        │
│                                                                 │
│  ## 합충형파해                                                   │
│  ${_formatHapchung()}  // hapchung['summary'] 사용              │
└─────────────────────────────────────────────────────────────────┘
```

### 16.2 SajuAnalysesQueries 핵심 메서드

**파일**: `common/saju_analyses_queries.dart`

```dart
/// DB에서 조회 + 파싱
Future<Map<String, dynamic>?> getForFortuneInput(String profileId) async {
  final response = await _supabase.from('saju_analyses').select('''
    year_gan, year_ji, month_gan, month_ji,
    day_gan, day_ji, hour_gan, hour_ji,
    yongsin, hapchung, day_strength,
    sinsal_list, twelve_sinsal, sipsin_info
  ''').eq('profile_id', profileId).maybeSingle();

  return _parseForPrompt(response);
}

/// 합충형파해 파싱
Map<String, dynamic>? _parseHapchung(Map<String, dynamic>? hapchung) {
  // 천간합충, 지지합, 지지충형파해 분류
  // summary 문자열 생성:
  // - 천간 합충: 을경합화금(乙庚合化金)
  // - 지지 합: 인오술 삼합(火局)
  // - 지지 충형파해: 자오충(子午衝)
}

/// 신살 파싱
Map<String, dynamic>? _parseSinsal(List? sinsalList, List? twelveSinsal) {
  // 길신/흉신/중립 분류
  // summary 문자열 생성:
  // - 길신(吉神): 천을귀인(년주), 천덕귀인(월주)
  // - 흉신(凶神): 도화살(일주), 역마살(시주)
}
```

### 16.3 FortuneInputData 추가된 getter

| getter | 반환 | 용도 |
|--------|------|------|
| `sinsal` | `Map<String, dynamic>?` | 신살 전체 데이터 |
| `sipsinInfo` | `Map<String, dynamic>?` | 십신 정보 |
| `sinsalInfo` | `String` | 프롬프트용 신살 요약 |
| `hapchungInfo` | `String` | 프롬프트용 합충 요약 |

### 16.4 프롬프트 변경 사항

3개 프롬프트 모두에 신살 정보 섹션 추가:

```dart
// yearly_2026_prompt.dart
## 합충형파해
${_formatHapchung()}

## 신살(神煞)           // ← NEW!
${inputData.sinsalInfo}

## 현재 대운/세운
```

### 16.5 파싱된 데이터 예시

**합충 (hapchung)**:
```json
{
  "cheongan_hapchung": "을경합화금(乙庚合化金)",
  "jiji_haps": "인오술 삼합(火局)",
  "jiji_chunghyungpaehae": "자오충(子午衝), 축술형(丑戌刑)",
  "total_haps": 2,
  "total_chungs": 1,
  "summary": "- 천간 합충: 을경합화금(乙庚合化金)\n- 지지 합: 인오술 삼합(火局)\n- 지지 충형파해: 자오충(子午衝)"
}
```

**신살 (sinsal)**:
```json
{
  "gilsin": "천을귀인(년주), 천덕귀인(월주), 장성(월주)",
  "hyungsin": "도화살(일주), 역마살(시주)",
  "neutral": "화개살(년주)",
  "summary": "- 길신(吉神): 천을귀인(년주), 천덕귀인(월주)\n- 흉신(凶神): 도화살(일주), 역마살(시주)\n- 중립: 화개살(년주)"
}
```
