# 사주 관계도 DB 설계 명세

> 작성일: 2026-01-08
> 버전: v1.2
> 상태: Phase 43 Flutter 코드 구현 완료

---

## 1. 개요

### 1.1 목적
- "나"를 기준으로 가족/친구/연인 등 관계된 사람들의 사주 정보 관리
- AI 채팅에서 "엄마랑 궁합 어때?" 같은 자연어 질문 처리
- 궁합 분석 결과 캐싱으로 반복 계산 방지

### 1.2 핵심 요구사항
- 대규모 사용자 지원 (100만+ 유저, 1600만+ 프로필)
- 관계의 방향성 표현 ("A가 B의 엄마" vs "B가 A의 엄마")
- 세부 관계 유형 지원 (19종: family_parent, romantic_partner 등)
- RLS(Row Level Security)로 데이터 격리

---

## 2. 현재 상황 분석

### 2.1 기존 테이블 현황
| 테이블 | Row 수 | 상태 |
|--------|--------|------|
| saju_profiles | 149 | 사용 중 |
| saju_analyses | 136 | 사용 중 |
| profile_relations | 0 | **미사용** |
| compatibility_analyses | 0 | **미사용** |

### 2.2 기존 문제점
1. **profile_relations 미사용**: 관계를 saju_profiles.relation_type으로 flat하게 표현
2. **역할 혼재**: "나"와 "관계인"이 같은 테이블에 구분 없이 저장
3. **관계 방향성 없음**: "누가 누구의 무슨 관계인지" 표현 불가
4. **세부 관계 미지원**: 'family'만 있고 'family_parent', 'family_spouse' 구분 없음

---

## 3. 권장 DB 구조

### 3.1 ERD

```
┌──────────────────────────────────────────────────────────────────────┐
│                          만톡 관계 DB 구조                             │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│   auth.users                                                         │
│       │                                                              │
│       │ 1:N (소유자)                                                  │
│       ▼                                                              │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │ saju_profiles                                                │   │
│   │ ─────────────                                                │   │
│   │ • id (PK, UUID)                                              │   │
│   │ • user_id (FK → auth.users)                                  │   │
│   │ • profile_type: 'primary' | 'other'  ← NEW                   │   │
│   │ • display_name, birth_date, gender...                        │   │
│   │ • relation_type (DEPRECATED)                                 │   │
│   └───────────┬────────────────────────────────┬─────────────────┘   │
│               │                                │                      │
│               │ 1:1                            │ N:M                  │
│               ▼                                ▼                      │
│   ┌─────────────────────┐          ┌─────────────────────────────┐  │
│   │ saju_analyses       │          │ profile_relations           │  │
│   │ ───────────────     │          │ ─────────────────           │  │
│   │ • profile_id (UK)   │          │ • from_profile_id (나)      │  │
│   │ • 사주 4주, 오행,    │          │ • to_profile_id (상대방)    │  │
│   │   용신, 신살, 합충... │          │ • relation_type (19종)     │  │
│   └─────────────────────┘          │ • display_name, memo        │  │
│                                    │ • is_favorite, sort_order   │  │
│                                    │ • from/to_analysis_id       │  │
│                                    └──────────────┬──────────────┘  │
│                                                   │                  │
│                                                   │ 1:1 (캐시)       │
│                                                   ▼                  │
│                                    ┌─────────────────────────────┐  │
│                                    │ compatibility_analyses      │  │
│                                    │ ─────────────────────────── │  │
│                                    │ • profile1_id + profile2_id │  │
│                                    │ • analysis_type (궁합 유형)  │  │
│                                    │ • overall_score (0-100)     │  │
│                                    │ • saju_analysis (JSONB)     │  │
│                                    │ • strengths[], challenges[] │  │
│                                    └─────────────────────────────┘  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### 3.2 테이블 역할 정의

| 테이블 | 역할 | 비고 |
|--------|------|------|
| saju_profiles | 프로필 데이터 저장소 | profile_type으로 primary/other 구분 |
| saju_analyses | 사주 분석 결과 (1:1) | 만세력 계산 결과 |
| profile_relations | 관계 그래프 | from→to 방향성, 19종 관계 유형 |
| compatibility_analyses | 궁합 분석 캐시 | AI 분석 결과 저장 |

### 3.3 관계 유형 (19종)

```sql
-- profile_relations.relation_type CHECK constraint
relation_type IN (
  -- 가족
  'family_parent',      -- 부모
  'family_child',       -- 자녀
  'family_sibling',     -- 형제자매
  'family_spouse',      -- 배우자
  'family_grandparent', -- 조부모
  'family_in_law',      -- 시댁/처가
  'family_other',       -- 기타 가족

  -- 연인
  'romantic_partner',   -- 현재 연인
  'romantic_crush',     -- 짝사랑
  'romantic_ex',        -- 전 연인

  -- 친구
  'friend_close',       -- 친한 친구
  'friend_general',     -- 일반 친구

  -- 직장
  'work_colleague',     -- 동료
  'work_boss',          -- 상사
  'work_subordinate',   -- 부하
  'work_client',        -- 고객/클라이언트

  -- 기타
  'business_partner',   -- 사업 파트너
  'mentor',             -- 멘토
  'other'               -- 기타
)
```

---

## 4. 마이그레이션 계획

### 4.1 Phase 1: 컬럼 추가 (비파괴적)

```sql
-- 1. profile_type 컬럼 추가
ALTER TABLE saju_profiles
ADD COLUMN IF NOT EXISTS profile_type TEXT DEFAULT 'other'
CHECK (profile_type IN ('primary', 'other'));

