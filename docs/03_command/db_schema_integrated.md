# 만톡 DB 스키마 통합 문서

> 최종 업데이트: 2026-02-06 (KST)
> 대상: Supabase PostgreSQL

---

## 1. 핵심 테이블 관계도

```
auth.users (Supabase Auth)
    │
    ├─→ saju_profiles (1:N) ─→ saju_analyses (1:1)
    │         │
    │         ├─→ chat_sessions (1:N) ─→ chat_messages (1:N)
    │         │         │
    │         │         └─→ chat_mentions (1:N)
    │         │
    │         ├─→ profile_relations (N:M) ─→ compatibility_analyses
    │         │
    │         └─→ ai_summaries (1:N)
    │
    ├─→ user_daily_token_usage (1:N, 일별 1행)
    │
    ├─→ ad_events (1:N) ─→ feature_unlocks (1:N)
    │
    ├─→ ai_tasks (1:N)
    │
    └─→ subscriptions (1:N)
```

---

## 2. 주요 테이블 스키마

### 2.1 saju_profiles (사주 프로필)

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | UUID | PK |
| `user_id` | UUID | FK → auth.users |
| `display_name` | TEXT | 표시 이름 (≤12자) |
| `profile_type` | TEXT | `primary` (본인) / `other` (관계인) |
| `relation_type` | TEXT | me/family/friend/lover/work/other/admin |
| `birth_date` | DATE | 생년월일 |
| `birth_time_minutes` | INT | 출생 시간 (분, 0-1439) |
| `birth_time_unknown` | BOOL | 시간 미상 여부 |
| `is_lunar` | BOOL | 음력 여부 |
| `is_leap_month` | BOOL | 윤달 여부 |
| `gender` | TEXT | male/female |
| `birth_city` | TEXT | 출생 도시 |
| `time_correction` | INT | 시간 보정 (분) |
| `use_ya_jasi` | BOOL | 야자시 사용 여부 |

> **RLS**: `user_id = auth.uid()` 또는 admin

---

### 2.2 saju_analyses (사주 분석 결과)

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | UUID | PK |
| `profile_id` | UUID | FK → saju_profiles (UNIQUE) |
| `year_gan/ji` | TEXT | 년주 천간/지지 (한글(한자) 형식) |
| `month_gan/ji` | TEXT | 월주 천간/지지 |
| `day_gan/ji` | TEXT | 일주 천간/지지 |
| `hour_gan/ji` | TEXT | 시주 천간/지지 (nullable) |
| `oheng_distribution` | JSONB | 오행 분포 |
| `day_strength` | JSONB | 일간 강약 |
| `yongsin` | JSONB | **용신/희신/기신** (AI 상담 핵심) |
| `gyeokguk` | JSONB | 격국 |
| `sipsin_info` | JSONB | 십신 정보 |
| `jijanggan_info` | JSONB | 지장간 정보 |
| `sinsal_list` | JSONB | 12신살 |
| `twelve_unsung` | JSONB | 12운성 |
| `twelve_sinsal` | JSONB | 12신살 (기둥별) |
| `gilseong` | JSONB | 길성 (특수 신살) |
| `hapchung` | JSONB | 합충형파해 분석 |
| `daeun` | JSONB | 대운 정보 |
| `current_seun` | JSONB | 현재 세운 |
| `ai_summary` | JSONB | Gemini 생성 사주 요약 |

---

### 2.3 chat_sessions (채팅 세션)

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | UUID | PK |
| `profile_id` | UUID | FK → saju_profiles (주체) |
| `target_profile_id` | UUID | FK → saju_profiles (궁합 상대, nullable) |
| `title` | TEXT | 세션 제목 |
| `chat_type` | TEXT | dailyFortune/sajuAnalysis/compatibility/general |
| `**chat_persona**` | TEXT | **페르소나 ID** (basePerson, stRealistic, ntAnalytic 등) |
| `**mbti_quadrant**` | TEXT | MBTI 4분면 (NF/NT/SF/ST) - basePerson 선택 시 |
| `gemini_cache_name` | TEXT | Gemini Context Cache 이름 |
| `message_count` | INT | 총 메시지 수 |
| `user_message_count` | INT | 유저 메시지 수 |
| `assistant_message_count` | INT | AI 응답 수 |
| `total_tokens_used` | INT | 세션 총 토큰 (트리거 자동 계산) |
| `last_message_preview` | TEXT | 마지막 메시지 미리보기 |
| `context_summary` | TEXT | AI 요약 (토큰 절약용) |

