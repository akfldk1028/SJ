-- =============================================================================
-- Migration: rename_token_columns_match_edge_functions
-- Date: 2026-02-01
-- Description:
--   user_daily_token_usage 테이블의 컬럼명을 Edge Function이 사용하는 이름으로 변경.
--   Edge Function(ai-gemini, ai-openai, ai-openai-result)이 production에서
--   gpt_saju_analysis_tokens, gemini_chat_tokens 등의 컬럼에 쓰고 있지만
--   실제 DB에는 saju_analysis_tokens, chatting_tokens 등의 이름으로 존재하여
--   토큰 사용량이 전혀 기록되지 않는 문제 수정.
--
-- 변경 내역:
--   1. 컬럼 리네이밍 (4개)
--   2. 누락 컬럼 추가 (3개)
--   3. GENERATED 컬럼 재생성 (total_tokens, is_quota_exceeded, total_api_calls)
--   4. 트리거 함수 업데이트 (새 컬럼명 반영)
--   5. RPC 함수 업데이트 (check_user_quota, add_ad_bonus_tokens, increment_ad_counter)
-- =============================================================================

-- ===== Step 1: GENERATED 컬럼 먼저 삭제 (의존성 제거) =====
-- GENERATED 컬럼이 기존 컬럼을 참조하므로 리네이밍 전에 삭제해야 함

ALTER TABLE user_daily_token_usage DROP COLUMN IF EXISTS total_tokens;
ALTER TABLE user_daily_token_usage DROP COLUMN IF EXISTS is_quota_exceeded;
ALTER TABLE user_daily_token_usage DROP COLUMN IF EXISTS total_api_calls;

-- ===== Step 2: 컬럼 리네이밍 =====

-- saju_analysis_tokens → gpt_saju_analysis_tokens
ALTER TABLE user_daily_token_usage RENAME COLUMN saju_analysis_tokens TO gpt_saju_analysis_tokens;

-- daily_fortune_tokens → gemini_fortune_tokens
ALTER TABLE user_daily_token_usage RENAME COLUMN daily_fortune_tokens TO gemini_fortune_tokens;

-- chatting_tokens → gemini_chat_tokens
ALTER TABLE user_daily_token_usage RENAME COLUMN chatting_tokens TO gemini_chat_tokens;

-- chatting_message_count → gemini_chat_message_count
ALTER TABLE user_daily_token_usage RENAME COLUMN chatting_message_count TO gemini_chat_message_count;

-- chatting_session_count → gemini_chat_session_count
ALTER TABLE user_daily_token_usage RENAME COLUMN chatting_session_count TO gemini_chat_session_count;

-- ===== Step 3: 누락 컬럼 추가 =====

-- GPT 사주분석 횟수 (Edge Function ai-openai가 기록)
ALTER TABLE user_daily_token_usage ADD COLUMN IF NOT EXISTS gpt_saju_analysis_count INTEGER DEFAULT 0;

-- 궁합 분석 (미래 기능)
ALTER TABLE user_daily_token_usage ADD COLUMN IF NOT EXISTS compatibility_tokens INTEGER DEFAULT 0;
ALTER TABLE user_daily_token_usage ADD COLUMN IF NOT EXISTS compatibility_count INTEGER DEFAULT 0;

-- Gemini 운세 횟수
ALTER TABLE user_daily_token_usage ADD COLUMN IF NOT EXISTS gemini_fortune_count INTEGER DEFAULT 0;

-- ===== Step 4: GENERATED 컬럼 재생성 =====

-- total_tokens: 모든 토큰 합계 (자동 계산)
ALTER TABLE user_daily_token_usage ADD COLUMN total_tokens INTEGER GENERATED ALWAYS AS (
  COALESCE(gpt_saju_analysis_tokens, 0) +
  COALESCE(gemini_fortune_tokens, 0) +
  COALESCE(gemini_chat_tokens, 0) +
  COALESCE(compatibility_tokens, 0)
) STORED;

-- total_api_calls: 모든 API 호출 합계 (자동 계산)
ALTER TABLE user_daily_token_usage ADD COLUMN total_api_calls INTEGER GENERATED ALWAYS AS (
  COALESCE(gpt_saju_analysis_count, 0) +
  COALESCE(gemini_fortune_count, 0) +
  COALESCE(gemini_chat_message_count, 0) +
  COALESCE(compatibility_count, 0)
) STORED;

-- is_quota_exceeded: quota 초과 여부 (자동 계산)
ALTER TABLE user_daily_token_usage ADD COLUMN is_quota_exceeded BOOLEAN GENERATED ALWAYS AS (
  (COALESCE(gpt_saju_analysis_tokens, 0) +
   COALESCE(gemini_fortune_tokens, 0) +
   COALESCE(gemini_chat_tokens, 0) +
   COALESCE(compatibility_tokens, 0)) >= COALESCE(daily_quota, 50000)
) STORED;

