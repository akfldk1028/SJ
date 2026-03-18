-- =============================================================================
-- Migration: fix_ad_bonus_rpc_critical_issues
-- Date: 2026-03-16
-- Description:
--   P0-CRITICAL 3건 수정:
--   1. add_ad_bonus_tokens: 구버전(2파라미터) DROP + 신버전 수정
--      - bonus_tokens_earned → bonus_tokens 컬럼 사용 (check_user_quota 일치)
--      - daily_quota 미변경 (이중 계산 방지)
--      - p_is_fallback 파라미터: fallback=true면 ads_watched 미증가
--   2. add_native_bonus_tokens: ads_watched +1 제거 (네이티브 클릭 ≠ 시청)
--      - native_tokens_earned를 effective quota에 포함
--   3. bonus_tokens_earned → bonus_tokens 데이터 마이그레이션
--   4. check_user_quota: native_tokens_earned 누락 수정
-- =============================================================================

-- =============================================================================
-- Step 1: 구버전 add_ad_bonus_tokens(uuid, integer) DROP + 신버전 수정
-- =============================================================================

-- 구버전(2파라미터) 삭제 — check_user_quota가 bonus_tokens만 읽으므로 구버전 제거 필수
DROP FUNCTION IF EXISTS add_ad_bonus_tokens(uuid, integer);