> **페르소나 종류** (chat_persona 값):
> - `basePerson`: 기본 (MBTI 4분면 선택)
> - `stRealistic`: 현실적 ST
> - `sfFriendly`: 친근한 SF
> - `nfSensitive`: 감성적 NF
> - `ntAnalytic`: 분석적 NT
> - `sewerSaju`: 하수구 사주
> - `saOngJiMa`: 새옹지마
> - `babyMonk`: 아기 스님

---

### 2.4 chat_messages (채팅 메시지)

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | UUID | PK |
| `session_id` | UUID | FK → chat_sessions |
| `role` | TEXT | user/assistant/system |
| `content` | TEXT | 메시지 내용 |
| `tokens_used` | INT | 토큰 사용량 (assistant만 기록) |
| `suggested_questions` | TEXT[] | AI 추천 질문 |
| `status` | TEXT | sending/sent/error |
| `created_at` | TIMESTAMPTZ | 생성 시각 |

---

### 2.5 user_daily_token_usage (일별 토큰 사용량)

> PK: `(user_id, usage_date)` UNIQUE

#### 핵심 계산식
```sql
effective_quota = daily_quota + bonus_tokens + rewarded_tokens_earned + native_tokens_earned
is_quota_exceeded = chatting_tokens >= effective_quota
```

| 컬럼 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `id` | UUID | gen_random_uuid() | PK |
| `user_id` | UUID | - | FK → auth.users |
| `usage_date` | DATE | CURRENT_DATE | 기록 날짜 (KST) |

**토큰 사용량 (쿼터 대상: chatting_tokens만)**

| 컬럼 | 설명 |
|------|------|
| `chatting_tokens` | AI 채팅 토큰 **(쿼터 대상)** |
| `saju_analysis_tokens` | GPT 사주 분석 (쿼터 면제) |
| `daily_fortune_tokens` | 오늘의 운세 (쿼터 면제) |
| `monthly_fortune_tokens` | 월별 운세 (쿼터 면제) |
| `yearly_fortune_2025_tokens` | 2025 회고 (쿼터 면제) |
| `yearly_fortune_2026_tokens` | 2026 신년 (쿼터 면제) |

**쿼터 & 보상 토큰**

| 컬럼 | 기본값 | 설명 |
|------|--------|------|
| `daily_quota` | 20,000 | 일일 기본 할당량 |
| `bonus_tokens` | 0 | Rewarded Ad 보상 토큰 |
| `rewarded_tokens_earned` | 0 | Rewarded Video 완료 보상 |
| `native_tokens_earned` | 0 | Native Ad 클릭 보상 |
| `is_quota_exceeded` | GENERATED | 쿼터 초과 여부 (자동 계산) |

**광고 카운터**

| 컬럼 | 설명 |
|------|------|
| `ads_watched` | 총 광고 시청 횟수 |
| `banner_impressions/clicks` | 배너 광고 |
| `interstitial_shows/completes/clicks` | 전면 광고 |
| `rewarded_shows/completes/clicks` | 보상형 광고 |
| `native_impressions/clicks` | 네이티브 광고 |

**비용 추적**

| 컬럼 | 설명 |
|------|------|
| `gpt_cost_usd` | GPT API 비용 ($) |
| `gemini_cost_usd` | Gemini API 비용 ($) |
| `total_cost_usd` | GENERATED: gpt + gemini |

---

