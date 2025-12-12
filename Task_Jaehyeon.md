# 만톡 - 구현 작업 목록

> Main Claude 컨텍스트 유지용 작업 노트
> 작업 브랜치: Jaehyeon(Test)
> 백엔드(Supabase): 사용자가 직접 처리

---

## 현재 상태

| 항목 | 상태 |
|------|------|
| 기획 문서 | ✅ 완료 |
| CLAUDE.md | ✅ 완료 |
| JH_Agent (서브에이전트) | ✅ 완료 (9개) |
| Flutter 프로젝트 | ✅ 기반 설정 완료 |
| 의존성 | ✅ 설치 완료 |
| 폴더 구조 | ✅ 구현 완료 |
| Phase 1 | ✅ **완료** |
| Phase 2 | ✅ **부분 완료** (상수/테마) |
| Phase 4 (Profile) | ✅ **완료** |
| Phase 5 (Saju Chat) | ✅ **대부분 완료** (Gemini 3.0 연동) |
| Phase 8 (만세력) | ✅ **기본 완료** |
| **Phase 9 (만세력 고급)** | ✅ **9-A/9-B 완료** |
| **Phase 10 (RuleEngine)** | ✅ **10-A/10-B/10-C 모두 완료** |
| **다음 작업** | **Phase 10 서비스 전환 (RuleEngine 적용)** |

---

## Phase 1: 프로젝트 기반 설정 ✅ 완료

### 1.1 pubspec.yaml 의존성 추가 ✅
- [x] flutter_riverpod: ^2.6.1
- [x] riverpod_annotation: ^2.6.1
- [x] go_router: ^14.6.2
- [x] hive_flutter: ^1.1.0
- [x] flutter_secure_storage: ^9.2.4
- [x] shared_preferences: ^2.3.5
- [x] freezed_annotation: ^2.4.4
- [x] json_annotation: ^4.9.0
- [x] uuid: ^4.5.1
- [x] equatable: ^2.0.7
- [x] dio: ^5.7.0
- [x] intl: ^0.20.1

### 1.2 dev_dependencies ✅
- [x] build_runner: ^2.4.9
- [x] riverpod_generator: ^2.3.11
- [x] freezed: ^2.4.7
- [x] json_serializable: ^6.7.1
- [ ] riverpod_lint (disabled - analyzer 충돌)
- [ ] hive_generator (disabled - analyzer 충돌)

### 1.3 폴더 구조 생성 ✅
```
lib/
├── main.dart ✅
├── app.dart ✅
├── core/
│   ├── constants/
│   │   ├── app_colors.dart ✅
│   │   ├── app_strings.dart ✅
│   │   └── app_sizes.dart ✅
│   ├── theme/
│   │   └── app_theme.dart ✅
│   ├── utils/
│   │   ├── validators.dart
│   │   └── formatters.dart
│   └── errors/
│       ├── exceptions.dart
│       └── failures.dart
├── features/
│   ├── splash/ ✅ (placeholder)
│   ├── onboarding/ ✅ (placeholder)
│   ├── profile/ ✅ (placeholder)
│   ├── saju_chart/ ✅ (폴더만)
│   ├── saju_chat/ ✅ (placeholder)
│   ├── history/ ✅ (placeholder)
│   └── settings/ ✅ (placeholder)
├── shared/
│   ├── widgets/
│   └── extensions/
└── router/
    ├── app_router.dart ✅
    └── routes.dart ✅
```

### 1.4 기본 설정 파일 ✅
- [x] analysis_options.yaml (린트 규칙)
- [x] app.dart (MaterialApp 설정)
- [x] router/routes.dart (라우트 상수)
- [x] router/app_router.dart (go_router 설정)

---

## Phase 2: Core 레이어 구현 (부분 완료)

### 2.1 상수 정의 ✅
- [x] app_colors.dart - 컬러 팔레트
- [x] app_strings.dart - 문자열 상수
- [x] app_sizes.dart - 크기/패딩 상수

### 2.2 테마 설정 ✅
- [x] app_theme.dart - 라이트/다크 테마

### 2.3 에러 처리
- [ ] exceptions.dart - 예외 클래스
- [ ] failures.dart - Failure 클래스

### 2.4 유틸리티
- [ ] validators.dart - 생년월일 검증 등
- [ ] formatters.dart - 날짜 포맷 등

---

## Phase 3: 공유 컴포넌트

### 3.1 공통 위젯
- [ ] custom_button.dart
- [ ] custom_text_field.dart
- [ ] loading_indicator.dart
- [ ] error_widget.dart
- [ ] disclaimer_banner.dart ("사주는 참고용입니다")

### 3.2 Extensions
- [ ] context_extensions.dart
- [ ] datetime_extensions.dart

---

## Phase 4: Feature - Profile (P0) ✅ 완료

> 참조: docs/02_features/profile_input.md
> 2025-12-02: Profile Feature 구현 완료 (21개 파일)

### 4.1 Domain 레이어 ✅
- [x] entities/saju_profile.dart (Freezed)
- [x] entities/gender.dart (enum)
- [x] repositories/profile_repository.dart (abstract)

### 4.2 Data 레이어 ✅
- [x] models/saju_profile_model.dart (Freezed + JSON)
- [x] datasources/profile_local_datasource.dart (Hive)
- [x] repositories/profile_repository_impl.dart

### 4.3 Presentation 레이어 ✅
- [x] providers/profile_provider.dart (Riverpod 3.0)
- [x] screens/profile_edit_screen.dart
- [x] widgets/profile_name_input.dart
- [x] widgets/gender_toggle_buttons.dart
- [x] widgets/calendar_type_dropdown.dart
- [x] widgets/birth_date_picker.dart
- [x] widgets/birth_time_picker.dart
- [x] widgets/birth_time_options.dart
- [x] widgets/city_search_field.dart
- [x] widgets/time_correction_banner.dart
- [x] widgets/profile_action_buttons.dart

### 4.4 수락 조건 ✅
- [x] 프로필명 입력 (최대 12자)
- [x] 성별 선택 (필수) - 토글 버튼
- [x] 생년월일 선택 (필수) - ShadDatePicker
- [x] 음력/양력 선택 - ShadSelect
- [x] 출생시간 입력 (선택)
- [x] "시간 모름" 체크 기능
- [x] "야자시/조자시" 옵션 추가
- [x] 도시 검색 (25개 도시 + 자동완성)
- [x] 진태양시 보정 표시 (예: "-26분")
- [x] 로컬 저장 (Hive)
- [x] 유효성 검사

### 4.5 TODO
- [ ] `dart run build_runner build` 실행
- [ ] 빌드 테스트

---

## Phase 5: Feature - Saju Chat (P0) ✅ 대부분 완료

> 참조: docs/02_features/saju_chat.md
> 2025-12-05: Gemini 3.0 REST API 연동, 스트리밍 응답, UI 위젯 구현 완료

