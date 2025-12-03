# 만톡 - 구현 작업 목록

> Main Claude 컨텍스트 유지용 작업 노트
> 작업 브랜치: Jaehyeon(Test)
> 백엔드(Supabase): 사용자가 직접 처리
> Flutter 경로: C:\Users\SOGANG\flutter\flutter\bin\flutter.bat

---

## 현재 상태

| 항목 | 상태 |
|------|------|
| 기획 문서 | ✅ 완료 |
| CLAUDE.md | ✅ 완료 |
| JH_Agent (서브에이전트) | ✅ 완료 (10개) |
| Flutter 프로젝트 | ✅ 기반 설정 완료 |
| 의존성 | ✅ 설치 완료 |
| 폴더 구조 | ✅ 구현 완료 |
| Phase 1 | ✅ **완료** |
| Phase 4 (Profile) | ✅ **완료** |
| Phase 4.5 (UI 개선) | ✅ **완료** |
| Phase 8 (만세력 로직) | ✅ **완료** (화면 포함) |
| **다음 작업** | **Phase 5: Saju Chat (AI 사주 상담)** |

---

## ✅ Phase 4.5 - UI 개선 & 만세력 화면 (완료)

> 2025-12-02 완료

### 완료된 작업

| 파일 | 변경 내용 | 상태 |
|------|----------|------|
| `birth_date_picker.dart` | Calendar → 연/월/일 드롭다운 (1900~현재) | ✅ |
| `city_search_field.dart` | 부분 검색 + 별칭 매핑 | ✅ |
| `true_solar_time_service.dart` | 도시 별칭 + searchCities() 추가 | ✅ |
| **NEW** `saju_chart_screen.dart` | 포스텔러 스타일 만세력 결과 화면 | ✅ |
| **NEW** `saju_chart_provider.dart` | 만세력 상태 관리 | ✅ |
| **NEW** `pillar_column_widget.dart` | 년/월/일/시주 컬럼 (오행 색상) | ✅ |
| **NEW** `saju_info_header.dart` | 프로필 정보 헤더 (띠 이모지) | ✅ |
| `routes.dart` | /saju/chart 라우트 추가 | ✅ |
| `app_router.dart` | SajuChartScreen 라우트 등록 | ✅ |
| `profile_action_buttons.dart` | 저장 후 만세력 화면으로 이동 | ✅ |

### 수락 조건 체크
- [x] 생년월일 연/월/일 빠르게 선택 가능
- [x] "부산" 입력 시 "부산광역시" 자동 제안
- [x] 만세력 보러가기 클릭 → /saju/chart 화면 표시
- [x] 사주팔자 (년주/월주/일주/시주) 한자+한글 표시
- [x] 띠 (동물) 표시 + 이모지
- [x] 보정 시간 표시

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
- [x] shadcn_ui: ^0.39.14

### 1.2 dev_dependencies ✅
- [x] build_runner: ^2.4.9
- [x] riverpod_generator: ^2.3.11
- [x] freezed: ^2.4.7
- [x] json_serializable: ^6.7.1

### 1.3 폴더 구조 생성 ✅
```
lib/
├── main.dart ✅
├── app.dart ✅ (ShadApp.router로 변경됨)
├── core/
│   ├── constants/ ✅
│   ├── theme/ ✅
│   ├── utils/
│   └── errors/
├── features/
│   ├── splash/ ✅
│   ├── onboarding/ ✅
│   ├── profile/ ✅ (21개 파일)
│   ├── saju_chart/ ✅ (19개 파일 - 로직만)
│   ├── saju_chat/ ✅ (placeholder)
│   ├── history/ ✅
│   └── settings/ ✅
├── shared/
└── router/ ✅
```

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
- [x] widgets/* (11개)

---

## Phase 8: Saju Chart (만세력) ✅ 로직 완료

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

### 8.3 Domain Services ✅
- [x] domain/services/saju_calculation_service.dart - 통합 계산
- [x] domain/services/lunar_solar_converter.dart - 음양력 변환 (Stub)
- [x] domain/services/solar_term_service.dart - 절입시간
- [x] domain/services/true_solar_time_service.dart - 진태양시 (25개 도시)
- [x] domain/services/dst_service.dart - 서머타임
- [x] domain/services/jasi_service.dart - 야자시/조자시

### 8.4 Data Models ✅
- [x] data/models/pillar_model.dart - JSON 직렬화
- [x] data/models/saju_chart_model.dart - JSON 직렬화

### 8.5 Presentation ✅
- [x] providers/saju_chart_provider.dart
- [x] screens/saju_chart_screen.dart
- [x] widgets/pillar_column_widget.dart
- [x] widgets/saju_info_header.dart

---

## Phase 5: Feature - Saju Chat (P0) - 대기

> Phase 4.5 완료 후 진행

---

## 진행 기록

| 날짜 | 작업 내용 | 상태 |
|------|-----------|------|
| 2025-12-01 | 프로젝트 시작, 기획 문서 완료 | 완료 |
| 2025-12-02 | Phase 1 완료: 의존성, 폴더구조, 라우터, 테마 | 완료 |
| 2025-12-02 | Phase 8 기본 완료: 만세력 계산 로직 19개 파일 | 완료 |
| 2025-12-02 | Phase 4 완료: Profile Feature 21개 파일 | 완료 |
| 2025-12-02 | Flutter 빌드 오류 수정 (const→final, shadcn API) | 완료 |
| 2025-12-02 | app.dart를 ShadApp.router로 변경 | 완료 |
| 2025-12-02 | 웹 테스트 완료, UI 개선점 발견 | 완료 |
| 2025-12-02 | **Phase 4.5 완료**: 프로필 UI 개선 + 만세력 화면 | 완료 |

---

## 메모

### Flutter 실행 명령
```bash
cd e:\SJ\frontend
"C:\Users\SOGANG\flutter\flutter\bin\flutter.bat" pub get
"C:\Users\SOGANG\flutter\flutter\bin\dart.bat" run build_runner build --delete-conflicting-outputs
"C:\Users\SOGANG\flutter\flutter\bin\flutter.bat" run -d chrome --web-port=8080
```

### 수정된 주요 파일 (2025-12-02 빌드 오류 수정)
- `dst_periods.dart`: const → final (DateTime 불가)
- `solar_term_table.dart`: const → final
- `cheongan_jiji.dart`: oheng → cheonganOheng/jijiOheng 분리 (중복키 해결)
- `pillar.dart`: ganOheng/jiOheng getter 수정
- `profile_provider.dart`: ProfileRepositoryRef → Ref
- `app.dart`: MaterialApp.router → ShadApp.router

---

## 서브 에이전트 (.claude/JH_Agent/) - A2A Orchestration

| 번호 | 에이전트 | 역할 |
|------|----------|------|
| **00** | **orchestrator** | 작업 분석 & 파이프라인 구성 |
| **00** | **widget_tree_guard** | 위젯 최적화 검증 |
| 01 | feature_builder | Feature 폴더 구조 생성 |
| 02 | widget_composer | 화면→작은 위젯 분해 |
| 03 | provider_builder | Riverpod Provider 생성 |
| 04 | model_generator | Entity/Model 생성 |
| 05 | router_setup | go_router 설정 |
| 06 | local_storage | Hive 저장소 설정 |
| 07 | task_tracker | TASKS.md 관리 |
| **08** | **shadcn_ui_builder** | shadcn_ui 모던 UI |
| **09** | **manseryeok_calculator** | 만세력 계산 로직 |
