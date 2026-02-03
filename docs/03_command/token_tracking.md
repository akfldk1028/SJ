# Token 추적 시스템

## 개요

사용자별 일일 토큰 사용량을 `user_daily_token_usage` 테이블에서 추적한다.
운세 분석(운세 콘텐츠)과 채팅(대화)을 분리하여 관리하며, **쿼터(일일 제한)는 채팅 토큰에만 적용**된다.

---

## 테이블: `user_daily_token_usage`

### 토큰 컬럼 (6종)

| 컬럼 | 기록 주체 | 설명 |
|------|----------|------|
| `saju_analysis_tokens` | ai-openai-result (Edge Function) | GPT-5.2 사주 분석 (saju_base) |
| `daily_fortune_tokens` | PostgreSQL trigger (`trg_update_token_usage_on_ai_summaries`) | Gemini 일운 분석 |
| `monthly_fortune_tokens` | ai-openai-result (Edge Function) | GPT-5-mini 월운 분석 |
| `yearly_fortune_2025_tokens` | ai-openai-result (Edge Function) | GPT-5-mini 2025 회고 |
| `yearly_fortune_2026_tokens` | ai-openai-result (Edge Function) | GPT-5-mini 2026 신년운 |
| `chatting_tokens` | PostgreSQL trigger (`trg_update_daily_chat_tokens`) | Gemini 채팅 대화 |

### Generated 컬럼 (자동 계산)

| 컬럼 | 수식 | 설명 |
|------|------|------|
| `my_fortune_tokens` | `saju_analysis + daily_fortune + monthly + yearly_2025 + yearly_2026` | 운세 토큰 합계 |
| `total_tokens` | `my_fortune_tokens + chatting_tokens` | 전체 토큰 합계 |
| `total_cost_usd` | `gpt_cost_usd + gemini_cost_usd` | 전체 비용 합계 |
| `is_quota_exceeded` | `chatting_tokens >= (daily_quota + bonus_tokens + rewarded_tokens_earned)` | 쿼터 초과 여부 (v27: 보상 토큰 포함) |

### 광고 보상 컬럼 (v27 추가, v29 수정)

| 컬럼 | 기록 주체 | 설명 |
|------|----------|------|
| `bonus_tokens` | `add_ad_bonus_tokens` RPC | Rewarded Ad(보상형 광고) 보상 |
| `rewarded_tokens_earned` | `trackRewarded()` → `increment_ad_counter` | 보상형 영상 시청 보상 |
| `native_tokens_earned` | `add_native_bonus_tokens` RPC | Native 광고 **클릭** 보상 (+7,000/회). 노출만으로는 0 |
| `ads_watched` | `add_ad_bonus_tokens` + `add_native_bonus_tokens` RPC | 광고 보상 지급 횟수 합산 |

### 쿼터 설정

| 사용자 유형 | `daily_quota` | 비고 |
|------------|--------------|------|
| 일반 사용자 | **20,000** | 채팅 토큰만 차감 |
| 관리자 (admin) | 1,000,000,000 | 실질적 무제한 |

---

## 토큰 기록 경로 (6개 파이프라인)

### 1. 사주 분석 (`saju_analysis_tokens`)

```
Flutter → ai-openai (Edge Function) → GPT-5.2 Background Mode
        → ai-openai-result (polling) → completed 시 토큰 기록
        → getTokenColumnForTaskType('saju_base') → 'saju_analysis_tokens'
```

- **모델**: GPT-5.2 (OpenAI)
- **task_type**: `saju_base`, `saju_base_phase1~4`
- **기록 시점**: ai-openai-result에서 `completed` 또는 `incomplete` 상태 감지 시
- **캐시**: `saju_analyses` 테이블 (한번 생성 후 영구 보관)

### 2. 일운 (`daily_fortune_tokens`)

```
Flutter (DailyService) → Gemini API 직접 호출
        → ai_summaries 테이블에 INSERT
        → PostgreSQL trigger → user_daily_token_usage 업데이트
```

