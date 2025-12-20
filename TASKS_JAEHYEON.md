# 만톡 - Jaehyeon 작업 목록

> 개인 작업 노트 (협업자와 충돌 방지용)
> 작업 브랜치: Jaehyeon(Test)
> 우선순위: **만세력 로직 구현 완성**

---

## 현재 집중 과제

| 항목 | 상태 | 우선순위 |
|------|------|----------|
| **만세력 로직 검증 및 완성** | ✅ 완료 | **P0** |
| 음양력 변환 실제 구현 | ✅ **완료** (1900-2100년) | 완료 |
| 절기 테이블 확장 | ✅ **완료** (1900-2100년) | 완료 |
| 대운(大運) 계산 | ✅ **구현됨** | 완료 |
| 채팅 히스토리 사이드바 | ✅ 구현됨 | 완료 |
| **포스텔러 스타일 UI** | ✅ 구현됨 | 완료 |

---

## Phase 8: 만세력 (Saju Chart) - 핵심 작업

### 현재 완료된 파일 (19개)

#### Constants
- [x] `data/constants/cheongan_jiji.dart` - 천간(10), 지지(12), 오행
- [x] `data/constants/gapja_60.dart` - 60갑자
- [x] `data/constants/solar_term_table.dart` - 절기 시각 **(2020-2030년 확장 완료)**
- [x] `data/constants/dst_periods.dart` - 서머타임 기간

#### Domain Entities
- [x] `domain/entities/pillar.dart` - 기둥 (천간+지지)
- [x] `domain/entities/saju_chart.dart` - 사주 차트
- [x] `domain/entities/lunar_date.dart` - 음력 날짜
- [x] `domain/entities/solar_term.dart` - 24절기 enum

#### Domain Services (핵심)
- [x] `domain/services/saju_calculation_service.dart` - 통합 계산 (메인)
- [x] `domain/services/lunar_solar_converter.dart` - 음양력 변환 **(✅ 1900-2100년 테이블 기반 완전 구현)**
- [x] `domain/services/solar_term_service.dart` - 절입시간
- [x] `domain/services/true_solar_time_service.dart` - 진태양시 (25개 도시)
- [x] `domain/services/dst_service.dart` - 서머타임
- [x] `domain/services/jasi_service.dart` - 야자시/조자시

#### Data Models
- [x] `data/models/pillar_model.dart` - JSON 직렬화
- [x] `data/models/saju_chart_model.dart` - JSON 직렬화

---

## 만세력 TODO (우선순위 순)

### 1. 음양력 변환 실제 구현 ✅ 완료 (2025-12-16)
> ~~현재 `lunar_solar_converter.dart`가 Stub 상태~~

**구현 완료:**
- [x] 오프라인 음양력 테이블 구현 (1900-2100년)
- [x] `lunar_data/` 폴더에 4개 테이블 파일
- [x] `solarToLunar()`, `lunarToSolar()` 양방향 변환
- [x] 윤달 처리 완료
- [x] 14개 테스트 케이스 통과

### 2. 절기 테이블 확장 ✅ 완료 (2025-12-16)
> ~~현재 2024-2025년만 포함~~

**구현 완료 (1900-2100년, 201년치):**
- [x] 2020-2030년: 한국천문연구원 공식 데이터
- [x] 1900-2019년, 2031-2100년: 천문학적 계산값 (Jean Meeus 알고리즘)
  - `solar_term_calculator.dart` - 24절기 천문학적 계산기
  - `solar_term_table_extended.dart` - 확장 테이블 + API
- [x] 동적 계산 + 캐싱 방식으로 메모리 효율성 확보
- [x] 하위 호환성 유지 (기존 `solarTermTable` deprecated)
- [x] 오차 범위: 대부분 ±60분 이내 (사주 계산에 충분)
- [x] 테스트 케이스 11개 통과

### 3. 대운(大運) 계산 ✅ 구현됨
- [x] `domain/entities/daeun.dart` 생성
- [x] `domain/services/daeun_service.dart` 구현
- [x] 대운 시작 나이 계산
- [x] 10년 단위 대운 배열
- [x] 순행/역행 판단 (남자양년생/여자음년생)

### 4. 검증 및 테스트 ✅ 완료 (2025-12-16)
- [x] 포스텔러 만세력 2.2와 비교 검증 (1990-02-15, 1997-11-29)
- [x] 사주 계산 테스트 통과 (`saju_logic_test.dart`)
- [x] 음양력 변환 테스트 통과 (`lunar_solar_test.dart`)
  - 양력→음력 변환
  - 음력→양력 변환
  - 왕복 변환
  - 윤달 테스트
  - 지원 범위 테스트

