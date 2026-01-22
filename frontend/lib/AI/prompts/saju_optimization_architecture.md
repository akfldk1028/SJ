# 평생운세 속도 최적화 아키텍처

> 작성일: 2026-01-21
> 최종 수정: 2026-01-21
> 목적: 7분 → 즉시~2.5분 단축 (캐시 + 토큰 축소 + Phase 분할)

---

## 구현 현황 (2026-01-21)

| 항목 | 상태 | 비고 |
|------|------|------|
| **토큰 축소** | ✅ **완료** | saju_base_prompt.dart 수정 (62% 감소) |
| **L1 캐시** | ✅ **완료** | saju_analysis_service.dart:431-438 |
| **L2 캐시** | ✅ **완료** | queries.dart + saju_analysis_service.dart:441-480 |
| **Phase 분할** | ✅ **완료** | DB 마이그레이션 + 4개 Phase 프롬프트 + 서비스 로직 |
| **Progressive Disclosure UI** | ✅ **완료** | PhaseProgressData + 폴링 + 부분 결과 즉시 표시 |

### 현재 예상 성능
- **L1 캐시 히트**: 즉시 (<1초) - 동일 profile 재요청 시
- **L2 캐시 히트**: 즉시 (<1초) - 동일 사주팔자 (다른 프로필)
- **캐시 미스**: ~3분 (토큰 62% 감소 반영)

---

## 기존 문제

- 단일 API 호출로 17개 섹션 전체 생성 → **~7분 소요**
- Supabase Edge Function 타임아웃 위험
- 사용자 체감 대기 시간이 너무 김
- 앱 런칭 시 치명적인 UX 문제

---

## 목표

| 시나리오 | 현재 | 목표 |
|----------|------|------|
| **L1 캐시 히트** (동일 사주) | 7분 | **즉시 (<1초)** |
| **L2 캐시 히트** (기반 데이터) | 7분 | **2분 (첫 30초)** |
| **캐시 미스** (새 사주) | 7분 | **2.5분 (첫 60초)** |

---

## 기존 테이블 활용 (새 테이블 불필요!)

### ai_summaries 테이블 - L1 캐시로 활용

```sql
-- 이미 존재하는 필드들:
- id, user_id, profile_id
- summary_type = 'saju_base'     -- 평생운세 타입
- content (JSONB)                -- AI 분석 결과 전체
- is_cached (boolean)            -- 캐시 여부
- expires_at (timestamptz)       -- 캐시 만료 시간
- status                         -- 'cached' 상태 사용 가능
```

**L1 캐시 로직:**
```
1. profile_id로 ai_summaries 조회
2. summary_type = 'saju_base' AND status = 'completed'
3. 존재하면 → content 즉시 반환 (0초)
4. 없으면 → GPT 호출
```

### saju_analyses 테이블 - L2 캐시로 활용

```sql
-- 이미 존재하는 필드들:
- year_gan, year_ji, month_gan, month_ji, day_gan, day_ji, hour_gan, hour_ji
- oheng_distribution (JSONB)     -- 오행 분포
- sipsin_info (JSONB)            -- 십성 정보
- hapchung (JSONB)               -- 합충 분석
- yongsin (JSONB)                -- 용신 정보
- daeun (JSONB)                  -- 대운 정보
```

**L2 캐시 로직:**
```
1. 사주팔자 키 생성: "甲子-乙丑-丙寅-丁卯"
2. saju_analyses에서 동일 사주 검색
3. 존재하면 → 기반 데이터 재사용, 해석만 생성
4. 없으면 → 전체 생성
```

---