### 2.6 ai_summaries (AI 분석 결과)

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | UUID | PK |
| `user_id` | UUID | FK → auth.users |
| `profile_id` | UUID | FK → saju_profiles |
| `summary_type` | TEXT | saju_base/daily_fortune/monthly_fortune/yearly_fortune_2025/yearly_fortune_2026 등 |
| `target_date` | DATE | 일운 대상 날짜 |
| `target_year` | SMALLINT | 대상 연도 (KST) |
| `target_month` | SMALLINT | 대상 월 (1-12, KST) |
| `content` | JSONB | AI 분석 결과 |
| `prompt_version` | TEXT | 프롬프트 버전 (V1.0, V2.0 등) |
| `model_provider` | TEXT | openai/google/anthropic |
| `model_name` | TEXT | 모델명 |
| `total_tokens` | INT | 총 토큰 |
| `cached_tokens` | INT | 캐싱된 토큰 |
| `total_cost_usd` | NUMERIC | API 비용 ($) |
| `status` | TEXT | pending/processing/completed/failed/cached |
| `expires_at` | TIMESTAMPTZ | 캐시 만료 시간 |

> **UNIQUE 제약**: `(user_id, profile_id, summary_type, target_year, target_month, target_date)`

---

### 2.7 compatibility_analyses (궁합 분석)

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | UUID | PK |
| `profile1_id` | UUID | FK → saju_profiles (요청자) |
| `profile2_id` | UUID | FK → saju_profiles (상대방) |
| `analysis_type` | TEXT | general/love/business/friendship/family |
| `overall_score` | INT | 종합 점수 (0-100) |
| `category_scores` | JSONB | 카테고리별 점수 |
| `owner_hapchung` | JSONB | 나(profile1)의 합충형해파 |
| `pair_hapchung` | JSONB | 두 사람 간 합충형해파 **(핵심)** |
| `target_*` | 각종 | 상대방 사주 정보 (년/월/일/시주, 오행, 신살 등) |
| `summary` | TEXT | 요약 |
| `strengths` | TEXT[] | 장점 목록 |
| `challenges` | TEXT[] | 주의점 목록 |
| `advice` | TEXT | 조언 |

---

### 2.8 ad_events (광고 이벤트 로그)

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | UUID | PK |
| `user_id` | UUID | FK → auth.users |
| `profile_id` | UUID | FK → saju_profiles |
| `ad_type` | TEXT | banner/interstitial/rewarded/native |
| `event_type` | TEXT | impression/show/complete/click/rewarded |
| `purpose` | TEXT | feature_unlock/token_bonus/general |
| `screen` | TEXT | 화면 식별자 (규칙: {feature_type}_{feature_key}_{target_year}[_{target_month}]) |
| `reward_amount` | INT | 보상 금액 |
| `revenue_micros` | BIGINT | 광고 수익 (1,000,000 = $1.00) |
| `revenue_currency` | TEXT | 통화 코드 (USD) |
| `device_info` | JSONB | 디바이스 정보 |

---

### 2.9 feature_unlocks (기능 해금)

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | UUID | PK |
| `user_id` | UUID | FK → auth.users |
| `feature_type` | TEXT | category_yearly/category_monthly/weekly/lifetime |
| `feature_key` | TEXT | career/love/wealth/health/study/family/social/overall |
| `target_year` | SMALLINT | 대상 연도 |
| `target_month` | SMALLINT | 대상 월 (0이면 연간) |
| `unlock_method` | TEXT | ad_rewarded/subscription/purchase/free_trial/admin_grant |
| `ad_event_id` | UUID | FK → ad_events |
| `expires_at` | TIMESTAMPTZ | 만료 시점 (NULL이면 영구) |
| `is_active` | BOOL | 활성 상태 |

---

### 2.10 subscriptions (구독)

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | UUID | PK |
| `user_id` | UUID | FK → auth.users |
| `product_id` | TEXT | sadam_day_pass/sadam_week_pass/sadam_monthly |
| `platform` | TEXT | android/ios |
| `status` | TEXT | active/expired/cancelled |
| `is_lifetime` | BOOL | 영구 구독 여부 |
| `starts_at` | TIMESTAMPTZ | 시작 시점 |
| `expires_at` | TIMESTAMPTZ | 만료 시점 |

---

## 3. 트리거 & 함수

### 3.1 토큰 추적 트리거

#### `update_daily_chat_tokens` (chat_messages INSERT 시)

