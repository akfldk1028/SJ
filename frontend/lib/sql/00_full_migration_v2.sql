-- ============================================================
-- 만톡(Mantok) AI 사주 챗봇 - 전체 마이그레이션 v2
-- ============================================================
-- 현재 Flutter 코드베이스 분석 기반 + AI 컨텍스트 저장 최적화
-- Supabase SQL Editor에서 한 번에 실행하세요.
-- ============================================================
-- 실행 전 체크리스트:
-- [ ] Supabase Dashboard에서 Anonymous Sign-In 활성화
-- ============================================================


-- ████████████████████████████████████████████████████████████
-- PART 1: 테이블 생성
-- ████████████████████████████████████████████████████████████

-- ============================================================
-- 1. public.saju_profiles - 사주 프로필
-- ============================================================
-- Flutter: SajuProfile 엔티티 기반

CREATE TABLE IF NOT EXISTS public.saju_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- 기본 정보
  display_name TEXT NOT NULL,                    -- "나", "연인", "친구" (최대 12자)
  relation_type TEXT DEFAULT 'me',               -- me, family, friend, lover, work, other
  memo TEXT,                                     -- 메모

  -- 생년월일 정보
  birth_date DATE NOT NULL,
  birth_time_minutes INTEGER,                    -- 0~1439 (분 단위), NULL이면 시간 모름
  birth_time_unknown BOOLEAN DEFAULT FALSE,

  -- 음력/양력
  is_lunar BOOLEAN DEFAULT FALSE,
  is_leap_month BOOLEAN DEFAULT FALSE,           -- 음력 윤달

  -- 성별
  gender TEXT NOT NULL,                          -- male, female

  -- 출생지 (진태양시 계산용)
  birth_city TEXT NOT NULL,                      -- 25개 도시 중 선택
  time_correction INTEGER DEFAULT 0,             -- 진태양시 보정값 (분)

  -- 야자시/조자시
  use_ya_jasi BOOLEAN DEFAULT TRUE,

  -- 상태
  is_primary BOOLEAN DEFAULT FALSE,              -- 대표 프로필

  -- 타임스탬프
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- 제약조건
  CONSTRAINT check_gender CHECK (gender IN ('male', 'female')),
  CONSTRAINT check_relation_type CHECK (relation_type IN ('me', 'family', 'friend', 'lover', 'work', 'other')),
  CONSTRAINT check_display_name_length CHECK (char_length(display_name) <= 12),
  CONSTRAINT check_birth_time_range CHECK (birth_time_minutes IS NULL OR (birth_time_minutes >= 0 AND birth_time_minutes <= 1439))
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_saju_profiles_user_id ON public.saju_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_saju_profiles_is_primary ON public.saju_profiles(user_id, is_primary) WHERE is_primary = TRUE;

COMMENT ON TABLE public.saju_profiles IS '사주 프로필 - Flutter SajuProfile 엔티티 매핑';


-- ============================================================
-- 2. public.saju_analyses - 만세력 + 상세 분석 (통합)
-- ============================================================
-- Flutter: SajuChart + SajuAnalysis 통합
-- 핵심: Gemini에 전달할 사주 컨텍스트 데이터