## 3단계 캐시 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                       요청 들어옴                            │
│                    (profile_id 기반)                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  L1 캐시 체크: ai_summaries                                 │
│  ─────────────────────────────────────────────────────────  │
│  SELECT content FROM ai_summaries                           │
│  WHERE profile_id = ? AND summary_type = 'saju_base'        │
│        AND status = 'completed'                             │
│  ─────────────────────────────────────────────────────────  │
│  히트 → 즉시 반환! (0초)                                    │
│  미스 → L2 체크                                             │
└─────────────────────────────────────────────────────────────┘
                              │ 미스
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  L2 캐시 체크: saju_analyses (동일 사주팔자)                │
│  ─────────────────────────────────────────────────────────  │
│  SELECT * FROM saju_analyses                                │
│  WHERE year_gan = ? AND year_ji = ?                         │
│    AND month_gan = ? AND month_ji = ?                       │
│    AND day_gan = ? AND day_ji = ?                           │
│    AND (hour_gan = ? OR hour_gan IS NULL)                   │
│  ─────────────────────────────────────────────────────────  │
│  히트 → 기반 데이터 재사용, Phase 1 일부 스킵 (30초 단축)   │
│  미스 → 전체 생성                                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  L3: GPT 호출 (토큰 축소 + Phase 분할)                      │
│  ─────────────────────────────────────────────────────────  │
│  Phase 1 (60초) → 원국, 십성, 성격 → UI 표시                │
│  Phase 2+3 병렬 (60초) → 운세, 건강 → UI 추가               │
│  Phase 4 (45초) → 종합 → UI 완료                            │
│  ─────────────────────────────────────────────────────────  │
│  완료 후 → ai_summaries에 저장 (다음 요청 시 L1 히트)       │
└─────────────────────────────────────────────────────────────┘
```

---

## 토큰 축소 전략 (7분 → 3분)

### 변경되는 것 vs 유지되는 것

```
┌─────────────────────────────────────────────────────────────┐
│ 유지 (Output 팀원 영향 없음)                                 │
├─────────────────────────────────────────────────────────────┤
│ • JSON 키 이름: summary, personality, wealth...             │
│ • 중첩 구조: personality.reading, wealth.advice...          │
│ • 데이터 타입: string, array, object 등                     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ 변경 (프롬프트 내부만)                                       │
├─────────────────────────────────────────────────────────────┤
│ • "최소 15~20문장" → "핵심을 명확히 5-8문장"                │
│ • "30문장 요약" → "핵심 10문장 요약"                        │
│ • daeun_detail.cycles: 8개 × 10문장 → 3개 × 5문장          │
└─────────────────────────────────────────────────────────────┘
```

### 토큰 감소 효과

| 항목 | 현재 | 변경 후 | 감소 |
|------|------|---------|------|
| 섹션당 문장 | 15-20 | 5-8 | -60% |
| 대운 상세 | 80문장 | 15문장 | -81% |
| summary | 30문장 | 10문장 | -67% |
| **총 출력 토큰** | ~8,000 | ~3,000 | **-62%** |
| **예상 시간** | 7분 | 3분 | **-57%** |

---

## Phase 분할 전략 (Progressive Disclosure)

### Phase 구성

| Phase | 섹션 | 모델 | 시간 | 의존성 |
|-------|------|------|------|--------|
| **1** | 원국, 십성, 합충, 성격, 행운 | GPT-5.2 | 60초 | 없음 |
| **2** | 재물, 직업, 사업, 애정, 결혼 | GPT-5.2 | 45초 | Phase 1 |
| **3** | 신살, 건강, 대운상세 | GPT-5.2 | 45초 | Phase 1 |
| **4** | 인생주기, 전성기, 현대해석 | GPT-5.2 | 45초 | 1-3 |

**Phase 2 + 3 병렬 실행 가능!**

### 스키마 유지 방법

```
Phase 1 → { original_chart, ten_stars, hapchung, personality, lucky_elements }
Phase 2 → { wealth, career, business, love, marriage }
Phase 3 → { health, sinsal_gilseong, daeun_detail }
Phase 4 → { summary, life_cycles, peak_years, modern_interpretation }

────────────────────────────────────────────────────────────────
                      병합 (merge)
────────────────────────────────────────────────────────────────
                           ↓
                기존과 100% 동일한 JSON 구조!
```

---

## DB 스키마 변경 (ai_tasks 테이블)

### Phase 지원을 위한 컬럼 추가

```sql
-- ai_tasks 테이블에 컬럼 추가
ALTER TABLE ai_tasks ADD COLUMN IF NOT EXISTS phase INTEGER DEFAULT 1;
ALTER TABLE ai_tasks ADD COLUMN IF NOT EXISTS total_phases INTEGER DEFAULT 4;
ALTER TABLE ai_tasks ADD COLUMN IF NOT EXISTS partial_result JSONB DEFAULT '{}';

