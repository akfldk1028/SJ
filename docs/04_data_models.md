# Supabase 스키마 설계 문서 v2

> 만톡(Mantok) AI 사주 챗봇 - 데이터베이스 스키마 설계
>
> **v2 업데이트**: 현재 코드베이스 분석 + AI 대화 컨텍스트 저장 최적화

---

## 1. 설계 원칙

### 1.1 Anonymous → Permanent User 패턴

```
[첫 앱 실행]                    [나중에 로그인]
     │                              │
     ▼                              ▼
signInAnonymously()  →  linkIdentity() / updateUser()
     │                              │
     ▼                              ▼
익명 사용자 생성              기존 데이터 유지 + 영구 계정 전환
(is_anonymous=true)          (is_anonymous=false)
```

### 1.2 AI 대화 데이터 저장 전략

**왜 사주 분석 데이터를 DB에 저장해야 하나?**

| 이유 | 설명 |
|------|------|
| **AI 컨텍스트 재구성** | 새 세션에서도 "지난번에 말씀드린 것처럼 을목 일간이시니..." 가능 |
| **토큰 비용 절감** | 매번 만세력 계산 + 프롬프트 전송 대신 저장된 요약 사용 |
| **세션 간 연속성** | 과거 대화 기반 후속 상담 ("이직 얘기 이어서 할까요?") |
| **분석/통계** | 사용자 질문 패턴, 인기 주제 분석 가능 |

### 1.3 데이터 저장 범위

```
[반드시 저장]
├── 사주 프로필 (생년월일, 성별, 출생지 등)
├── 만세력 계산 결과 (4주, 대운, 오행분포 등)
├── 채팅 세션 메타데이터
└── 채팅 메시지 (user/assistant 모두)

[저장 안 함]
├── Gemini API 키 (환경변수)
├── 실시간 스트리밍 상태 (메모리)
└── UI 임시 상태 (Riverpod)
```

---

## 2. ERD (Entity Relationship Diagram)

```
auth.users (Supabase 내장)
    │
    └── 1:N ──── public.saju_profiles (사주 프로필)
                      │
                      ├── 1:1 ── public.saju_analyses (만세력 + 분석 결과)
                      │
                      └── 1:N ── public.chat_sessions (채팅 세션)
                                      │
                                      └── 1:N ── public.chat_messages (메시지)
```

**변경점 (v1 대비):**
- `public.users` 테이블 제거 → `auth.users` 직접 사용 (간소화)
- `saju_charts` + `saju_summaries` 통합 → `saju_analyses` (만세력 + AI 분석 결과)

---

## 3. 상세 스키마

### 3.1 public.saju_profiles

**현재 Flutter 코드의 `SajuProfile` 엔티티 기반**

```sql
CREATE TABLE public.saju_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- 기본 정보 (Flutter: SajuProfile)
  display_name TEXT NOT NULL,           -- "나", "연인", "친구" (최대 12자)
  relation_type TEXT DEFAULT 'me',      -- me, family, friend, lover, work, other
  memo TEXT,                            -- 메모

  -- 생년월일 정보
  birth_date DATE NOT NULL,
  birth_time_minutes INTEGER,           -- 0~1439 (분 단위), NULL이면 시간 모름
  birth_time_unknown BOOLEAN DEFAULT FALSE,

  -- 음력/양력
  is_lunar BOOLEAN DEFAULT FALSE,
  is_leap_month BOOLEAN DEFAULT FALSE,  -- 음력 윤달

  -- 성별
  gender TEXT NOT NULL,                 -- male, female

  -- 출생지 (진태양시 계산용)
  birth_city TEXT NOT NULL,             -- 25개 도시 중 선택
  time_correction INTEGER DEFAULT 0,    -- 진태양시 보정값 (분)

  -- 야자시/조자시
  use_ya_jasi BOOLEAN DEFAULT TRUE,

  -- 상태
  is_primary BOOLEAN DEFAULT FALSE,     -- 대표 프로필

  -- 타임스탬프
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- 제약조건
  CONSTRAINT check_gender CHECK (gender IN ('male', 'female')),
  CONSTRAINT check_relation_type CHECK (relation_type IN ('me', 'family', 'friend', 'lover', 'work', 'other')),
  CONSTRAINT check_display_name_length CHECK (char_length(display_name) <= 12),
  CONSTRAINT check_birth_time_range CHECK (birth_time_minutes IS NULL OR (birth_time_minutes >= 0 AND birth_time_minutes <= 1439))
);
```

