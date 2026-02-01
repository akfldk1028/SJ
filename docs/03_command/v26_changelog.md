# v26 Changelog - Edge Function Bug Fixes + Ad System Integration

> 작성일: 2026-02-01
> 작업자: DK (Claude Code)
> 영향 범위: Supabase Edge Functions (3개) + Flutter ad flow (3개 파일) + Flutter Gemini datasource (1개)

---

## 1. 개요

### 수정된 버그 (6개)
| # | 심각도 | 버그 | 영향 |
|---|--------|------|------|
| 1 | CRITICAL | ai-gemini 스트리밍 버퍼 미플러시 → usageMetadata 유실 | gemini_cost_usd ≈ $0 (실제 $0.03/msg) |
| 2 | CRITICAL | chatting_tokens 이중 기록 (Edge Function + DB 트리거) | 쿼터 2배 속도로 소진 |
| 3 | MEDIUM | ai-openai checkQuota가 total_tokens 사용 | DB GENERATED is_quota_exceeded와 불일치 |
| 4 | MEDIUM | Gemini 3.0 thinking 파트 미필터링 | AI 내부 사고과정이 사용자에게 노출 |
| 5 | MEDIUM | Rewarded ad 이중 토큰 지급 | bonus_tokens + rewarded_tokens_earned 동시 증가 → 쿼터 2배 확장 |
| 6 | MINOR | Native ad impression 서버 추적 누락 | native_impressions, ads_watched 항상 0 |

### 배포된 Edge Functions
| Function | Version | 상태 |
|----------|---------|------|
| ai-gemini | v43 | ACTIVE |
| ai-openai | v42 | ACTIVE |
| ai-openai-result | v32 | 변경 없음 (기존 reasoning 필터링 이미 완료) |

---

## 2. Edge Function 변경 상세

### 2.1 ai-gemini (v25 코드, v43 배포)

**파일**: `supabase/functions/ai-gemini/index.ts`

#### BUG 1: 스트리밍 버퍼 미플러시 (CRITICAL)

**원인**: SSE 스트리밍 루프에서 `buffer = lines.pop() || ""`으로 마지막 불완전 라인을 보관하는데, 스트림 종료(`done=true`) 시 잔여 buffer를 처리하지 않음. Gemini API는 마지막 SSE 청크에 `usageMetadata`를 포함하므로, 이 데이터가 유실됨.

**증상**: `gemini_cost_usd`가 모든 유저에 대해 ≈ $0.0002 (실제 ≈ $0.03/msg)

**수정**:
```typescript
// 루프 종료 후 잔여 버퍼 처리
buffer += decoder.decode(new Uint8Array(), { stream: false }); // TextDecoder flush
if (buffer.trim()) {
  const remainingLines = buffer.split("\n");
  for (const line of remainingLines) {
    processSSELine(line); // usageMetadata 캡처
  }
}
```

**검증**: 로그에 `prompt=XXXX, completion=YYYY` (0이 아닌 값) 출력 확인

#### BUG 2: chatting_tokens 이중 기록 (CRITICAL)

**원인**:
- Edge Function `recordTokenUsage()`가 `chatting_tokens` 업데이트
- DB 트리거 `update_daily_chat_tokens`가 `chat_messages` INSERT 시 `chatting_tokens` 업데이트
- 두 경로가 동시에 발동 → 토큰이 2배로 카운트

**증상**: BUG 1로 인해 Edge Function이 ~60 토큰만 기록해서 현재는 영향 미미. BUG 1 수정 후 실제 이중 기록 발생.

**수정**:
- `recordTokenUsage()` → `recordGeminiCost()`로 리네임
- `chatting_tokens` 업데이트 제거, `gemini_cost_usd`만 기록
- DB 트리거가 `chatting_tokens`를 정확히 관리