- **모델**: Gemini 3.0 Flash (Google)
- **트리거**: `trg_update_token_usage_on_ai_summaries` → `update_user_daily_token_usage()`
- **조건**: `summary_type = 'daily_fortune'`만 처리
- **캐시**: `ai_summaries` 테이블 (당일 만료)

### 3. 월운 (`monthly_fortune_tokens`)

```
Flutter → ai-openai (Edge Function) → GPT-5.2 Background Mode
        → ai-openai-result (polling) → completed 시 토큰 기록
        → getTokenColumnForTaskType('monthly_fortune') → 'monthly_fortune_tokens'
```

- **모델**: GPT-5.2 (OpenAI)
- **task_type**: `monthly_fortune`
- **캐시**: `ai_summaries` 테이블 (월 단위 만료)

### 4. 2025 회고 (`yearly_fortune_2025_tokens`)

```
Flutter → ai-openai (Edge Function) → GPT-5.2 Background Mode
        → ai-openai-result (polling) → completed 시 토큰 기록
        → getTokenColumnForTaskType('yearly_2025') → 'yearly_fortune_2025_tokens'
```

- **모델**: GPT-5.2 (OpenAI)
- **task_type**: `yearly_2025`
- **캐시**: `ai_summaries` 테이블 (연 단위)

### 5. 2026 신년운 (`yearly_fortune_2026_tokens`)

```
Flutter → ai-openai (Edge Function) → GPT-5.2 Background Mode
        → ai-openai-result (polling) → completed 시 토큰 기록
        → getTokenColumnForTaskType('yearly_2026') → 'yearly_fortune_2026_tokens'
```

- **모델**: GPT-5.2 (OpenAI)
- **task_type**: `yearly_2026`
- **캐시**: `ai_summaries` 테이블 (연 단위)

### 6. 채팅 (`chatting_tokens`)

```
Flutter → ai-gemini (Edge Function) → Gemini API 호출
        → chat_messages 테이블에 INSERT (assistant 메시지)
        → PostgreSQL trigger → user_daily_token_usage 업데이트
```

- **모델**: Gemini 3.0 Flash (Google)
- **트리거**: `trg_update_daily_chat_tokens` → `update_daily_chat_tokens()`
- **추가 기록**: `chatting_message_count`, `chatting_session_count`

---

## 쿼터 면제 시스템 (v39)

### 원칙

운세 분석은 앱의 핵심 콘텐츠이므로 쿼터에서 면제된다.
한번 생성되면 캐시되어 재사용되므로 반복 비용이 발생하지 않는다.

### 면제 대상 (ai-openai Edge Function)

```typescript
const QUOTA_EXEMPT_TASK_TYPES = new Set([
  'saju_analysis', 'saju_base',
  'saju_base_phase1', 'saju_base_phase2', 'saju_base_phase3', 'saju_base_phase4',
  'monthly_fortune', 'yearly_2025', 'yearly_2026',
]);
```

### 쿼터 체크 흐름

```
사용자 메시지 전송
  → ai-gemini Edge Function
  → user_daily_token_usage에서 chatting_tokens 조회
  → chatting_tokens >= daily_quota?
    → YES: 429 에러 반환
    → NO: Gemini API 호출 진행
```

### DB 레벨 (`is_quota_exceeded`) - v27 업데이트

```sql
is_quota_exceeded = COALESCE(chatting_tokens, 0) >= (
  COALESCE(daily_quota, 20000)
  + COALESCE(bonus_tokens, 0)        -- Native impression/click 보상
  + COALESCE(rewarded_tokens_earned, 0) -- 보상형 영상 시청 보상
)
-- 운세 토큰(my_fortune_tokens)은 포함되지 않음
-- bonus_tokens: Native 광고 impression(1,500) + click(1,500) 즉시 서버 저장
-- rewarded_tokens_earned: 영상 광고(35,000) / 네이티브 선택(21,000)
```

---

## 완료 태스크 재사용 (v39)

