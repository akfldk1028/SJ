# Supabase 스키마 설계 문서 v2

> 만톡(Mantok) AI 사주 챗봇 - 데이터베이스 스키마 설계
>
> **v2 업데이트**: 현재 코드베이스 분석 + AI 대화 컨텍스트 저장 최적화

---

## 1. 설계 원칙

### 1.1 Anonymous → Permanent User 패턴

```
[첫 앱 실행]              [나중에 로그인]
     │                         │
     ▼                         ▼
signInAnonymously()  →  linkIdentity() / updateUser()
     │                         │
     ▼                         ▼
익명 사용자 생성         기존 데이터 유지 + 영구 계정 전환
(is_anonymous=true)      (is_anonymous=false)
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
  display_name TEXT NOT NULL,                    -- "나", "연인", "친구" (최대 12자)
  relation_type TEXT DEFAULT 'me',               -- me, family, friend, lover, work, other
  memo TEXT,                                      -- 메모

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
```

### 3.2 public.saju_analyses

**현재 Flutter 코드의 `SajuChart` + `SajuAnalysis` 통합**

핵심: **Gemini에 전달할 사주 컨텍스트 데이터**

```sql
CREATE TABLE public.saju_analyses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.saju_profiles(id) ON DELETE CASCADE UNIQUE,

  -- ==========================================
  -- 만세력 기본 (SajuChart)
  -- ==========================================

  -- 연주 (Year Pillar)
  year_gan TEXT NOT NULL,                        -- 천간: 갑을병정무기경신임계
  year_ji TEXT NOT NULL,                         -- 지지: 자축인묘진사오미신유술해

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
  -- 상세 분석 (SajuAnalysis)
  -- ==========================================

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
      "yongsin": "수",      -- 용신 (필요한 오행)
      "heesin": "금",       -- 희신 (용신을 돕는 오행)
      "gisin": "토",        -- 기신 (나쁜 오행)
      "gusin": "화",        -- 구신 (기신을 돕는 오행)
      "hansin": "목",       -- 한신 (중립)
      "method": "eokbu",    -- 선정 방법
      "reason": "일간이 약하므로..."
    }
  */

  -- 격국 (gyeokguk)
  gyeokguk JSONB,
  /*
    {
      "name": "정관격",
      "description": "..."
    }
  */

  -- 십신 정보 (sipsinInfo) - 4주 각각의 십신
  sipsin_info JSONB,
  /*
    {
      "year": {"gan": "편관", "ji": "정재"},
      "month": {"gan": "정인", "ji": "비견"},
      "day": {"gan": "일간", "ji": "겁재"},
      "hour": {"gan": "식신", "ji": "상관"}
    }
  */

  -- 지장간 정보 (jijangganInfo)
  jijanggan_info JSONB,
  /*
    {
      "year": ["계", "신", "기"],
      "month": ["갑", "병", "무"],
      ...
    }
  */

  -- 신살 목록 (sinsalList)
  sinsal_list JSONB,
  /*
    [
      {"name": "역마살", "position": "year", "description": "..."},
      {"name": "도화살", "position": "day", "description": "..."}
    ]
  */

  -- 대운 (daeun)
  daeun JSONB,
  /*
    {
      "startAge": 3,
      "isForward": true,
      "list": [
        {"age": 3, "year": 1998, "gan": "갑", "ji": "자"},
        {"age": 13, "year": 2008, "gan": "을", "ji": "축"},
        ...
      ]
    }
  */

  -- 현재 세운 (currentSeun)
  current_seun JSONB,
  /*
    {
      "year": 2025,
      "gan": "을",
      "ji": "사",
      "description": "을사년..."
    }
  */

  -- ==========================================
  -- AI 요약 (Gemini가 생성)
  -- ==========================================

  ai_summary JSONB,
  /*
    {
      "overview": "을목 일간으로 부드럽고 유연한 성품...",
      "personality": "창의적이고 적응력이 뛰어남...",
      "strengths": ["유연한 사고", "대인관계 능력"],
      "weaknesses": ["우유부단함", "자기주장 약함"],
      "career": "예술, 교육, 상담 분야에 적합...",
      "love": "상대를 배려하는 연애 스타일...",
      "money": "안정적인 재물운...",
      "yearly_focus": "2025년은 변화의 해...",
      "generated_at": "2025-01-15T10:30:00Z",
      "ai_model": "gemini-2.0-flash"
    }
  */

  -- 메타데이터
  calculated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 3.3 public.chat_sessions

**현재 Flutter 코드의 `ChatSession` 엔티티 기반**

```sql
CREATE TABLE public.chat_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.saju_profiles(id) ON DELETE CASCADE,

  -- 세션 정보
  title TEXT,                                    -- 첫 질문에서 자동 생성
  chat_type TEXT DEFAULT 'general',              -- dailyFortune, sajuAnalysis, compatibility, general

  -- 통계
  message_count INTEGER DEFAULT 0,
  last_message_preview TEXT,                     -- 마지막 메시지 미리보기 (50자)

  -- AI 컨텍스트 (선택적 - 토큰 절약용)
  context_summary TEXT,                          -- AI가 생성한 대화 요약 (긴 대화 압축용)

  -- 타임스탬프
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT check_chat_type CHECK (chat_type IN ('dailyFortune', 'sajuAnalysis', 'compatibility', 'general'))
);
```

### 3.4 public.chat_messages

**현재 Flutter 코드의 `ChatMessage` 엔티티 기반**

```sql
CREATE TABLE public.chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES public.chat_sessions(id) ON DELETE CASCADE,

  -- 메시지 내용
  role TEXT NOT NULL,                            -- user, assistant, system
  content TEXT NOT NULL,

  -- AI 응답 메타데이터 (assistant만 해당)
  suggested_questions TEXT[],                    -- 추천 질문
  tokens_used INTEGER,                           -- 사용 토큰 (비용 추적)

  -- 상태
  status TEXT DEFAULT 'sent',                    -- sending, sent, error

  -- 타임스탬프
  created_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT check_role CHECK (role IN ('user', 'assistant', 'system')),
  CONSTRAINT check_status CHECK (status IN ('sending', 'sent', 'error'))
);
```

---

## 4. 인덱스 전략

```sql
-- saju_profiles
CREATE INDEX idx_saju_profiles_user_id ON public.saju_profiles(user_id);
CREATE INDEX idx_saju_profiles_is_primary ON public.saju_profiles(user_id, is_primary) WHERE is_primary = TRUE;