---

## 만세력 정확도 핵심 요소

### 1. 진태양시 보정 ✅ 구현됨
```
한국 표준시: 동경 135도 기준
실제 한반도: 약 127도 → ~32분 차이

예시:
- 창원: -26분
- 서울: -30분
- 부산: -25분
```

### 2. 절입시간 ✅ 구현됨 (2024-2025)
```
월주 변경 시점 = 절기 시작 시간
예: 입춘(2024) = 2024-02-04 16:27 → 이때부터 인월(寅月)
```

### 3. 서머타임 ✅ 구현됨
```
적용 기간:
- 1948-1951
- 1955-1960
- 1987-1988
해당 기간 출생자 +1시간 보정
```

### 4. 야자시/조자시 ✅ 구현됨
```
자시(子時): 23:00-01:00
- 야자시: 23:00-24:00 당일로 계산
- 조자시: 00:00-01:00 익일로 계산
```

---

## 채팅 기능 현황

### Saju Chat (Phase 5) ✅ 대부분 완료
- [x] Gemini 3.0 REST API 연동
- [x] SSE 스트리밍 응답
- [x] 메시지 버블 UI
- [x] 타이핑 인디케이터
- [x] 면책 배너

### 채팅 히스토리 사이드바 ✅ 신규 구현
- [x] `chat_history_sidebar.dart`
- [x] `session_list_tile.dart`
- [x] `session_group_header.dart`
- [x] `sidebar_header.dart`
- [x] `sidebar_footer.dart`
- [x] `chat_session_provider.dart`
- [x] `chat_session_model.dart`
- [x] `chat_message_model.dart`

---

## 작업 규칙

### Git
- **작업 브랜치**: Jaehyeon(Test)
- master 건들지 않음
- 협업자(DK)와 충돌 시 이 파일 참조

### 우선순위
1. **만세력 로직 완성** ← 현재 집중
2. Profile/Chat 통합 테스트
3. 나머지 UI 개선

---

## 진행 기록

| 날짜 | 작업 내용 | 상태 |
|------|-----------|------|
| 2025-12-02 | 만세력 계산 로직 19개 파일 구현 | ✅ |
| 2025-12-05 | Gemini 3.0 REST API 연동 | ✅ |
| 2025-12-05 | 채팅 히스토리 사이드바 구현 | ✅ |
| 2025-12-06 | TASKS_JAEHYEON.md 분리 생성 | ✅ |
| 2025-12-06 | 만세력 로직 검증 시작 | ✅ |
| 2025-12-16 | 절기 테이블 2020-2030년 확장 | ✅ |
| 2025-12-16 | 음양력 변환 테스트 14개 작성 및 통과 | ✅ |
| 2025-12-16 | 문서 동기화 (TASKS_JAEHYEON.md 업데이트) | ✅ |
| 2025-12-15 | Supabase 연동 (Anonymous Auth + RLS) | ✅ |
| 2025-12-15 | 한글(한자) 형식 저장 + Check Constraint 수정 | ✅ |
| 2025-12-15 | 12운성/12신살 DB 저장 로직 구현 | ✅ |
| 2025-12-15 | **포스텔러 스타일 UI 구현** | ✅ |

---

## 메모

### 다음 작업 계획 ✅ 완료 (2025-12-16)
1. ~~`lunar_solar_converter.dart` 실제 구현~~ ✅ 완료 (1900-2100년)
2. ~~테스트 케이스 작성~~ ✅ 완료 (14개 테스트)
3. ~~포스텔러 만세력과 결과 비교~~ ✅ 완료

### 향후 개선 사항 (우선순위 낮음)
1. 절기 테이블 1900-2019년 추가 (필요 시)
2. 절기 테이블 2031-2100년 추가 (필요 시)
3. 통합 E2E 테스트

### 협업 노트
- 협업자(DK)가 master 브랜치에서 메인 작업 중
- TASKS.md는 협업자가 관리
- 이 파일(TASKS_JAEHYEON.md)로 개인 작업 추적

---

## Supabase 연동 작업 (2025-12-15)

### 현재 상태