-- 신버전(3파라미터) 교체: bonus_tokens 컬럼 사용, daily_quota 미변경
CREATE OR REPLACE FUNCTION add_ad_bonus_tokens(
  p_user_id UUID,
  p_bonus_tokens INTEGER DEFAULT 5000,
  p_is_fallback BOOLEAN DEFAULT false
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
  v_new_quota INTEGER;
  v_ads_watched INTEGER;
  v_bonus_earned INTEGER;
  v_tokens_used INTEGER;
  v_remaining INTEGER;
  v_ads_increment INTEGER;
BEGIN
  -- fallback이면 ads_watched 증가하지 않음
  v_ads_increment := CASE WHEN p_is_fallback THEN 0 ELSE 1 END;

  -- UPSERT: bonus_tokens 컬럼 사용 (check_user_quota와 일치)
  -- daily_quota 미변경 (check_user_quota가 bonus_tokens를 별도로 더함)
  INSERT INTO user_daily_token_usage (user_id, usage_date, ads_watched, bonus_tokens)
  VALUES (p_user_id, v_today, v_ads_increment, p_bonus_tokens)
  ON CONFLICT (user_id, usage_date) DO UPDATE SET
    ads_watched = user_daily_token_usage.ads_watched + v_ads_increment,
    bonus_tokens = COALESCE(user_daily_token_usage.bonus_tokens, 0) + p_bonus_tokens,
    updated_at = NOW();

  -- check_user_quota와 동일한 수식으로 quota 계산
  SELECT
    (COALESCE(u.daily_quota, 20000) + COALESCE(u.bonus_tokens, 0) + COALESCE(u.rewarded_tokens_earned, 0)),
    u.ads_watched,
    COALESCE(u.bonus_tokens, 0) + COALESCE(u.rewarded_tokens_earned, 0),
    COALESCE(u.chatting_tokens, 0)
  INTO v_new_quota, v_ads_watched, v_bonus_earned, v_tokens_used
  FROM user_daily_token_usage u
  WHERE u.user_id = p_user_id AND u.usage_date = v_today;

  v_remaining := GREATEST(v_new_quota - v_tokens_used, 0);

  RETURN json_build_object(
    'success', true,
    'new_quota', v_new_quota,
    'ads_watched', v_ads_watched,
    'bonus_earned', v_bonus_earned,
    'tokens_used', v_tokens_used,
    'remaining', v_remaining,
    'is_fallback', p_is_fallback
  );
END;
$$;

-- =============================================================================
-- Step 2: add_native_bonus_tokens에서 ads_watched 제거
-- 네이티브 광고 클릭은 "시청"이 아님 → ads_watched 부풀리기 방지
-- native_tokens_earned를 effective quota 계산에 포함
-- =============================================================================

CREATE OR REPLACE FUNCTION add_native_bonus_tokens(p_user_id uuid, p_bonus_tokens integer)
RETURNS TABLE(success boolean, new_quota integer, new_remaining integer)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_effective_quota INTEGER;
  v_chatting_tokens INTEGER;
BEGIN
  -- ads_watched 증가 제거! 네이티브 클릭은 "시청"이 아님
  INSERT INTO user_daily_token_usage (user_id, usage_date, native_tokens_earned)
  VALUES (p_user_id, CURRENT_DATE, p_bonus_tokens)
  ON CONFLICT (user_id, usage_date)
  DO UPDATE SET
    native_tokens_earned = COALESCE(user_daily_token_usage.native_tokens_earned, 0) + p_bonus_tokens,
    updated_at = NOW();

  -- native_tokens_earned 포함하여 effective quota 계산
  SELECT
    (COALESCE(u.daily_quota, 20000) + COALESCE(u.bonus_tokens, 0) + COALESCE(u.rewarded_tokens_earned, 0) + COALESCE(u.native_tokens_earned, 0)),
    COALESCE(u.chatting_tokens, 0)
  INTO v_effective_quota, v_chatting_tokens
  FROM user_daily_token_usage u
  WHERE u.user_id = p_user_id AND u.usage_date = CURRENT_DATE;

  success := true;
  new_quota := v_effective_quota;
  new_remaining := GREATEST(0, v_effective_quota - v_chatting_tokens);
  RETURN NEXT;
END;
$$;

-- =============================================================================
-- Step 3: bonus_tokens_earned → bonus_tokens 데이터 마이그레이션
-- 신버전 RPC가 bonus_tokens_earned에 쓴 데이터를 bonus_tokens로 이동
-- =============================================================================

UPDATE user_daily_token_usage
SET bonus_tokens = COALESCE(bonus_tokens, 0) + COALESCE(bonus_tokens_earned, 0),
    bonus_tokens_earned = 0
WHERE bonus_tokens_earned > 0;

-- =============================================================================
-- Step 4: check_user_quota에 native_tokens_earned 추가
-- 기존: quota_limit = daily_quota + bonus_tokens + rewarded_tokens_earned
-- 수정: quota_limit = daily_quota + bonus_tokens + rewarded_tokens_earned + native_tokens_earned
-- =============================================================================

CREATE OR REPLACE FUNCTION check_user_quota(p_user_id uuid)
RETURNS TABLE(can_use boolean, tokens_used integer, tokens_remaining integer, quota_limit integer, ads_watched integer, bonus_tokens integer)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    NOT COALESCE(u.is_quota_exceeded, false) as can_use,
    COALESCE(u.chatting_tokens, 0) as tokens_used,
    GREATEST(0,
      (COALESCE(u.daily_quota, 20000) + COALESCE(u.bonus_tokens, 0) + COALESCE(u.rewarded_tokens_earned, 0) + COALESCE(u.native_tokens_earned, 0))
      - COALESCE(u.chatting_tokens, 0)
    ) as tokens_remaining,
    (COALESCE(u.daily_quota, 20000) + COALESCE(u.bonus_tokens, 0) + COALESCE(u.rewarded_tokens_earned, 0) + COALESCE(u.native_tokens_earned, 0)) as quota_limit,
    COALESCE(u.ads_watched, 0) as ads_watched,
    COALESCE(u.bonus_tokens, 0) + COALESCE(u.rewarded_tokens_earned, 0) + COALESCE(u.native_tokens_earned, 0) as bonus_tokens
  FROM user_daily_token_usage u
  WHERE u.user_id = p_user_id AND u.usage_date = CURRENT_DATE;

  IF NOT FOUND THEN
    can_use := true;
    tokens_used := 0;
    tokens_remaining := 20000;
    quota_limit := 20000;
    ads_watched := 0;
    bonus_tokens := 0;
    RETURN NEXT;
  END IF;
END;
$$;
