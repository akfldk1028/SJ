# 궁합 분석 시스템 설계

> 작성일: 2026-01-15
> 버전: v2.0
> 상태: 설계 완료 - 구현 대기

---

## 1. 개요

### 1.1 현재 상태

스크린샷에서 확인된 기능:
- **멘션 기반 궁합**: `@친구/김동현 @직장/이유국` 형식으로 여러 인연 멘션 가능
- **1대1 궁합만 분석**: 현재 DB 구조상 `profile1_id`, `profile2_id` 두 명만 지원
- **다중 인연 질문은 가능**: "나랑 해서 3명의 궁합봐바" 같은 질문은 받지만, 실제 분석은 제한적

### 1.2 문제점

| 문제 | 설명 |
|------|------|
| **1:1 구조 한계** | `compatibility_analyses`에 `profile1_id`, `profile2_id`만 존재 |
| **chat_sessions도 1:1** | `target_profile_id` 단일 필드만 존재 |
| **합충형해파 원리 미저장** | "갑기합토"는 저장하지만 갑+기=토 변환 규칙이 없음 |
| **나 제외 궁합 불가** | "엄마랑 아빠 궁합" (나 빠짐) 케이스 미지원 |

### 1.3 지원해야 할 궁합 시나리오

```
┌─────────────────────────────────────────────────────────────────┐
│                    궁합 시나리오 4가지                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  [A] 나 vs 1명 (기존)                                            │
│  ───────────────                                                │
│  예: "나랑 엄마 궁합"                                             │
│  구조: profile1_id(나) + profile2_id(엄마)                        │
│  → 기존 compatibility_analyses로 충분 ✅                          │
│                                                                  │
│  [B] 나 vs N명 (다중 멘션)                                        │
│  ────────────────────                                           │
│  예: "@친구/철수 @직장/영희 궁합 봐줘"                             │
│  구조: 나 + [철수, 영희]                                          │
│  계산: 나↔철수, 나↔영희, 철수↔영희 (3쌍)                          │
│  → multi_compatibility_analyses 필요                             │
│                                                                  │
│  [C] 타인 vs 타인 (나 제외) ⭐ 신규                               │
│  ───────────────────────                                        │
│  예: "엄마랑 아빠 궁합 어때?" (나는 빠짐)                          │
│  구조: [엄마, 아빠] (나 없음)                                      │
│  계산: 엄마↔아빠 (1쌍)                                            │
│  → includes_owner = false 플래그 필요                            │
│                                                                  │
│  [D] 타인 N명끼리 (나 제외)                                       │
│  ─────────────────────                                          │
│  예: "부모님이랑 동생 셋이서 궁합"                                 │
│  구조: [엄마, 아빠, 동생] (나 없음)                                │
│  계산: 엄마↔아빠, 엄마↔동생, 아빠↔동생 (3쌍)                      │
│  → includes_owner = false + participant_ids[]                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. 현재 DB 구조 분석

### 2.1 현재 데이터 규모 (2026-01-15)

| 테이블 | 행 수 | 비고 |
|--------|-------|------|
| saju_profiles (primary) | 228 | 본인 프로필 |
| saju_profiles (other) | 42 | 인연 프로필 |
| profile_relations | 38 | 유저당 평균 1.3명 |
| compatibility_analyses | 7 | 1:1 궁합 (신규만 적용 예정) |
| chat_sessions | 175 | target 있는 건 13개 |
| saju_analyses | 232 | hapchung 있음: 230 |

### 2.2 테이블 관계도 (현재)

```
                    ┌─────────────────┐
                    │  saju_profiles  │
                    │─────────────────│
                    │ id (PK)         │
                    │ user_id         │
                    │ display_name    │
                    │ profile_type    │ ← 'primary' / 'other'
                    └────────┬────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ saju_analyses   │ │ profile_relations│ │ chat_sessions   │