### 5.1 Domain 레이어 ✅
- [x] entities/chat_session.dart
- [x] entities/chat_message.dart (MessageRole, MessageStatus 포함)
- [x] models/chat_type.dart (ChatType enum)
- [x] repositories/chat_repository.dart (abstract)

- [x] widgets/typing_indicator.dart
- [x] widgets/disclaimer_banner.dart
- [x] widgets/error_banner.dart
- [ ] widgets/suggested_questions.dart (추후)
- [ ] widgets/saju_summary_sheet.dart (추후)

### 5.4 수락 조건
- [x] AI 인사 메시지 표시 (ChatType별 환영 메시지)
- [x] 메시지 입력/전송
- [x] 스트리밍 응답 표시
- [x] 타이핑 인디케이터
- [x] 면책 배너 표시
- [x] 에러 처리 (에러 배너)
- [ ] 추천 질문 칩 표시 (추후)
- [ ] 프로필 전환 기능 (추후)
- [ ] 사주 요약 바텀시트 (추후)

---

## Phase 6: Feature - Splash/Onboarding

### 6.1 Splash
- [x] screens/splash_screen.dart (프로필 체크 로직 추가)
- [x] 로컬 데이터 로드
- [x] 온보딩/프로필 체크 후 라우팅

### 6.2 Onboarding
- [x] screens/onboarding_screen.dart (사주 정보 입력 폼 구현)
- [x] 서비스 소개 페이지 (입력 폼으로 대체)
- [x] "사주는 참고용입니다" 안내
- [x] 온보딩 완료 플래그 저장 (프로필 저장으로 대체)

---

## Phase 7: Feature - History/Settings

### 7.1 History
- [ ] screens/history_screen.dart
- [ ] 과거 대화 목록 표시
- [ ] 대화 선택 → 채팅 화면 이동

### 7.2 Settings
- [ ] screens/settings_screen.dart
- [ ] 프로필 관리 진입점
- [ ] 알림 설정 (추후)
- [ ] 약관/면책 안내

---

## Phase 8: Saju Chart (만세력) ✅ 기본 완료

> 2025-12-02: 만세력 계산 로직 구현 완료 (19개 파일)

### 8.1 Constants ✅
- [x] data/constants/cheongan_jiji.dart - 천간(10), 지지(12), 오행
- [x] data/constants/gapja_60.dart - 60갑자
- [x] data/constants/solar_term_table.dart - 절기 시각 (2024-2025)
- [x] data/constants/dst_periods.dart - 서머타임 기간

### 8.2 Domain Entities ✅
- [x] domain/entities/pillar.dart - 기둥 (천간+지지)
- [x] domain/entities/saju_chart.dart - 사주 차트
- [x] domain/entities/lunar_date.dart - 음력 날짜
- [x] domain/entities/solar_term.dart - 24절기 enum
- [ ] domain/entities/daewoon.dart - 대운 (추후)

### 8.3 Domain Services ✅
- [x] domain/services/saju_calculation_service.dart - 통합 계산 (메인)
- [x] domain/services/lunar_solar_converter.dart - 음양력 변환 (Stub)
- [x] domain/services/solar_term_service.dart - 절입시간
- [x] domain/services/true_solar_time_service.dart - 진태양시 (25개 도시)
- [x] domain/services/dst_service.dart - 서머타임
- [x] domain/services/jasi_service.dart - 야자시/조자시

### 8.4 Data Models ✅
- [x] data/models/pillar_model.dart - JSON 직렬화
- [x] data/models/saju_chart_model.dart - JSON 직렬화

### 8.5 Presentation (미구현)
## 작업 규칙

### 컨텍스트 관리
1. **Compaction**: 대화 길어지면 이 파일에 진행 상황 업데이트
2. **노트 작성**: 결정 사항, 변경점 기록
3. **서브 Agent**: 복잡한 작업은 Task 도구로 분리

### Git 규칙
- 작업 브랜치: Jaehyeon(Test)
- master 건들지 않음
- 기능 단위로 커밋

### 우선순위
1. Phase 1-2: 기반 설정 (먼저)
2. Phase 4: Profile (P0 필수)
3. Phase 5: Saju Chat (P0 핵심)
4. Phase 6-7: 나머지 화면
5. Phase 8: Supabase 연동 후

---

## 진행 기록

| 날짜 | 작업 내용 | 상태 |
|------|-----------|------|
| 2025-12-01 | 프로젝트 시작, 기획 문서 완료 | 완료 |
| 2025-12-02 | TASKS.md 작성 | 완료 |
| 2025-12-02 | CLAUDE.md 생성 | 완료 |
| 2025-12-02 | JH_Agent 서브에이전트 생성 (8개) | 완료 |
| 2025-12-02 | 만세력 정확도 연구 (진태양시, 절입시간 등) | 완료 |
| 2025-12-02 | 세션 1 종료, Phase 1 시작 대기 | 완료 |
| 2025-12-02 | **Phase 1 완료**: 의존성, 폴더구조, 라우터, 테마 | 완료 |
| 2025-12-02 | **Phase 2 부분 완료**: 상수, 테마, Placeholder 화면들 | 진행중 |
| 2025-12-02 | **Phase 8 기본 완료**: 만세력 계산 로직 19개 파일 구현 | 완료 |
| 2025-12-02 | SubAgent A2A 아키텍처 개선 (Orchestrator 추가) | 완료 |
| 2025-12-02 | 09_manseryeok_calculator SubAgent 추가 | 완료 |
| 2025-12-02 | 앱 런칭 전략 문서 작성 (APP_LAUNCH_STRATEGY.md) | 완료 |
| 2025-12-02 | **Phase 4 완료**: Profile Feature 21개 파일 구현 | 완료 |
| 2025-12-05 | **Phase 5 대부분 완료**: Saju Chat 18개 파일 구현 | 완료 |
| 2025-12-05 | Gemini 3.0 REST API 연동 (SDK → REST 마이그레이션) | 완료 |
| 2025-12-05 | SSE 스트리밍 응답, 타이핑 인디케이터 구현 | 완료 |
| 2025-12-06 | 일주 계산 오류 분석 및 수정 완료 | ✅ 완료 |
| 2025-12-06 | baseDayIndex=10 확정, 테스트 통과 | ✅ 완료 |
| 2025-12-06 | 포스텔러 검증 완료 (1990-02-15, 1997-11-29) | ✅ 완료 |
| 2025-12-06 | SajuDetailSheet "자세히 보기" 에러 수정 (3개 파일) | ✅ 완료 |
| 2025-12-06 | Provider container 전달, ShadSheet→Flutter 위젯 변환 | ✅ 완료 |
| 2025-12-06 | PillarDisplay 한자 표시 기능 추가 | ✅ 완료 |
| 2025-12-06 | 천간지지 JSON 기반 리팩토링 (4개 파일) | ✅ 완료 |
| 2025-12-08 | DK-AA 브랜치 merge (관계도 그래프 기능) | ✅ 완료 |
| 2025-12-08 | 만세력 로직 문서 작성 (docs/manseryeok_logic.md) | ✅ 완료 |
| 2025-12-08 | **Phase 9 시작**: 만세력 고급 분석 기능 | ✅ 완료 |
| 2025-12-08 | **Phase 9-A 완료**: 데이터 구조 (Constants) 6개 파일 | ✅ 완료 |
| 2025-12-08 | **Phase 9-B 완료**: 고급 분석 서비스 5개 구현 | ✅ 완료 |
| 2025-12-08 | unsung_service.dart - 12운성 계산 서비스 | ✅ 완료 |
| 2025-12-08 | gongmang_service.dart - 공망 계산 서비스 | ✅ 완료 |
| 2025-12-08 | jijanggan_service.dart - 지장간+십성 분석 서비스 | ✅ 완료 |
| 2025-12-08 | twelve_sinsal_service.dart - 12신살 전용 서비스 | ✅ 완료 |
| 2025-12-08 | saju_chart.dart export 업데이트 | ✅ 완료 |
| 2025-12-12 | **Phase 10 시작**: RuleEngine 리팩토링 설계 | ✅ 완료 |
| 2025-12-12 | 코어 엔진 아키텍처 분석 및 피드백 반영 | ✅ 완료 |
| 2025-12-12 | **Phase 10-A 완료**: RuleEngine 기반 구축 (9개 파일) | ✅ 완료 |
| 2025-12-12 | **Phase 10-C 완료**: 나머지 룰 JSON 분리 (5개 JSON + 3개 코드 수정 + 테스트) | ✅ 완료 |

