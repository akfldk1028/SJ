# JH_BE - Supabase 백엔드 TODO

> 작성일: 2024-12-21
> 담당: JH_BE (Supabase 스키마 + Edge Functions)

---

## 우선순위 가이드

| 우선순위 | 설명 |
|----------|------|
| **P0** | MVP 필수 - 앱 출시 전 완료 |
| **P1** | 핵심 기능 - MVP 직후 |
| **P2** | 개선 사항 - 추후 |

---

## 핵심 원칙

### 연관 사람 사주 처리 방식

**기존 구조 그대로 활용!**

```
saju_profiles (relation_type: me, family, friend, lover, work, other)
       │
       └── 1:1 ── saju_analyses (오행, 십신, 용신 전부 파싱)
```

- 친구/가족 추가 시 → `saju_profiles` + `saju_analyses` 생성 (내 사주와 동일)
- 궁합 요청 시 → AI 채팅에서 GPT-5.2가 두 `saju_analyses` 비교해서 실시간 계산
- 별도 `compatibility_results` 테이블 **불필요** (AI가 실시간 처리)

---

## Phase 1: 광고 시스템 테이블 (P0)

### 마이그레이션 파일

```
📁 sql/migrations/
├── 002_create_ad_views.sql              [ ] 생성
├── 003_create_user_credits.sql          [ ] 생성
└── 004_create_credit_transactions.sql   [ ] 생성
```

### 1.1 ad_views (광고 시청 기록)

```sql
CREATE TABLE public.ad_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- 광고 정보
  ad_type TEXT NOT NULL,              -- 'rewarded', 'interstitial', 'banner'
  ad_unit_id TEXT,                    -- AdMob ad unit ID
  ad_provider TEXT DEFAULT 'admob',   -- 'admob', 'applovin', etc.

  -- 보상 정보
  reward_type TEXT NOT NULL,          -- 'credits', 'premium_unlock', 'chat_count'
  reward_amount INTEGER NOT NULL,     -- 보상량
  reward_granted BOOLEAN DEFAULT FALSE,

  -- 시청 정보
  watched_at TIMESTAMPTZ DEFAULT NOW(),
  watch_duration_seconds INTEGER,     -- 실제 시청 시간
  completed BOOLEAN DEFAULT FALSE,    -- 끝까지 봤는지

  -- 제약조건
  CONSTRAINT check_ad_type CHECK (ad_type IN ('rewarded', 'interstitial', 'banner')),
  CONSTRAINT check_reward_type CHECK (reward_type IN ('credits', 'premium_unlock', 'chat_count'))
);

-- RLS
ALTER TABLE public.ad_views ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own ad_views"
  ON public.ad_views FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own ad_views"
  ON public.ad_views FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 인덱스
CREATE INDEX idx_ad_views_user_id ON public.ad_views(user_id);
CREATE INDEX idx_ad_views_watched_at ON public.ad_views(user_id, watched_at DESC);
```

### 1.2 user_credits (유저 크레딧 잔액)

```sql
CREATE TABLE public.user_credits (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  -- 잔액
  balance INTEGER NOT NULL DEFAULT 0,

  -- 누적 통계
  total_earned INTEGER NOT NULL DEFAULT 0,
  total_spent INTEGER NOT NULL DEFAULT 0,
  total_expired INTEGER NOT NULL DEFAULT 0,

  -- 일일 광고 시청 횟수 제한용
  daily_ad_count INTEGER NOT NULL DEFAULT 0,
  daily_reset_at DATE DEFAULT CURRENT_DATE,

  -- 타임스탬프
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- 제약조건
  CONSTRAINT check_balance_non_negative CHECK (balance >= 0)
);

-- RLS
ALTER TABLE public.user_credits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own credits"
  ON public.user_credits FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

### 1.3 credit_transactions (크레딧 거래 이력)

```sql
CREATE TABLE public.credit_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- 거래 정보
  type TEXT NOT NULL,                 -- 'earn', 'spend', 'expire', 'refund', 'bonus'
  amount INTEGER NOT NULL,            -- 양수(적립) 또는 음수(사용)
  balance_after INTEGER NOT NULL,     -- 거래 후 잔액 (감사용)

  -- 출처/용도
  source TEXT NOT NULL,               -- 'ad_reward', 'purchase', 'bonus', 'referral', 'premium_chat'
  description TEXT,                   -- "프리미엄 채팅 사용", "보상형 광고 시청"
  reference_id UUID,                  -- ad_view_id 참조

  -- 만료 관련 (적립에만 해당)
  expires_at TIMESTAMPTZ,             -- 만료일 (NULL이면 무기한)

  -- 타임스탬프
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- 제약조건
  CONSTRAINT check_type CHECK (type IN ('earn', 'spend', 'expire', 'refund', 'bonus'))
);

