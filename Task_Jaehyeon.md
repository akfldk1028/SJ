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
| **다음 작업** | **Phase 6 (Splash/Onboarding)** |

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

### Flutter 경로 (로컬 환경)

- **Jaehyeon PC:** `C:\Users\SOGANG\flutter\flutter\bin\flutter.bat`
- **협업자(DK) PC:** `D:\development\flutter\bin\flutter.bat`

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