CREATE TABLE IF NOT EXISTS public.saju_analyses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.saju_profiles(id) ON DELETE CASCADE UNIQUE,

  -- ==========================================
  -- 만세력 기본 (SajuChart)
  -- ==========================================

  -- 연주 (Year Pillar)
  year_gan TEXT NOT NULL,                        -- 천간
  year_ji TEXT NOT NULL,                         -- 지지

  -- 월주 (Month Pillar)
  month_gan TEXT NOT NULL,
  month_ji TEXT NOT NULL,

  -- 일주 (Day Pillar) - 일간이 "나"
  day_gan TEXT NOT NULL,
  day_ji TEXT NOT NULL,

  -- 시주 (Hour Pillar) - 시간 모르면 NULL
  hour_gan TEXT,
  hour_ji TEXT,

  -- 보정된 출생시간
  corrected_datetime TIMESTAMPTZ,

  -- ==========================================
  -- 상세 분석 (SajuAnalysis) - JSONB 사용
  -- ==========================================

  -- 오행 분포 {"mok":2,"hwa":1,"to":3,"geum":1,"su":1,"strongest":"to","weakest":"hwa","missing":[]}
  oheng_distribution JSONB NOT NULL,

  -- 일간 강약 {"strength":"strong","score":65,"reason":"..."}
  day_strength JSONB,

  -- 용신 분석 (AI 상담의 핵심!)
  -- {"yongsin":"수","heesin":"금","gisin":"토","gusin":"화","hansin":"목","method":"eokbu","reason":"..."}
  yongsin JSONB,

  -- 격국 {"name":"정관격","description":"..."}
  gyeokguk JSONB,

  -- 십신 정보 {"year":{"gan":"편관","ji":"정재"},"month":{...},...}
  sipsin_info JSONB,

  -- 지장간 정보 {"year":["계","신","기"],"month":[...],...}
  jijanggan_info JSONB,

  -- 신살 목록 [{"name":"역마살","position":"year","description":"..."},...]
  sinsal_list JSONB,

  -- 대운 {"startAge":3,"isForward":true,"list":[{"age":3,"year":1998,"gan":"갑","ji":"자"},...]}
  daeun JSONB,

  -- 현재 세운 {"year":2025,"gan":"을","ji":"사","description":"..."}
  current_seun JSONB,

  -- ==========================================
  -- AI 요약 (Gemini가 생성)
  -- ==========================================
  -- {"overview":"...","personality":"...","strengths":[],"weaknesses":[],"career":"...","love":"...","money":"...","yearly_focus":"...","generated_at":"...","ai_model":"..."}
  ai_summary JSONB,

  -- 메타데이터
  calculated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- 제약조건 (천간/지지 유효성)
  CONSTRAINT check_year_gan CHECK (year_gan IN ('갑','을','병','정','무','기','경','신','임','계')),
  CONSTRAINT check_year_ji CHECK (year_ji IN ('자','축','인','묘','진','사','오','미','신','유','술','해')),
  CONSTRAINT check_month_gan CHECK (month_gan IN ('갑','을','병','정','무','기','경','신','임','계')),
  CONSTRAINT check_month_ji CHECK (month_ji IN ('자','축','인','묘','진','사','오','미','신','유','술','해')),
  CONSTRAINT check_day_gan CHECK (day_gan IN ('갑','을','병','정','무','기','경','신','임','계')),
  CONSTRAINT check_day_ji CHECK (day_ji IN ('자','축','인','묘','진','사','오','미','신','유','술','해')),
  CONSTRAINT check_hour_gan CHECK (hour_gan IS NULL OR hour_gan IN ('갑','을','병','정','무','기','경','신','임','계')),
  CONSTRAINT check_hour_ji CHECK (hour_ji IS NULL OR hour_ji IN ('자','축','인','묘','진','사','오','미','신','유','술','해'))
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_saju_analyses_profile_id ON public.saju_analyses(profile_id);
CREATE INDEX IF NOT EXISTS idx_saju_analyses_day_gan ON public.saju_analyses(day_gan);

COMMENT ON TABLE public.saju_analyses IS '만세력 + 상세 분석 - Flutter SajuChart+SajuAnalysis 통합';
COMMENT ON COLUMN public.saju_analyses.yongsin IS 'AI 상담의 핵심 - 용신/희신/기신 정보';
COMMENT ON COLUMN public.saju_analyses.ai_summary IS 'Gemini가 생성한 사주 요약';


-- ============================================================
-- 3. public.chat_sessions - 채팅 세션
-- ============================================================
-- Flutter: ChatSession 엔티티 기반