-- 2. 기존 데이터 마이그레이션
UPDATE saju_profiles
SET profile_type = CASE
  WHEN relation_type = 'me' THEN 'primary'
  ELSE 'other'
END
WHERE profile_type IS NULL OR profile_type = 'other';

-- 3. 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_saju_profiles_user_type
ON saju_profiles (user_id, profile_type);
```

### 4.2 Phase 2: profile_relations 활성화

```sql
-- 기존 관계 데이터를 profile_relations로 마이그레이션
INSERT INTO profile_relations (
  user_id, from_profile_id, to_profile_id,
  relation_type, display_name
)
SELECT
  p_other.user_id,
  p_me.id as from_profile_id,
  p_other.id as to_profile_id,
  CASE p_other.relation_type
    WHEN 'family' THEN 'family_other'
    WHEN 'friend' THEN 'friend_general'
    WHEN 'lover' THEN 'romantic_partner'
    WHEN 'work' THEN 'work_colleague'
    ELSE 'other'
  END as relation_type,
  p_other.display_name
FROM saju_profiles p_other
JOIN saju_profiles p_me
  ON p_me.user_id = p_other.user_id
  AND p_me.relation_type = 'me'
WHERE p_other.relation_type != 'me'
  AND p_other.relation_type != 'admin'
ON CONFLICT (from_profile_id, to_profile_id) DO NOTHING;
```

### 4.3 Phase 3: 추가 인덱스 (성능 최적화)

```sql
-- 복합 인덱스: 특정 유저의 모든 관계 빠른 조회
CREATE INDEX IF NOT EXISTS idx_profile_relations_user_from
ON profile_relations (user_id, from_profile_id);