```sql
-- chat_messages 삽입 시 user_daily_token_usage 자동 업데이트
-- assistant 메시지만 토큰 카운트 (user 메시지는 tokens_used = NULL)

BEGIN
  -- chat_session → profile → user_id 조회
  SELECT sp.user_id INTO v_user_id
  FROM chat_sessions cs
  JOIN saju_profiles sp ON cs.profile_id = sp.id
  WHERE cs.id = v_session_id;

  IF NEW.role = 'assistant' AND NEW.tokens_used > 0 THEN
    INSERT INTO user_daily_token_usage (
      user_id, usage_date, chatting_tokens, chatting_message_count, chatting_session_count
    )
    VALUES (v_user_id, CURRENT_DATE, NEW.tokens_used, 1, ...)
    ON CONFLICT (user_id, usage_date)
    DO UPDATE SET chatting_tokens = chatting_tokens + EXCLUDED.chatting_tokens, ...;
  END IF;
END;
```

> **주의**: `CURRENT_DATE`는 Supabase 서버 시간(UTC) 기준.
> KST 변환 마이그레이션 (`20260201075846`) 적용 후 정상 작동.

#### `update_chat_session_stats` (chat_messages INSERT 시)

```sql
-- 세션 통계 자동 업데이트
UPDATE chat_sessions SET
  total_tokens_used = SUM(tokens_used),
  user_message_count = COUNT(role='user'),
  assistant_message_count = COUNT(role='assistant'),
  message_count = COUNT(*),
  updated_at = NOW()
WHERE id = NEW.session_id;
```

### 3.2 프로필 이름 동기화 트리거 (v31 → v32)

#### `sync_user_display_name` (saju_profiles UPDATE 시)

> - 2026-02-04 도입 (v31): 프로필 `display_name` 변경 시 관련 테이블 자동 동기화
> - **2026-02-06 수정 (v32)**: `ai_summaries.profile_display_name` 동기화 제거
>   - 이유: 앱에서 사용하지 않는 필드 + 과거 운세 기록은 생성 당시 이름 유지

```sql
CREATE OR REPLACE FUNCTION sync_user_display_name()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.display_name IS DISTINCT FROM NEW.display_name THEN

    -- [REMOVED in v32] ai_summaries.profile_display_name 동기화 제거
    -- 앱에서 이 필드를 사용하지 않으며, 과거 운세 기록은 생성 당시 이름 유지

    -- 1. profile_relations: to_profile의 display_name 업데이트
    UPDATE profile_relations
    SET display_name = NEW.display_name
    WHERE to_profile_id = NEW.id
      AND display_name IS DISTINCT FROM NEW.display_name;

    -- 2. "본인" 프로필(primary + me)일 때만 user_display_name 업데이트
    IF NEW.profile_type = 'primary' AND NEW.relation_type = 'me' THEN
      UPDATE user_daily_token_usage
      SET user_display_name = NEW.display_name
      WHERE user_id = NEW.user_id
        AND user_display_name IS DISTINCT FROM NEW.display_name;

      UPDATE ai_summaries
      SET user_display_name = NEW.display_name
      WHERE user_id = NEW.user_id
        AND user_display_name IS DISTINCT FROM NEW.display_name;
    END IF;

    RAISE LOG '[sync_display_name] profile_id=% type=%/% name: "%" → "%" (profile_display_name NOT synced)',
              NEW.id, NEW.profile_type, NEW.relation_type, OLD.display_name, NEW.display_name;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_display_name
  AFTER UPDATE OF display_name ON saju_profiles
  FOR EACH ROW
  EXECUTE FUNCTION sync_user_display_name();
```

**영향 테이블**:

| 테이블 | 컬럼 | 조건 | 상태 |
|--------|------|------|------|
| `ai_summaries` | `profile_display_name` | 해당 profile_id | **제거됨 (v32)** |
| `ai_summaries` | `user_display_name` | primary+me 프로필일 때만 | 유지 |
| `user_daily_token_usage` | `user_display_name` | primary+me 프로필일 때만 | 유지 |
| `profile_relations` | `display_name` | to_profile_id 일치 | 유지 |

> **주의**: `user_display_name`과 `profile_display_name`은 다른 의미
> - `user_display_name`: 로그인한 사용자의 "본인" 프로필 이름
> - `profile_display_name`: 분석 대상 프로필의 이름 **(v32부터 동기화 안 함)**

---

### 3.3 RPC 함수