---

## Phase 10: RuleEngine 리팩토링 (2025-12-12~)

> **목적**: 하드코딩된 룰/테이블을 JSON으로 분리하여 운영 유연성 확보
> **원칙**: JSON(작성/관리) + Dart Map(실행) 이중 구조
> **전략**: 인터페이스는 완성형, 구현은 MVP (Lean RuleEngine)

### 배경

현재 문제점:
- 신살/십성/합충 등 룰이 Dart 코드에 하드코딩
- 룰 수정 시 코드 변경 + 앱 재배포 필요
- 테스트 부족 (2개 케이스만)

목표 구조:
```
[JSON 룰 파일] ──→ [RuleRepository] ──→ [RuleEngine] ──→ [기존 서비스]
 (assets)          load + validate      matchAll()      사용
                   + compile
```

### Phase 10-A: 기반 구축 (Lean MVP)

#### 생성할 파일
```
lib/features/saju_chart/
├── domain/
│   ├── entities/
│   │   ├── rule.dart              # Rule 인터페이스 + 타입
│   │   ├── rule_condition.dart    # 조건 타입 (op enum)
│   │   ├── compiled_rules.dart    # 컴파일된 룰 구조
│   │   └── saju_context.dart      # 사주 컨텍스트
│   ├── repositories/
│   │   └── rule_repository.dart   # Repository 인터페이스
│   └── services/
│       ├── rule_engine.dart       # 매칭 엔진
│       └── rule_validator.dart    # 기본 검증
├── data/
│   ├── repositories/
│   │   └── rule_repository_impl.dart
│   └── models/
│       └── rule_models.dart       # JSON 파싱 모델

assets/data/rules/
└── sinsal_rules.json              # 첫 번째 JSON 룰
```

#### 작업 순서
- [x] 1. `rule.dart` - Rule 인터페이스 정의 ✅
- [x] 2. `rule_condition.dart` - 조건 타입 + op enum ✅
- [x] 3. `saju_context.dart` - SajuContext 정의 ✅
- [x] 4. `compiled_rules.dart` - CompiledRules (MVP: 단순 리스트) ✅
- [x] 5. `rule_repository.dart` - Repository 인터페이스 ✅
- [x] 6. `rule_engine.dart` - RuleEngine 핵심 로직 ✅
- [x] 7. `rule_validator.dart` - 기본 필드 검증 ✅
- [x] 8. `rule_models.dart` - JSON 파싱 모델 ✅
- [x] 9. `rule_repository_impl.dart` - Repository 구현 ✅

### Phase 10-B: 신살 JSON 분리 ✅ 완료 (2025-12-12)

- [x] `sinsal_rules.json` 생성 (957줄, 12신살 + 특수신살)
- [x] TwelveSinsalService.analyzeWithRuleEngine() 연동 완료
- [x] 테스트 케이스 19개 추가 (rule_engine_sinsal_test.dart)

### Phase 10-C: 나머지 룰 분리 ✅ 완료 (2025-12-12)

- [x] `hapchung_rules.json` - 합충형파해 56개 룰
- [x] `sipsin_tables.json` - 십신 10천간 매핑
- [x] `jijanggan_tables.json` - 지장간 12지지 매핑
- [x] `unsung_tables.json` - 12운성 테이블
- [x] `gongmang_tables.json` - 공망 6순 테이블
- [x] `rule_condition.dart` - gte/lte 연산자, jiCount/ganCount 필드 추가
- [x] `saju_context.dart` - jiCount/ganCount getter 추가
- [x] `rule_engine.dart` - _evaluateGte/_evaluateLte 메서드 추가
- [x] `rule_engine_hapchung_test.dart` - 합충형파해 테스트 케이스

### Phase 10-D: Supabase 연동 (추후)

- [ ] `loadFromRemote()` 구현
- [ ] 해시 검증 (SHA256)
- [ ] 버전 관리 + 롤백

### Phase 10 작업 순서 분석 (2025-12-12)

> **핵심 발견**: Option 3 (하드코딩 제거)는 마지막에 해야 함

#### 현재 앱 실행 흐름
```
saju_chart_provider.dart
        ↓
SajuAnalysisService.analyze()  ← 실제 앱 진입점
        ↓
SinSalService (하드코딩)
DayStrengthService
GyeokGukService
```

#### RuleEngine 적용 현황

| 서비스 | RuleEngine 메서드 | JSON 룰 | 상태 |
|--------|-------------------|---------|------|
| TwelveSinsalService | `analyzeWithRuleEngine()` ✅ | ✅ sinsal_rules.json | **완료** |
| HapchungService | ❌ 없음 | ✅ hapchung_rules.json | **불완전** |
| SipsinService | ❌ 없음 | ✅ sipsin_tables.json | 테이블만 |
| UnsungService | ❌ 없음 | ✅ unsung_tables.json | 테이블만 |
| GongmangService | ❌ 없음 | ✅ gongmang_tables.json | 테이블만 |
| JijangganService | ❌ 없음 | ✅ jijanggan_tables.json | 테이블만 |

#### 올바른 작업 순서

```
① Phase 10-B ✅ → ② 서비스 전환 → ③ 테스트 검증 → ④ 하드코딩 제거 → ⑤ UI
  (sinsal.json)    (RuleEngine)    (결과 비교)      (Option 3)       (Option 2)
```