### 3.2 public.saju_analyses

**현재 Flutter 코드의 `SajuChart` + `SajuAnalysis` 통합**

핵심: **Gemini에 전달할 사주 컨텍스트 데이터**

```sql
CREATE TABLE public.saju_analyses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.saju_profiles(id) ON DELETE CASCADE UNIQUE,

  -- ================================================
  -- 만세력 기본 (SajuChart)
  -- ================================================

  -- 연주 (Year Pillar)
  year_gan TEXT NOT NULL,               -- 천간: 갑을병정무기경신임계
  year_ji TEXT NOT NULL,                -- 지지: 자축인묘진사오미신유술해

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

  -- ================================================
  -- 상세 분석 (SajuAnalysis)
  -- ================================================

  -- 오행 분포 (ohengDistribution)
  oheng_distribution JSONB NOT NULL,
  /*
    {
      "mok": 2,   -- 목
      "hwa": 1,   -- 화
      "to": 3,    -- 토
      "geum": 1,  -- 금
      "su": 1,    -- 수
      "strongest": "to",
      "weakest": "hwa",
      "missing": []
    }
  */

  -- 일간 강약 (dayStrength)
  day_strength JSONB,
  /*
    {
      "strength": "strong" | "weak" | "neutral",
      "score": 65,
      "reason": "..."
    }
  */

  -- 용신 분석 (yongsin) - AI 상담의 핵심!
  yongsin JSONB,
  /*
    {
      "yongsin": "수",       -- 용신 (필요한 오행)
      "heesin": "금",        -- 희신 (용신을 돕는 오행)
      "gisin": "화",         -- 기신 (해로운 오행)
      "reason": "일간 갑목이 강하므로..."
    }
  */

  -- 십신 분석 (sipsin)
  sipsin JSONB,
  /*
    {
      "year_gan_sipsin": "편인",
      "year_ji_sipsin": "정재",
      "month_gan_sipsin": "겁재",
      "month_ji_sipsin": "편관",
      "day_ji_sipsin": "식신",      -- 일간은 "비견(나)"이므로 제외
      "hour_gan_sipsin": "상관",
      "hour_ji_sipsin": "정인",
      "dominant": "식상",           -- 가장 많은 십신 그룹
      "characteristics": ["창의적", "표현력"]
    }
  */

  -- 지장간 분석 (jijanGan)
  jijang_gan JSONB,
  /*
    {
      "year_ji": ["계", "신", "기"],   -- 자 → 계(본기), 신(중기), 기(여기)
      "month_ji": ["갑", "병", "무"],
      "day_ji": ["을", "계", "기"],
      "hour_ji": ["병", "무", "경"]
    }
  */

  -- ================================================
  -- 대운/세운 (운세 흐름)
  -- ================================================

  -- 대운 목록 (10년 단위)
  daewoon JSONB NOT NULL,
  /*
    [
      {
        "index": 1,
        "start_age": 4,
        "end_age": 13,
        "start_year": 2028,
        "end_year": 2037,
        "gan": "병",
        "ji": "인",
        "oheng": "화목",
        "analysis": "학업운 상승, 부모 덕..."
      },
      ...
    ]
  */

  -- 대운 시작 나이 (남녀, 순행/역행에 따라 다름)
  daewoon_start_age INTEGER NOT NULL,

  -- 대운 순행/역행
  daewoon_direction TEXT NOT NULL,      -- 'forward' | 'backward'

  -- 현재 대운 인덱스 (자동 계산 또는 캐시)
  current_daewoon_index INTEGER,

  -- 올해 세운 (매년 업데이트 가능)
  current_sewoon JSONB,
  /*
    {
      "year": 2025,
      "gan": "을",
      "ji": "사",
      "oheng": "목화",
      "analysis": "을목이 일간과 비견, 사화가 식신..."
    }
  */

  -- ================================================
  -- AI 기본 분석 요약
  -- ================================================

  -- 기본 성격/특성 요약 (AI가 생성)
  personality_summary TEXT,
  /*
    "갑목 일간으로 곧고 정직한 성품, 리더십이 있으나
    고집이 셀 수 있음. 인성이 강해 학문 적성..."
  */

  -- 강점/약점
  strengths TEXT[],                     -- ["창의력", "리더십", "추진력"]
  weaknesses TEXT[],                    -- ["고집", "성급함"]

  -- 적성 분야
  career_aptitude TEXT[],               -- ["교육", "IT", "창작"]

  -- 주요 키워드 (AI 대화에서 참조용)
  keywords TEXT[],                      -- ["을목", "편인격", "식상생재"]

  -- ================================================
  -- 타임스탬프
  -- ================================================

  calculated_at TIMESTAMPTZ DEFAULT NOW(),  -- 만세력 계산 시점
  analyzed_at TIMESTAMPTZ,                  -- AI 분석 시점
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 3.3 public.chat_sessions

**채팅 세션 메타데이터**

```sql
CREATE TABLE public.chat_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.saju_profiles(id) ON DELETE CASCADE,

  -- 세션 정보
  title TEXT,                           -- 대화 제목 (자동 생성 또는 사용자 지정)
  topic TEXT,                           -- 주요 주제: career, love, money, health, general

  -- 통계
  message_count INTEGER DEFAULT 0,
  user_message_count INTEGER DEFAULT 0,
  assistant_message_count INTEGER DEFAULT 0,

  -- AI 컨텍스트 요약 (긴 대화 요약)
  context_summary TEXT,
  /*
    "사용자는 이직 고민 중. 현재 IT 회사 재직 3년차.
    경력직 이직 vs 창업 사이에서 고민. 용신 수(水)를
    활용한 방향 제시함..."
  */

  -- 마지막 논의 주제 (세션 이어가기용)
  last_discussed_topics TEXT[],         -- ["이직", "재물운", "2025년 운세"]

  -- 타임스탬프
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_message_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 3.4 public.chat_messages

