# 만톡 - 구현 작업 목록

> Main Claude 컨텍스트 유지용 작업 노트
> 작업 브랜치: Jaehyeon(Test)
> 백엔드(Supabase): 사용자가 직접 처리
> Flutter 경로: C:\Users\SOGANG\flutter\flutter\bin\flutter.bat
>
> **A2A 협업**: Claude 4.5 Opus + Gemini 3 Pro High (수동 오케스트레이션)
> **태그 규칙**: 작업자 표시 `[Claude]` / `[Gemini]`

---

## 현재 상태

| 항목 | 상태 | 작업자 |
|------|------|--------|
| 기획 문서 | ✅ 완료 | - |
| CLAUDE.md | ✅ 완료 | - |
| JH_Agent (서브에이전트) | ✅ 완료 (10개) | - |
| Flutter 프로젝트 | ✅ 기반 설정 완료 | [Claude] |
| 의존성 | ✅ 설치 완료 | [Claude] |
| 폴더 구조 | ✅ 구현 완료 | [Claude] |
| Phase 1 | ✅ **완료** | [Claude] |
| Phase 4 (Profile) | ✅ **완료** | [Claude] |
| Phase 4.5 (UI 개선) | ✅ **완료** | [Claude] |
| Phase 8 (만세력 로직) | ✅ **완료** (화면 포함) | [Claude] |
| Phase 5 (인연) | ✅ **완료** | [Gemini] |
| Phase 6 (Context Chat) | ✅ **완료** | [Gemini] |
| Phase 7 (앱 완성도) | ✅ **완료** | [Claude/Gemini] |

---

## Phase 5: 인연 (Relationships) - 지인 관리 👥 [Gemini]
> **목표**: 가족, 친구, 연인 등 지인들의 사주를 카테고리별로 관리

### 5.1 Domain Layer
- [x] entities/relationship_type.dart (enum)
- [x] entities/saju_profile.dart (relationType, memo 필드 추가)

### 5.2 Data Layer
- [x] models/saju_profile_model.dart (필드 업데이트)
- [x] datasources/profile_local_datasource.dart (getAllProfiles 추가)
- [x] repositories/profile_repository.dart (getAllProfiles 추가)

### 5.3 Presentation Layer
- [x] screens/relationship_list_screen.dart (인연 탭 메인)
- [x] widgets/relationship_category_section.dart
- [x] widgets/add_profile_sheet.dart (ProfileEditScreen으로 대체)
- [x] screens/home_screen.dart (MainScaffold 및 기본 홈)

---

## Phase 6: 컨텍스트 사주 챗봇 (Advanced Chat) 💬 [Gemini]
> **목표**: 나 + 상대방의 데이터를 기반으로 한 심층 상담

### 6.1 Chat Core
- [x] domain/entities/chat_session.dart (targetProfileId 추가)
- [x] presentation/screens/saju_chat_screen.dart (대상 선택 UI)

### 6.2 AI Integration
- [x] system_prompt_v2 (관계 분석 프롬프트)
- [x] edge_functions/saju-chat (멀티 프로필 지원)

---

## Phase 7: 앱 완성도 (Polishing) ✨ [Claude/Gemini] - ✅ 완료
> **목표**: 스토어 출시 수준의 UI/UX 완성

### 7.1 Main Tab ✅ [Claude]
- [x] screens/home_screen.dart (대시보드 + 프로필 연동) (2025-12-04)
- [x] widgets/daily_fortune_card.dart (2025-12-04)

### 7.2 Settings & Legal ✅ [Claude]
- [x] screens/settings_screen.dart (2025-12-04)
- [x] widgets/legal_notice_dialog.dart (2025-12-04)

### 7.3 빌드 에러 수정 ✅ [Claude]
- [x] main_scaffold.dart (ShadBottomNavigationBar → Material BottomNavigationBar)
- [x] relationship_list_screen.dart (prefix → leading)
- [x] relationship_type_dropdown.dart (selectedOptionBuilder 추가)
- [x] saju_chat_screen.dart (_selectedTargetProfile 선언, ShadSheet/ShadButton 수정)
- [x] chat_bubble.dart (AppColors import 경로)
- [x] chat_input_field.dart (ShadButton.icon → ShadButton)
- [x] chat_*_model.g.dart (Hive TypeAdapter 수동 생성)

---

## ✅ Phase 4.5 - UI 개선 & 만세력 화면 (완료) [Claude]

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