```typescript
// Before: recordTokenUsage(supabase, userId, promptTokens, completionTokens, cost, isAdmin)
//   → chatting_tokens += totalTokens (이중 기록!)
//   → gemini_cost_usd += cost

// After: recordGeminiCost(supabase, userId, promptTokens, completionTokens, cost)
//   → gemini_cost_usd += cost (만 기록)
//   → chatting_tokens는 DB 트리거가 처리
```

#### BUG 4: Gemini 3.0 thinking 파트 미필터링 (MEDIUM)

**원인**: Gemini 3.0은 `thought: true` 속성을 가진 thinking 파트를 응답에 포함. 기존 코드는 `parts[0].text`만 읽어서 thinking이 첫 번째 파트이면 그대로 노출.

**수정** (3곳):
1. **스트리밍**: `processSSELine()` 헬퍼에서 parts 배열 순회, `thought === true` 스킵
2. **비스트리밍**: 동일하게 parts 배열 순회 + 필터링
3. **Intent 분류**: gemini-2.5-flash-lite 사용 (thinking 없음), JSON 파싱이라 영향 미미

```typescript
let text = "";
const parts = candidate?.content?.parts;
if (Array.isArray(parts)) {
  for (const part of parts) {
    if (part.thought === true) continue; // thinking 스킵
    if (part.text) text += part.text;
  }
}
```

### 2.2 ai-openai (v41 코드, v42 배포)

**파일**: `supabase/functions/ai-openai/index.ts`

#### BUG 3: checkQuota가 total_tokens 사용 (MEDIUM)

**원인**: `checkQuota()` 함수가 `total_tokens` (GENERATED 컬럼, 모든 토큰 합산)을 쿼터 비교에 사용. DB의 `is_quota_exceeded`는 `chatting_tokens`만 비교.

**영향**: 운세 토큰(saju_analysis 등)이 chatting 쿼터에 포함되어 쿼터가 빨리 소진. 현재는 ai-openai가 주로 fortune task(쿼터 면제)를 처리하여 실제 영향은 작음.

**수정**:
```typescript
// Before
.select("total_tokens, daily_quota, bonus_tokens, rewarded_tokens_earned")
const currentUsage = usage?.total_tokens || 0;

// After
.select("chatting_tokens, daily_quota, bonus_tokens, rewarded_tokens_earned")
const currentUsage = usage?.chatting_tokens || 0;
```

### 2.3 ai-openai-result (v32, 변경 없음)

reasoning 필터링이 v30에서 이미 구현됨:
```typescript
// extractOutputText() 함수
if (outputItem.type === "reasoning") continue;
if (contentItem.type === "reasoning") continue;
```

---

## 3. Flutter 변경 상세

### 3.1 gemini_rest_datasource.dart - Thought 필터링

**파일**: `frontend/lib/features/saju_chat/data/datasources/gemini_rest_datasource.dart`

**비스트리밍** (line 128-135):
```dart
final buffer = StringBuffer();
for (final p in parts) {
  if (p is Map && p['thought'] == true) continue;
  final t = (p is Map) ? p['text'] as String? : null;
  if (t != null) buffer.write(t);
}
```

**스트리밍** (line 284-291):
```dart
for (final part in parts) {
  if (part is! Map) continue;
  if (part['thought'] == true) continue;
  final text = part['text'] as String?;
  if (text != null) accumulated += text;
}
```

### 3.2 chat_provider.dart - addBonusTokens 이중 기록 방지

**파일**: `frontend/lib/features/saju_chat/presentation/providers/chat_provider.dart`

**변경**: `addBonusTokens(int tokens)` → `addBonusTokens(int tokens, {bool isRewardedAd = false})`

**로직**:
- `isRewardedAd = true` (보상형 광고): client-side 토큰 확장만 수행, RPC 스킵
  - `AdTrackingService.trackRewarded()`가 이미 `rewarded_tokens_earned`를 증가시킴
  - `bonus_tokens`까지 증가하면 쿼터 2배 확장 (이중 기록 버그)