동일한 운세 분석을 중복 실행하지 않도록 ai-openai에서 당일 완료된 태스크를 재사용한다.

```
ai-openai 호출 시:
  1. ai_tasks에서 오늘 completed 태스크 검색
     - user_id + task_type + status='completed' + completed_at >= 오늘
  2. 있으면 → 기존 태스크 ID/결과 반환 (reused: true)
  3. 없으면 → 새 태스크 생성 → GPT-5.2 호출
```

---

## 비용 계산

### GPT-5.2 (OpenAI) - 2026-02 기준

| 항목 | 가격 (USD) |
|------|-----------|
| Input tokens | $1.75 / 1M tokens |
| Output tokens | $14.00 / 1M tokens |

- 기록 컬럼: `gpt_cost_usd`
- 기록 시점: ai-openai-result에서 completed 감지 시

### Gemini 3.0 Flash (Google) - 2026-02 기준

| 항목 | 가격 (USD) |
|------|-----------|
| Input tokens | $0.50 / 1M tokens |
| Output tokens | $3.00 / 1M tokens |

- 기록 컬럼: `gemini_cost_usd`
- 채팅: ai-gemini Edge Function에서 기록
- 일운: Flutter에서 `GeminiPricing.calculateCost()` → ai_summaries.total_cost_usd

---

## PostgreSQL 트리거 상세

### `update_user_daily_token_usage()` (ai_summaries INSERT)

```sql
-- summary_type = 'daily_fortune'인 경우만 처리
-- total_tokens 컬럼에서 daily_fortune_tokens 증가
-- UPSERT: 없으면 생성, 있으면 증가
```

### `update_daily_chat_tokens()` (chat_messages INSERT)

```sql
-- assistant 역할 메시지만 처리
-- prompt_tokens + completion_tokens → chatting_tokens 증가
-- chatting_message_count + 1
-- session별 첫 메시지면 chatting_session_count + 1
-- UPSERT 패턴
```

---

## 로드 밸런싱 (ai-openai)

3개 OpenAI API 키를 task_type 기반으로 분산:

```
key_index = hash(task_type) % 3
→ 429 에러 시 다음 키로 자동 fallback
→ 최대 3회 시도
```

---

## Edge Function 버전 (배포 기준)

| 함수명 | 배포 버전 | 주요 변경 |
|--------|----------|----------|
| **ai-openai** | **v39** | 쿼터 면제 + 완료 태스크 재사용 + Background dedup |
| **ai-openai-result** | **v32** | task_type별 토큰 컬럼 라우팅 (`getTokenColumnForTaskType`) |
| **ai-gemini** | **v22** | 쿼터 체크 `chatting_tokens`만 확인 |

---

## Supabase MCP 검증 결과 (2026-02-01)

### DB 스키마 검증

- `user_daily_token_usage` 테이블: 6개 토큰 컬럼 + 4개 generated 컬럼 확인
- `is_quota_exceeded`: `COALESCE(chatting_tokens, 0) >= daily_quota` 정상 동작 확인
- `my_fortune_tokens`: 5개 운세 컬럼 합산 정상
- `total_tokens`: `my_fortune_tokens + chatting_tokens` 정상

### 트리거 검증

- `trg_update_token_usage_on_ai_summaries`: `summary_type = 'daily_fortune'` 조건 확인
- `trg_update_daily_chat_tokens`: `role = 'assistant'` 조건 + session_count 로직 확인
- 두 트리거 모두 UPSERT 패턴 정상

### 실제 데이터 검증

- 운세 토큰(monthly_fortune_tokens, yearly_fortune_2025_tokens 등)이 각각 올바른 컬럼에 기록됨
- 50,000+ fortune tokens를 가진 사용자가 `is_quota_exceeded = false`로 정상 (채팅 토큰만 판단)
- `chatting_tokens`가 `daily_quota` 미만인 경우 쿼터 미초과 정상

### 로컬 ↔ 배포 동기화

