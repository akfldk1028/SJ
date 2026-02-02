-- =============================================================================
-- Migration: add_native_tokens_earned_to_increment_ad_counter
-- Date: 2026-02-02
-- Description:
--   increment_ad_counter RPC의 허용 컬럼 목록에 'native_tokens_earned' 추가.
--   기존에는 native_clicks만 추적 가능했지만, 토큰 지급액도
--   같은 RPC로 원자적으로 기록할 수 있도록 수정.
-- =============================================================================

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
    'native_impressions', 'native_clicks', 'native_tokens_earned',
    'ads_watched', 'bonus_tokens_earned'
  ) THEN
    RAISE EXCEPTION 'Invalid column name: %', p_column_name;
  END IF;

  -- upsert: 레코드 없으면 생성, 있으면 카운터 증가
  INSERT INTO user_daily_token_usage (user_id, usage_date)
  VALUES (p_user_id, v_date)
  ON CONFLICT (user_id, usage_date) DO NOTHING;

  -- 동적 SQL로 해당 컬럼만 업데이트
  EXECUTE format(
    'UPDATE user_daily_token_usage SET %I = COALESCE(%I, 0) + $1 WHERE user_id = $2 AND usage_date = $3',
    p_column_name, p_column_name
  ) USING p_increment, p_user_id, v_date;
END;
$$;