| 항목 | 상태 | 설명 |
|------|------|------|
| `.env` 설정 | ✅ 완료 | JWT 형식 anon key로 수정됨 |
| `SupabaseService` 초기화 | ✅ 완료 | main.dart에서 호출 |
| 프로필 → Hive 저장 | ✅ 완료 | 로컬 저장 정상 |
| **프로필 → Supabase 저장** | ✅ 완료 | Anonymous Auth + Repository 연동 |
| **사주분석 → Supabase 저장** | ✅ 완료 | saju_analyses 테이블에 저장 확인됨 |
| Anonymous Sign-in | ✅ 완료 | Supabase 대시보드에서 활성화됨 |
| RLS 정책 | ✅ 완료 | own_profiles 정책 설정됨 |

### 해결된 문제점 ✅

1. **ProfileRepositoryImpl Supabase 연동** → ✅ 해결
   - `_saveToSupabase()`, `_deleteFromSupabase()` 메서드 추가
   - save/update/delete 시 Hive + Supabase 동시 저장

2. **user_id 필수 컬럼 문제** → ✅ 해결
   - 방법 B 채택: Anonymous Sign-in 구현
   - `SupabaseService.ensureAuthenticated()` 추가
   - 익명 사용자도 user_id 자동 발급

3. **사주분석 저장** → ✅ 해결
   - saju_analyses 테이블에 데이터 저장 확인됨

### Supabase 테이블 스키마 (saju_profiles)

```
id              UUID (PK, NOT NULL)
user_id         UUID (FK, NOT NULL)  ← 문제!
display_name    TEXT (NOT NULL)
relation_type   TEXT
memo            TEXT
birth_date      DATE (NOT NULL)
birth_time_minutes  INTEGER
birth_time_unknown  BOOLEAN
is_lunar        BOOLEAN
is_leap_month   BOOLEAN
gender          TEXT (NOT NULL)
birth_city      TEXT (NOT NULL)
time_correction INTEGER
use_ya_jasi     BOOLEAN
is_primary      BOOLEAN
created_at      TIMESTAMPTZ
updated_at      TIMESTAMPTZ
```

### 수정해야 할 파일

1. **`profile_repository_impl.dart`**
   - `save()`, `update()`, `delete()` 메서드에 Supabase 저장 추가

2. **`saju_profile_model.dart`**
   - `toSupabase()` 메서드 추가 필요

3. **테이블 스키마 또는 인증**
   - 옵션 A: `ALTER TABLE saju_profiles ALTER COLUMN user_id DROP NOT NULL;`
   - 옵션 B: 익명 인증 구현

### 완료된 구현 내용

| 파일 | 변경 내용 |
|------|-----------|
| `supabase_service.dart` | `ensureAuthenticated()` 익명 로그인 추가 |
| `saju_profile_model.dart` | `toSupabaseMap()`, `fromSupabaseMap()` 추가 |
| `profile_repository_impl.dart` | `_saveToSupabase()`, `_deleteFromSupabase()` 추가 |

---

## 한글(한자) 형식 구현 작업 ✅ 완료 (2025-12-15)

### 구현 완료된 형식 변환

#### 기본 천간/지지 필드 (8개)
| 필드 | 예시 (before) | 예시 (after) |
|------|--------------|--------------|
| year_gan | 갑 | 갑(甲) |
| year_ji | 자 | 자(子) |
| month_gan | 을 | 을(乙) |
| month_ji | 해 | 해(亥) |
| day_gan | 병 | 병(丙) |
| day_ji | 인 | 인(寅) |
| hour_gan | 정 | 정(丁) |
| hour_ji | 묘 | 묘(卯) |

#### JSONB 필드 한글(한자) 변환
| JSONB 필드 | 변환 대상 | 예시 |
|------------|----------|------|
| oheng_distribution | 오행 이름 | 목(木), 화(火), 토(土), 금(金), 수(水) |
| day_strength | level | 신강(身强), 중화(中和), 신약(身弱) |
| yongsin | 용신/희신/기신/구신/한신, method | 목(木), 억부법(抑扶法) |
| gyeokguk | name | 정관격(正官格) |
| sipsin_info | 모든 십신 | 비견(比肩), 겁재(劫財), 식신(食神)... |
| jijanggan_info | gan, sipsin | 갑(甲), 비견(比肩) |

### 수정된 파일

| 파일 | 변경 내용 |
|------|----------|
| `saju_analysis_db_model.dart` | `toSupabase()` 한글(한자) 변환, `_formatWithHanja()`, `_extractHangul()` 헬퍼 추가, `toSajuChart()` 역변환 지원 |
| `saju_analysis_repository_provider.dart` | `saveFromAnalysis()` JSONB 필드 전체 한글(한자) 형식 적용 |

### 핵심 구현 로직

