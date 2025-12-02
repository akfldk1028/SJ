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
| JH_Agent (서브에이전트) | ✅ 완료 (8개) |
| Flutter 프로젝트 | ✅ 기반 설정 완료 |
| 의존성 | ✅ 설치 완료 |
| 폴더 구조 | ✅ 구현 완료 |
| Phase 1 | ✅ **완료** |
| Phase 2 | ✅ **부분 완료** (상수/테마) |
| **다음 작업** | **Phase 2 나머지 → Phase 4 시작** |

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

## Phase 4: Feature - Profile (P0)

> 참조: docs/02_features/profile_input.md

### 4.1 Domain 레이어
- [ ] entities/saju_profile.dart
- [ ] entities/gender.dart (enum)
- [ ] repositories/profile_repository.dart (abstract)

### 4.2 Data 레이어
- [ ] models/saju_profile_model.dart (fromJson/toJson)
- [ ] datasources/profile_local_datasource.dart (Hive)
- [ ] repositories/profile_repository_impl.dart

### 4.3 Presentation 레이어
- [ ] providers/profile_provider.dart (Riverpod)
- [ ] providers/profile_form_provider.dart
- [ ] screens/profile_edit_screen.dart
- [ ] widgets/birth_date_picker.dart
- [ ] widgets/birth_time_picker.dart
- [ ] widgets/gender_selector.dart

### 4.4 수락 조건
- [ ] 프로필명 입력 (프리셋: 나, 연인, 가족)
- [ ] 성별 선택 (필수)
- [ ] 생년월일 선택 (필수)
- [ ] 음력/양력 선택
- [ ] 출생시간 입력 (선택)
- [ ] "시간 모름" 체크 기능
- [ ] 로컬 저장 (Hive)
- [ ] 유효성 검사

---

## Phase 5: Feature - Saju Chat (P0)

> 참조: docs/02_features/saju_chat.md

### 5.1 Domain 레이어
- [ ] entities/chat_session.dart
- [ ] entities/chat_message.dart
- [ ] entities/message_role.dart (enum)
- [ ] repositories/chat_repository.dart (abstract)

### 5.2 Data 레이어
- [ ] models/chat_session_model.dart
- [ ] models/chat_message_model.dart
- [ ] datasources/chat_local_datasource.dart (Hive 캐시)
- [ ] repositories/chat_repository_impl.dart

### 5.3 Presentation 레이어
- [ ] providers/chat_provider.dart
- [ ] providers/chat_state.dart (freezed)
- [ ] screens/saju_chat_screen.dart
- [ ] widgets/chat_bubble.dart
- [ ] widgets/chat_input_field.dart
- [ ] widgets/suggested_questions.dart
- [ ] widgets/saju_summary_sheet.dart

### 5.4 수락 조건
- [ ] AI 인사 메시지 표시
- [ ] 메시지 입력/전송
- [ ] 로딩 인디케이터
- [ ] 추천 질문 칩 표시
- [ ] 추천 질문 탭 → 자동 전송
- [ ] 프로필 전환 기능
- [ ] 사주 요약 바텀시트
- [ ] 면책 배너 표시
- [ ] 에러 처리 (재시도 버튼)

---

## Phase 6: Feature - Splash/Onboarding

### 6.1 Splash
- [ ] screens/splash_screen.dart
- [ ] 로컬 데이터 로드
- [ ] 온보딩/프로필 체크 후 라우팅

### 6.2 Onboarding
- [ ] screens/onboarding_screen.dart
- [ ] 서비스 소개 페이지
- [ ] "사주는 참고용입니다" 안내
- [ ] 온보딩 완료 플래그 저장

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

## Phase 8: Saju Chart (만세력)

> Supabase Edge Function 연동 후 진행

### 8.1 Domain
- [ ] entities/saju_chart.dart
- [ ] entities/pillar.dart
- [ ] entities/daewoon.dart

### 8.2 Data
- [ ] models/saju_chart_model.dart
- [ ] models/pillar_model.dart

### 8.3 Presentation
- [ ] providers/saju_chart_provider.dart
- [ ] widgets/saju_summary_card.dart
- [ ] widgets/pillar_display.dart

---

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

## 서브 에이전트 (.claude/JH_Agent/)

| 번호 | 에이전트 | 역할 |
|------|----------|------|
| **00** | **widget_tree_guard** | 위젯 최적화 검증 **(최우선)** |
| 01 | feature_builder | Feature 폴더 구조 생성 |
| 02 | widget_composer | 화면→작은 위젯 분해 |
| 03 | provider_builder | Riverpod Provider 생성 |
| 04 | model_generator | Entity/Model 생성 |
| 05 | router_setup | go_router 설정 |
| 06 | local_storage | Hive 저장소 설정 |
| 07 | task_tracker | TASKS.md 관리 |

### 필수 규칙
- **모든 위젯 코드 작성 시 00_widget_tree_guard 검증 필수**
- const 생성자/인스턴스화
- ListView.builder 사용
- 위젯 100줄 이하
- setState 범위 최소화