│─────────────────│ │─────────────────│ │─────────────────│
│ profile_id (FK) │ │ from_profile_id │ │ profile_id (FK) │ ← 나
│ hapchung (JSONB)│ │ to_profile_id   │ │ target_profile_id│ ← 상대 1명만!
│ ...             │ │ compatibility_  │ │ ...             │
└─────────────────┘ │ analysis_id (FK)│ └────────┬────────┘
                    └────────┬────────┘          │
                             │                   │
                             ▼                   ▼
                    ┌─────────────────┐ ┌─────────────────┐
                    │compatibility_   │ │ chat_messages   │
                    │analyses         │ │─────────────────│
                    │─────────────────│ │ session_id (FK) │
                    │ profile1_id (FK)│ │ role            │
                    │ profile2_id (FK)│ │ content         │
                    │ saju_analysis   │ └─────────────────┘
                    │ (JSONB)         │
                    └─────────────────┘
```

### 2.3 각 테이블 역할

#### `saju_profiles` - 프로필 정보
| 필드 | 설명 |
|------|------|
| id | PK |
| user_id | 소유자 |
| display_name | 표시명 (나, 김동현, 이유국 등) |
| profile_type | 'primary' (나) / 'other' (인연) |

#### `saju_analyses` - 개인 사주 분석
| 필드 | 설명 |
|------|------|
| profile_id | FK → saju_profiles |
| year_gan/ji ~ hour_gan/ji | 4주 8자 |
| hapchung | JSONB - **개인 내 합충** (cheongan_haps, jiji_yukhaps 등) |
| oheng_distribution | 오행 분포 |

#### `profile_relations` - 인연 관계
| 필드 | 설명 |
|------|------|
| from_profile_id | 나 |
| to_profile_id | 상대방 |
| relation_type | family_parent, friend_close, work_colleague 등 19종 |
| compatibility_analysis_id | FK → compatibility_analyses |

#### `chat_sessions` - 채팅 세션
| 필드 | 설명 |
|------|------|
| profile_id | 나 (채팅 주체) |
| target_profile_id | **상대방 1명만** ← 문제! |
| chat_type | 'general', 'compatibility' 등 |

#### `compatibility_analyses` - 궁합 분석 (1:1)
| 필드 | 설명 |
|------|------|
| profile1_id | 나 |
| profile2_id | **상대방 1명만** ← 문제! |
| saju_analysis | JSONB - 두 사람 간 합충 분석 결과 |
| target_hapchung | JSONB - 상대방 개인 합충 정보 |
| overall_score | 종합 점수 (0-100) |

---

## 3. 설계 결정사항

### 3.1 반합 해석 기준
**결정: 느슨한 해석(포스텔러 기준) 포함**

현재 Dart 코드에 이미 구현:
- `isHalfMatch()` - 왕지 필수 (엄격)
- `isHalfMatchLoose()` - 2글자면 OK (느슨)

→ DB 저장 시 느슨한 해석 결과도 포함

### 3.2 마이그레이션 범위
**결정: 신규 분석부터만 적용**

이유:
- 기존 compatibility_analyses는 7건뿐 (이관 비용 대비 가치 낮음)
- 다중 멘션은 기존 1:1 구조와 호환 안 됨
- 기존 테이블은 삭제 안 하고 읽기 전용으로 유지

### 3.3 AI 해석 저장
**결정: 불필요**

현재 구조:
```
GPT-5.2 → saju_analyses (개인 사주 계산)
    ↓
Dart (compatibility_calculator.dart) → 궁합 계산 (합충형해파)
    ↓
결과 → DB 저장
```
→ Dart 계산 결과만 저장, AI 해석 필드 불필요

### 3.4 스케일링 전략
**결정: 하이브리드 방식 (정규화 + JSONB)**

```
정규화 (검색/조회용):
├── chat_session_targets: 다중 멘션 대상
├── saju_relation_rules: 합충형해파 마스터 (약 60개)
└── 인덱스: participant_ids GIN, session_id