```dart
// 천간/지지 한글(한자) 변환
static String _formatWithHanja(String hangul, {required bool isCheongan}) {
  if (hangul.contains('(') && hangul.contains(')')) return hangul;
  final hanja = isCheongan ? cheonganHanja[hangul] : jijiHanja[hangul];
  return hanja != null ? '$hangul($hanja)' : hangul;
}

// 십신 한글(한자) 변환
String formatSipsin(SipSin sipsin) => '${sipsin.korean}(${sipsin.hanja})';
```

---

### DB Check Constraint 수정 ✅ (2025-12-15)

**문제**: saju_analyses 테이블 check constraint가 한글만 허용
```
에러: violates check constraint "check_day_gan"
원인: 한글(한자) 형식 "축(丑)" 저장 시 기존 constraint 위반
```

**해결**: Supabase Migration으로 check constraint 수정
```sql
-- 기존: 한글만 허용
CHECK (day_gan = ANY (ARRAY['갑', '을', ...]))

-- 수정: 한글 또는 한글(한자) 형식 허용
CHECK (day_gan ~ '^(갑|을|병|정|무|기|경|신|임|계)(\([甲乙丙丁戊己庚辛壬癸]\))?$')
```

**적용된 제약조건 (8개)**:
| 제약조건 | 허용 형식 | 예시 |
|---------|----------|------|
| check_year_gan | 한글 또는 한글(한자) | 갑, 갑(甲) |
| check_year_ji | 한글 또는 한글(한자) | 자, 자(子) |
| check_month_gan | 한글 또는 한글(한자) | 을, 을(乙) |
| check_month_ji | 한글 또는 한글(한자) | 해, 해(亥) |
| check_day_gan | 한글 또는 한글(한자) | 병, 병(丙) |
| check_day_ji | 한글 또는 한글(한자) | 인, 인(寅) |
| check_hour_gan | NULL 또는 한글(한자) | 정, 정(丁) |
| check_hour_ji | NULL 또는 한글(한자) | 묘, 묘(卯) |

**결과**: ✅ 축(丑), 금(金) 등 한글(한자) 형식 저장 성공 확인됨

---

### 이전 완료 작업 (2025-12-15 오전)

| 작업 | 파일 | 설명 |
|------|------|------|
| Pillar 필드명 수정 | `saju_analysis_db_model.dart` | cheongan→gan, jiji→ji |
| OhengDistribution import | `saju_detail_tabs.dart` | 타입 에러 해결 |
| Supabase anon key 수정 | `.env` | sb_publishable → JWT 형식 |
| **Anonymous Auth 구현** | `supabase_service.dart` | `ensureAuthenticated()` 추가 |
| **Supabase 직렬화** | `saju_profile_model.dart` | `toSupabaseMap()`, `fromSupabaseMap()` |
| **Repository 연동** | `profile_repository_impl.dart` | Supabase save/delete 로직 |
| **Supabase 저장 확인** | saju_analyses 테이블 | 데이터 저장 성공 확인됨 |
| **Check Constraint 수정** | Supabase Migration | 한글(한자) 형식 허용 |

---

---

## 12운성/12신살 저장 구현 ✅ 완료 (2025-12-15)

### 구현 완료 항목

| 항목 | 상태 | 설명 |
|------|------|------|
| saju_analysis_db_model.dart 확장 | ✅ 완료 | 5개 필드 추가 |
| saveFromAnalysis() 수정 | ✅ 완료 | 신살/대운/세운/12운성/12신살 저장 |
| Supabase Migration | ✅ 완료 | twelve_unsung, twelve_sinsal 컬럼 추가 |

### 추가된 DB 필드 (saju_analyses 테이블)

| 필드명 | 타입 | 설명 | 예시 데이터 |
|--------|------|------|-------------|
| sinsal_list | JSONB | 신살 목록 (기존) | `[{"name":"역마살(驛馬殺)","type":"길흉혼합",...}]` |
| daeun | JSONB | 대운 정보 (기존) | `{"startAge":5,"isForward":true,"list":[...]}` |
| current_seun | JSONB | 현재 세운 (기존) | `{"year":2025,"age":32,"pillar":"을(乙)사(巳)"}` |
| **twelve_unsung** | JSONB | **12운성 (신규)** | `[{"pillar":"년주","unsung":"장생(長生)","strength":10}...]` |
| **twelve_sinsal** | JSONB | **12신살 (신규)** | `[{"pillar":"년지","sinsal":"역마(驛馬)","fortuneType":"길흉혼합"}...]` |

### 12운성 (十二運星) 데이터 형식

