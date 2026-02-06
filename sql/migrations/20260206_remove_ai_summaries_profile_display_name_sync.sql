-- ============================================================================
-- Migration: Remove ai_summaries.profile_display_name sync from trigger
-- Date: 2026-02-06
-- Description:
--   ai_summaries.profile_display_name 필드는 앱에서 사용하지 않음
--   프로필 이름 변경 시 과거 운세 기록의 이름을 덮어쓰지 않도록 수정
--   - 제거: ai_summaries.profile_display_name 동기화 (line 340-344)
--   - 유지: profile_relations.display_name 동기화
--   - 유지: user_display_name 동기화 (primary+me 프로필)
-- ============================================================================

CREATE OR REPLACE FUNCTION sync_user_display_name()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.display_name IS DISTINCT FROM NEW.display_name THEN

    -- [REMOVED] ai_summaries.profile_display_name 동기화 제거
    -- 앱에서 이 필드를 사용하지 않으며, 과거 운세 기록은 생성 당시 이름 유지
    -- UPDATE ai_summaries
    -- SET profile_display_name = NEW.display_name
    -- WHERE profile_id = NEW.id
    --   AND profile_display_name IS DISTINCT FROM NEW.display_name;

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

-- 트리거는 함수만 변경되므로 재생성 불필요
-- (기존 트리거가 변경된 함수를 자동으로 참조)
