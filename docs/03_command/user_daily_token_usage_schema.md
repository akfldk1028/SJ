# user_daily_token_usage 테이블 스키마

> 유저별 일일 토큰 사용량 + 광고 추적 + 비용 기록
> PK: `(user_id, usage_date)` UNIQUE

---

## 핵심 계산식

```
effective_quota = daily_quota + bonus_tokens + rewarded_tokens_earned + native_tokens_earned

is_quota_exceeded = chatting_tokens >= effective_quota
```

- `chatting_tokens`만 쿼터 대상 (운세 토큰은 면제)
- 광고 보상 토큰은 3개 컬럼으로 분리 추적

---

## 필드 설명

### 기본 키

| 컬럼 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `id` | UUID | `gen_random_uuid()` | PK |
| `user_id` | UUID | - | `auth.users.id` FK |
| `usage_date` | DATE | `CURRENT_DATE` | 기록 날짜 (일별 1행) |

### 토큰 사용량 (AI 호출 시 기록)

| 컬럼 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `chatting_tokens` | INT | 0 | AI 채팅에 사용된 토큰. **쿼터 대상**. DB 트리거(`update_daily_chat_tokens`)가 `chat_messages` INSERT 시 자동 기록 |
| `saju_analysis_tokens` | INT | 0 | GPT 사주 분석(평생운세)에 사용된 토큰. 쿼터 면제 |
| `daily_fortune_tokens` | INT | 0 | 오늘의 운세에 사용된 토큰. 쿼터 면제 |
| `monthly_fortune_tokens` | INT | 0 | 월별 운세에 사용된 토큰. 쿼터 면제 |
| `yearly_fortune_2025_tokens` | INT | 0 | 2025년 회고 운세. 쿼터 면제 |
| `yearly_fortune_2026_tokens` | INT | 0 | 2026년 신년 운세. 쿼터 면제 |
| `my_fortune_tokens` | INT | NULL | (예비) |

### 쿼터 & 보상 토큰

| 컬럼 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `daily_quota` | INT | 20,000 | 일일 기본 할당량. 무과금 유저 20,000 / 프리미엄 구독자는 Edge Function에서 면제 |
| `bonus_tokens` | INT | 0 | **Rewarded Ad(보상형 광고)** 시청으로 획득한 토큰. RPC: `add_ad_bonus_tokens` |
| `rewarded_tokens_earned` | INT | 0 | Rewarded Video 시청 완료로 획득한 토큰. `trackRewarded()` → `incrementDailyCounter` |
| `native_tokens_earned` | INT | 0 | **Native Ad(네이티브 광고) 클릭**으로 획득한 토큰. 노출만으로는 0. RPC: `add_native_bonus_tokens` |
| `is_quota_exceeded` | BOOL | GENERATED | `chatting_tokens >= (daily_quota + bonus_tokens + rewarded_tokens_earned + native_tokens_earned)` 자동 계산 |

### 광고 추적 - 카운터

| 컬럼 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `ads_watched` | INT | 0 | 총 광고 시청 횟수 (모든 타입 합산). RPC에서 +1 |
| `banner_impressions` | INT | 0 | 배너 광고 노출 수 |
| `banner_clicks` | INT | 0 | 배너 광고 클릭 수 |
| `interstitial_shows` | INT | 0 | 전면 광고 표시 수 |
| `interstitial_completes` | INT | 0 | 전면 광고 완료(닫기) 수 |
| `interstitial_clicks` | INT | 0 | 전면 광고 클릭 수 |
| `rewarded_shows` | INT | 0 | 보상형 광고 표시 수 |
| `rewarded_completes` | INT | 0 | 보상형 광고 완료(시청 완료) 수 |
| `rewarded_clicks` | INT | 0 | 보상형 광고 클릭 수 |
| `native_impressions` | INT | 0 | 네이티브 광고 노출 수 |
| `native_clicks` | INT | 0 | 네이티브 광고 클릭 수 |