```json
[
  {"pillar": "년주", "jiji": "인", "unsung": "장생(長生)", "strength": 10, "fortuneType": "길"},
  {"pillar": "월주", "jiji": "해", "unsung": "목욕(沐浴)", "strength": 7, "fortuneType": "흉"},
  {"pillar": "일주", "jiji": "축", "unsung": "관대(冠帶)", "strength": 8, "fortuneType": "길"},
  {"pillar": "시주", "jiji": "묘", "unsung": "건록(建祿)", "strength": 9, "fortuneType": "길"}
]
```

### 12신살 (十二神煞) 데이터 형식

```json
[
  {"pillar": "년지", "jiji": "인", "sinsal": "겁살(劫殺)", "fortuneType": "흉"},
  {"pillar": "월지", "jiji": "해", "sinsal": "역마(驛馬)", "fortuneType": "길흉혼합"},
  {"pillar": "일지", "jiji": "축", "sinsal": "화개(華蓋)", "fortuneType": "길"},
  {"pillar": "시지", "jiji": "묘", "sinsal": "도화(桃花)", "fortuneType": "길흉혼합"}
]
```

### 수정된 파일

| 파일 | 변경 내용 |
|------|----------|
| `saju_analysis_db_model.dart` | 5개 필드 추가 (sinsalList, daeun, currentSeun, twelveUnsung, twelveSinsal) |
| `saju_analysis_repository_provider.dart` | imports 추가, saveFromAnalysis()에서 12운성/12신살/대운/세운 계산 및 저장 |

### 포스텔러 스타일 UI ✅ 완료 (2025-12-15)

**구현 완료된 테이블 UI**

```
| 구분   | 시주     | 일주     | 월주     | 년주     |
|--------|----------|----------|----------|----------|
| 천간   | 정(丁)   | 병(丙)   | 을(乙)   | 갑(甲)   |
| 지지   | 묘(卯)   | 축(丑)   | 해(亥)   | 인(寅)   |
| 십성   | 식신     | 일원     | 겁재     | 비견     |
| 지장간 | 을       | 신계기   | 무갑임   | 무기병   |
| 12운성 | 건록     | 관대     | 목욕     | 장생     |
| 12신살 | 도화     | 화개     | 역마     | 겁살     |
```

**구현된 파일:**

| 파일 | 역할 |
|------|------|
| `possteller_style_table.dart` | 포스텔러 스타일 통합 테이블 위젯 (신규) |
| `saju_detail_tabs.dart` | 만세력 탭에 PosstellerStyleTable 추가 |

**주요 기능:**
- 천간/지지: 한자 크게, 한글 작게 (오행별 색상)
- 십성: 일주는 '일원' 표시, 카테고리별 색상
- 지장간: 한자 문자열 표시
- 12운성: 강도(strength) 기반 색상 (강=녹색, 중=파란색, 약=주황색/빨간색)
- 12신살: 길흉 기반 색상 (길=녹색, 혼합=파란색, 흉=빨간색)
- compact 모드 지원 (PosstellerMiniTable)

---

## 다음 세션 시작 프롬프트

```
@TASKS_JAEHYEON.md 읽고 이어서 작업해.

현재 완료된 상태:
- Supabase 연동 완료 (Anonymous Auth + RLS)
- saju_analyses 테이블에 한글(한자) 형식으로 저장됨
- 12운성/12신살 DB 저장 로직 구현 완료 (2025-12-15)
- Supabase Migration 완료 (twelve_unsung, twelve_sinsal 컬럼)
- **포스텔러 스타일 UI 구현 완료** (2025-12-15)
- ✅ **음양력 변환 완전 구현** (1900-2100년, 테스트 14개 통과)
- ✅ **절기 테이블 확장** (2020-2030년, 한국천문연구원 데이터)
- ✅ **만세력 로직 검증 완료** (2025-12-16)

다음 작업 후보:
1. 절기 테이블 추가 확장 (1900-2019년, 2031-2100년) - 필요 시
2. 통합 테스트 (Profile 입력 → 사주 계산 → AI 채팅 플로우)
3. 성능 최적화 및 UI 개선
4. 세운/대운 상세 분석 기능

관련 파일:
- `possteller_style_table.dart` - 포스텔러 스타일 테이블 위젯
- `lunar_solar_converter.dart` - 음양력 변환 ✅ 완전 구현
- `solar_term_table.dart` - 절기 테이블 ✅ 2020-2030년 확장 완료
- `lunar_solar_test.dart` - 음양력 변환 테스트 (14개)

작업 시작해줘.
```