JSONB (유연성/저장용):
├── multi_compatibility_analyses.analysis_result: N명 쌍별 궁합 결과
└── saju_analyses.hapchung: 개인 합충 정보
```

---

## 4. 신규 테이블 설계

### 4.1 chat_session_targets (다중 멘션 지원)

```sql
CREATE TABLE chat_session_targets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
    target_profile_id UUID NOT NULL REFERENCES saju_profiles(id),

    -- 멘션 순서 (UI 표시용)
    mention_order INT NOT NULL DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT now(),

    UNIQUE(session_id, target_profile_id)
);

-- 인덱스
CREATE INDEX idx_chat_session_targets_session
ON chat_session_targets(session_id);

CREATE INDEX idx_chat_session_targets_profile
ON chat_session_targets(target_profile_id);

-- RLS
ALTER TABLE chat_session_targets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own session targets"
ON chat_session_targets FOR ALL
USING (
    session_id IN (
        SELECT id FROM chat_sessions WHERE user_id = auth.uid()
    )
);
```

### 4.2 multi_compatibility_analyses (N명 궁합 결과)

```sql
CREATE TABLE multi_compatibility_analyses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    session_id UUID REFERENCES chat_sessions(id),

    -- 핵심 필드
    participant_ids UUID[] NOT NULL,           -- 참여자 전체 (정렬된 상태로 저장)
    includes_owner BOOLEAN NOT NULL DEFAULT true,  -- 나 포함 여부
    owner_profile_id UUID REFERENCES saju_profiles(id),  -- 나의 프로필

    participant_count INT GENERATED ALWAYS AS (array_length(participant_ids, 1)) STORED,

    -- 결과 저장 (JSONB)
    analysis_result JSONB NOT NULL DEFAULT '{}'::jsonb,
    /*
    {
      "pairs": [
        {
          "profile_a_id": "uuid1",
          "profile_b_id": "uuid2",
          "score": 85,
          "hapchung": {
            "cheongan_haps": [...],
            "jiji_yukhaps": [...],
            "jiji_chungs": [...]
          }
        }
      ],
      "group_summary": "세 분의 전체적인 조화도는...",
      "overall_harmony": 75
    }
    */

    created_at TIMESTAMPTZ DEFAULT now(),

    -- RLS
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- 인덱스
CREATE INDEX idx_multi_compat_user
ON multi_compatibility_analyses(user_id);

CREATE INDEX idx_multi_compat_participants
ON multi_compatibility_analyses USING GIN(participant_ids);

CREATE INDEX idx_multi_compat_session
ON multi_compatibility_analyses(session_id);

-- RLS
ALTER TABLE multi_compatibility_analyses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own analyses"
ON multi_compatibility_analyses FOR ALL
USING (user_id = auth.uid());
```

### 4.3 saju_relation_rules (합충형해파 마스터)

```sql
CREATE TABLE saju_relation_rules (
    id SERIAL PRIMARY KEY,

    -- 분류
    category TEXT NOT NULL,        -- 'cheongan_hap', 'jiji_yukhap', 'jiji_samhap', 'jiji_banghap',
                                   -- 'jiji_chung', 'jiji_hyung', 'jiji_hae', 'jiji_pa', 'wonjin'
    sub_category TEXT,             -- 'full', 'half_strict', 'half_loose', 'samhyung', 'jahyung'

    -- 글자 (한글)
    char1 TEXT NOT NULL,           -- '갑', '자', '인'
    char2 TEXT NOT NULL,           -- '기', '축', '오'
    char3 TEXT,                    -- '술' (삼합/방합용, NULL 가능)

    -- 글자 (한자)
    char1_hanja TEXT NOT NULL,     -- '甲', '子', '寅'
    char2_hanja TEXT NOT NULL,     -- '己', '丑', '午'
    char3_hanja TEXT,              -- '戌'

    -- 결과 오행
    result_oheng TEXT,             -- '토', '목', '화' (충/형/해/파는 NULL)
    result_oheng_hanja TEXT,       -- '土', '木', '火'

    -- 명칭
    name_korean TEXT NOT NULL,     -- '갑기합토', '자축합토'
    name_hanja TEXT NOT NULL,      -- '甲己合土', '子丑合土'

    -- 속성
    is_positive BOOLEAN NOT NULL,  -- true=합, false=충/형/해/파
    strength INT,                  -- 1-5 (방합:5, 삼합:4, 반합:3, 육합:2)
    description TEXT,              -- '중정지합(中正之合)'

    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(category, sub_category, char1, char2, char3)
);