-- ===== Step 5: 트리거 함수 업데이트 (새 컬럼명 반영) =====

-- ai_summaries → user_daily_token_usage 트리거 함수
CREATE OR REPLACE FUNCTION update_user_daily_token_usage()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id UUID;
  v_today DATE;
  v_saju_tokens INTEGER := 0;
  v_fortune_tokens INTEGER := 0;
  v_compatibility_tokens INTEGER := 0;
  v_gpt_cost NUMERIC := 0;
  v_gemini_cost NUMERIC := 0;
BEGIN
  -- user_id 직접 사용
  v_user_id := NEW.user_id;
  v_today := CURRENT_DATE;

  -- summary_type 기반 토큰 분류
  CASE NEW.summary_type
    WHEN 'saju_base' THEN
      v_saju_tokens := COALESCE(NEW.total_tokens, 0);
    WHEN 'daily_fortune', 'monthly_fortune', 'yearly_fortune' THEN
      v_fortune_tokens := COALESCE(NEW.total_tokens, 0);
    WHEN 'compatibility' THEN
      v_compatibility_tokens := COALESCE(NEW.total_tokens, 0);
    ELSE
      -- 알 수 없는 타입은 사주분석으로 분류
      v_saju_tokens := COALESCE(NEW.total_tokens, 0);
  END CASE;

  -- model_provider 기반 비용 분류
  IF NEW.model_provider = 'openai' THEN
    v_gpt_cost := COALESCE(NEW.cost_usd, 0);
  ELSIF NEW.model_provider = 'google' THEN
    v_gemini_cost := COALESCE(NEW.cost_usd, 0);
  END IF;

  -- UPSERT: 새 컬럼명으로 업데이트
  INSERT INTO user_daily_token_usage (
    user_id, usage_date,
    gpt_saju_analysis_tokens, gpt_saju_analysis_count,
    gemini_fortune_tokens, gemini_fortune_count,
    compatibility_tokens, compatibility_count,
    gpt_cost_usd, gemini_cost_usd
  ) VALUES (
    v_user_id, v_today,
    v_saju_tokens, CASE WHEN v_saju_tokens > 0 THEN 1 ELSE 0 END,
    v_fortune_tokens, CASE WHEN v_fortune_tokens > 0 THEN 1 ELSE 0 END,
    v_compatibility_tokens, CASE WHEN v_compatibility_tokens > 0 THEN 1 ELSE 0 END,
    v_gpt_cost, v_gemini_cost
  )
  ON CONFLICT (user_id, usage_date) DO UPDATE SET
    gpt_saju_analysis_tokens = user_daily_token_usage.gpt_saju_analysis_tokens + EXCLUDED.gpt_saju_analysis_tokens,
    gpt_saju_analysis_count = user_daily_token_usage.gpt_saju_analysis_count + EXCLUDED.gpt_saju_analysis_count,
    gemini_fortune_tokens = user_daily_token_usage.gemini_fortune_tokens + EXCLUDED.gemini_fortune_tokens,
    gemini_fortune_count = user_daily_token_usage.gemini_fortune_count + EXCLUDED.gemini_fortune_count,
    compatibility_tokens = user_daily_token_usage.compatibility_tokens + EXCLUDED.compatibility_tokens,
    compatibility_count = user_daily_token_usage.compatibility_count + EXCLUDED.compatibility_count,
    gpt_cost_usd = user_daily_token_usage.gpt_cost_usd + EXCLUDED.gpt_cost_usd,
    gemini_cost_usd = user_daily_token_usage.gemini_cost_usd + EXCLUDED.gemini_cost_usd,
    updated_at = NOW();

  RETURN NEW;
END;
$$;

-- 기존 트리거 재생성
DROP TRIGGER IF EXISTS trg_update_token_usage_on_ai_summaries ON ai_summaries;
CREATE TRIGGER trg_update_token_usage_on_ai_summaries
  AFTER INSERT ON ai_summaries
  FOR EACH ROW
  WHEN (NEW.status = 'completed')
  EXECUTE FUNCTION update_user_daily_token_usage();

-- ===== Step 6: check_user_quota RPC 업데이트 =====

CREATE OR REPLACE FUNCTION check_user_quota(p_user_id UUID)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
  v_usage RECORD;
  v_is_admin BOOLEAN := false;
  v_quota_limit INTEGER := 50000;
  v_tokens_used INTEGER := 0;
  v_remaining INTEGER;
