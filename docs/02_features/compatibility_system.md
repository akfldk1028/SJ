# 궁합 분석 시스템 설계

> 작성일: 2026-01-15
> 버전: v1.0
> 상태: 설계 검토 중

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

---

## 2. 현재 DB 구조 분석

### 2.1 테이블 관계도 (현재)

```
                    ┌─────────────────┐
                    │  saju_profiles  │
                    │─────────────────│
                    │ id (PK)         │
                    │ user_id         │
                    │ display_name    │
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

### 2.2 각 테이블 역할

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

#### `compatibility_analyses` - 궁합 분석
| 필드 | 설명 |
|------|------|
| profile1_id | 나 |
| profile2_id | **상대방 1명만** ← 문제! |
| saju_analysis | JSONB - 두 사람 간 합충 분석 결과 |
| target_hapchung | JSONB - 상대방 개인 합충 정보 |
| overall_score | 종합 점수 (0-100) |

---

## 3. 다중 궁합 지원 방안

### 3.1 옵션 A: 그룹 궁합 테이블 추가 (권장)

```
┌─────────────────────────────────────────────────────────────┐
│                    NEW: compatibility_groups                │
│─────────────────────────────────────────────────────────────│
│ id (PK)           - 그룹 ID                                 │
│ owner_profile_id  - 나 (분석 요청자)                         │
│ group_name        - "나+김동현+이유국" 자동 생성              │
│ analysis_type     - 'pair' / 'group'                        │
│ overall_summary   - AI 종합 분석                             │
│ created_at        - 생성일                                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ 1:N
                              ▼
┌─────────────────────────────────────────────────────────────┐
│               NEW: compatibility_group_members              │
│─────────────────────────────────────────────────────────────│
│ id (PK)                                                     │
│ group_id (FK)     - → compatibility_groups                  │
│ profile_id (FK)   - → saju_profiles (참여자)                │
│ role              - 'owner' / 'member'                      │
│ sort_order        - 표시 순서                                │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ 그룹 내 1:1 궁합 참조
                              ▼
┌─────────────────────────────────────────────────────────────┐
│          NEW: compatibility_group_pair_results              │
│─────────────────────────────────────────────────────────────│
│ id (PK)                                                     │
│ group_id (FK)     - → compatibility_groups                  │
│ pair_analysis_id  - → compatibility_analyses (기존 1:1)     │
│ profile_a_id      - 쌍 중 첫 번째                            │
│ profile_b_id      - 쌍 중 두 번째                            │
└─────────────────────────────────────────────────────────────┘
```

#### 장점
- 기존 `compatibility_analyses` 재사용 (1:1 분석 로직 그대로)
- N명 그룹 → N*(N-1)/2개 쌍으로 분해하여 각각 분석
- 예: 3명 → 3쌍 (나-김동현, 나-이유국, 김동현-이유국)

#### 예시 데이터

```sql
-- 1. 그룹 생성
INSERT INTO compatibility_groups (owner_profile_id, group_name, analysis_type)
VALUES ('나_profile_id', '나+김동현+이유국', 'group');

-- 2. 멤버 등록
INSERT INTO compatibility_group_members (group_id, profile_id, role)
VALUES
  (group_id, '나_profile_id', 'owner'),
  (group_id, '김동현_profile_id', 'member'),
  (group_id, '이유국_profile_id', 'member');

-- 3. 쌍별 분석 연결 (기존 compatibility_analyses 재사용)
INSERT INTO compatibility_group_pair_results (group_id, pair_analysis_id, profile_a_id, profile_b_id)
VALUES
  (group_id, '나-김동현_analysis_id', '나', '김동현'),
  (group_id, '나-이유국_analysis_id', '나', '이유국'),
  (group_id, '김동현-이유국_analysis_id', '김동현', '이유국');
```

### 3.2 옵션 B: chat_sessions 확장

```sql
-- chat_sessions에 다중 타겟 지원
ALTER TABLE chat_sessions
ADD COLUMN target_profile_ids UUID[] DEFAULT '{}';  -- 배열로 변경