-- RLS
ALTER TABLE public.credit_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own transactions"
  ON public.credit_transactions FOR SELECT
  USING (auth.uid() = user_id);

-- 인덱스
CREATE INDEX idx_credit_transactions_user_id ON public.credit_transactions(user_id);
CREATE INDEX idx_credit_transactions_created_at ON public.credit_transactions(user_id, created_at DESC);
CREATE INDEX idx_credit_transactions_expires_at ON public.credit_transactions(expires_at)
  WHERE expires_at IS NOT NULL AND type = 'earn';
```

---

## Phase 2: 트리거 함수 (P0)

```
📁 sql/triggers/
├── credit_balance_update.sql    [ ] 생성
├── ad_reward_grant.sql          [ ] 생성
└── daily_ad_count_reset.sql     [ ] 생성
```

### 2.1 크레딧 잔액 자동 업데이트

```sql
CREATE OR REPLACE FUNCTION update_user_credits()
RETURNS TRIGGER AS $$
BEGIN
  -- user_credits 레코드 없으면 생성
  INSERT INTO public.user_credits (user_id, balance, total_earned, total_spent)
  VALUES (NEW.user_id, 0, 0, 0)
  ON CONFLICT (user_id) DO NOTHING;

  -- 타입별 업데이트
  IF NEW.type IN ('earn', 'bonus', 'refund') THEN
    UPDATE public.user_credits
    SET
      balance = balance + NEW.amount,
      total_earned = total_earned + NEW.amount,
      updated_at = NOW()
    WHERE user_id = NEW.user_id;

  ELSIF NEW.type = 'spend' THEN
    UPDATE public.user_credits
    SET
      balance = balance + NEW.amount,  -- amount는 음수
      total_spent = total_spent + ABS(NEW.amount),
      updated_at = NOW()
    WHERE user_id = NEW.user_id;

  ELSIF NEW.type = 'expire' THEN
    UPDATE public.user_credits
    SET
      balance = balance + NEW.amount,  -- amount는 음수
      total_expired = total_expired + ABS(NEW.amount),
      updated_at = NOW()
    WHERE user_id = NEW.user_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_credit_transaction_insert
  AFTER INSERT ON public.credit_transactions
  FOR EACH ROW EXECUTE FUNCTION update_user_credits();
```

### 2.2 광고 보상 지급 트리거

```sql
CREATE OR REPLACE FUNCTION grant_ad_reward()
RETURNS TRIGGER AS $$
DECLARE
  current_balance INTEGER;
BEGIN
  -- completed=TRUE이고 아직 reward_granted=FALSE일 때만
  IF NEW.completed = TRUE AND NEW.reward_granted = FALSE AND NEW.reward_type = 'credits' THEN

    -- 현재 잔액 조회
    SELECT COALESCE(balance, 0) INTO current_balance
    FROM public.user_credits
    WHERE user_id = NEW.user_id;

    -- 트랜잭션 생성
    INSERT INTO public.credit_transactions (
      user_id, type, amount, balance_after, source, description, reference_id, expires_at
    ) VALUES (
      NEW.user_id,
      'earn',
      NEW.reward_amount,
      current_balance + NEW.reward_amount,
      'ad_reward',
      '보상형 광고 시청',
      NEW.id,
      NOW() + INTERVAL '90 days'  -- 90일 후 만료
    );

    -- reward_granted 업데이트
    NEW.reward_granted := TRUE;

    -- 일일 광고 시청 횟수 증가
    UPDATE public.user_credits
    SET
      daily_ad_count = CASE
        WHEN daily_reset_at < CURRENT_DATE THEN 1
        ELSE daily_ad_count + 1
      END,
      daily_reset_at = CURRENT_DATE
    WHERE user_id = NEW.user_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_ad_view_complete
  BEFORE UPDATE ON public.ad_views
  FOR EACH ROW
  WHEN (NEW.completed = TRUE AND OLD.completed = FALSE)
  EXECUTE FUNCTION grant_ad_reward();