-- 궁합 조회 최적화 (양방향)
CREATE INDEX IF NOT EXISTS idx_compatibility_pair
ON compatibility_analyses (
  LEAST(profile1_id, profile2_id),
  GREATEST(profile1_id, profile2_id)
);
```

---

## 5. Flutter 연동 설계

### 5.1 AI 채팅 → 궁합 질문 플로우

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter App                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  [관계도 화면]                                                    │
│       │                                                          │
│       │ "엄마" 프로필 탭 → "사주 상담" 버튼                        │
│       ▼                                                          │
│  [라우팅]                                                         │
│  /saju/chat/compatibility                                        │
│  ?from={나의 profile_id}                                         │
│  &to={엄마 profile_id}                                           │
│  &type=family_parent                                             │
│       │                                                          │
│       ▼                                                          │
│  [채팅 화면]                                                      │
│  CompatibilityContext 로드:                                      │
│  - 나의 saju_analyses                                            │
│  - 엄마의 saju_analyses                                          │
│  - relation_type → 적절한 프롬프트 선택                           │
│       │                                                          │
│       ▼                                                          │
│  [AI 응답]                                                        │
│  "두 분의 궁합을 분석해드릴게요..."                                │
│       │                                                          │
│       ▼                                                          │
│  [결과 캐시]                                                      │
│  compatibility_analyses에 저장                                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 관계 유형별 분석 초점

| relation_type | 분석 초점 | analysis_type |
|--------------|----------|---------------|
| family_parent | 부모-자녀 관계, 효도, 소통 | family |
| family_spouse | 결혼 궁합, 동반자 | love |
| romantic_partner | 연애 궁합, 미래 전망 | love |
| friend_close | 우정, 신뢰, 협력 | friendship |
| work_colleague | 협업, 갈등 해소 | business |
| business_partner | 사업 파트너 | business |

---

## 6. 스케일링 전략

### 6.1 예상 성장

| 단계 | 사용자 | 관계/유저 | Profiles | Relations |
|------|--------|----------|----------|-----------|
| MVP | 1K | 5 | 6K | 5K |
| Growth | 100K | 10 | 1.1M | 1M |
| Scale | 1M | 15 | 16M | 15M |

### 6.2 최적화 방안

1. **읽기 복제본**: Supabase Read Replica
2. **파티셔닝**: user_id 기준 (필요 시)
3. **캐싱**: compatibility_analyses 활용
4. **인덱스**: 복합 인덱스로 쿼리 최적화

---

## 7. 구현 체크리스트

### 7.1 DB 마이그레이션
- [x] profile_type 컬럼 추가 (2026-01-08 완료)
- [x] 기존 데이터 마이그레이션 (2026-01-08 완료)
- [x] profile_relations 활성화 (2026-01-08 완료)
- [x] 추가 인덱스 생성 (2026-01-08 완료)

### 7.2 Flutter 코드
- [x] SajuProfile/SajuProfileModel에 profileType 필드 추가 (2026-01-08 완료)
- [x] CompatibilityContext 모델 생성 (2026-01-09 완료)
  - 파일: `features/saju_chat/domain/models/compatibility_context.dart`
  - toPromptContext(): AI 프롬프트용 문자열 생성
  - 관계 유형별 분석 초점 (family, love, friendship, business)
- [x] CompatibilityAnalysisCache 모델 생성 (2026-01-09 완료)
- [x] 관계도 QuickView → 궁합 채팅 라우팅 (2026-01-09 완료)
  - routes.dart: `sajuChatCompatibility = '/saju/chat/compatibility'`
  - app_router.dart: 라우트 등록 (from, to, relationType 파라미터)
  - relationship_screen.dart: "사주 상담" 버튼 연결
- [x] SajuChatShell 파라미터 추가 (2026-01-09 완료)
  - fromProfileId, toProfileId, relationType
- [ ] 채팅 화면에서 두 사주 분석 로드
- [ ] 관계 유형별 프롬프트 분기
- [ ] compatibility_analyses 캐싱 로직

### 7.3 AI 프롬프트
- [x] 관계 유형별 분석 프롬프트 작성 (CompatibilityContext.toPromptContext())
- [ ] 궁합 결과 JSON 스키마 정의

---

## 8. 참고 자료

- [ByteByteGo: Normalization vs Denormalization](https://blog.bytebytego.com/p/database-schema-design-simplified)
- [Supabase: Table Partitioning](https://supabase.com/docs/guides/database/partitions)
- [AWS: Multi-tenant PostgreSQL](https://docs.aws.amazon.com/prescriptive-guidance/latest/saas-multitenant-managed-postgresql/partitioning-models.html)
- [Citus: SaaS Database Design](https://www.citusdata.com/blog/2023/08/04/understanding-partitioning-and-sharding-in-postgres-and-citus/)

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| v1.0 | 2026-01-08 | 초안 작성 |
| v1.1 | 2026-01-08 | Phase 1~3 마이그레이션 완료 (profile_type 컬럼, profile_relations 활성화, 인덱스, Flutter 코드) |
| v1.2 | 2026-01-09 | Phase 43 Flutter 코드 완료 (CompatibilityContext, 궁합 채팅 라우팅, QuickView 연결) |