| 순서 | 작업 | 설명 | 의존성 |
|:----:|------|------|--------|
| ✅ ① | Phase 10-B | sinsal_rules.json 생성 | 완료 |
| **② 다음** | 서비스 RuleEngine 전환 | HapchungService 등에 메서드 추가 | ① 완료 |
| ③ | 테스트 검증 | 하드코딩 == RuleEngine 결과 확인 | ② 완료 |
| ④ | 하드코딩 제거 (Option 3) | 기존 로직 deprecate | ③ 통과 |
| ⑤ | UI 컴포넌트 (Option 2) | 화면 표시 위젯 | ④ 선택 |

#### Option 3을 먼저 하면 안 되는 이유

1. ~~**sinsal_rules.json 미생성** → TwelveSinsalService RuleEngine 불완전~~ ✅ 해결됨
2. **HapchungService에 RuleEngine 메서드 없음** → 하드코딩 제거 시 앱 깨짐
3. **검증 미완료** → 하드코딩 vs RuleEngine 결과 비교 안됨

---

## Phase 11: Supabase 만세력 DB 설계 (2025-12-12 분석)

> **목적**: 만세력 계산 결과를 DB에 저장하여 재계산 없이 빠르게 조회
> **원칙**: 정규화(4주) + JSONB(분석 데이터) 하이브리드 구조
> **확장성**: 100만 사용자까지 대응 가능한 스키마

### 현재 Supabase 구조

```
public.users (기존)
├── id (PK, uuid)
├── name (text)
├── gender (text)
├── birth_date (date)
├── birth_time (time)
├── birth_city (text)
├── is_lunar (boolean)
└── created_at (timestamp)
```

### 목표 DB 스키마

#### 11.1 saju_charts 테이블 (핵심)

```sql
CREATE TABLE saju_charts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

  -- 사주 기본 (정규화 - 인덱싱 가능)
  year_gan TEXT NOT NULL,      -- 년간 (갑~계)
  year_ji TEXT NOT NULL,       -- 년지 (자~해)
  month_gan TEXT NOT NULL,
  month_ji TEXT NOT NULL,
  day_gan TEXT NOT NULL,       -- 일간 = 나
  day_ji TEXT NOT NULL,
  hour_gan TEXT,               -- 시주 (선택)
  hour_ji TEXT,

  -- 계산 기준 정보
  birth_datetime TIMESTAMPTZ NOT NULL,
  corrected_datetime TIMESTAMPTZ,  -- 진태양시 보정 후
  birth_city TEXT,
  is_lunar BOOLEAN DEFAULT FALSE,

  -- 메타데이터
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  calculation_version TEXT DEFAULT '1.0.0',  -- 로직 버전
  needs_recalculation BOOLEAN DEFAULT FALSE
);
```

#### 11.2 saju_analysis 테이블 (분석 결과)

```sql
CREATE TABLE saju_analysis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chart_id UUID UNIQUE REFERENCES saju_charts(id) ON DELETE CASCADE,

  -- JSONB 컬럼들 (가변 구조)
  sipsin JSONB,              -- 십성 분석
  twelve_unsung JSONB,       -- 12운성
  relations JSONB,           -- 합충형파해
  twelve_sinsal JSONB,       -- 12신살
  gongmang JSONB,            -- 공망
  jijanggan JSONB,           -- 지장간
  oheng_distribution JSONB,  -- 오행 분포

  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### 11.3 인덱싱 전략

```sql
-- 사용자별 조회
CREATE INDEX idx_saju_charts_user_id ON saju_charts(user_id);

-- 일간 기준 조회 (통계/분석용)
CREATE INDEX idx_saju_charts_day_gan ON saju_charts(day_gan);

-- 생년월일 범위 조회
CREATE INDEX idx_saju_charts_birth_datetime ON saju_charts(birth_datetime);

-- JSONB 내부 검색용 (선택적)
CREATE INDEX idx_saju_analysis_relations ON saju_analysis
  USING GIN (relations jsonb_path_ops);
```

#### 11.4 Row Level Security (RLS)

```sql
ALTER TABLE saju_charts ENABLE ROW LEVEL SECURITY;
ALTER TABLE saju_analysis ENABLE ROW LEVEL SECURITY;

-- 본인 데이터만 조회
CREATE POLICY "Users can view own charts" ON saju_charts
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own charts" ON saju_charts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own charts" ON saju_charts
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own charts" ON saju_charts
  FOR DELETE USING (auth.uid() = user_id);

-- saju_analysis는 chart_id 통해 간접 보호
CREATE POLICY "Users can view own analysis" ON saju_analysis
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM saju_charts
      WHERE saju_charts.id = saju_analysis.chart_id
      AND saju_charts.user_id = auth.uid()
    )
  );
```

### ERD

```
┌─────────────────────┐       ┌─────────────────────┐
│   auth.users        │       │    saju_charts      │
├─────────────────────┤       ├─────────────────────┤
│ id (PK)             │──1:N──│ user_id (FK)        │
│ email               │       │ id (PK)             │
│ ...                 │       │ year_gan/ji         │
└─────────────────────┘       │ month_gan/ji        │
                              │ day_gan/ji          │
                              │ hour_gan/ji         │
                              │ birth_datetime      │
                              │ corrected_datetime  │
                              └──────────┬──────────┘
                                         │
                                        1:1
                                         │
                              ┌──────────┴──────────┐
                              │   saju_analysis     │
                              ├─────────────────────┤
                              │ chart_id (FK, UQ)   │
                              │ sipsin (JSONB)      │
                              │ twelve_unsung       │
                              │ relations (JSONB)   │
                              │ twelve_sinsal       │
                              │ gongmang (JSONB)    │
                              │ jijanggan (JSONB)   │
                              │ oheng_distribution  │
                              └─────────────────────┘
```

### JSONB 데이터 구조 예시

```json
// sipsin
{ "yearGan": "정관", "monthGan": "편인", "dayGan": "비견", "hourGan": "식신" }

// twelve_unsung
{ "yearJi": { "name": "장생", "strength": 7 }, "monthJi": {...} }

// relations (합충형파해)
{
  "hapchung": [{"type": "자축합", "positions": ["년지", "월지"]}],
  "chung": [],
  "hyung": [{"type": "인사형", "positions": ["월지", "시지"]}]
}

// gongmang
{ "gongmangJi": ["술", "해"], "affectedPositions": ["년지"] }