```

---

## Phase 3: Edge Functions (P1)

```
📁 supabase/functions/
├── check-credit-balance/    [ ] 크레딧 잔액 확인
├── spend-credits/           [ ] 크레딧 사용 (프리미엄 채팅)
└── expire-credits/          [ ] 만료 크레딧 처리 (Cron)
```

### 3.1 크레딧 사용 (프리미엄 채팅)

```typescript
// supabase/functions/spend-credits/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { amount, description } = await req.json()
  const authHeader = req.headers.get('Authorization')!

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } }
  )

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return new Response('Unauthorized', { status: 401 })

  // 잔액 확인
  const { data: credits } = await supabase
    .from('user_credits')
    .select('balance')
    .eq('user_id', user.id)
    .single()

  if (!credits || credits.balance < amount) {
    return new Response(JSON.stringify({ error: 'Insufficient credits' }), { status: 400 })
  }

  // 사용 트랜잭션 생성
  const { error } = await supabase
    .from('credit_transactions')
    .insert({
      user_id: user.id,
      type: 'spend',
      amount: -amount,
      balance_after: credits.balance - amount,
      source: 'premium_chat',
      description: description || '프리미엄 채팅 사용'
    })

  if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 })

  return new Response(JSON.stringify({
    success: true,
    new_balance: credits.balance - amount
  }))
})
```

---

## Phase 4: Flutter 연동 (P1)

```
📁 frontend/lib/features/
├── ads/
│   └── data/datasources/
│       └── ad_supabase_datasource.dart      [ ] 생성
└── credits/
    └── data/datasources/
        └── credit_supabase_datasource.dart  [ ] 생성
```

---

## ERD (최종)

```
auth.users
    │
    ├── 1:N ──── public.saju_profiles (본인 + 연관 사람 모두)
    │                 │     ↑ relation_type: me, family, friend, lover, work, other
    │                 │
    │                 ├── 1:1 ── public.saju_analyses (오행, 십신, 용신 전부)
    │                 │
    │                 └── 1:N ── public.chat_sessions
    │                                └── 1:N ── public.chat_messages
    │
    ├── 1:1 ──── public.user_credits (잔액 + 일일 광고 횟수)
    │
    ├── 1:N ──── public.ad_views (광고 시청 기록)
    │
    └── 1:N ──── public.credit_transactions (크레딧 이력)
```

**궁합 처리:**
- 별도 테이블 없음
- AI 채팅 시 GPT-5.2가 두 프로필의 `saju_analyses` 비교해서 실시간 분석

---

## 체크리스트

### Phase 1: 테이블 생성 (P0)
- [ ] `ad_views` 테이블 + RLS + 인덱스
- [ ] `user_credits` 테이블 + RLS
- [ ] `credit_transactions` 테이블 + RLS + 인덱스

### Phase 2: 트리거 (P0)
- [ ] `update_user_credits()` 트리거
- [ ] `grant_ad_reward()` 트리거
- [ ] 트리거 테스트 (광고 시청 → 크레딧 적립)

### Phase 3: Edge Functions (P1)
- [ ] `check-credit-balance` 함수
- [ ] `spend-credits` 함수
- [ ] `expire-credits` Cron 설정

### Phase 4: Flutter 연동 (P1)
- [ ] `AdSupabaseDatasource` 구현
- [ ] `CreditSupabaseDatasource` 구현
- [ ] `AdMob` 연동 테스트

---

## 보상 설정값 (DK와 협의 필요)

| 항목 | 값 | 비고 |
|------|-----|------|
| 보상형 광고 1회 | 10 크레딧 | |
| 프리미엄 채팅 1회 | 5 크레딧 | |
| 일일 광고 시청 한도 | 10회 | 100 크레딧/일 |
| 크레딧 만료 기간 | 90일 | |

---

## 일정

| Phase | 예상 | 비고 |
|-------|------|------|
| Phase 1 | 1일 | 테이블 3개 |
| Phase 2 | 1일 | 트리거 2개 |
| Phase 3 | 1일 | Edge Function |
| Phase 4 | 2일 | Flutter 연동 |

**총: 약 5일**