CREATE TABLE IF NOT EXISTS public.chat_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.saju_profiles(id) ON DELETE CASCADE,

  -- 세션 정보
  title TEXT,                                    -- 첫 질문에서 자동 생성
  chat_type TEXT DEFAULT 'general',              -- dailyFortune, sajuAnalysis, compatibility, general

  -- 통계
  message_count INTEGER DEFAULT 0,
  last_message_preview TEXT,                     -- 마지막 메시지 미리보기 (50자)

  -- AI 컨텍스트 (토큰 절약용)
  context_summary TEXT,                          -- AI가 생성한 대화 요약

  -- 타임스탬프
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT check_chat_type CHECK (chat_type IN ('dailyFortune', 'sajuAnalysis', 'compatibility', 'general'))
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_chat_sessions_profile_id ON public.chat_sessions(profile_id);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_updated_at ON public.chat_sessions(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_chat_type ON public.chat_sessions(chat_type);

COMMENT ON TABLE public.chat_sessions IS '채팅 세션 - Flutter ChatSession 엔티티 매핑';
COMMENT ON COLUMN public.chat_sessions.context_summary IS '긴 대화 압축용 AI 요약 (토큰 절약)';


-- ============================================================
-- 4. public.chat_messages - 채팅 메시지
-- ============================================================
-- Flutter: ChatMessage 엔티티 기반

CREATE TABLE IF NOT EXISTS public.chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES public.chat_sessions(id) ON DELETE CASCADE,

  -- 메시지 내용
  role TEXT NOT NULL,                            -- user, assistant, system
  content TEXT NOT NULL,

  -- AI 응답 메타데이터 (assistant만)
  suggested_questions TEXT[],                    -- 추천 질문
  tokens_used INTEGER,                           -- 사용 토큰 (비용 추적)

  -- 상태
  status TEXT DEFAULT 'sent',                    -- sending, sent, error

  -- 타임스탬프
  created_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT check_role CHECK (role IN ('user', 'assistant', 'system')),
  CONSTRAINT check_status CHECK (status IN ('sending', 'sent', 'error'))
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_chat_messages_session_id ON public.chat_messages(session_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_session_created ON public.chat_messages(session_id, created_at);

COMMENT ON TABLE public.chat_messages IS '채팅 메시지 - Flutter ChatMessage 엔티티 매핑';


-- ████████████████████████████████████████████████████████████
-- PART 2: RLS 정책
-- ████████████████████████████████████████████████████████████

-- RLS 활성화
ALTER TABLE public.saju_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saju_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- saju_profiles: 자신의 프로필만 CRUD
DROP POLICY IF EXISTS "own_profiles" ON public.saju_profiles;
CREATE POLICY "own_profiles" ON public.saju_profiles
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- saju_analyses: 자신의 프로필에 연결된 분석만
DROP POLICY IF EXISTS "own_analyses" ON public.saju_analyses;
CREATE POLICY "own_analyses" ON public.saju_analyses
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.saju_profiles WHERE id = profile_id AND user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.saju_profiles WHERE id = profile_id AND user_id = auth.uid()));

-- chat_sessions: 자신의 프로필에 연결된 세션만
DROP POLICY IF EXISTS "own_sessions" ON public.chat_sessions;
CREATE POLICY "own_sessions" ON public.chat_sessions
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.saju_profiles WHERE id = profile_id AND user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.saju_profiles WHERE id = profile_id AND user_id = auth.uid()));

-- chat_messages: 자신의 세션에 연결된 메시지만
DROP POLICY IF EXISTS "own_messages" ON public.chat_messages;
CREATE POLICY "own_messages" ON public.chat_messages
  FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.chat_sessions cs
    JOIN public.saju_profiles sp ON cs.profile_id = sp.id
    WHERE cs.id = session_id AND sp.user_id = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.chat_sessions cs
    JOIN public.saju_profiles sp ON cs.profile_id = sp.id
    WHERE cs.id = session_id AND sp.user_id = auth.uid()
  ));


-- ████████████████████████████████████████████████████████████
-- PART 3: 트리거 함수
-- ████████████████████████████████████████████████████████████