// oheng_distribution
{ "목": 2, "화": 1, "토": 3, "금": 1, "수": 1 }
```

### 설계 원칙 요약

| 원칙 | 적용 |
|------|------|
| **정규화** | 4주(8개 간지)는 별도 컬럼 → 인덱싱/검색 최적화 |
| **JSONB** | 파생 데이터(십성/신살/관계)는 JSONB → 스키마 유연성 |
| **RLS** | user_id 기반 행 수준 보안 → 데이터 격리 |
| **Foreign Key** | auth.users.id 참조 (Supabase 권장) |
| **버전 관리** | calculation_version으로 로직 변경 추적 |
| **인덱싱** | user_id, day_gan, birth_datetime에 인덱스 |

### 구현 작업 (추후)

- [ ] Supabase 마이그레이션 SQL 작성
- [ ] Flutter 모델 클래스 생성 (saju_chart_model.dart)
- [ ] Repository 구현 (saju_chart_repository.dart)
- [ ] 로컬 캐시(Hive) ↔ Supabase 동기화 로직
- [ ] calculation_version 기반 재계산 트리거

### 설계 원칙

1. **인터페이스는 완성형** - 확장 대비
2. **구현은 MVP** - 빠른 출시
3. **하위 호환성** - 기존 하드코딩 로직 유지
4. **점진적 마이그레이션** - sinsal부터 시작

### JSON 룰 구조 (예시)

```json
{
  "schemaVersion": "1.0.0",
  "ruleType": "sinsal",
  "rules": [
    {
      "id": "cheon_eul_gwin",
      "name": "천을귀인",
      "hanja": "天乙貴人",
      "category": "길성",
      "when": {
        "op": "and",
        "conditions": [
          { "field": "dayGan", "op": "in", "value": ["갑", "무", "경"] },
          { "field": "jiAny", "op": "in", "value": ["축", "미"] }
        ]
      },
      "reasonTemplate": "일간 {dayGan}에서 {matchedJi}가 천을귀인"
    }
  ]
}
```

---

## Phase 9: 만세력 고급 분석 기능 (2025-12-08~)

> 포스텔러 레퍼런스 기준 - 사주 풀이 자세히 보기 기능 구현
> 현재: 기본 4주(년월일시) + 오행 분포만 표시
> 목표: 전문 만세력 수준의 상세 분석 제공

### 9.1 합충형파해(合沖刑破害) - 우선순위 1

#### 9.1.1 천간 관계
- [ ] **천간합(天干合)** - 5가지: 갑기합, 을경합, 병신합, 정임합, 무계합
- [ ] **천간충(天干沖)** - 4가지: 갑경충, 을신충, 병임충, 정계충

#### 9.1.2 지지 관계
- [ ] **지지육합(地支六合)** - 6가지: 자축합, 인해합, 묘술합, 진유합, 사신합, 오미합
- [ ] **지지삼합(地支三合)** - 4가지: 인오술(화), 사유축(금), 신자진(수), 해묘미(목)
- [ ] **지지방합(地支方合)** - 4가지: 인묘진(동), 사오미(남), 신유술(서), 해자축(북)
- [ ] **지지충(地支沖)** - 6가지: 자오충, 축미충, 인신충, 묘유충, 진술충, 사해충
- [ ] **지지형(地支刑)** - 삼형살, 자형, 상형 등
- [ ] **지지파(地支破)** - 6가지
- [ ] **지지해(地支害)** - 6가지: 자미해, 축오해, 인사해, 묘진해, 신해해, 유술해
- [ ] **원진(怨嗔)** - 12가지

### 9.2 십성(十星) - 우선순위 2

> 일간(나)을 기준으로 다른 천간/지지와의 관계

- [ ] **비견(比肩)** - 같은 오행, 같은 음양
- [ ] **겁재(劫財)** - 같은 오행, 다른 음양
- [ ] **식신(食神)** - 내가 생하는 오행, 같은 음양
- [ ] **상관(傷官)** - 내가 생하는 오행, 다른 음양
- [ ] **편재(偏財)** - 내가 극하는 오행, 같은 음양
- [ ] **정재(正財)** - 내가 극하는 오행, 다른 음양
- [ ] **편관(偏官/七殺)** - 나를 극하는 오행, 같은 음양
- [ ] **정관(正官)** - 나를 극하는 오행, 다른 음양
- [ ] **편인(偏印)** - 나를 생하는 오행, 같은 음양
- [ ] **정인(正印)** - 나를 생하는 오행, 다른 음양

### 9.3 지장간(支藏干) - 우선순위 3

> 지지 속에 숨어있는 천간 (여기, 중기, 본기)

| 지지 | 여기 | 중기 | 본기 |
|------|------|------|------|
| 자(子) | - | - | 계(癸) |
| 축(丑) | 계(癸) | 신(辛) | 기(己) |
| 인(寅) | 무(戊) | 병(丙) | 갑(甲) |
| 묘(卯) | - | - | 을(乙) |
| 진(辰) | 을(乙) | 계(癸) | 무(戊) |
| 사(巳) | 무(戊) | 경(庚) | 병(丙) |
| 오(午) | - | 기(己) | 정(丁) |
| 미(未) | 정(丁) | 을(乙) | 기(己) |
| 신(申) | 무(戊) | 임(壬) | 경(庚) |
| 유(酉) | - | - | 신(辛) |
| 술(戌) | 신(辛) | 정(丁) | 무(戊) |
| 해(亥) | - | 갑(甲) | 임(壬) |

- [ ] 지장간 테이블 구현 (이미 `jijanggan_table.dart` 있음)
- [ ] 지장간 기반 십성 계산
- [ ] UI에 지장간 표시

### 9.4 12운성(十二運星) - 우선순위 4

> 일간의 12단계 생명 주기

- [ ] 장생(長生) - 태어남
- [ ] 목욕(沐浴) - 씻김
- [ ] 관대(冠帶) - 성인
- [ ] 건록(建祿) - 독립
- [ ] 제왕(帝旺) - 전성기
- [ ] 쇠(衰) - 쇠퇴
- [ ] 병(病) - 병듦
- [ ] 사(死) - 죽음
- [ ] 묘(墓) - 무덤
- [ ] 절(絶) - 끊어짐
- [ ] 태(胎) - 잉태
- [ ] 양(養) - 양육

### 9.5 12신살(十二神殺) - 우선순위 5

> 길흉을 나타내는 신살

- [ ] 겁살(劫殺)
- [ ] 재살(災殺)
- [ ] 천살(天殺)
- [ ] 지살(地殺)
- [ ] 년살(年殺)
- [ ] 월살(月殺)
- [ ] 망신살(亡身殺)
- [ ] 장성살(將星殺)
- [ ] 반안살(攀鞍殺)
- [ ] 역마살(驛馬殺)
- [ ] 육해살(六害殺)
- [ ] 화개살(華蓋殺)

### 9.6 공망(空亡) - 우선순위 6

> 60갑자에서 빠진 지지 (순중공망)

- [ ] 일주 기준 공망 계산
- [ ] 공망 지지 표시
- [ ] 공망의 의미 설명

### 9.7 구현 계획

#### Phase 9-A: 데이터 구조 (Constants) ✅ 완료 (2025-12-08)
```
data/constants/
├── hapchung_relations.dart    # ✅ 합충형파해 관계 테이블
├── sipsin_relations.dart      # ✅ 십성 관계 (기존)
├── jijanggan_table.dart       # ✅ 지장간 (확장 완료)
├── twelve_unsung.dart         # ✅ 12운성 테이블
├── twelve_sinsal.dart         # ✅ 12신살 테이블
└── gongmang_table.dart        # ✅ 공망 테이블
```

#### Phase 9-B: 도메인 서비스 ✅ 완료 (2025-12-08)
```
domain/services/
├── hapchung_service.dart       # ✅ 합충형파해 분석 서비스
├── unsung_service.dart         # ✅ 12운성 계산 서비스
├── gongmang_service.dart       # ✅ 공망 계산 서비스
├── jijanggan_service.dart      # ✅ 지장간+십성 분석 서비스
├── twelve_sinsal_service.dart  # ✅ 12신살 전용 서비스
└── sinsal_service.dart         # ✅ 기존 신살 탐지 서비스
```

#### Phase 9-C: UI 컴포넌트
```
presentation/widgets/
├── hapchung_tab.dart          # 합충 탭 (천간합, 지지육합 등)
├── sipsung_display.dart       # 십성 표시
├── jijanggan_display.dart     # 지장간 표시
├── unsung_display.dart        # 12운성 표시
├── sinsal_display.dart        # 12신살 표시
└── saju_detail_tabs.dart      # 탭 컨테이너 (포스텔러 스타일)
```

### 9.8 레퍼런스 (포스텔러 UI)

```
┌─────────────────────────────────────────────────────┐
│  사주 풀이 자세히 보기                           ∧  │
├─────────────────────────────────────────────────────┤
│ [궁성] [천간합] [지지육합] [지지삼합] [지지방합]    │
│ [천간충] [지지충] [공망] [형] [파] [해] [원진]      │
├─────────────────────────────────────────────────────┤
│        생시      생일      생월      생년          │
│        말년운    중년운    청년운    초년운        │
│        자녀운    정체성    부모      조상          │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐                       │
│ │ 경庚│ │ 을乙│ │ 신辛│ │ 정丁│  천간              │
│ │ 아들│ │ 자신│ │ 부친│ │ 조부│                    │
│ │ 정관│ │ 비견│ │ 편관│ │ 식신│  십성              │
│ └────┘ └────┘ └────┘ └────┘                       │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐                       │
│ │ 진辰│ │ 해亥│ │ 해亥│ │ 축丑│  지지              │
│ │ 딸  │ │배우자│ │ 모친│ │ 조모│                    │
│ │ 정재│ │ 정인│ │ 정인│ │ 편재│  십성              │
│ └────┘ └────┘ └────┘ └────┘                       │
│ 지장간  을계무   무갑임   무갑임   계신기            │
│ 12운성  관대     사       사       쇠               │
│ 12신살  천살     역마살   역마살   월살             │
└─────────────────────────────────────────────────────┘
```

---

## 메모

- Supabase는 사용자가 직접 설정 예정
- 프론트엔드만 집중해서 구현
- 로컬 저장(Hive) 우선, Supabase 연동은 나중에

### 만세력 정확도 연구 (2025-12-02)

**핵심 보정 요소:**
1. **진태양시 보정 (지역 시간차)**
   - 한국 표준시: 동경 135도 기준
   - 실제 한반도: 약 127도 → ~32분 차이
   - 예: 창원 = -26분, 서울 = -30분 보정

2. **절입시간 (24절기 정밀 계산)**
   - 월주 변경 시점 = 절기 시작 시간
   - 한국천문연구원 API 활용 가능

3. **서머타임 (일광절약시간제)**
   - 1948-1951, 1955-1960, 1987-1988 적용 기간
   - 해당 기간 출생자 +1시간 보정 필요

4. **야자시/조자시 처리**
   - 23:00-01:00 자시(子時) 구간 처리 방식
   - 야자시: 23:00-24:00 당일로 계산
   - 조자시: 00:00-01:00 익일로 계산

**참고 자료:**
- 한국천문연구원 음양력 API
- Inflearn 만세력 강의
- GitHub: bikul-manseryeok 프로젝트
- 포스텔러 만세력 2.2 (레퍼런스 앱)

---

## ✅ 완료된 작업 (2025-12-06)

### 일주(日柱) 계산 오류 수정 ✅

**문제 상황:**
- 1997-11-29 08:03 부산: 을유(乙酉) → **을해(乙亥)** 수정 필요
- 1990-02-15 09:30 서울: 신유(辛酉) → **신해(辛亥)** 수정 필요

**해결:**
- `saju_calculation_service.dart` baseDayIndex = **10** 확정
- 포스텔러 검증 완료 (두 케이스 모두 통과)

**포스텔러 검증 결과:**

| 날짜 | 시주 | 일주 | 월주 | 년주 | 상태 |
|------|------|------|------|------|------|
| 1990-02-15 서울 | 임진 | **신해** | 무인 | 경오 | ✅ |
| 1997-11-29 부산 | 경진 | **을해** | 신해 | 정축 | ✅ |

**테스트 결과:** `flutter test test/saju_logic_test.dart` → All tests passed!

### 만세력 UI 한자 표시 ✅

한자 표시 기능이 이미 구현되어 있음 확인:
- `Pillar.hanja` 게터
- `SajuChart.fullSajuHanja` 게터
- `PillarColumnWidget` - 한자 박스 표시 (28px)
- `SajuChartScreen` - 사주팔자 한자 표시

### SajuDetailSheet "자세히 보기" 에러 수정 ✅

**문제:** "자세히 보기" 버튼 클릭 시 "Unexpected null value" 에러 발생

**수정 내용 (3개 파일):**

1. **`saju_mini_card.dart`** - Provider container를 bottom sheet에 전달
   ```dart
   final container = ProviderScope.containerOf(context);
   showModalBottomSheet(
     builder: (sheetContext) => UncontrolledProviderScope(
       container: container,
       child: const SajuDetailSheet(),
     ),
   );
   ```

2. **`saju_detail_sheet.dart`** - ShadSheet → 네이티브 Flutter Container로 변경
   - shadcn_ui 의존성 제거
   - 안정적인 네이티브 Flutter 위젯으로 구현

3. **`yongsin_service.dart`** - null-safe 처리 추가
   ```dart
   final dayOheng = cheonganToOheng[dayMaster];
   if (dayOheng == null) {
     return YongSinResult(...); // 기본값 반환
   }
   ```

**결과:** ✅ "자세히 보기" 바텀시트 정상 동작 (만세력 + 오행 분포 표시)

---

### ✅ 해결됨: SajuDetailSheet 한자 표시 추가

**수정 내용:** `PillarDisplay` 위젯에 한자 표시 기능 추가

**수정 파일:** `frontend/lib/features/saju_chart/presentation/widgets/pillar_display.dart`

**변경 사항:**
- `showHanja` 파라미터 추가 (기본값: true)
- 한자를 큰 글씨(28px+)로, 한글을 작은 글씨로 표시
- 오행별 색상 적용 (목-초록, 화-빨강, 토-주황, 금-금색, 수-파랑)
- `cheongan_jiji.dart`의 한자 매핑 테이블 활용

---

### ✅ 완료: 천간지지 JSON 기반 리팩토링

**목적:** 데이터 정확도 향상, 타입 안전성, 확장성 개선

**생성/수정 파일:**

1. **`assets/data/cheongan_jiji.json`** - 통합 JSON 데이터
2. **`data/models/cheongan_model.dart`** - 천간 모델 클래스
3. **`data/models/jiji_model.dart`** - 지지 모델 클래스
4. **`data/models/oheng_model.dart`** - 오행 모델 클래스
5. **`data/constants/cheongan_jiji.dart`** - JSON 파싱 + 하위호환 API

**데이터 구조:**
```json
{
  "cheongan": [
    {"hangul": "갑", "hanja": "甲", "oheng": "목", "eum_yang": "양", "order": 0}
  ],
  "jiji": [
    {"hangul": "자", "hanja": "子", "oheng": "수", "animal": "쥐",
     "month": 11, "hour_start": 23, "hour_end": 1, "order": 0}
  ],
  "oheng": [
    {"name": "목", "hanja": "木", "color": "#4CAF50", "season": "봄", "direction": "동"}
  ]
}
```

**신규 기능:**
- `CheonganJijiData.instance` - 싱글톤 데이터 저장소
- `getCheonganByHanja()`, `getJijiByHanja()` - 한자→한글 역조회
- `getJijiByHour()` - 시간대로 지지 조회
- `cheonganEumYang`, `jijiEumYang` - 음양 매핑
- `ohengHanja`, `ohengColor` - 오행 한자/색상

**하위 호환성:** 기존 API 모두 유지
- `cheongan`, `jiji` (List)
- `cheonganHanja`, `jijiHanja`, `jijiAnimal` (Map)
- `cheonganOheng`, `jijiOheng` (Map)
- `getOheng()` 함수

**테스트 결과:** ✅ 2개 테스트 통과 (1990-02-15, 1997-11-29)

---

## ✅ 완료된 작업 (2025-12-08)

### Phase 9-B: 만세력 고급 분석 서비스 ✅ 완료

**생성된 서비스 파일:**

1. **`unsung_service.dart`** - 12운성 계산 서비스
   - `UnsungService.analyzeFromChart()` - 사주 차트 기반 분석
   - `UnsungService.analyze()` - 개별 파라미터 분석
   - `UnsungResult` - 단일 궁성 12운성 결과
   - `UnsungAnalysisResult` - 사주 전체 12운성 분석 결과
   - 건록지, 제왕지, 장생지, 묘지 조회 기능
   - 12운성별 상세 해석 제공

2. **`gongmang_service.dart`** - 공망 계산 서비스
   - `GongmangService.analyzeFromChart()` - 사주 차트 기반 분석
   - `GongmangService.analyze()` - 개별 파라미터 분석
   - `GongmangResult` - 단일 궁성 공망 결과
   - `GongmangAnalysisResult` - 사주 전체 공망 분석 결과
   - 진공/반공/탈공 유형 판단
   - 궁성별 공망 해석 (년지/월지/일지/시지)

3. **`jijanggan_service.dart`** - 지장간+십성 분석 서비스
   - `JiJangGanService.analyzeFromChart()` - 사주 차트 기반 분석
   - `JiJangGanService.analyze()` - 개별 파라미터 분석
   - `JiJangGanSipSin` - 지장간 천간의 십성 정보
   - `JiJangGanResult` - 단일 궁성 지장간 결과
   - `JiJangGanAnalysisResult` - 사주 전체 지장간 분석 결과
   - 정기/중기/여기 구분, 십성 분포 분석
   - 십성별 카테고리 분류 (비겁/식상/재성/관성/인성)

4. **`twelve_sinsal_service.dart`** - 12신살 전용 서비스
   - `TwelveSinsalService.analyzeFromChart()` - 사주 차트 기반 분석
   - `TwelveSinsalService.analyze()` - 개별 파라미터 분석
   - `TwelveSinsalResult` - 단일 궁성 12신살 결과
   - `TwelveSinsalAnalysisResult` - 사주 전체 12신살 분석 결과
   - 역마살, 도화살, 화개살, 장성살 조회 기능
   - 특수 신살 탐지 (양인살, 천을귀인)
   - 12신살별 상세 해석 제공

**업데이트된 파일:**

- **`saju_chart.dart`** - Phase 9 서비스 export 추가
  - `hapchung_service.dart` (합충형파해)
  - `unsung_service.dart` (12운성)
  - `gongmang_service.dart` (공망)
  - `jijanggan_service.dart` (지장간+십성)
  - `twelve_sinsal_service.dart` (12신살)

**서비스 아키텍처 패턴:**
- 모든 서비스는 `static` 메서드로 구현
- `analyzeFromChart()` - SajuChart 객체 직접 분석
- `analyze()` - 개별 파라미터로 분석 (유연성)
- Result 모델에 해석 메서드 포함

---

### Phase 9-A: 만세력 고급 분석 데이터 구조 ✅ 완료

**생성된 파일:**

1. **`hapchung_relations.dart`** - 합충형파해 관계 테이블
   - 천간합 (5합): 갑기합토, 을경합금, 병신합수, 정임합목, 무계합화
   - 천간충 (4충): 갑경충, 을신충, 병임충, 정계충
   - 지지육합 (6합): 자축합토, 인해합목, 묘술합화, 진유합금, 사신합수, 오미합토
   - 지지삼합 (4국): 인오술화국, 사유축금국, 신자진수국, 해묘미목국
   - 지지방합 (4방): 인묘진동방목, 사오미남방화, 신유술서방금, 해자축북방수
   - 지지충 (6충): 자오충, 축미충, 인신충, 묘유충, 진술충, 사해충
   - 지지형 (3형): 무은지형(인사신), 지세지형(축술미), 자형
   - 지지파 (6파)
   - 지지해 (6해)
   - 원진 (6원진)
   - 통합 분석 함수: `analyzeJijiRelations()`, `analyzeCheonganRelations()`

2. **`twelve_unsung.dart`** - 12운성 테이블
   - 12운성: 장생, 목욕, 관대, 건록, 제왕, 쇠, 병, 사, 묘, 절, 태, 양
   - 양간/음간별 장생 지지 테이블
   - `calculateTwelveUnsung()` - 12운성 계산
   - 운성별 강도(strength), 길흉(fortuneType) 속성
   - 운성별 해석 제공

3. **`gongmang_table.dart`** - 공망 테이블
   - 6순 공망: 갑자순(술해), 갑술순(신유), 갑신순(오미), 갑오순(진사), 갑진순(인묘), 갑인순(자축)
   - `getGongmangByGapja()` - 갑자로 공망 조회
   - `getDayGongmang()` - 일주 기준 공망 지지
   - `analyzeAllGongmang()` - 사주 전체 공망 분석
   - 궁성별 공망 해석 (년지/월지/시지)

4. **`twelve_sinsal.dart`** - 12신살 테이블
   - 12신살: 겁살, 재살, 천살, 지살, 연살(도화), 월살, 망신, 장성, 반안, 역마, 육해, 화개
   - 삼합 기준 12신살 배치
   - 특수 신살: 괴강살, 양인살, 천을귀인, 백호살, 천라지망, 문창귀인, 홍염살
   - `calculateSinsal()` - 12신살 계산
   - `analyzeSajuSinsal()` - 사주 전체 신살 분석

5. **`jijanggan_table.dart`** - 지장간 확장
   - `JiJangGanDetail` 클래스 (한자, 오행 포함)
   - `getJiJangGanDetail()` - 상세 지장간 조회
   - `JiJangGanTypeExtension` - korean, hanja, strengthRank 속성

**생성된 서비스:**

1. **`hapchung_service.dart`** - 합충형파해 분석 서비스
   - `HapchungService.analyzeSaju()` - 사주 전체 분석
   - `HapchungAnalysisResult` - 분석 결과 모델
   - `HapchungInterpreter` - 해석 유틸리티

### Flutter 경로 (로컬 환경)

- **Jaehyeon PC:** `C:\Users\SOGANG\flutter\flutter\bin\flutter.bat`
- **협업자(DK) PC:** `D:\development\flutter\bin\flutter.bat`

---

## ✅ 완료된 작업 (2025-12-12)

### Phase 10-A: RuleEngine 기반 구축 ✅ 완료

**생성된 파일 (9개):**

#### Domain Layer - Entities
1. **`rule.dart`** - Rule 인터페이스 + 타입 정의
   - `RuleType` enum: sinsal, hapchung, hyungpahae, sipsin, unsung, jijanggan, gongmang, gyeokguk, daeun
   - `FortuneType` enum: 길/흉/중
   - `Rule` 추상 인터페이스
   - `RuleMatchResult` 매칭 결과 클래스
   - `RuleSetMeta` 룰셋 메타데이터

2. **`rule_condition.dart`** - 조건 타입 + 연산자 정의
   - `ConditionOp` enum: eq, ne, in, notIn, and, or, not, samhapMatch, yukhapMatch 등
   - `ConditionField` enum: dayGan, dayJi, jiAny, ganAny 등 사주 필드
   - `RuleCondition` sealed class (SimpleCondition, CompositeCondition)

3. **`saju_context.dart`** - 사주 컨텍스트 래퍼
   - `SajuChart` 감싸서 RuleEngine 필드 접근 제공
   - `getFieldValue()`: ConditionField로 값 조회
   - 오행, 음양 파생 데이터 자동 계산

4. **`compiled_rules.dart`** - 컴파일된 룰 컨테이너
   - `CompiledRules`: 파싱된 룰셋 저장
   - `CompiledRulesRegistry`: 여러 RuleType 통합 관리

#### Domain Layer - Repository
5. **`rule_repository.dart`** - Repository 추상 인터페이스
   - `loadFromAsset()`, `loadFromRemote()`, `loadFromString()`
   - 캐시 관리: `getCached()`, `setCache()`, `invalidateCache()`
   - 버전 관리: `getLocalVersion()`, `needsUpdate()`
   - 예외 클래스: `RuleLoadException`, `RuleValidationException`

#### Domain Layer - Services
6. **`rule_engine.dart`** - 핵심 매칭 엔진
   - `RuleEngine.matchAll()`: 전체 룰 매칭
   - `RuleEngine.match()`: 단일 룰 매칭
   - `RuleEngine.evaluate()`: 조건 평가
   - 특수 연산자 지원: 삼합, 육합, 충, 형 매칭

7. **`rule_validator.dart`** - 룰 검증기
   - `validateRuleSet()`: 전체 룰셋 검증
   - `validateRule()`: 개별 룰 검증
   - `validateCondition()`: 조건 구조 검증
   - `ValidationResult`, `ValidationError` 결과 클래스

#### Data Layer - Models
8. **`rule_models.dart`** - JSON 파싱 모델
   - `RuleModel`: Rule 인터페이스 구현체
   - `RuleSetParseResult`: 파싱 결과 컨테이너
   - `RuleParser`: JSON 파싱 헬퍼

#### Data Layer - Repository
9. **`rule_repository_impl.dart`** - Repository 구현체
   - Asset 로드 구현 (MVP)
   - 메모리 캐시 관리
   - Remote 로드는 Phase 10-D 예정

**아키텍처:**
```
[JSON 룰 파일] → [RuleRepository] → [RuleEngine] → [기존 서비스]
 (assets)        load + validate    matchAll()     사용
                 + compile