-- saju_analyses
CREATE INDEX idx_saju_analyses_profile_id ON public.saju_analyses(profile_id);
CREATE INDEX idx_saju_analyses_day_gan ON public.saju_analyses(day_gan);  -- 일간으로 검색

-- chat_sessions
CREATE INDEX idx_chat_sessions_profile_id ON public.chat_sessions(profile_id);
CREATE INDEX idx_chat_sessions_updated_at ON public.chat_sessions(updated_at DESC);
CREATE INDEX idx_chat_sessions_chat_type ON public.chat_sessions(chat_type);

-- chat_messages
CREATE INDEX idx_chat_messages_session_id ON public.chat_messages(session_id);
CREATE INDEX idx_chat_messages_session_created ON public.chat_messages(session_id, created_at);
```

---

## 5. RLS (Row Level Security) 정책

```sql
-- 모든 테이블 RLS 활성화
ALTER TABLE public.saju_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saju_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- saju_profiles: 자신의 프로필만 CRUD
CREATE POLICY "own_profiles" ON public.saju_profiles
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- saju_analyses: 자신의 프로필에 연결된 분석만
CREATE POLICY "own_analyses" ON public.saju_analyses
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.saju_profiles WHERE id = profile_id AND user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.saju_profiles WHERE id = profile_id AND user_id = auth.uid()));

-- chat_sessions: 자신의 프로필에 연결된 세션만
CREATE POLICY "own_sessions" ON public.chat_sessions
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.saju_profiles WHERE id = profile_id AND user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.saju_profiles WHERE id = profile_id AND user_id = auth.uid()));

