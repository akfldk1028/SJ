-- ============================================================================
-- Migration: Add Fortune Summary Types + Target Year/Month Fields
-- Date: 2026-01-18
-- Author: JH_AI
--
-- Description:
-- 1. ai_summaries.summary_type CHECK 제약 조건에 새로운 운세 유형 추가
--    - yearly_fortune_2026: 2026 신년운세
--    - yearly_fortune_2025: 2025 회고 운세
-- 2. target_year, target_month 필드 추가 (월운/년운 필터링용)
--    - 한국 시간 기준 월/년 전환 처리
--    - 쿼리에서 직접 필터링 가능
-- ============================================================================

-- Step 1: 기존 CHECK 제약 조건 삭제
ALTER TABLE ai_summaries
DROP CONSTRAINT IF EXISTS ai_summaries_summary_type_check;

-- Step 2: 새 CHECK 제약 조건 추가 (신규 유형 포함)
ALTER TABLE ai_summaries
ADD CONSTRAINT ai_summaries_summary_type_check
CHECK (summary_type IN (
  'saju_base',           -- 평생운세 (기존)
  'daily_fortune',       -- 일운 (기존)
  'monthly_fortune',     -- 월운 (기존)
  'yearly_fortune',      -- 년운 (기존)
  'yearly_fortune_2026', -- 2026 신년운세 (신규)
  'yearly_fortune_2025', -- 2025 회고 운세 (신규)
  'question_answer',     -- 질문 응답 (기존)
  'compatibility'        -- 궁합 (기존)
));

-- Step 3: target_year 필드 추가
-- - 년운/월운에서 대상 연도 저장
-- - NULL 허용 (saju_base 등 연도 무관 유형)
ALTER TABLE ai_summaries
ADD COLUMN IF NOT EXISTS target_year SMALLINT;

-- Step 4: target_month 필드 추가
-- - 월운에서 대상 월 저장
-- - NULL 허용 (년운 등 월 무관 유형)
-- - 1-12 범위 제한
ALTER TABLE ai_summaries
ADD COLUMN IF NOT EXISTS target_month SMALLINT;

-- Step 5: target_month 범위 제약 조건
ALTER TABLE ai_summaries
ADD CONSTRAINT ai_summaries_target_month_check
CHECK (target_month IS NULL OR (target_month >= 1 AND target_month <= 12));

-- Step 6: 인덱스 추가 (성능 최적화)
-- 6.1 profile_id + summary_type 복합 인덱스
CREATE INDEX IF NOT EXISTS idx_ai_summaries_profile_summary_type
ON ai_summaries (profile_id, summary_type);

-- 6.2 profile_id + summary_type + target_year + target_month 복합 인덱스
-- 월운/년운 조회 최적화
CREATE INDEX IF NOT EXISTS idx_ai_summaries_profile_summary_year_month
ON ai_summaries (profile_id, summary_type, target_year, target_month);

-- Step 7: 기존 UNIQUE 제약 조건 수정 (필요시)
-- 기존: profile_id + summary_type
-- 변경: profile_id + summary_type + target_year + target_month
-- 주의: 기존 제약 조건명 확인 필요
-- ALTER TABLE ai_summaries DROP CONSTRAINT IF EXISTS ai_summaries_profile_id_summary_type_key;
-- ALTER TABLE ai_summaries ADD CONSTRAINT ai_summaries_unique_fortune
-- UNIQUE (profile_id, summary_type, target_year, target_month);

-- Step 8: 코멘트 추가
COMMENT ON COLUMN ai_summaries.target_year IS '대상 연도 (년운/월운용, 한국 시간 기준)';
COMMENT ON COLUMN ai_summaries.target_month IS '대상 월 (월운용, 1-12, 한국 시간 기준)';

-- ============================================================================
-- 사용 예시
-- ============================================================================
--
-- 1. 2026년 1월 월운 조회:
-- SELECT * FROM ai_summaries
-- WHERE profile_id = 'xxx'
--   AND summary_type = 'monthly_fortune'
--   AND target_year = 2026
--   AND target_month = 1;
--
-- 2. 2026 신년운세 조회:
-- SELECT * FROM ai_summaries
-- WHERE profile_id = 'xxx'
--   AND summary_type = 'yearly_fortune_2026'
--   AND target_year = 2026;
--
-- ============================================================================
-- Rollback Script (필요시)
-- ============================================================================
-- ALTER TABLE ai_summaries DROP CONSTRAINT IF EXISTS ai_summaries_target_month_check;
-- ALTER TABLE ai_summaries DROP COLUMN IF EXISTS target_month;
-- ALTER TABLE ai_summaries DROP COLUMN IF EXISTS target_year;
-- DROP INDEX IF EXISTS idx_ai_summaries_profile_summary_year_month;
-- ALTER TABLE ai_summaries DROP CONSTRAINT ai_summaries_summary_type_check;
-- ALTER TABLE ai_summaries ADD CONSTRAINT ai_summaries_summary_type_check
-- CHECK (summary_type IN (
--   'saju_base', 'daily_fortune', 'monthly_fortune', 'yearly_fortune',
--   'question_answer', 'compatibility'
-- ));