```

**MVP 원칙 적용:**
- RuleValidator: 필수 필드 체크만 (스키마 검증은 추후)
- CompiledRules: 인덱싱 없이 단순 리스트 (성능 이슈 시 추가)
- 하위 호환성: 기존 하드코딩 서비스 유지

---

## 서브 에이전트 (.claude/JH_Agent/) - A2A Orchestration

### 아키텍처
```
Main Claude → [Orchestrator] → Pipeline → [Quality Gate] → 완료
```

### 에이전트 목록

| 번호 | 에이전트 | 역할 | 유형 |
|------|----------|------|------|
| **00** | **orchestrator** | 작업 분석 & 파이프라인 구성 | **진입점** |
| **00** | **widget_tree_guard** | 위젯 최적화 검증 | **품질 게이트** |
| 01 | feature_builder | Feature 폴더 구조 생성 | Builder |
| 02 | widget_composer | 화면→작은 위젯 분해 | Builder |
| 03 | provider_builder | Riverpod Provider 생성 | Builder |
| 04 | model_generator | Entity/Model 생성 | Builder |
| 05 | router_setup | go_router 설정 | Config |
| 06 | local_storage | Hive 저장소 설정 | Config |
| 07 | task_tracker | TASKS.md 관리 | Tracker |
| **08** | **shadcn_ui_builder** | shadcn_ui 모던 UI | **UI 필수** |
| **09** | **manseryeok_calculator** | 만세력 계산 로직 | **Domain 전문** |

### 호출 방식
```
# Orchestrator 자동 파이프라인 (권장)
Task 도구:
- prompt: "[Orchestrator] Profile Feature 구현"

# 개별 에이전트 직접 호출
Task 도구:
- prompt: "[09_manseryeok_calculator] 사주 계산 로직 구현"
```

### 필수 규칙
- **모든 위젯 코드 작성 시 00_widget_tree_guard 검증 필수**
- const 생성자/인스턴스화
- ListView.builder 사용
- 위젯 100줄 이하
- setState 범위 최소화