-- chat_messages: 자신의 세션에 연결된 메시지만
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
```

---

## 6. 트리거 함수

```sql
-- updated_at 자동 갱신
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_saju_profiles_updated_at BEFORE UPDATE ON public.saju_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_saju_analyses_updated_at BEFORE UPDATE ON public.saju_analyses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

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

CREATE TRIGGER trg_single_primary BEFORE UPDATE OF is_primary ON public.saju_profiles
  FOR EACH ROW EXECUTE FUNCTION ensure_single_primary();
```

---

## 7. Gemini AI 컨텍스트 활용 예시

### 7.1 새 채팅 시작 시 사주 컨텍스트 로드

```dart
// Flutter에서 Gemini에 전달할 컨텍스트 구성
Future<String> buildSajuContext(String profileId) async {
  final analysis = await supabase
    .from('saju_analyses')
    .select()
    .eq('profile_id', profileId)
    .single();

  return '''
사용자 사주 정보:
- 사주: ${analysis['year_gan']}${analysis['year_ji']} ${analysis['month_gan']}${analysis['month_ji']} ${analysis['day_gan']}${analysis['day_ji']} ${analysis['hour_gan'] ?? ''}${analysis['hour_ji'] ?? ''}
- 일간: ${analysis['day_gan']} (${_getDayMasterDescription(analysis['day_gan'])})
- 용신: ${analysis['yongsin']['yongsin']}
- 오행 분포: 목${analysis['oheng_distribution']['mok']} 화${analysis['oheng_distribution']['hwa']} 토${analysis['oheng_distribution']['to']} 금${analysis['oheng_distribution']['geum']} 수${analysis['oheng_distribution']['su']}

이 정보를 바탕으로 상담해주세요.
''';
}
```

### 7.2 긴 대화 요약 저장 (토큰 절약)

```dart
// 20개 메시지 이상이면 AI가 요약 생성
if (messageCount > 20) {
  final summary = await gemini.summarizeConversation(messages);
  await supabase
    .from('chat_sessions')
    .update({'context_summary': summary})
    .eq('id', sessionId);
}
```

---

## 8. 쿼리 예시

### 8.1 프로필 + 사주 분석 조회

```sql
SELECT
  p.*,
  a.day_gan, a.day_ji,
  a.oheng_distribution,
  a.yongsin,
  a.ai_summary
FROM public.saju_profiles p
LEFT JOIN public.saju_analyses a ON p.id = a.profile_id
WHERE p.user_id = auth.uid()
ORDER BY p.is_primary DESC, p.created_at DESC;
```

### 8.2 채팅 히스토리 (최근 세션 + 메시지)

```sql
SELECT
  s.*,
  (
    SELECT json_agg(m ORDER BY m.created_at)
    FROM public.chat_messages m
    WHERE m.session_id = s.id
    LIMIT 50
  ) as messages
FROM public.chat_sessions s
WHERE s.profile_id = $1
ORDER BY s.updated_at DESC
LIMIT 10;
```

---

## 9. 체크리스트

- [ ] Supabase Dashboard에서 Anonymous Sign-In 활성화
- [ ] 테이블 생성 마이그레이션 실행
- [ ] RLS 정책 적용
- [ ] 트리거 함수 생성
- [ ] Flutter SajuAnalysis → saju_analyses 매핑 구현
- [ ] 채팅 시 사주 컨텍스트 자동 로드 구현
- [ ] 긴 대화 요약 기능 구현 (선택)

---

## 10. v1 대비 변경 사항

| 항목 | v1 | v2 |
|------|----|----|
| users 테이블 | 별도 생성 | auth.users 직접 사용 |
| 사주 데이터 | saju_charts + saju_summaries 분리 | saju_analyses 통합 |
| 오행/용신 저장 | 없음 | JSONB로 상세 저장 |
| AI 컨텍스트 | 매번 계산 | DB에서 로드 |
| 대화 요약 | 없음 | context_summary 필드 |