- `ai-openai/index.ts`: 로컬 → v39 동기화 완료
- `ai-openai-result/index.ts`: 로컬 → v32 동기화 완료 (v31에서 `getTokenColumnForTaskType` 누락 수정)
- `ai-gemini/index.ts`: 로컬 → v22 동기화 완료

---

## 수정 기록

### 2026-02-02 (v29 — Native Click 추적 수정)

> 근본 원인: CardNativeAdWidget에서 토큰 미지급 + ad_events에 reward_amount 누락 + `_ensureAiSummary` race condition

**1. CardNativeAdWidget 토큰 지급 버그 수정** (`card_native_ad_widget.dart`)
- **Before**: `trackNativeClick()` 만 호출 → `native_clicks +1` BUT `native_tokens_earned +0`
- **After**: `trackNativeClick(rewardTokens: 7000)` + `grantNativeAdTokens(7000)` 추가
- 메뉴 화면 카드 광고 클릭 시 토큰 미지급 문제 해결

**2. `trackNativeClick()` — `rewardTokens` 파라미터 추가** (`ad_tracking_service.dart`)
- `ad_events` 테이블에 `reward_amount` 기록 (기존: 항상 `null`)
- `native_tokens_earned` 증가는 `add_native_bonus_tokens` RPC에서만 처리 (이중 카운팅 방지)
- 4개 호출부 모두 `rewardTokens: 7000` 전달

**3. `conversational_ad_provider._onAdClicked()` 리팩토링**
- 토큰 금액 결정 → 추적 → 지급 순서를 명확화
- `trackNativeClick(rewardTokens:)` 에 금액 전달

**4. `increment_ad_counter` RPC 업데이트** (Supabase)
- TEXT 버전 + DATE 버전 **모두** `native_tokens_earned` 허용 컬럼 추가
- DATE 버전에 누락된 `ads_watched`, `bonus_tokens_earned`도 추가

**5. iOS Ad Unit ID assert 가드** (`ad_config.dart`)
- production 모드에서 `YOUR_*_IOS_ID` placeholder 사용 시 debug assert 에러
- `banner`, `interstitial`, `rewarded`, `native` 4개 getter 모두 적용

**6. `_ensureAiSummary()` Completer lock** (`chat_provider.dart`)
- 빠른 연속 메시지 전송 시 Edge Function 중복 호출 방지
- `Completer<AiSummary?>` 패턴으로 진행 중인 Future 재사용
- `clearSession()` 시 `_aiSummaryCompleter = null` 리셋

**7. DB 데이터 비정상 원인 확인**
- 2/2 일부 유저 `tokens_per_click = 30,000` (기대값 7,000)
- **원인**: `adfdd7d` 커밋에서 30000→7000 변경. 이전 APK 사용자가 30000 기준으로 토큰 수령
- `271121f6` (1click=7000) 만 새 APK 사용자
- 2/1 데이터: 모든 유저 `native_tokens_earned = 0` → CardNativeAdWidget 버그 확인

### 2026-02-01 (v27)

1. **bonus_tokens 즉시 서버 저장**: `_saveBonusToServer()` → impression/click 시점에 `add_ad_bonus_tokens` RPC 즉시 호출
2. **is_quota_exceeded 재정의**: `chatting_tokens >= (daily_quota + bonus_tokens + rewarded_tokens_earned)`
3. **daily_quota**: 50,000 → **20,000**
4. **GPT-5.2 가격**: $1.75/$14.00 per 1M tokens
5. **Gemini 3.0 Flash 가격**: $0.50/$3.00 per 1M tokens
6. **보상 토큰 추가**: `depletedRewardTokensVideo`(35,000), `depletedRewardTokensNative`(21,000)
7. **쿼터 기준 변경**: `total_tokens` → `chatting_tokens` (운세 토큰 면제)
8. **ai-openai v39**: 쿼터 면제 + 완료 태스크 재사용
9. **ai-openai-result v32**: task_type별 토큰 컬럼 라우팅
10. **ai-gemini v22**: 쿼터 체크 `chatting_tokens`만 확인