**개별 메시지**

```sql
CREATE TABLE public.chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES public.chat_sessions(id) ON DELETE CASCADE,

  -- 메시지 정보
  role TEXT NOT NULL,                   -- 'user' | 'assistant'
  content TEXT NOT NULL,

  -- AI 응답 관련 (assistant만)
  suggested_questions TEXT[],           -- 추천 질문: ["올해 재물운은?", "연애운도 알려줘"]

  -- 토큰 사용량 (비용 추적용, assistant만)
  token_count INTEGER,

  -- 타임스탬프
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- 제약조건
  CONSTRAINT check_role CHECK (role IN ('user', 'assistant'))
);
```

---

## 4. RLS (Row Level Security) 정책

### 4.1 saju_profiles RLS

```sql
ALTER TABLE public.saju_profiles ENABLE ROW LEVEL SECURITY;

-- 자신의 프로필만 조회/생성/수정/삭제 가능
CREATE POLICY "Users can manage own profiles"
  ON public.saju_profiles
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

### 4.2 saju_analyses RLS

```sql
ALTER TABLE public.saju_analyses ENABLE ROW LEVEL SECURITY;

-- 자신의 프로필에 연결된 분석만 접근 가능
CREATE POLICY "Users can view own analyses"
  ON public.saju_analyses
  FOR SELECT
  USING (
    profile_id IN (
      SELECT id FROM public.saju_profiles WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own analyses"
  ON public.saju_analyses
  FOR INSERT
  WITH CHECK (
    profile_id IN (
      SELECT id FROM public.saju_profiles WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own analyses"
  ON public.saju_analyses
  FOR UPDATE
  USING (
    profile_id IN (
      SELECT id FROM public.saju_profiles WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own analyses"
  ON public.saju_analyses
  FOR DELETE
  USING (
    profile_id IN (
      SELECT id FROM public.saju_profiles WHERE user_id = auth.uid()
    )
  );
```

### 4.3 chat_sessions RLS

```sql
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own chat sessions"
  ON public.chat_sessions
  FOR ALL
  USING (
    profile_id IN (
      SELECT id FROM public.saju_profiles WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    profile_id IN (
      SELECT id FROM public.saju_profiles WHERE user_id = auth.uid()
    )
  );
```

### 4.4 chat_messages RLS

```sql
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own messages"
  ON public.chat_messages
  FOR ALL
  USING (
    session_id IN (
      SELECT cs.id FROM public.chat_sessions cs
      JOIN public.saju_profiles sp ON cs.profile_id = sp.id
      WHERE sp.user_id = auth.uid()
    )
  )
  WITH CHECK (
    session_id IN (
      SELECT cs.id FROM public.chat_sessions cs
      JOIN public.saju_profiles sp ON cs.profile_id = sp.id
      WHERE sp.user_id = auth.uid()
    )
  );
```

---

## 5. 인덱스

```sql
-- saju_profiles
CREATE INDEX idx_saju_profiles_user_id ON public.saju_profiles(user_id);
CREATE INDEX idx_saju_profiles_is_primary ON public.saju_profiles(user_id, is_primary) WHERE is_primary = TRUE;

-- saju_analyses
CREATE INDEX idx_saju_analyses_profile_id ON public.saju_analyses(profile_id);

-- chat_sessions
CREATE INDEX idx_chat_sessions_profile_id ON public.chat_sessions(profile_id);
CREATE INDEX idx_chat_sessions_last_message ON public.chat_sessions(profile_id, last_message_at DESC);

-- chat_messages
CREATE INDEX idx_chat_messages_session_id ON public.chat_messages(session_id);
CREATE INDEX idx_chat_messages_created_at ON public.chat_messages(session_id, created_at ASC);
```

---

## 6. 트리거

### 6.1 updated_at 자동 갱신

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 적용
CREATE TRIGGER update_saju_profiles_updated_at
  BEFORE UPDATE ON public.saju_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_saju_analyses_updated_at
  BEFORE UPDATE ON public.saju_analyses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### 6.2 채팅 세션 통계 자동 업데이트

```sql
CREATE OR REPLACE FUNCTION update_chat_session_stats()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.chat_sessions
    SET
      message_count = message_count + 1,
      user_message_count = CASE WHEN NEW.role = 'user' THEN user_message_count + 1 ELSE user_message_count END,
      assistant_message_count = CASE WHEN NEW.role = 'assistant' THEN assistant_message_count + 1 ELSE assistant_message_count END,
      last_message_at = NEW.created_at
    WHERE id = NEW.session_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.chat_sessions
    SET
      message_count = message_count - 1,
      user_message_count = CASE WHEN OLD.role = 'user' THEN user_message_count - 1 ELSE user_message_count END,
      assistant_message_count = CASE WHEN OLD.role = 'assistant' THEN assistant_message_count - 1 ELSE assistant_message_count END
    WHERE id = OLD.session_id;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_chat_message_change
  AFTER INSERT OR DELETE ON public.chat_messages
  FOR EACH ROW EXECUTE FUNCTION update_chat_session_stats();
```

### 6.3 대표 프로필 단일 유지

```sql
CREATE OR REPLACE FUNCTION ensure_single_primary_profile()
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

CREATE TRIGGER on_primary_profile_change
  BEFORE INSERT OR UPDATE OF is_primary ON public.saju_profiles
  FOR EACH ROW
  WHEN (NEW.is_primary = TRUE)
  EXECUTE FUNCTION ensure_single_primary_profile();
```

---

## 7. 쿼리 예시

### 7.1 프로필 + 분석 조회

```dart
final data = await supabase
  .from('saju_profiles')
  .select('''
    *,
    saju_analyses (*)
  ''')
  .eq('user_id', userId)
  .order('created_at', ascending: false);
```

### 7.2 대표 프로필 조회

```dart
final primaryProfile = await supabase
  .from('saju_profiles')
  .select('*, saju_analyses (*)')
  .eq('user_id', userId)
  .eq('is_primary', true)
  .maybeSingle();
```

### 7.3 채팅 세션 목록 (최신순)

```dart
final sessions = await supabase
  .from('chat_sessions')
  .select()
  .eq('profile_id', profileId)
  .order('last_message_at', ascending: false)
  .limit(20);
```

### 7.4 특정 세션의 메시지 (페이지네이션)

```dart
final messages = await supabase
  .from('chat_messages')
  .select()
  .eq('session_id', sessionId)
  .order('created_at', ascending: true)
  .range(0, 49);  // 50개씩
```

### 7.5 AI 컨텍스트용 프로필+분석+최근대화 조회

```dart
// Gemini 프롬프트 구성에 필요한 모든 데이터
final context = await supabase
  .from('saju_profiles')
  .select('''
    *,
    saju_analyses (*),
    chat_sessions (
      id,
      context_summary,
      last_discussed_topics,
      chat_messages (
        role,
        content,
        created_at
      )
    )
  ''')
  .eq('id', profileId)
  .single();

// chat_messages는 최근 10개만 사용
final recentMessages = context['chat_sessions']
    .expand((s) => s['chat_messages'])
    .take(10)
    .toList();
```

### 7.6 세션 컨텍스트 요약 업데이트 (Edge Function에서)

```dart
await supabase
  .from('chat_sessions')
  .update({
    'context_summary': '사용자는 2025년 이직 타이밍을 고민 중...',
    'last_discussed_topics': ['이직', '2025년 운세', '재물운']
  })
  .eq('id', sessionId);
```

---

## 8. 익명 사용자 정리

오래된 익명 사용자 자동 삭제 (관리자용):

```sql
-- 30일 이상 비활성 익명 사용자 삭제
DELETE FROM auth.users
WHERE is_anonymous = true
  AND created_at < NOW() - INTERVAL '30 days'
  AND id NOT IN (
    SELECT DISTINCT user_id
    FROM public.saju_profiles
    WHERE updated_at > NOW() - INTERVAL '30 days'
  );
```

---

## 9. 마이그레이션 파일 구조

```
frontend/lib/sql/
├── 01_create_tables.sql      -- 테이블 생성
├── 02_rls_policies.sql       -- RLS 정책
├── 03_indexes.sql            -- 인덱스
├── 04_triggers.sql           -- 트리거 함수
└── 05_seed_data.sql          -- 테스트 데이터 (선택)
```

---

## 10. 체크리스트

- [ ] Anonymous Sign-In 활성화 (Supabase Dashboard)
- [ ] 테이블 생성 마이그레이션 실행
- [ ] RLS 정책 적용
- [ ] 인덱스 생성
- [ ] 트리거 함수 생성
- [ ] Flutter 앱에서 signInAnonymously() 구현
- [ ] linkIdentity() / updateUser() 구현
- [ ] Edge Function: AI 대화 처리
- [ ] Edge Function: 세션 컨텍스트 요약

---

## 11. 다음 단계

1. SQL 마이그레이션 파일 생성 (`frontend/lib/sql/`)
2. Flutter Model 클래스 업데이트 (saju_analyses 구조 반영)
3. Repository 구현 (Supabase CRUD)
4. Edge Function 구현 (Gemini 연동)
