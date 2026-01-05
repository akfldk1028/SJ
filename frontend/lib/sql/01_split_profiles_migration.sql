-- ============================================================
-- 만톡(Mantok) 프로필 분리 마이그레이션
-- ============================================================
-- 목적: saju_profiles를 user_profiles + relationships로 분리
-- 실행: Supabase Dashboard > SQL Editor에서 실행
-- ============================================================


-- ████████████████████████████████████████████████████████████
-- PART 1: 새 테이블 생성
-- ████████████████████████████████████████████████████████████

-- ============================================================
-- 1. user_profiles (내 사주 - 1:1 관계)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,

  -- 기본 정보
  display_name TEXT NOT NULL DEFAULT '나',

  -- 생년월일
  birth_date DATE NOT NULL,
  birth_time_minutes INTEGER CHECK (birth_time_minutes IS NULL OR (birth_time_minutes >= 0 AND birth_time_minutes <= 1439)),
  birth_time_unknown BOOLEAN DEFAULT FALSE,

  -- 음력/양력
  is_lunar BOOLEAN DEFAULT FALSE,
  is_leap_month BOOLEAN DEFAULT FALSE,

  -- 성별
  gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),

  -- 출생지 (진태양시 계산용)
  birth_city TEXT NOT NULL,
  time_correction INTEGER DEFAULT 0,

  -- 야자시/조자시
  use_ya_jasi BOOLEAN DEFAULT TRUE,

  -- 타임스탬프
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);

COMMENT ON TABLE public.user_profiles IS '내 사주 프로필 - auth.users와 1:1 관계';


-- ============================================================
-- 2. relationships (인맥 사주 - 1:N 관계)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- 관계 정보
  relation_type TEXT NOT NULL CHECK (
    relation_type IN ('family', 'friend', 'lover', 'work', 'other')
  ),
  display_name TEXT NOT NULL,
  memo TEXT,

  -- 생년월일
  birth_date DATE NOT NULL,
  birth_time_minutes INTEGER CHECK (birth_time_minutes IS NULL OR (birth_time_minutes >= 0 AND birth_time_minutes <= 1439)),
  birth_time_unknown BOOLEAN DEFAULT FALSE,

  -- 음력/양력
  is_lunar BOOLEAN DEFAULT FALSE,
  is_leap_month BOOLEAN DEFAULT FALSE,

  -- 성별
  gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),

  -- 출생지 (선택 - 인맥은 모를 수 있음)
  birth_city TEXT,
  time_correction INTEGER DEFAULT 0,

  -- 야자시/조자시
  use_ya_jasi BOOLEAN DEFAULT TRUE,

  -- 정렬 순서
  sort_order INTEGER DEFAULT 0,

  -- 타임스탬프
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_relationships_user_id ON public.relationships(user_id);
CREATE INDEX IF NOT EXISTS idx_relationships_type ON public.relationships(user_id, relation_type);

COMMENT ON TABLE public.relationships IS '인맥 사주 프로필 - auth.users와 1:N 관계';


-- ============================================================
-- 3. compatibility_analyses (궁합 분석)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.compatibility_analyses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- 비교 대상 (나 + 인맥)
  user_profile_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  relationship_id UUID NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,

  -- 궁합 점수
  overall_score INTEGER CHECK (overall_score IS NULL OR (overall_score >= 0 AND overall_score <= 100)),
  grade TEXT CHECK (grade IS NULL OR grade IN ('S', 'A', 'B', 'C', 'D', 'F')),

  -- 상세 분석 (JSONB)
  -- {"love":85,"work":70,"friendship":90,"family":80}
  category_scores JSONB,

  -- 장점/단점
  -- ["서로의 부족한 오행 보완", "성격적 조화"]
  strengths JSONB,
  weaknesses JSONB,

  -- AI 조언
  advice JSONB,
  ai_summary TEXT,

  -- 타임스탬프
  calculated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- 중복 방지: 같은 조합 한 번만
  UNIQUE (user_profile_id, relationship_id)
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_compatibility_user ON public.compatibility_analyses(user_id);
CREATE INDEX IF NOT EXISTS idx_compatibility_pair ON public.compatibility_analyses(user_profile_id, relationship_id);

COMMENT ON TABLE public.compatibility_analyses IS '궁합 분석 결과 - 나와 인맥 사이';


-- ████████████████████████████████████████████████████████████
-- PART 2: saju_analyses 수정 (Polymorphic FK)
-- ████████████████████████████████████████████████████████████

-- 새 컬럼 추가 (기존 profile_id 유지하면서)
ALTER TABLE public.saju_analyses
  ADD COLUMN IF NOT EXISTS user_profile_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS relationship_id UUID REFERENCES public.relationships(id) ON DELETE CASCADE;

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_saju_analyses_user_profile ON public.saju_analyses(user_profile_id);
CREATE INDEX IF NOT EXISTS idx_saju_analyses_relationship ON public.saju_analyses(relationship_id);