-- 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_ai_tasks_phase ON ai_tasks(id, phase);
```

### 상태 흐름

```
Phase 1 시작: status='processing', phase=1
Phase 1 완료: partial_result에 Phase 1 결과 저장, phase=2
Phase 2 시작: status='processing' 유지
Phase 2 완료: partial_result에 Phase 2 결과 병합, phase=3
...
Phase 4 완료: status='completed', ai_summaries에 전체 결과 저장
```

---

## L1 캐시 히트율 분석

### 사주 조합 수 계산

```
생년: 60갑자 주기 → 60개
생월: 12개
생일: 30개 (평균)
생시: 12개 (시진)
성별: 2개 (남/여)

총 조합: 60 × 12 × 30 × 12 × 2 = 518,400개
```

### 예상 히트율

```
한국 인구: ~5,000만명
동일 사주 확률: 5,000만 / 518,400 ≈ 96명/조합

앱 사용자 시나리오:
- 1만명 → 각 조합 평균 19회 히트
- 10만명 → 각 조합 평균 193회 히트

결론: 운영 몇 달 후 → 대부분 L1 캐시 히트 (즉시 반환)
```

---

## 구현 우선순위

```
1️⃣ ✅ [완료] 토큰 축소
   - saju_base_prompt.dart 문장 수 요구사항 수정
   - 효과: 7분 → 3분
   - 구현 위치: saju_base_prompt.dart, saju_base_prompt.md

2️⃣ ✅ [이미 구현됨] L1 캐시 로직
   - ai_summaries 조회 로직 이미 존재
   - 구현 위치: saju_analysis_service.dart:431-438
   - 쿼리: queries.dart → getSajuBaseSummary()
   - 효과: 재요청 즉시 반환

3️⃣ ❌ [미구현] Phase 분할
   - ai_tasks 테이블 컬럼 추가 필요
   - Edge Function 4개 분리 또는 단일 함수 내 Phase 처리
   - 효과: 첫 표시 60초
   - 상태: 복잡도 높음, 토큰 축소 효과 검증 후 결정

4️⃣ ✅ [완료] L2 캐시 (동일 사주팔자)
   - ai_summaries JSONB 기반 검색 로직
   - 구현 위치: queries.dart → getSajuBaseBySajuKey()
   - 구현 위치: saju_analysis_service.dart:441-480
   - 효과: 동일 사주팔자 결과 재사용 (GPT 비용 0)
```

---

## 최종 응답 시간 예측

| 시나리오 | 총 시간 | 첫 콘텐츠 표시 |
|----------|---------|----------------|
| L1 히트 (동일 profile) | **즉시** | 즉시 |
| L2 히트 (동일 사주팔자) | 2분 | 30초 |
| 캐시 미스 (완전 새 사주) | 2.5분 | 60초 |

**vs 현재: 모든 경우 7분, 7분 후 표시**

---

## 관련 파일

| 파일 | 용도 | 상태 |
|------|------|------|
| `saju_base_prompt.dart` | 단일 프롬프트 (기존) | ✅ 토큰 축소 완료 |
| `saju_base_phase1_prompt.dart` | Phase 1: Foundation | ✅ 구현 완료 |
| `saju_base_phase2_prompt.dart` | Phase 2: Fortune | ✅ 구현 완료 |
| `saju_base_phase3_prompt.dart` | Phase 3: Special | ✅ 구현 완료 |
| `saju_base_phase4_prompt.dart` | Phase 4: Synthesis | ✅ 구현 완료 |
| `saju_analysis_service.dart` | 분석 서비스 | ✅ L1/L2 캐시 + Phase 분할 |
| `queries.dart` | DB 쿼리 | ✅ L1/L2 캐시 쿼리 구현 |
| `ai_api_service.dart` | API 호출 | ✅ 메시지 전달 확인됨 |
| `ai_tasks` 테이블 | 작업 관리 | ✅ phase/partial_result 컬럼 추가됨 |
| `ai_summaries` 테이블 | 결과 저장 | ✅ L1 캐시로 활용 중 |

---

## 참고: saju_chunked_architecture.md

Phase 분할 상세 설계는 `saju_chunked_architecture.md` 참조