BEGIN
  -- Admin 확인
  SELECT EXISTS(
    SELECT 1 FROM saju_profiles
    WHERE user_id = p_user_id AND is_primary = true AND relation_type = 'admin'
  ) INTO v_is_admin;

  IF v_is_admin THEN
    RETURN json_build_object(
      'can_use', true,
      'tokens_used', 0,
      'quota_limit', 1000000000,
      'remaining', 1000000000
    );
  END IF;

  -- 오늘 사용량 조회
  SELECT
    COALESCE(total_tokens, 0) AS tokens_used,
    COALESCE(daily_quota, 50000) AS quota_limit,
    COALESCE(ads_watched, 0) AS ads_watched,
    COALESCE(bonus_tokens_earned, 0) AS bonus_tokens
  INTO v_usage
  FROM user_daily_token_usage
  WHERE user_id = p_user_id AND usage_date = v_today;

  IF NOT FOUND THEN
    RETURN json_build_object(
      'can_use', true,
      'tokens_used', 0,
      'quota_limit', 50000,
      'remaining', 50000
    );
  END IF;

  v_tokens_used := v_usage.tokens_used;
  v_quota_limit := v_usage.quota_limit;
  v_remaining := GREATEST(v_quota_limit - v_tokens_used, 0);

  RETURN json_build_object(
    'can_use', v_tokens_used < v_quota_limit,
    'tokens_used', v_tokens_used,
    'quota_limit', v_quota_limit,
    'remaining', v_remaining,
    'ads_watched', v_usage.ads_watched,
    'bonus_tokens', v_usage.bonus_tokens
  );
END;
$$;

-- ===== Step 7: add_ad_bonus_tokens RPC 업데이트 =====

CREATE OR REPLACE FUNCTION add_ad_bonus_tokens(p_user_id UUID, p_bonus_tokens INTEGER DEFAULT 5000)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
  v_new_quota INTEGER;
  v_ads_watched INTEGER;
  v_bonus_earned INTEGER;
  v_tokens_used INTEGER;
  v_remaining INTEGER;
BEGIN
  -- UPSERT: 오늘 레코드 없으면 생성
  INSERT INTO user_daily_token_usage (user_id, usage_date, daily_quota, ads_watched, bonus_tokens_earned)
  VALUES (p_user_id, v_today, 50000 + p_bonus_tokens, 1, p_bonus_tokens)
  ON CONFLICT (user_id, usage_date) DO UPDATE SET
    ads_watched = user_daily_token_usage.ads_watched + 1,
    bonus_tokens_earned = user_daily_token_usage.bonus_tokens_earned + p_bonus_tokens,
    daily_quota = user_daily_token_usage.daily_quota + p_bonus_tokens,
    updated_at = NOW();

  -- 업데이트된 값 조회
  SELECT
    daily_quota, ads_watched, bonus_tokens_earned,
    COALESCE(total_tokens, 0)
  INTO v_new_quota, v_ads_watched, v_bonus_earned, v_tokens_used
  FROM user_daily_token_usage
  WHERE user_id = p_user_id AND usage_date = v_today;

  v_remaining := GREATEST(v_new_quota - v_tokens_used, 0);

  RETURN json_build_object(
    'success', true,
    'new_quota', v_new_quota,
    'ads_watched', v_ads_watched,
    'bonus_earned', v_bonus_earned,
    'tokens_used', v_tokens_used,
    'remaining', v_remaining
  );
END;
$$;

-- ===== Step 8: increment_ad_counter RPC 업데이트 =====

CREATE OR REPLACE FUNCTION increment_ad_counter(
  p_user_id UUID,
  p_usage_date TEXT,
  p_column_name TEXT,
  p_increment INTEGER DEFAULT 1
)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_date DATE := p_usage_date::DATE;
BEGIN
  -- 허용된 컬럼명만 업데이트 (SQL injection 방지)
  IF p_column_name NOT IN (
    'banner_impressions', 'banner_clicks',
    'interstitial_shows', 'interstitial_completes', 'interstitial_clicks',
    'rewarded_shows', 'rewarded_completes', 'rewarded_clicks', 'rewarded_tokens_earned',
    'native_impressions', 'native_clicks',
    'ads_watched', 'bonus_tokens_earned'
  ) THEN
    RAISE EXCEPTION 'Invalid column name: %', p_column_name;
  END IF;

  -- UPSERT로 레코드 생성 또는 카운터 증가
  EXECUTE format(
    'INSERT INTO user_daily_token_usage (user_id, usage_date, %I)
     VALUES ($1, $2, $3)
     ON CONFLICT (user_id, usage_date) DO UPDATE SET
       %I = COALESCE(user_daily_token_usage.%I, 0) + $3,
       updated_at = NOW()',
    p_column_name, p_column_name, p_column_name
  ) USING p_user_id, v_date, p_increment;
END;
$$;

-- ===== Step 9: 인덱스 확인 =====

-- unique constraint on (user_id, usage_date) 확인/생성
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'user_daily_token_usage_user_id_usage_date_key'
  ) THEN
    ALTER TABLE user_daily_token_usage
    ADD CONSTRAINT user_daily_token_usage_user_id_usage_date_key
    UNIQUE (user_id, usage_date);
  END IF;
END $$;

-- ===== 완료 =====
-- 검증: SELECT column_name FROM information_schema.columns
--        WHERE table_name = 'user_daily_token_usage' ORDER BY ordinal_position;