COMMENT ON COLUMN public.saju_analyses.user_profile_id IS '내 사주 분석인 경우';
COMMENT ON COLUMN public.saju_analyses.relationship_id IS '인맥 사주 분석인 경우';


-- ████████████████████████████████████████████████████████████
-- PART 3: RLS 정책
-- ████████████████████████████████████████████████████████████

-- user_profiles RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "own_user_profile" ON public.user_profiles;
CREATE POLICY "own_user_profile" ON public.user_profiles
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- relationships RLS
ALTER TABLE public.relationships ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "own_relationships" ON public.relationships;
CREATE POLICY "own_relationships" ON public.relationships
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- compatibility_analyses RLS
ALTER TABLE public.compatibility_analyses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "own_compatibility" ON public.compatibility_analyses;
CREATE POLICY "own_compatibility" ON public.compatibility_analyses
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);


-- ████████████████████████████████████████████████████████████
-- PART 4: 트리거
-- ████████████████████████████████████████████████████████████

-- updated_at 자동 갱신 (기존 함수 사용)
DROP TRIGGER IF EXISTS trg_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER trg_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_relationships_updated_at ON public.relationships;
CREATE TRIGGER trg_relationships_updated_at
  BEFORE UPDATE ON public.relationships
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_compatibility_updated_at ON public.compatibility_analyses;
CREATE TRIGGER trg_compatibility_updated_at
  BEFORE UPDATE ON public.compatibility_analyses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();


-- ████████████████████████████████████████████████████████████
-- PART 5: 데이터 이관 (기존 saju_profiles → 새 테이블)
-- ████████████████████████████████████████████████████████████

-- 1) "나" 프로필 → user_profiles
INSERT INTO public.user_profiles (
  id, user_id, display_name, birth_date, birth_time_minutes,
  birth_time_unknown, is_lunar, is_leap_month, gender,
  birth_city, time_correction, use_ya_jasi, created_at, updated_at
)
SELECT
  id, user_id, display_name, birth_date, birth_time_minutes,
  birth_time_unknown, is_lunar, is_leap_month, gender,
  birth_city, time_correction, use_ya_jasi, created_at, updated_at
FROM public.saju_profiles
WHERE relation_type = 'me' OR is_primary = TRUE
ON CONFLICT (user_id) DO NOTHING;

-- 2) 인맥 프로필 → relationships
INSERT INTO public.relationships (
  id, user_id, relation_type, display_name, memo, birth_date,
  birth_time_minutes, birth_time_unknown, is_lunar, is_leap_month,
  gender, birth_city, time_correction, use_ya_jasi, created_at, updated_at
)
SELECT
  id, user_id, relation_type, display_name, memo, birth_date,
  birth_time_minutes, birth_time_unknown, is_lunar, is_leap_month,
  gender, birth_city, time_correction, use_ya_jasi, created_at, updated_at
FROM public.saju_profiles
WHERE relation_type != 'me' AND (is_primary = FALSE OR is_primary IS NULL)
ON CONFLICT (id) DO NOTHING;

-- 3) saju_analyses FK 업데이트
UPDATE public.saju_analyses sa
SET user_profile_id = up.id
FROM public.user_profiles up
WHERE sa.profile_id = up.id;

UPDATE public.saju_analyses sa
SET relationship_id = r.id
FROM public.relationships r
WHERE sa.profile_id = r.id;


-- ████████████████████████████████████████████████████████████
-- 완료!
-- ████████████████████████████████████████████████████████████

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '██████████████████████████████████████████████████';
  RAISE NOTICE '  프로필 분리 마이그레이션 완료!';
  RAISE NOTICE '██████████████████████████████████████████████████';
  RAISE NOTICE '';
  RAISE NOTICE '새로 생성된 테이블:';
  RAISE NOTICE '  - user_profiles     (내 사주 - 1:1)';
  RAISE NOTICE '  - relationships     (인맥 사주 - 1:N)';
  RAISE NOTICE '  - compatibility_analyses (궁합 분석)';
  RAISE NOTICE '';
  RAISE NOTICE '수정된 테이블:';
  RAISE NOTICE '  - saju_analyses (user_profile_id, relationship_id 추가)';
  RAISE NOTICE '';
  RAISE NOTICE '다음 단계:';
  RAISE NOTICE '  1. Flutter 엔티티/모델 업데이트';
  RAISE NOTICE '  2. Provider 수정';
  RAISE NOTICE '  3. 기존 saju_profiles 테이블 제거 (선택)';
  RAISE NOTICE '';
  RAISE NOTICE '██████████████████████████████████████████████████';
END $$;