-- 또는 별도 테이블
CREATE TABLE chat_session_targets (
  session_id UUID REFERENCES chat_sessions(id),
  profile_id UUID REFERENCES saju_profiles(id),
  PRIMARY KEY (session_id, profile_id)
);
```

### 3.3 권장 조합

| 목적 | 테이블 | 변경 |
|------|--------|------|
| **다중 궁합 분석 저장** | `compatibility_groups` + `_members` + `_pair_results` | 신규 생성 |
| **채팅 다중 멘션** | `chat_session_targets` | 신규 생성 |
| **기존 1:1 분석** | `compatibility_analyses` | 그대로 유지 |

---

## 4. 합충형해파 마스터 테이블

### 4.1 현재 문제

```json
// saju_analyses.hapchung - 현재 저장 형식
{
  "cheongan_haps": [
    {
      "gan1": "을",
      "gan2": "경",
      "pillar1": "일",
      "pillar2": "시",
      "description": "을경합화금(乙庚合化金) - 인의지합"
    }
  ]
}
```

**문제**: "을+경=금"이라는 **변환 규칙 자체**가 DB에 없음. Dart 코드에만 하드코딩.

### 4.2 제안: 마스터 테이블

```sql
CREATE TABLE saju_relation_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- 분류
  category TEXT NOT NULL,        -- 'cheongan_hap', 'jiji_yukhap', 'jiji_samhap', 'jiji_banghap',
                                 -- 'jiji_chung', 'jiji_hyung', 'jiji_hae', 'jiji_pa', 'wonjin'
  sub_category TEXT,             -- 'full', 'half_with_wangji', 'half_loose', 'samhyung', 'jahyung'

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
  strength INTEGER,              -- 1-5 (방합:5, 삼합:4, 반합:3, 육합:2)
  description TEXT,              -- '중정지합(中正之合)'

  -- 방합 전용
  season TEXT,                   -- '봄', '여름', '가을', '겨울'
  direction TEXT,                -- '동', '남', '서', '북'

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 예시 데이터 (약 60개)
INSERT INTO saju_relation_rules (category, char1, char2, char1_hanja, char2_hanja, result_oheng, result_oheng_hanja, name_korean, name_hanja, is_positive, strength, description) VALUES
-- 천간합 (5개)
('cheongan_hap', '갑', '기', '甲', '己', '토', '土', '갑기합토', '甲己合土', true, 4, '중정지합(中正之合)'),
('cheongan_hap', '을', '경', '乙', '庚', '금', '金', '을경합금', '乙庚合金', true, 4, '인의지합(仁義之合)'),
('cheongan_hap', '병', '신', '丙', '辛', '수', '水', '병신합수', '丙辛合水', true, 4, '위엄지합(威嚴之合)'),
('cheongan_hap', '정', '임', '丁', '壬', '목', '木', '정임합목', '丁壬合木', true, 4, '인수지합(仁壽之合)'),
('cheongan_hap', '무', '계', '戊', '癸', '화', '火', '무계합화', '戊癸合火', true, 4, '무정지합(無情之合)'),

-- 지지육합 (6개)
('jiji_yukhap', '자', '축', '子', '丑', '토', '土', '자축합토', '子丑合土', true, 2, NULL),
('jiji_yukhap', '인', '해', '寅', '亥', '목', '木', '인해합목', '寅亥合木', true, 2, NULL),
('jiji_yukhap', '묘', '술', '卯', '戌', '화', '火', '묘술합화', '卯戌合火', true, 2, NULL),
('jiji_yukhap', '진', '유', '辰', '酉', '금', '金', '진유합금', '辰酉合金', true, 2, NULL),
('jiji_yukhap', '사', '신', '巳', '申', '수', '水', '사신합수', '巳申合水', true, 2, NULL),
('jiji_yukhap', '오', '미', '午', '未', '화', '火', '오미합화', '午未合火', true, 2, NULL),

-- 지지삼합 (4개 - 완전 삼합)
('jiji_samhap', '인', '오', '寅', '午', '화', '火', '인오술합화', '寅午戌合火', true, 4, '화국'),
-- ... (술 추가 필요 - char3)

-- 지지충 (6개)
('jiji_chung', '자', '오', '子', '午', NULL, NULL, '자오충', '子午沖', false, 4, '수화상극'),
('jiji_chung', '축', '미', '丑', '未', NULL, NULL, '축미충', '丑未沖', false, 4, '토토충'),
-- ...
```

### 4.3 궁합 상세 관계 테이블

```sql
CREATE TABLE compatibility_relations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  compatibility_analysis_id UUID NOT NULL REFERENCES compatibility_analyses(id) ON DELETE CASCADE,
  rule_id UUID NOT NULL REFERENCES saju_relation_rules(id),

  -- 나의 위치
  my_pillar TEXT NOT NULL,       -- '년', '월', '일', '시'
  my_position TEXT NOT NULL,     -- '간', '지'
  my_char TEXT NOT NULL,         -- '갑', '자'

  -- 상대의 위치
  target_pillar TEXT NOT NULL,
  target_position TEXT NOT NULL,
  target_char TEXT NOT NULL,

  -- 삼합용 (세 번째 글자)
  third_char TEXT,
  third_pillar TEXT,
  third_source TEXT,             -- 'my', 'target', 'both'

  -- 점수 영향
  score_impact INTEGER,          -- +8, -5 등
  interpretation TEXT,           -- AI 해석

  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 5. 전체 ERD (제안)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              제안 DB 구조                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   saju_profiles ◄──────────────────────────────────────────────┐            │