-- updated_at 자동 갱신
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_saju_profiles_updated_at ON public.saju_profiles;
CREATE TRIGGER trg_saju_profiles_updated_at BEFORE UPDATE ON public.saju_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_saju_analyses_updated_at ON public.saju_analyses;
CREATE TRIGGER trg_saju_analyses_updated_at BEFORE UPDATE ON public.saju_analyses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_chat_sessions_updated_at ON public.chat_sessions;
CREATE TRIGGER trg_chat_sessions_updated_at BEFORE UPDATE ON public.chat_sessions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 메시지 추가 시 세션 통계 업데이트
CREATE OR REPLACE FUNCTION update_session_on_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.chat_sessions SET
    message_count = message_count + 1,
    last_message_preview = LEFT(NEW.content, 50),
    updated_at = NOW()
  WHERE id = NEW.session_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_message_insert ON public.chat_messages;
CREATE TRIGGER trg_message_insert AFTER INSERT ON public.chat_messages
  FOR EACH ROW EXECUTE FUNCTION update_session_on_message();

-- 첫 메시지로 세션 제목 자동 생성
CREATE OR REPLACE FUNCTION auto_session_title()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role = 'user' THEN
    UPDATE public.chat_sessions
    SET title = LEFT(NEW.content, 50)
    WHERE id = NEW.session_id AND title IS NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_first_message_title ON public.chat_messages;
CREATE TRIGGER trg_first_message_title AFTER INSERT ON public.chat_messages
  FOR EACH ROW EXECUTE FUNCTION auto_session_title();

-- 첫 프로필 자동 대표 설정
CREATE OR REPLACE FUNCTION set_first_profile_primary()
RETURNS TRIGGER AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.saju_profiles WHERE user_id = NEW.user_id) THEN
    NEW.is_primary = TRUE;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_first_profile_primary ON public.saju_profiles;
CREATE TRIGGER trg_first_profile_primary BEFORE INSERT ON public.saju_profiles
  FOR EACH ROW EXECUTE FUNCTION set_first_profile_primary();

-- 대표 프로필 단일 유지
CREATE OR REPLACE FUNCTION ensure_single_primary()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_primary = TRUE THEN
    UPDATE public.saju_profiles
    SET is_primary = FALSE
    WHERE user_id = NEW.user_id AND id != NEW.id AND is_primary = TRUE;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_single_primary ON public.saju_profiles;
CREATE TRIGGER trg_single_primary BEFORE UPDATE OF is_primary ON public.saju_profiles
  FOR EACH ROW EXECUTE FUNCTION ensure_single_primary();


-- ████████████████████████████████████████████████████████████
-- 완료!
-- ████████████████████████████████████████████████████████████
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '██████████████████████████████████████████████████';
  RAISE NOTICE '  만톡(Mantok) 데이터베이스 마이그레이션 v2 완료!';
  RAISE NOTICE '██████████████████████████████████████████████████';
  RAISE NOTICE '';
  RAISE NOTICE '생성된 테이블 (4개):';
  RAISE NOTICE '  - public.saju_profiles    (사주 프로필)';
  RAISE NOTICE '  - public.saju_analyses    (만세력 + 분석)';
  RAISE NOTICE '  - public.chat_sessions    (채팅 세션)';
  RAISE NOTICE '  - public.chat_messages    (채팅 메시지)';
  RAISE NOTICE '';
  RAISE NOTICE 'v2 주요 변경점:';
  RAISE NOTICE '  - users 테이블 제거 (auth.users 직접 사용)';
  RAISE NOTICE '  - saju_charts + saju_summaries → saju_analyses 통합';
  RAISE NOTICE '  - 오행/용신/십신 등 상세 분석 JSONB 저장';
  RAISE NOTICE '  - AI 컨텍스트 저장 (토큰 절약)';
  RAISE NOTICE '';
  RAISE NOTICE '다음 단계:';
  RAISE NOTICE '  1. Supabase Dashboard에서 Anonymous Sign-In 활성화';
  RAISE NOTICE '  2. Flutter에서 signInAnonymously() 구현';
  RAISE NOTICE '  3. SajuAnalysis → saju_analyses 매핑 구현';
  RAISE NOTICE '';
  RAISE NOTICE '██████████████████████████████████████████████████';
END $$;