#### `add_ad_bonus_tokens(p_user_id, p_bonus_tokens)`
- Rewarded Ad 시청 완료 시 호출
- `bonus_tokens += p_bonus_tokens`, `ads_watched += 1`
- 반환: `{ success, new_quota, new_remaining }`

#### `add_native_bonus_tokens(p_user_id, p_bonus_tokens)`
- Native Ad 클릭 시 호출
- `native_tokens_earned += p_bonus_tokens`, `ads_watched += 1`
- 반환: `{ success, new_quota, new_remaining }`

#### `increment_ad_counter(p_user_id, p_usage_date, p_column_name, p_increment)`
- 광고 이벤트 카운터 범용 증가
- 허용 컬럼: banner_*, interstitial_*, rewarded_*, native_*, ads_watched

#### `check_user_quota(p_user_id)`
- 사용자 쿼터 상태 조회
- 반환: `{ can_use, tokens_used, tokens_remaining, quota_limit, ads_watched, bonus_tokens }`

---

## 4. 쿼터 체크 동기화 (3곳)

| 위치 | 파일 | 공식 |
|------|------|------|
| DB | `is_quota_exceeded` GENERATED 컬럼 | `chatting_tokens >= (daily_quota + bonus_tokens + rewarded_tokens_earned + native_tokens_earned)` |
| Edge Function | `ai-gemini/index.ts` | `effectiveQuota = baseQuota + bonusTokens + rewardedTokens + nativeTokens` |
| Edge Function | `ai-openai/index.ts` | `effectiveQuota = baseQuota + bonusTokens + rewardedTokens + nativeTokens` |

> ⚠️ **3곳의 공식이 항상 일치해야 함**

---

## 5. Gemini Context Caching (v26)

> 2026-02-02 도입 (`gemini_cache_name` 컬럼)

### 5.1 개요