- `isRewardedAd = false` (네이티브 광고): `add_ad_bonus_tokens` RPC 호출
  - `bonus_tokens` 증가 + `ads_watched` 카운터 증가 (1 RPC로 2개 업데이트)

**RPC 변경**: `add_bonus_tokens` → `add_ad_bonus_tokens`
- `add_bonus_tokens`: bonus_tokens만 증가
- `add_ad_bonus_tokens`: bonus_tokens + ads_watched 동시 증가, 결과 반환

### 3.3 conversational_ad_widget.dart - isRewardedAd 전달

**파일**: `frontend/lib/features/saju_chat/presentation/widgets/conversational_ad_widget.dart`

**변경**: `_handleAdComplete()`에서 광고 타입 판별 후 `isRewardedAd` 전달

```dart
final isRewardedAd = adState.adType == AdMessageType.tokenDepleted ||
    adState.adType == AdMessageType.tokenNearLimit;
ref.read(chatNotifierProvider(sessionId).notifier)
    .addBonusTokens(adState.rewardedTokens!, isRewardedAd: isRewardedAd);
```

### 3.4 conversational_ad_provider.dart - Native impression 추적

**파일**: `frontend/lib/features/saju_chat/presentation/providers/conversational_ad_provider.dart`

**변경**: `onAdImpression` 콜백에 `AdTrackingService.instance.trackNativeImpression()` 추가

```dart
onAdImpression: (ad) {
  // v26: 서버 추적 추가
  AdTrackingService.instance.trackNativeImpression(
    screen: 'saju_chat_${state.adType?.name ?? 'unknown'}',
  );
  // ... 기존 로직 유지
}
```

---

## 4. 데이터 흐름 (수정 후)

### 4.1 user_daily_token_usage 업데이트 경로

```
chatting_tokens
  └─ DB 트리거 update_daily_chat_tokens (chat_messages INSERT 시)
     ※ Edge Function은 더 이상 chatting_tokens를 건드리지 않음

saju_analysis_tokens / monthly_fortune_tokens / yearly_fortune_*_tokens
  └─ ai-openai recordTokenUsage() (task_type별 컬럼 라우팅)
  └─ ai-openai-result recordTokenUsage() (동일)

daily_fortune_tokens
  └─ DB 트리거 update_user_daily_token_usage (ai_summaries INSERT 시)

gpt_cost_usd
  └─ ai-openai recordTokenUsage()
  └─ ai-openai-result recordTokenUsage()

gemini_cost_usd
  └─ ai-gemini recordGeminiCost() (v25: 버퍼 플러시 수정으로 정확한 값)

bonus_tokens
  └─ Flutter add_ad_bonus_tokens RPC (Native 광고 completion 시)
     ※ Rewarded 광고는 rewarded_tokens_earned만 사용 (이중 기록 방지)

ads_watched
  └─ Flutter add_ad_bonus_tokens RPC (Native 광고 completion 시)

rewarded_tokens_earned
  └─ AdTrackingService.trackRewarded() → increment_ad_counter RPC

native_impressions
  └─ AdTrackingService.trackNativeImpression() → increment_ad_counter RPC (v26 신규)

native_clicks
  └─ AdTrackingService.trackNativeClick() → increment_ad_counter RPC

total_tokens, total_cost_usd, is_quota_exceeded
  └─ DB GENERATED ALWAYS AS STORED (자동 계산)
```

### 4.2 쿼터 공식

```sql
is_quota_exceeded = chatting_tokens >= (daily_quota + bonus_tokens + rewarded_tokens_earned)
```

- `daily_quota`: 기본 20,000 (admin: 1,000,000,000)
- `bonus_tokens`: Native 광고 시청으로 획득 (impression: 1,500)
- `rewarded_tokens_earned`: Rewarded 광고 시청으로 획득 (depleted: 3,000)
- **v26 수정**: 두 컬럼이 같은 광고에 대해 동시에 증가하지 않음

