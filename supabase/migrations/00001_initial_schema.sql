-- =====================================================
-- 만톡 (Mantok) AI 사주 챗봇 - Initial Database Schema
-- =====================================================
-- Supabase에서 SQL Editor로 실행하거나
-- Supabase CLI: supabase db push
-- =====================================================

-- 1. Users 테이블 (Supabase Auth와 연동)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  nickname TEXT,
  profile_image TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS 활성화
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- RLS 정책
CREATE POLICY "Users can view own profile"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

-- 2. Saju Profiles 테이블 (사주 프로필)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.saju_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  birth_date DATE NOT NULL,
  birth_time_minutes INTEGER,  -- 0~1439 (분 단위)
  birth_time_unknown BOOLEAN DEFAULT FALSE,
  is_lunar BOOLEAN DEFAULT FALSE,
  is_leap_month BOOLEAN DEFAULT FALSE,  -- 음력 윤달 여부
  gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),
  birth_city TEXT NOT NULL,  -- 출생 도시 (진태양시 계산용)
  use_ya_jasi BOOLEAN DEFAULT TRUE,  -- 야자시/조자시 설정
  time_correction INTEGER DEFAULT 0,  -- 진태양시 보정값 (분 단위)
  is_active BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_saju_profiles_user_id ON public.saju_profiles(user_id);

-- RLS 활성화
ALTER TABLE public.saju_profiles ENABLE ROW LEVEL SECURITY;

-- RLS 정책
CREATE POLICY "Users can CRUD own profiles"
  ON public.saju_profiles FOR ALL
  USING (auth.uid() = user_id);

-- 3. Saju Charts 테이블 (만세력 계산 결과)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.saju_charts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES public.saju_profiles(id) ON DELETE CASCADE UNIQUE,

  -- 연주 (Year Pillar)
  year_stem TEXT NOT NULL,
  year_branch TEXT NOT NULL,

  -- 월주 (Month Pillar)
  month_stem TEXT NOT NULL,
  month_branch TEXT NOT NULL,

  -- 일주 (Day Pillar)
  day_stem TEXT NOT NULL,
  day_branch TEXT NOT NULL,

  -- 시주 (Hour Pillar) - nullable
  hour_stem TEXT,
  hour_branch TEXT,

  -- 대운 (JSON 배열)
  daewoon JSONB,

  -- 원본 계산 데이터
  raw_data JSONB,

  calculated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_saju_charts_profile_id ON public.saju_charts(profile_id);

-- RLS 활성화
ALTER TABLE public.saju_charts ENABLE ROW LEVEL SECURITY;

-- RLS 정책
CREATE POLICY "Users can view own charts"
  ON public.saju_charts FOR SELECT
  USING (
    profile_id IN (
      SELECT id FROM public.saju_profiles WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own charts"
  ON public.saju_charts FOR INSERT
  WITH CHECK (
    profile_id IN (
      SELECT id FROM public.saju_profiles WHERE user_id = auth.uid()
    )
  );

-- 4. Saju Summaries 테이블 (AI 요약)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.saju_summaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES public.saju_profiles(id) ON DELETE CASCADE UNIQUE,
  overview TEXT NOT NULL,
  strengths TEXT[] NOT NULL,
  weaknesses TEXT[] NOT NULL,
  career TEXT,
  love TEXT,
  money TEXT,
  yearly_focus TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_saju_summaries_profile_id ON public.saju_summaries(profile_id);

-- RLS 활성화
ALTER TABLE public.saju_summaries ENABLE ROW LEVEL SECURITY;

-- RLS 정책
CREATE POLICY "Users can view own summaries"
  ON public.saju_summaries FOR SELECT
  USING (
    profile_id IN (
      SELECT id FROM public.saju_profiles WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own summaries"
  ON public.saju_summaries FOR INSERT
  WITH CHECK (
    profile_id IN (
      SELECT id FROM public.saju_profiles WHERE user_id = auth.uid()
    )
  );

-- 5. Chat Sessions 테이블 (채팅 세션)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.chat_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES public.saju_profiles(id) ON DELETE CASCADE,
  title TEXT,
  message_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_message_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_chat_sessions_profile_id ON public.chat_sessions(profile_id);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_last_message_at ON public.chat_sessions(last_message_at DESC);

-- RLS 활성화
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;

-- RLS 정책
CREATE POLICY "Users can CRUD own chat sessions"
  ON public.chat_sessions FOR ALL
  USING (
    profile_id IN (
      SELECT id FROM public.saju_profiles WHERE user_id = auth.uid()
    )
  );

-- 6. Chat Messages 테이블 (채팅 메시지)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  suggested_questions TEXT[],  -- AI 추천 질문 (assistant만)
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_chat_messages_chat_id ON public.chat_messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON public.chat_messages(created_at);

-- RLS 활성화
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- RLS 정책
CREATE POLICY "Users can CRUD own messages"
  ON public.chat_messages FOR ALL
  USING (
    chat_id IN (
      SELECT cs.id FROM public.chat_sessions cs
      JOIN public.saju_profiles sp ON cs.profile_id = sp.id
      WHERE sp.user_id = auth.uid()
    )
  );

-- =====================================================
-- 7. Trigger Functions
-- =====================================================

-- updated_at 자동 갱신 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- 각 테이블에 트리거 적용
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_saju_profiles_updated_at ON public.saju_profiles;
CREATE TRIGGER update_saju_profiles_updated_at
  BEFORE UPDATE ON public.saju_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_saju_summaries_updated_at ON public.saju_summaries;
CREATE TRIGGER update_saju_summaries_updated_at
  BEFORE UPDATE ON public.saju_summaries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 메시지 추가 시 세션의 message_count, last_message_at 업데이트
CREATE OR REPLACE FUNCTION update_chat_session_on_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.chat_sessions
  SET
    message_count = message_count + 1,
    last_message_at = NEW.created_at
  WHERE id = NEW.chat_id;
  RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS on_chat_message_insert ON public.chat_messages;
CREATE TRIGGER on_chat_message_insert
  AFTER INSERT ON public.chat_messages
  FOR EACH ROW EXECUTE FUNCTION update_chat_session_on_message();

-- =====================================================
-- 8. Auth 연동: 새 유저 생성 시 자동 프로필 생성
-- =====================================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- auth.users 테이블에 트리거 (Supabase에서 이미 존재할 수 있음)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- =====================================================
-- 완료!
-- =====================================================