Gemini API의 [Context Caching](https://ai.google.dev/gemini-api/docs/caching) 기능으로 system prompt + saju 데이터를 캐싱하여 **입력 토큰 비용 90% 절감**.

```
표준 입력: $0.50 / 1M tokens
캐시 입력: $0.05 / 1M tokens  ← 90% 할인!
```

### 5.2 동작 흐름

```
1. 채팅 시작 (session_id 전달)
   │
   ├─ 기존 캐시 있음 (gemini_cache_name)
   │   └─→ cachedContent 파라미터로 캐시 사용
   │
   └─ 캐시 없음 + system_prompt > 500자
       └─→ createGeminiCache() 호출
           └─→ chat_sessions.gemini_cache_name 저장
```

### 5.3 DB 스키마

| 테이블 | 컬럼 | 설명 |
|--------|------|------|
| `chat_sessions` | `gemini_cache_name` | 캐시 이름 (예: `cachedContents/f2peaj5n...`) |

### 5.4 캐시 생성 조건

- `session_id` 전달됨
- `systemInstruction.length > 500` (약 1,024+ 토큰)
- Gemini API 최소 요구: 1,024 토큰

### 5.5 캐시 TTL

- 기본값: **3,600초 (1시간)**
- 만료 시 자동 삭제 (Gemini API 측)
- Edge Function: 캐시 만료/에러 시 표준 요청으로 fallback

### 5.6 비용 계산 (ai-gemini v26)

```typescript
// 캐시 할인 적용
const nonCachedPrompt = totalPromptTokens - totalCachedTokens;
const cost =
  (nonCachedPrompt * 0.50 / 1000000) +      // 표준 입력
  (totalCachedTokens * 0.05 / 1000000) +    // 캐시 입력 (90% 할인)
  (totalCompletionTokens * 3.00 / 1000000); // 출력
```

### 5.7 현재 캐시 사용률 (최근 7일)

| 페르소나 | 세션 수 | 캐시 사용 | 캐시율 |
|----------|---------|-----------|--------|
| stRealistic | 24 | 2 | 8.3% |
| sewerSaju | 4 | 1 | 25.0% |
| 기타 | 92 | 0 | 0% |

> **참고**: 캐시는 세션 내 두 번째 메시지부터 효과. 단일 메시지 세션은 캐시 미사용.

### 5.8 캐시 샘플

| 세션 ID | 페르소나 | 캐시 이름 | 토큰 | 생성 시각 (KST) |
|---------|----------|-----------|------|-----------------|
| 086646b4... | stRealistic | cachedContents/f2peaj5n... | 6,073 | 2026-02-03 08:09 |
| 7a85d85d... | stRealistic | cachedContents/dd0lm78j... | 5,523 | 2026-02-03 08:07 |
| 5d66460e... | sewerSaju | cachedContents/ugz8vqrw... | 21,395 | 2026-02-02 20:41 |

---

## 6. 페르소나 추적 (`chat_sessions.chat_persona`)

### 6.1 페르소나 종류

| ID | 이름 | MBTI 기반 |
|----|------|-----------|
| `basePerson` | 기본 | 4분면 선택 (NF/NT/SF/ST) |
| `stRealistic` | 현실적 ST | ST 성향 |
| `sfFriendly` | 친근한 SF | SF 성향 |
| `nfSensitive` | 감성적 NF | NF 성향 |
| `ntAnalytic` | 분석적 NT | NT 성향 |
| `sewerSaju` | 하수구 사주 | 특수 |
| `saOngJiMa` | 새옹지마 | 특수 |
| `babyMonk` | 아기 스님 | 특수 |
| `null` | 레거시 | 도입 전 |

### 6.2 사용 통계 (최근 7일)

| 페르소나 | 세션 수 | 총 토큰 | 메시지 | 평균 토큰/세션 |
|----------|---------|---------|--------|----------------|
| null (레거시) | 31 | 353,388 | 191 | 11,400 |
| **stRealistic** | **24** | 231,780 | 88 | 9,658 |
| sfFriendly | 22 | 60,511 | 16 | 2,751 |
| nfSensitive | 21 | 231,728 | 90 | 11,035 |
| ntAnalytic | 10 | 620,419 | 151 | 62,042 |
| basePerson | 6 | 771,757 | 166 | 128,626 |
| sewerSaju | 4 | 365,499 | 83 | 91,375 |
| saOngJiMa | 1 | 16,249 | 8 | 16,249 |
| babyMonk | 1 | 0 | 0 | 0 |

### 6.3 인사이트

- **stRealistic이 가장 인기** (레거시 제외)
- `basePerson`/`ntAnalytic` → 평균 토큰 높음 (깊은 대화)
- `sfFriendly` → 토큰 적음 (짧은 대화)

---

## 7. 토큰 추적 현황 (2026-02-03 기준)

### KST 변환 마이그레이션 적용일: 2026-02-01

| 날짜 | chat_messages 토큰 | daily_usage 토큰 | 차이 | 비고 |
|------|-------------------|------------------|------|------|
| 02-03 | 44,469 | 7,096 | +37,373 | 진행 중 (정상) |
| 02-02 | 590,738 | 645,090 | -54,352 | 정상 (오차 범위) |
| 02-01 | 482,314 | 326,529 | +155,785 | KST 변환일 (전환 과도기) |

> **결론**: KST 변환 이후 (02-02~) 토큰 추적 정상 작동 중

---

## 8. 인덱스

### chat_messages
- `idx_chat_messages_session_id` ON (session_id)
- `idx_chat_messages_created_at` ON (created_at)

### chat_sessions
- `idx_chat_sessions_profile_id` ON (profile_id)
- `idx_chat_sessions_updated_at` ON (updated_at)

### user_daily_token_usage
- UNIQUE `(user_id, usage_date)` - PK

### ai_summaries
- UNIQUE `(user_id, profile_id, summary_type, target_year, target_month, target_date)`

---

## 9. RLS 정책 요약

모든 테이블에 RLS 활성화:
- **기본 정책**: `user_id = auth.uid()`
- **관리자 예외**: `is_admin_user()` 함수로 체크
- **프로필 연관**: saju_profiles를 통해 user_id 확인

---

## 10. 마이그레이션 히스토리 (주요)

| 버전 | 이름 | 설명 |
|------|------|------|
| 20251209111144 | initial_schema_v2 | 초기 스키마 |
| 20251230070851 | create_user_daily_token_usage | 토큰 사용량 테이블 |
| 20260114110925 | create_token_usage_auto_update_trigger | 토큰 자동 업데이트 트리거 |
| 20260122100745 | create_ad_events_table | 광고 이벤트 테이블 |
| 20260131095344 | add_persona_tracking_to_chat_sessions | **페르소나 추적 추가** |
| 20260201075846 | fix_update_daily_chat_tokens_function | **토큰 트리거 KST 변환** |
| 20260202135648 | add_gemini_cache_name | Gemini 캐시 이름 컬럼 |
| 20260202145444 | create_subscriptions_table | 구독 테이블 |
| 20260204xxxxxx | sync_display_name_trigger_v4 | **프로필 이름 동기화 트리거 (v31)** |

---

## 11. 토큰 윈도우 설정 (Flutter)

> 1회 API 호출의 입력 토큰 한도 (일일 쿼터와 별개)

### 현재 설정 (2026-02-02)

| 파라미터 | 값 | 파일 |
|----------|-----|------|
| `defaultMaxInputTokens` | 20,000 | `token_counter.dart:28` |
| `safetyMargin` | 2,000 | `token_counter.dart:25` |

### 계산식

```
availableTokens = defaultMaxInputTokens - safetyMargin - systemPromptTokens
                = 20,000 - 2,000 - ~1,500
                = ~16,500 (대화 공간)
```

### 개념 구분

| 개념 | 용도 | 현재 값 |
|------|------|---------|
| `defaultMaxInputTokens` | 1회 API 호출 입력 토큰 한도 (컨텍스트 윈도우) | 20,000 |
| `DAILY_QUOTA` | 하루 총 사용 가능 토큰 (Edge Function) | 20,000 |
| `safetyMargin` | 출력 토큰 예약 공간 | 2,000 |

---

## 12. 토큰 추적 파이프라인 (6종)

### 쿼터 대상 vs 면제

| 토큰 컬럼 | 쿼터 | 기록 주체 | 모델 |
|----------|------|----------|------|
| `chatting_tokens` | **대상** | DB 트리거 | Gemini 3.0 Flash |
| `saju_analysis_tokens` | 면제 | ai-openai-result | GPT-5.2 |
| `daily_fortune_tokens` | 면제 | DB 트리거 | Gemini |
| `monthly_fortune_tokens` | 면제 | ai-openai-result | GPT-5.2 |
| `yearly_fortune_2025_tokens` | 면제 | ai-openai-result | GPT-5.2 |
| `yearly_fortune_2026_tokens` | 면제 | ai-openai-result | GPT-5.2 |

### 광고 보상 토큰 (effective_quota에 포함)

| 컬럼 | 기록 주체 | 보상 |
|------|----------|------|
| `bonus_tokens` | `add_ad_bonus_tokens` RPC | Rewarded Ad |
| `rewarded_tokens_earned` | `increment_ad_counter` RPC | 보상형 영상 |
| `native_tokens_earned` | `add_native_bonus_tokens` RPC | Native 클릭 (+7,000/회) |

### Edge Function 버전

| 함수명 | 버전 | 주요 기능 |
|--------|------|----------|
| `ai-gemini` | v27 | Context Caching + 쿼터 체크 + 스트리밍 |
| `ai-openai` | v39 | 쿼터 면제 + 완료 태스크 재사용 |
| `ai-openai-result` | v32 | task_type별 토큰 컬럼 라우팅 |

---

## 13. API 비용 (2026-02)

### GPT-5.2 (OpenAI)

| 항목 | 가격 |
|------|------|
| Input | $1.75 / 1M tokens |
| Output | $14.00 / 1M tokens |

### Gemini 3.0 Flash (Google)

| 항목 | 표준 | 캐시 (90% 할인) |
|------|------|-----------------|
| Input | $0.50 / 1M | $0.05 / 1M |
| Output | $3.00 / 1M | - |

### Gemini 2.5 Flash Lite (Intent 분류용)

| 항목 | 가격 |
|------|------|
| Input | $0.10 / 1M |
| Output | $0.40 / 1M |

---

## 14. 관련 문서

- [user_daily_token_usage 상세](./user_daily_token_usage_schema.md)
- [광고 토큰 플로우](./ad_token_user_flow.md)
- [토큰 추적 시스템](./token_tracking.md)
- [UI 자동 갱신 시스템](./ui_auto_refresh_system.md)