## Phase 1: 프로젝트 기반 설정 ✅ 완료 [Claude]

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
├── constants/ ✅
├── theme/ ✅
├── utils/
├── errors/
├── features/
├── splash/ ✅
├── onboarding/ ✅
├── profile/ ✅ (21개 파일)
├── saju_chart/ ✅ (19개 파일 - 로직만)
├── saju_chat/ ✅ (placeholder)
├── history/ ✅
└── settings/ ✅
├── shared/
└── router/ ✅
```

### 1.4 기본 설정 파일 ✅
- [x] analysis_options.yaml (린트 규칙)
- [x] app.dart (MaterialApp 설정)
- [x] router/routes.dart (라우트 상수)
- [x] router/app_router.dart (go_router 설정)

---

## Phase 4: Feature - Profile (P0) ✅ 완료 [Claude]

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
- [x] `dart run build_runner build` 실행
- [x] 빌드 테스트

---

## Phase 8: Saju Chart (만세력) ✅ 완료 [Claude]

> 2025-12-02: 기본 로직 구현 (19개 파일)
> 2025-12-05: **포스텔러 수준 상세 분석 기능 추가** (24개 파일 추가, 총 43개)

### 8.1 Constants ✅
- [x] data/constants/cheongan_jiji.dart - 천간(10), 지지(12), 오행
- [x] data/constants/gapja_60.dart - 60갑자
- [x] data/constants/solar_term_table.dart - 절기 시각 (2024-2025)
- [x] data/constants/dst_periods.dart - 서머타임 기간
- [x] **data/constants/jijanggan_table.dart** - 지장간 테이블 🆕
- [x] **data/constants/sipsin_relations.dart** - 십신 관계 테이블 🆕
- [x] **data/constants/lunar_data/** - 음양력 변환 테이블 (1900-2100년) 🆕
  - lunar_year_data.dart
  - lunar_table_1900_1949.dart
  - lunar_table_1950_1999.dart
  - lunar_table_2000_2050.dart
  - lunar_table_2051_2100.dart
  - lunar_table.dart (통합)

### 8.2 Domain Entities ✅
- [x] domain/entities/pillar.dart - 기둥 (천간+지지)
- [x] domain/entities/saju_chart.dart - 사주 차트
- [x] domain/entities/lunar_date.dart - 음력 날짜
- [x] domain/entities/solar_term.dart - 24절기 enum
- [x] **domain/entities/day_strength.dart** - 일간 강약 (신강/신약) 🆕
- [x] **domain/entities/gyeokguk.dart** - 격국 (14종) 🆕
- [x] **domain/entities/sinsal.dart** - 신살 (14종) 🆕
- [x] **domain/entities/yongsin.dart** - 용신 🆕
- [x] **domain/entities/daeun.dart** - 대운/세운 🆕
- [x] **domain/entities/saju_analysis.dart** - 종합 분석 결과 🆕

### 8.3 Domain Services ✅
- [x] domain/services/saju_calculation_service.dart - 기본 사주 계산
- [x] domain/services/lunar_solar_converter.dart - 음양력 변환 (**실제 구현 완료**)
- [x] domain/services/solar_term_service.dart - 절입시간
- [x] domain/services/true_solar_time_service.dart - 진태양시 (25개 도시)
- [x] domain/services/dst_service.dart - 서머타임
- [x] domain/services/jasi_service.dart - 야자시/조자시
- [x] **domain/services/day_strength_service.dart** - 일간 강약 분석 🆕
- [x] **domain/services/gyeokguk_service.dart** - 격국 판정 🆕
- [x] **domain/services/sinsal_service.dart** - 신살 탐지 🆕
- [x] **domain/services/yongsin_service.dart** - 용신 선정 🆕
- [x] **domain/services/daeun_service.dart** - 대운/세운 계산 🆕
- [x] **domain/services/saju_analysis_service.dart** - 종합 분석 통합 🆕

### 8.4 Data Models ✅
- [x] data/models/pillar_model.dart - JSON 직렬화
- [x] data/models/saju_chart_model.dart - JSON 직렬화

### 8.5 Presentation ✅
- [x] providers/saju_chart_provider.dart
- [x] screens/saju_chart_screen.dart
- [x] widgets/pillar_column_widget.dart
- [x] widgets/saju_info_header.dart

### 8.6 구현된 분석 기능 (포스텔러 수준) 🆕
| 기능 | 설명 | 상태 |
|------|------|------|
| 음양력 변환 | 1900-2100년 완전 지원 | ✅ |
| 지장간 | 12지지별 숨은 천간 + 세력 비율 | ✅ |
| 십신(십성) | 일간 기준 오행 관계 분석 | ✅ |
| 일간 강약 | 신강/신약/중화 5단계 판정 | ✅ |
| 격국 | 14종 (기본 10 + 특수 3 + 중화) | ✅ |
| 신살 | 14종 (천을귀인, 도화살, 역마 등) | ✅ |
| 용신 | 억부법 기반 오행 선정 | ✅ |
| 대운 | 10년 주기 운 흐름 | ✅ |
| 세운 | 1년 단위 운 | ✅ |

### 8.7 다음 단계 (TODO)
- [ ] **MenuScreen의 SajuTable을 실제 만세력 로직으로 연결** ⚠️ 현재 Mock 데이터 사용 중
- [ ] UI에 상세 분석 결과 표시 (십신, 지장간, 용신 등)
- [ ] 대운/세운 화면 구현
- [ ] 포스텔러 결과와 비교 검증

### 8.8 발견 사항 (2025-12-06)
| 화면 | 데이터 소스 | 상태 |
|------|-------------|------|
| `MenuScreen > SajuTable` | `MockFortuneData` (하드코딩) | ⚠️ Mock 사용 |
| `SajuChartScreen` | `SajuCalculationService` (실제 로직) | ✅ 실제 만세력 로직 |

**문제**: `menu/presentation/widgets/saju_table.dart`가 `MockFortuneData.sajuPillarsDetailed`를 사용하여 하드코딩된 데이터(己亥, 辛酉, 戊寅, 庚辰)를 표시 중. 사용자 프로필과 연동 필요.

---

## 진행 기록

| 날짜 | 작업 내용 | 작업자 | 상태 |
|------|-----------|--------|------|
| 2025-12-01 | 프로젝트 시작, 기획 문서 완료 | - | 완료 |
| 2025-12-02 | Phase 1 완료: 의존성, 폴더구조, 라우터, 테마 | [Claude] | 완료 |
| 2025-12-02 | Phase 8 기본 완료: 만세력 계산 로직 19개 파일 | [Claude] | 완료 |
| 2025-12-02 | Phase 4 완료: Profile Feature 21개 파일 | [Claude] | 완료 |
| 2025-12-02 | Flutter 빌드 오류 수정 (const→final, shadcn API) | [Claude] | 완료 |
| 2025-12-02 | app.dart를 ShadApp.router로 변경 | [Claude] | 완료 |
| 2025-12-02 | 웹 테스트 완료, UI 개선점 발견 | [Claude] | 완료 |
| 2025-12-02 | **Phase 4.5 완료**: 프로필 UI 개선 + 만세력 화면 | [Claude] | 완료 |
| 2025-12-04 | Phase 5 시작: Saju Chat AI 상담 | [Gemini] | 진행중 |
| 2025-12-04 | **Phase 5 완료**: 인연 관리 UI 및 데이터 연동 | [Gemini] | 완료 |
| 2025-12-04 | Phase 6 시작: Context Saju Chatbot (대상 선택 및 상담) | [Gemini] | 진행중 |
| 2025-12-04 | **Phase 7.2 완료**: Settings & Legal (settings_screen, legal_notice_dialog) | [Claude] | 완료 |
| 2025-12-04 | **Phase 6 완료**: Context Saju Chatbot (UI, Entity, Edge Function) | [Gemini] | 완료 |
| 2025-12-04 | **Phase 7 완료**: home_screen 개선, daily_fortune_card, 빌드 에러 87개 수정 | [Claude] | 완료 |
| 2025-12-04 | **Merge 후 정리**: Gemini 코드 merge 후 빌드 에러 수정 | [Claude] | 완료 |
| 2025-12-05 | **Phase 8 확장**: 만세력 로직 포스텔러 수준 구현 (24개 파일 추가) | [Claude] | 완료 |
| 2025-12-06 | **발견**: MenuScreen SajuTable이 Mock 데이터 사용 중 (실제 로직 미연결) | [Claude] | 확인 |

---

## Phase 9: Merge 후 정리 ✅ [Claude]
> **목표**: Gemini 협업자 코드 merge 후 빌드 가능하게 정리

### 9.1 수정된 파일
| 파일 | 변경 내용 | 상태 |
|------|----------|------|
| `routes.dart` | 누락 라우트 추가 (home, sajuChart, relationshipList) | ✅ |
| `gemini_service.dart` | flutter_dotenv → String.fromEnvironment | ✅ |
| `chat_message_model.dart` | 새 Entity 구조에 맞춤 (status 사용) | ✅ |
| `chat_session_model.dart` | 새 Entity 구조에 맞춤 (chatType, messages) | ✅ |
| `chat_local_datasource.dart` | lastMessageAt → updatedAt ?? createdAt | ✅ |
| `chat_bubble.dart` | import 수정, AppColors.textPrimary | ✅ |
| `gender_selector.dart` | AppStrings.gender, 상수 수정 | ✅ |
| `message_role.dart` | 삭제 (중복 - chat_message.dart에 정의됨) | ✅ |

### 9.2 백업된 파일 (MVP 미사용)
- `supabase_provider.dart.bak`
- `profile_remote_datasource.dart.bak`
- `profile_form_provider.dart.bak`
- `profile_list_screen.dart.bak`

### 9.3 결과
- ✅ flutter analyze 에러 0개
- ✅ Chrome에서 앱 정상 실행