│       │                                                         │            │
│       │ 1:1                                                     │            │
│       ▼                                                         │            │
│   saju_analyses                                                 │            │
│       │                                                         │            │
│       │                                                         │            │
│   ════════════════════════════════════════════════════════════  │            │
│   │  NEW: saju_relation_rules (마스터 - 약 60개 고정 규칙)    │  │            │
│   │      천간합(5) + 육합(6) + 삼합(4) + 방합(4) +            │  │            │
│   │      충(6) + 형(4) + 해(6) + 파(6) + 원진(6) = ~47개     │  │            │
│   │      + 반합/반방합 추가 시 ~60개                          │  │            │
│   ════════════════════════════════════════════════════════════  │            │
│                              │                                  │            │
│                              │ 참조                             │            │
│                              ▼                                  │            │
│   ┌─────────────────────────────────────────────────────────┐  │            │
│   │              compatibility_analyses (기존)               │  │            │
│   │              profile1_id, profile2_id (1:1)             │  │            │
│   └───────────────────────────┬─────────────────────────────┘  │            │
│                               │                                 │            │
│           ┌───────────────────┼───────────────────┐            │            │
│           │                   │                   │            │            │
│           ▼                   ▼                   ▼            │            │
│   ┌───────────────┐   ┌───────────────┐   ┌───────────────┐   │            │
│   │compatibility_ │   │compatibility_ │   │profile_       │   │            │
│   │relations (NEW)│   │groups (NEW)   │   │relations(기존)│   │            │
│   │───────────────│   │───────────────│   │───────────────│   │            │
│   │ rule_id (FK)  │   │ owner_id      │   │ from/to_id    │   │            │
│   │ my_pillar     │   │ group_name    │   │ relation_type │   │            │
│   │ target_pillar │   └───────┬───────┘   └───────────────┘   │            │
│   │ score_impact  │           │                                │            │
│   └───────────────┘           │ 1:N                            │            │
│                               ▼                                │            │
│                       ┌───────────────┐                        │            │
│                       │compatibility_ │                        │            │
│                       │group_members  │                        │            │
│                       │(NEW)          │◄───────────────────────┘            │
│                       │───────────────│                                      │
│                       │ profile_id(FK)│                                      │
│                       │ role          │                                      │
│                       └───────────────┘                                      │
│                                                                              │
│   ════════════════════════════════════════════════════════════              │
│   │  chat_sessions                                            │              │
│   │      │                                                    │              │
│   │      │ 1:N (NEW)                                          │              │
│   │      ▼                                                    │              │
│   │  chat_session_targets (NEW) ← 다중 멘션 지원              │              │
│   │      session_id, profile_id                               │              │
│   ════════════════════════════════════════════════════════════              │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. 구현 우선순위

### Phase 1: 다중 멘션 지원 (채팅)
1. `chat_session_targets` 테이블 생성
2. Dart `ChatSession` 모델에 `targetProfileIds` 추가
3. 멘션 파싱 로직 수정 (여러 `@카테고리/이름` 추출)

### Phase 2: 다중 궁합 분석
1. `compatibility_groups` + `_members` 테이블 생성
2. N명 → N*(N-1)/2 쌍 분해 로직
3. 각 쌍별 `compatibility_analyses` 생성/참조

### Phase 3: 합충형해파 마스터
1. `saju_relation_rules` 마스터 테이블 생성
2. 약 60개 규칙 데이터 INSERT
3. `compatibility_relations` 테이블 생성
4. Dart 분석 로직에서 마스터 참조하도록 수정

---

## 7. 체크리스트

### 7.1 DB 마이그레이션
- [ ] `chat_session_targets` 테이블 생성
- [ ] `compatibility_groups` 테이블 생성
- [ ] `compatibility_group_members` 테이블 생성
- [ ] `saju_relation_rules` 마스터 테이블 생성
- [ ] `compatibility_relations` 상세 테이블 생성
- [ ] 마스터 데이터 INSERT (약 60개 규칙)

### 7.2 Flutter 코드
- [ ] 멘션 파싱 다중화 (여러 @mentions 추출)
- [ ] `ChatSession` 모델 수정 (targetProfileIds 배열)
- [ ] 그룹 궁합 분석 로직 추가
- [ ] 합충형해파 계산 시 마스터 테이블 참조

### 7.3 AI 프롬프트
- [ ] 다중 인연 궁합 프롬프트 템플릿
- [ ] 그룹 케미 분석 프롬프트

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| v1.0 | 2026-01-15 | 초안 작성 - 현재 구조 분석, 다중 궁합/합충형해파 설계안 |