-- 인덱스
CREATE INDEX idx_saju_rules_category ON saju_relation_rules(category);
CREATE INDEX idx_saju_rules_chars ON saju_relation_rules(char1, char2);
```

---

## 5. 시나리오별 데이터 흐름

| 시나리오 | chat_session_targets | multi_compatibility_analyses |
|----------|---------------------|------------------------------|
| **A: 나↔엄마** | `[{엄마}]` | `participant_ids:[나,엄마], includes_owner:true` |
| **B: 나↔철수↔영희** | `[{철수}, {영희}]` | `participant_ids:[나,철수,영희], includes_owner:true` |
| **C: 엄마↔아빠** (나 제외) | `[{엄마}, {아빠}]` | `participant_ids:[엄마,아빠], includes_owner:false` |
| **D: 부모↔동생** (나 제외) | `[{엄마}, {아빠}, {동생}]` | `participant_ids:[엄마,아빠,동생], includes_owner:false` |

---

## 6. 전체 ERD (제안)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              제안 DB 구조 v2.0                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   saju_profiles ◄──────────────────────────────────────────────┐            │
│       │                                                         │            │
│       │ 1:1                                                     │            │
│       ▼                                                         │            │
│   saju_analyses                                                 │            │
│       │                                                         │            │
│   ════════════════════════════════════════════════════════════  │            │
│   │  saju_relation_rules (마스터 - 약 60개 고정 규칙)          │  │            │
│   │      천간합(5) + 육합(6) + 삼합(4) + 방합(4) +             │  │            │
│   │      충(6) + 형(4) + 해(6) + 파(6) + 원진(6) = ~47개      │  │            │
│   │      + 반합(strict/loose) 추가 시 ~60개                   │  │            │
│   ════════════════════════════════════════════════════════════  │            │
│                              │                                  │            │
│                              │ 참조 (Dart 계산 시)               │            │
│                              ▼                                  │            │
│   ┌─────────────────────────────────────────────────────────┐  │            │
│   │         multi_compatibility_analyses (NEW)              │  │            │
│   │─────────────────────────────────────────────────────────│  │            │
│   │ participant_ids[] - 참여자 UUID 배열                     │  │            │
│   │ includes_owner - 나 포함 여부                            │  │            │
│   │ owner_profile_id - 나의 프로필                           │  │            │
│   │ analysis_result (JSONB) - 쌍별 궁합 결과                 │◄─┘            │
│   └───────────────────────────┬─────────────────────────────┘               │
│                               │                                              │
│                               │ session_id FK                                │
│                               ▼                                              │
│   ┌─────────────────────────────────────────────────────────┐               │
│   │                chat_sessions (기존 유지)                 │               │
│   │─────────────────────────────────────────────────────────│               │
│   │ profile_id - 세션 소유자 (나)                            │               │
│   │ target_profile_id - 1:1 궁합용 (하위 호환)               │               │
│   └───────────────────────────┬─────────────────────────────┘               │
│                               │                                              │
│                               │ 1:N                                          │
│                               ▼                                              │
│   ┌─────────────────────────────────────────────────────────┐               │
│   │           chat_session_targets (NEW)                    │               │
│   │─────────────────────────────────────────────────────────│               │
│   │ session_id FK - 세션                                     │               │
│   │ target_profile_id FK - 대상 프로필                       │               │
│   │ mention_order - @멘션 순서                               │               │
│   └─────────────────────────────────────────────────────────┘               │
│                                                                              │
│   ════════════════════════════════════════════════════════════              │
│   │  기존 테이블 (읽기 전용 유지)                             │              │
│   │  - compatibility_analyses (1:1 궁합, 7건)                │              │
│   │  - profile_relations (인연 관계)                         │              │
│   ════════════════════════════════════════════════════════════              │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 7. 구현 우선순위

### Phase 1: 다중 멘션 지원 (채팅)
1. `chat_session_targets` 테이블 생성
2. Flutter `createSession()` 파라미터 변경 (`targetProfileIds: List<String>`)
3. 멘션 파싱 로직 수정 (여러 `@카테고리/이름` 추출)

### Phase 2: 다중 궁합 분석
1. `multi_compatibility_analyses` 테이블 생성
2. N명 → C(N,2) 쌍 분해 로직
3. `includes_owner` 플래그로 "나 제외" 케이스 처리
4. 각 쌍별 Dart 궁합 계산 → JSONB 저장

### Phase 3: 합충형해파 마스터 (선택적)
1. `saju_relation_rules` 마스터 테이블 생성
2. 약 60개 규칙 데이터 INSERT
3. Dart 코드에서 DB 규칙 참조하도록 변경 (선택적 최적화)
   - 현재 하드코딩도 잘 동작하므로 급하지 않음

---

## 8. 스케일링 전략

### 예상 성장

| 단계 | 사용자 | 인연/유저 | Profiles | Relations | 다중 궁합 |
|------|--------|----------|----------|-----------|----------|
| MVP | 1K | 5 | 6K | 5K | 1K |
| Growth | 100K | 10 | 1.1M | 1M | 50K |
| Scale | 1M | 15 | 16M | 15M | 500K |

### Phase별 최적화

```
Phase 1 (MVP ~ 10만 유저)
├── chat_session_targets: Junction 테이블
├── multi_compatibility_analyses: JSONB 결과
└── saju_relation_rules: 정규화 마스터