### 비용 추적

| 컬럼 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `gpt_cost_usd` | NUMERIC | 0 | GPT-5.2 API 비용 ($). `ai-openai` Edge Function이 기록 |
| `gemini_cost_usd` | NUMERIC | 0 | Gemini 3.0 Flash API 비용 ($). `ai-gemini` Edge Function이 기록 |
| `total_cost_usd` | NUMERIC | GENERATED | `gpt_cost_usd + gemini_cost_usd` |

### 통계

| 컬럼 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `chatting_session_count` | INT | 0 | 채팅 세션 수 |
| `chatting_message_count` | INT | 0 | 채팅 메시지 수 |
| `total_api_calls` | INT | 0 | 총 API 호출 수 |
| `total_tokens` | INT | GENERATED | 모든 토큰 합산 (채팅 + 운세) |
| `bonus_tokens_earned` | INT | 0 | (레거시, bonus_tokens로 대체됨) |

### 메타

| 컬럼 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `user_display_name` | TEXT | NULL | 유저 표시 이름 (대시보드 편의용) |
| `created_at` | TIMESTAMPTZ | `now()` | 레코드 생성 시각 |
| `updated_at` | TIMESTAMPTZ | `now()` | 마지막 수정 시각 |

---

## RPC 함수

### `add_ad_bonus_tokens(p_user_id, p_bonus_tokens)`
- Rewarded Ad 시청 완료 시 호출
- `bonus_tokens += p_bonus_tokens`, `ads_watched += 1`
- 반환: `{ success, new_quota, new_remaining }`

### `add_native_bonus_tokens(p_user_id, p_bonus_tokens)`
- Native Ad impression/click 시 호출
- `native_tokens_earned += p_bonus_tokens`, `ads_watched += 1`
- 반환: `{ success, new_quota, new_remaining }`

---

## 쿼터 체크 위치 (3곳 동기화 필수)

| 위치 | 파일 | 공식 |
|------|------|------|
| DB | `is_quota_exceeded` GENERATED 컬럼 | `chatting_tokens >= (daily_quota + bonus_tokens + rewarded_tokens_earned + native_tokens_earned)` |
| Edge Function | `ai-gemini/index.ts` `checkAndUpdateQuota()` | `effectiveQuota = baseQuota + bonusTokens + rewardedTokens + nativeTokens` |
| Edge Function | `ai-openai/index.ts` `checkQuota()` | `effectiveQuota = baseQuota + bonusTokens + rewardedTokens + nativeTokens` |

> 3곳의 공식이 항상 일치해야 함. 하나라도 빠지면 쿼터 판정 불일치 발생.

---

## 토큰 출처별 분리 (v28)

```
effective_quota 구성:
┌─────────────────┐
│ daily_quota      │  기본 20,000 (매일 리셋)
├─────────────────┤
│ bonus_tokens     │  Rewarded Ad 보상 (add_ad_bonus_tokens RPC)
├─────────────────┤
│ rewarded_tokens  │  Rewarded Video 시청 완료 (+20,000/회)
├─────────────────┤
│ native_tokens    │  Native Ad **클릭** 보상 (+30,000/회, 노출만으로는 0)
└─────────────────┘
```

---

## 무한 채팅 사이클

```
1. 기본 20,000 토큰 → 약 3교환
2. 토큰 소진 → 2버튼 UI (Rewarded Video / Native Ad)
3. Rewarded Video 시청 → rewarded_tokens_earned +20,000 → 약 3교환 추가
4. Native Ad 클릭 → native_tokens_earned +30,000 → 약 4교환 추가
5. 다시 소진 → 2번으로 돌아감 (무한 반복)
6. 인터벌 광고 클릭 시 → native_tokens_earned +30,000 추가
7. 인터벌/인라인 노출만 → 토큰 0 (순수 eCPM 수익)
```
