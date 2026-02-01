# v23 코드 리뷰 & 버그 수정 요약 (2026-02-01)

Phase 1 수익화 작업 후 전체 코드 리뷰에서 발견된 버그와 수정 내역.

---

## 발견된 버그 (7건)

### Critical (3건)

| # | 버그 | 위치 | 영향 |
|---|------|------|------|
| 1 | `userId` → `user_id` 변수명 오류 | `ai-gemini/index.ts:383` | non-streaming 경로에서 ReferenceError → 토큰 기록 실패 |
| 2 | `chatting_tokens` 미업데이트 | `ai-gemini recordTokenUsage()` | `gemini_cost_usd`만 기록, chatting_tokens 항상 0 → **서버 quota 체크 무효** |
| 3 | `is_quota_exceeded` 잘못된 formula | DB generated column | `bonus_tokens_earned` + `rewarded_tokens_earned` 사용 (잘못된 컬럼) + fallback 50000 |

### Medium (2건)

| # | 버그 | 위치 | 영향 |
|---|------|------|------|
| 4 | ai-openai `checkQuota`에 `bonus_tokens` 미포함 | `ai-openai/index.ts` | 보너스 토큰 받아도 GPT 호출 시 quota 초과 판정 |
| 5 | `impressionRewardTokens` 미연결 | `conversational_ad_provider.dart` | 상수 정의만 있고 impression 콜백에서 미사용 → 보상 0 |

### Bug Fix (2건)

| # | 버그 | 위치 | 영향 |
|---|------|------|------|
| 6 | 80% warning + 0 보상 → 보상형 광고 로드 | `ad_trigger_service.dart` | warningRewardTokens=0인데 rewarded ad 로드 → 빈 보상 + AdMob 정책 위반 위험 |
| 7 | intent classification이 message count 증가 | `ai-gemini recordTokenUsage()` | 의도 분류 호출도 chatting_message_count +1 → 실제보다 2배 집계 |

---

## 수정 파일 & 변경 내역

### 1. `supabase/functions/ai-gemini/index.ts` (v22 → v23)

| 수정 | Before | After |
|------|--------|-------|
| 변수명 오류 (line 383) | `userId` (미정의) | `user_id` |
| recordTokenUsage | `gemini_cost_usd`만 UPDATE | `chatting_tokens`, `chatting_message_count`, `gemini_cost_usd` 모두 UPDATE |
| countAsMessage 파라미터 추가 | 없음 | `countAsMessage: boolean = true` (의도 분류는 false) |
| 의도 분류 가격 | $0.075/$0.30 | $0.10/$0.40 (Gemini 2.5 Flash Lite 공식가) |
| 버전 로그 | v22 | v23 |

**핵심**: `recordTokenUsage`가 chatting_tokens를 직접 UPDATE하도록 복원.
v17에서 정상 동작하던 것이 v21에서 "PostgreSQL trigger가 처리" 주장하며 제거되었으나, 해당 trigger는 존재하지 않았음.

### 2. `supabase/functions/ai-openai/index.ts`

| 수정 | Before | After |
|------|--------|-------|
| checkQuota select | `total_tokens, daily_quota` | `total_tokens, daily_quota, bonus_tokens` |
| effectiveQuota 계산 | `baseQuota` | `baseQuota + bonusTokens` |

### 3. `frontend/lib/features/saju_chat/presentation/providers/conversational_ad_provider.dart`

| 수정 | Before | After |
|------|--------|-------|
| onAdImpression 콜백 | `adWatched: true` 만 설정 | `adWatched: true` + `rewardedTokens: AdTriggerService.impressionRewardTokens (1500)` |
| shownAdCount 추적 | 없음 | impression마다 `_shownAdCount++` |

### 4. `frontend/lib/features/saju_chat/data/services/ad_trigger_service.dart`

| 수정 | Before | After |
|------|--------|-------|
| impressionRewardTokens | 500 | 1500 |
| checkTokenTrigger 80% 분기 | 항상 tokenNearLimit 반환 | `warningRewardTokens <= 0`이면 `none` 반환 (비활성화) |

### 5. DB `is_quota_exceeded` generated column

| 수정 | Before | After |
|------|--------|-------|
| Formula | `chatting_tokens >= 50000 + bonus_tokens_earned + rewarded_tokens_earned` | `chatting_tokens >= (daily_quota(20000) + bonus_tokens)` |

### 6. `supabase/functions/README.md`

| 수정 | Before | After |
|------|--------|-------|
| 토큰 기록 설명 | "chatting_tokens는 PostgreSQL trigger가 처리" | "Edge Function에서 직접 UPDATE, trigger 없음" |
| 버전 히스토리 | v22까지 | v23 추가 |

---

## DB 추적 현황 (`user_daily_token_usage`)

### 정상 추적되는 컬럼

| 컬럼 | 업데이트 위치 | 비고 |
|------|-------------|------|
| `chatting_tokens` | ai-gemini `recordTokenUsage` | v23에서 복원 |
| `chatting_message_count` | ai-gemini `recordTokenUsage` | v23에서 복원, intent 제외 |
| `gemini_cost_usd` | ai-gemini `recordTokenUsage` | 기존 정상 |
| `gpt_cost_usd` | ai-openai | 기존 정상 |
| `saju_analysis_tokens` | ai-openai | 기존 정상 |
| `bonus_tokens` | `add_bonus_tokens` RPC (client) | v23에서 추가 |
| `daily_quota` | DB default 20000 | 기존 정상 |

### Generated 컬럼 (자동 계산)

| 컬럼 | Formula |
|------|---------|
| `my_fortune_tokens` | saju + daily + monthly + yearly |
| `total_tokens` | my_fortune_tokens + chatting_tokens |
| `total_cost_usd` | gpt_cost_usd + gemini_cost_usd |
| `is_quota_exceeded` | chatting_tokens >= (daily_quota + bonus_tokens) |

### 미추적 컬럼 (항상 0)

| 컬럼 | 이유 |
|------|------|
| `daily_fortune_tokens` | 운세 Edge Function에서 미기록 |
| `monthly_fortune_tokens` | 운세 Edge Function에서 미기록 |
| `yearly_fortune_2025_tokens` | 운세 Edge Function에서 미기록 |
| `yearly_fortune_2026_tokens` | 운세 Edge Function에서 미기록 |
| `chatting_session_count` | v21에서 제거 후 미복원 |
| `ads_watched` | 광고 추적은 별도 `ad_events` 테이블 사용 |
| `bonus_tokens_earned` | 레거시, `bonus_tokens`로 대체 |
| `total_api_calls` | 미구현 |
| `banner_*`, `interstitial_*`, `rewarded_*`, `native_*` | 광고 추적은 별도 `ad_events` 테이블 사용 |

---

## 남은 작업

| # | 작업 | 상태 | 비고 |
|---|------|------|------|
| 1 | `is_quota_exceeded`에서 `rewarded_tokens_earned` 제거 | ⬜ 미완 | 현재 formula에 아직 포함됨 (값은 0이라 실해 없음) |
| 2 | Edge Function 배포 (ai-gemini, ai-openai) | ⬜ 미배포 | `supabase functions deploy` 필요 |
| 3 | 운세 토큰 추적 (daily/monthly/yearly) | ⬜ 미구현 | 운세 Edge Function 수정 필요 |
| 4 | `chatting_session_count` 복원 여부 결정 | ⬜ 미결정 | 별도 세션 추적 필요 |
| 5 | flutter analyze 전체 통과 확인 | ⬜ 미확인 | |