Phase 2 (10만 ~ 100만)
├── 읽기 복제본 (Supabase Read Replica)
├── participant_ids에 GIN 인덱스 강화
└── 자주 조회되는 조합 Redis 캐싱

Phase 3 (100만+)
├── user_id 기준 파티셔닝
├── 오래된 분석 결과 아카이브
└── CDN 활용 (정적 규칙 데이터)
```

---

## 9. 체크리스트

### 9.1 DB 마이그레이션
- [ ] `chat_session_targets` 테이블 생성
- [ ] `multi_compatibility_analyses` 테이블 생성
- [ ] `saju_relation_rules` 마스터 테이블 생성 (선택적)
- [ ] 마스터 데이터 INSERT (약 60개 규칙)
- [ ] RLS 정책 설정

### 9.2 Flutter 코드
- [ ] `createSession()` 파라미터 변경 (`targetProfileIds: List<String>`)
- [ ] 멘션 파싱 다중화 (여러 @mentions 추출)
- [ ] `ChatSession` 모델 수정 (targetProfileIds 배열)
- [ ] 다중 궁합 분석 로직 추가 (C(N,2) 쌍 계산)
- [ ] `includes_owner` 플래그 처리 (나 제외 케이스)

### 9.3 AI 프롬프트
- [ ] 다중 인연 궁합 프롬프트 템플릿
- [ ] 그룹 케미 분석 프롬프트
- [ ] "나 제외" 케이스 프롬프트

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| v1.0 | 2026-01-15 | 초안 작성 - 현재 구조 분석, 다중 궁합/합충형해파 설계안 |
| v2.0 | 2026-01-15 | "나 제외" 시나리오 추가, includes_owner 플래그, 설계 결정사항 정리, 스케일링 전략 |