### 4.3 광고 보상 흐름 (수정 후)

```
[Rewarded 광고] tokenDepleted (100% 소진)
  1. AdMob onUserEarnedReward 콜백
  2. AdTrackingService.trackRewarded()
     → ad_events INSERT (purpose: token_bonus)
     → increment_ad_counter('rewarded_tokens_earned', +3000)
  3. _handleAdComplete()
     → addBonusTokens(3000, isRewardedAd: true)
     → client-side 토큰 확장만, RPC 스킵
  결과: rewarded_tokens_earned += 3000

[Native 광고] intervalAd (3메시지마다)
  1. AdMob onAdImpression 콜백
     → AdTrackingService.trackNativeImpression() (v26 신규)
     → increment_ad_counter('native_impressions', +1)
  2. _handleAdComplete()
     → addBonusTokens(1500, isRewardedAd: false)
     → add_ad_bonus_tokens RPC
     → bonus_tokens += 1500, ads_watched += 1
  결과: bonus_tokens += 1500, ads_watched += 1, native_impressions += 1
```

---

## 5. 미수정 사항 (알려진 제한)

| 항목 | 상태 | 설명 |
|------|------|------|
| banner_impressions/clicks | 항상 0 | 배너 광고 미사용 (Native 광고만 사용) |
| chatting_message_count | 235 vs 실제 488 | 의도적 — assistant 메시지만 카운트 (DB 트리거 설계) |
| error_logging_service | 미구현 | chat_error_logs 테이블 + Flutter 에러 로깅 (계획에 있음) |
| message_bubble SelectableText 터치 에러 | 미수정 | 스트리밍 중 SelectableText → Text 전환 필요 |

---

## 6. 검증 방법

```sql
-- 1. gemini_cost_usd가 0이 아닌지 확인 (BUG 1 수정 검증)
SELECT user_id, gemini_cost_usd, chatting_tokens
FROM user_daily_token_usage
WHERE usage_date = CURRENT_DATE AND gemini_cost_usd > 0;

-- 2. chatting_tokens 정합성 (BUG 2 수정 검증)
-- chat_messages의 token_count 합과 user_daily_token_usage.chatting_tokens가 일치해야 함
SELECT u.chatting_tokens, SUM(m.token_count) as actual
FROM user_daily_token_usage u
JOIN chat_messages m ON m.user_id = u.user_id AND m.created_at::date = u.usage_date
WHERE u.usage_date = CURRENT_DATE AND m.role = 'assistant'
GROUP BY u.chatting_tokens;

-- 3. 광고 추적 확인 (BUG 5, 6 수정 검증)
SELECT bonus_tokens, ads_watched, rewarded_tokens_earned, native_impressions, native_clicks
FROM user_daily_token_usage
WHERE usage_date = CURRENT_DATE;
```

---

## 7. 파일 변경 요약

| 파일 | 변경 유형 | 주요 내용 |
|------|-----------|-----------|
| `supabase/functions/ai-gemini/index.ts` | 배포 v43 | 버퍼 플러시, 이중기록 방지, thought 필터링 |
| `supabase/functions/ai-openai/index.ts` | 배포 v42 | checkQuota: chatting_tokens 사용 |
| `frontend/lib/features/saju_chat/data/datasources/gemini_rest_datasource.dart` | 수정 | thought 파트 필터링 (스트리밍 + 비스트리밍) |
| `frontend/lib/features/saju_chat/presentation/providers/chat_provider.dart` | 수정 | addBonusTokens isRewardedAd 파라미터, add_ad_bonus_tokens RPC |
| `frontend/lib/features/saju_chat/presentation/widgets/conversational_ad_widget.dart` | 수정 | isRewardedAd 전달 |
| `frontend/lib/features/saju_chat/presentation/providers/conversational_ad_provider.dart` | 수정 | native impression 서버 추적 추가 |
