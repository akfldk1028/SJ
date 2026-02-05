# 만톡 - 구현 작업 목록

> Main Claude 컨텍스트 유지용 작업 노트
> 작업 브랜치: DKBB (DK), Jaehyeon(Test) (JH)
> 백엔드(Supabase): 사용자가 직접 처리

---

## 현재 상태

| 항목 | 상태 |
|------|------|
| 기획 문서 | ✅ 완료 |
| CLAUDE.md | ✅ 완료 |
| JH_Agent (서브에이전트) | ✅ 완료 (11개) |
| Flutter 프로젝트 | ✅ 기반 설정 완료 |
| 의존성 | ✅ 설치 완료 |
| 폴더 구조 | ✅ 구현 완료 |
| Phase 1 | ✅ **완료** |
| Phase 2 | ✅ **부분 완료** (상수/테마) |
| Phase 4 (Profile) | ✅ **완료** |
| Phase 5 (Saju Chat) | ✅ **완료** (54개 파일) |
| Phase 8 (만세력) | ✅ **완료** (70개 파일) |
| Phase 9-10 | 📋 **계획 완료** (경쟁앱 대응 + 웹툰) |
| **다음 작업** | **Phase 6 (Splash/Onboarding) 또는 Phase 9 (MVP 확장)** |

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
│   ├── profile/ ✅ (완료)
│   ├── saju_chart/ ✅ (완료 - 70개 파일)
│   ├── saju_chat/ ✅ (완료 - 54개 파일)
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

---

## Phase 5: Feature - Saju Chat (P0) ✅ 완료

> 참조: docs/02_features/saju_chat.md
> 2025-12-05 ~ 2026-01-06: 54개 파일 구현 완료

### 5.1 Domain 레이어 ✅
- [x] entities/chat_session.dart
- [x] entities/chat_message.dart (MessageRole, MessageStatus 포함)
- [x] models/chat_type.dart (ChatType enum)
- [x] models/ai_persona.dart (4종 페르소나)
- [x] repositories/chat_repository.dart (abstract)
- [x] repositories/chat_session_repository.dart (abstract)

### 5.2 Data 레이어 ✅

**Datasources:**
- [x] gemini_edge_datasource.dart (Supabase Edge Function)
- [x] gemini_rest_datasource.dart (REST API 직접 호출)
- [x] openai_datasource.dart (GPT-5.2)
- [x] openai_edge_datasource.dart (OpenAI Edge Function)
- [x] saju_chat_edge_datasource.dart (통합 Edge)
- [x] ai_pipeline_manager.dart (GPT→Gemini 파이프라인)
- [x] chat_local_datasource.dart (Hive 캐시)
- [x] chat_session_local_datasource.dart (세션 로컬)

**Models:**
- [x] chat_message_model.dart (Freezed + JSON)
- [x] chat_session_model.dart (Freezed + JSON)

**Repositories:**
- [x] chat_repository_impl.dart
- [x] chat_session_repository_impl.dart

**Services:**
- [x] sse_stream_client.dart (SSE 스트리밍)
- [x] system_prompt_builder.dart (시스템 프롬프트 모듈화)
- [x] ai_summary_prompt_builder.dart (AI Summary 백업)
- [x] chat_realtime_service.dart (Supabase Realtime)
- [x] conversation_window_manager.dart (대화 윈도우)
- [x] message_queue_service.dart (메시지 큐)
- [x] token_counter.dart (토큰 계산)

**Supabase:**
- [x] schema.dart
- [x] queries.dart
- [x] mutations.dart

### 5.3 Presentation 레이어 ✅

**Providers:**
- [x] chat_provider.dart (Riverpod 3.0 - 797줄로 모듈화)
- [x] chat_session_provider.dart
- [x] persona_provider.dart

**Screens:**
- [x] saju_chat_shell.dart (메인 채팅 화면)

**Widgets - 채팅:**
- [x] chat_app_bar.dart
- [x] chat_bubble.dart
- [x] chat_input_field.dart
- [x] chat_message_list.dart
- [x] message_bubble.dart
- [x] streaming_message_bubble.dart
- [x] typing_indicator.dart
- [x] thinking_bubble.dart
- [x] send_button.dart
- [x] disclaimer_banner.dart
- [x] error_banner.dart
- [x] suggested_questions.dart

**Widgets - 페르소나:**
- [x] persona_avatar.dart
- [x] persona_selector_sheet.dart

**Widgets - 히스토리 사이드바:**
- [x] chat_history_sidebar/chat_history_sidebar.dart
- [x] chat_history_sidebar/chat_history_sidebar_widgets.dart
- [x] chat_history_sidebar/persona_selector_grid.dart
- [x] chat_history_sidebar/session_group_header.dart
- [x] chat_history_sidebar/session_list.dart
- [x] chat_history_sidebar/session_list_tile.dart
- [x] chat_history_sidebar/sidebar_footer.dart
- [x] chat_history_sidebar/sidebar_header.dart

### 5.4 수락 조건 ✅
- [x] AI 인사 메시지 표시 (ChatType별 환영 메시지)
- [x] 메시지 입력/전송
- [x] SSE 스트리밍 응답 표시
- [x] 타이핑 인디케이터 (3-dot 애니메이션)
- [x] 면책 배너 표시
- [x] 에러 처리 (에러 배너)
- [x] 추천 질문 칩 표시
- [x] 4종 페르소나 선택 (아기 도승/할머니 무당/MZ 타로/점집 도사)
- [x] 채팅 히스토리 사이드바
- [x] Supabase 실시간 동기화
- [x] GPT-5.2 → Gemini 3.0 듀얼 AI 파이프라인
- [x] 시스템 프롬프트에 현재 날짜 포함 (AI 날짜 인식)
- [x] 시스템 프롬프트에 프로필 정보 포함
- [x] 시스템 프롬프트 모듈화 (chat_provider 경량화)

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

## Phase 8: Saju Chart (만세력) ✅ 완료

> 2025-12-02 ~ 2026-01-06: 70개 파일 구현 완료
> 포스텔러 만세력 2.2 수준의 정확도 달성

### 8.1 Constants ✅ (15개)
- [x] cheongan_jiji.dart - 천간(10), 지지(12), 오행
- [x] gapja_60.dart - 60갑자
- [x] solar_term_table.dart - 절기 시각 (기본)
- [x] solar_term_table_extended.dart - 절기 시각 (확장)
- [x] solar_term_calculator.dart - 절기 계산
- [x] dst_periods.dart - 서머타임 기간
- [x] sipsin_relations.dart - 십성 관계
- [x] hapchung_relations.dart - 합충형파해 관계
- [x] jijanggan_table.dart - 지장간 테이블
- [x] gongmang_table.dart - 공망 테이블
- [x] twelve_sinsal.dart - 12신살 테이블
- [x] twelve_unsung.dart - 12운성 테이블
- [x] lunar_data/lunar_table.dart - 음력 테이블 (통합)
- [x] lunar_data/lunar_table_1900_1949.dart
- [x] lunar_data/lunar_table_1950_1999.dart
- [x] lunar_data/lunar_table_2000_2050.dart
- [x] lunar_data/lunar_table_2051_2100.dart
- [x] lunar_data/lunar_year_data.dart

### 8.2 Domain Entities ✅ (15개)
- [x] pillar.dart - 기둥 (천간+지지)
- [x] saju_chart.dart - 사주 차트
- [x] saju_analysis.dart - 사주 분석 결과
- [x] saju_context.dart - 사주 컨텍스트
- [x] lunar_date.dart - 음력 날짜
- [x] lunar_validation.dart - 음력 검증
- [x] solar_term.dart - 24절기 enum
- [x] daeun.dart - 대운
- [x] day_strength.dart - 신강/신약
- [x] gyeokguk.dart - 격국
- [x] yongsin.dart - 용신
- [x] sinsal.dart - 신살
- [x] rule.dart - 규칙
- [x] rule_condition.dart - 규칙 조건
- [x] compiled_rules.dart - 컴파일된 규칙

### 8.3 Domain Services ✅ (18개)
- [x] saju_calculation_service.dart - 통합 계산 (메인)
- [x] saju_analysis_service.dart - 분석 서비스
- [x] lunar_solar_converter.dart - 음양력 변환 (1900-2100년 완전 구현)
- [x] solar_term_service.dart - 절입시간
- [x] true_solar_time_service.dart - 진태양시 (25개 도시)
- [x] dst_service.dart - 서머타임
- [x] jasi_service.dart - 야자시/조자시
- [x] day_strength_service.dart - 신강/신약 계산
- [x] gyeokguk_service.dart - 격국 판정
- [x] yongsin_service.dart - 용신 계산
- [x] sinsal_service.dart - 신살 계산
- [x] twelve_sinsal_service.dart - 12신살 계산 (년지+일지 기준)
- [x] unsung_service.dart - 12운성 계산
- [x] hapchung_service.dart - 합충형파해 (삼합/반합/방합 포함)
- [x] jijanggan_service.dart - 지장간 계산
- [x] gongmang_service.dart - 공망 계산
- [x] gilseong_service.dart - 길성 계산
- [x] daeun_service.dart - 대운 계산
- [x] rule_engine.dart - 규칙 엔진
- [x] rule_validator.dart - 규칙 검증

### 8.4 Data Models ✅ (8개)
- [x] pillar_model.dart - JSON 직렬화
- [x] saju_chart_model.dart - JSON 직렬화
- [x] saju_analysis_model.dart - 분석 결과 모델
- [x] saju_analysis_db_model.dart - DB 모델
- [x] cheongan_model.dart - 천간 모델
- [x] jiji_model.dart - 지지 모델
- [x] oheng_model.dart - 오행 모델
- [x] rule_models.dart - 규칙 모델

### 8.5 Data Repositories ✅
- [x] saju_analysis_repository.dart
- [x] rule_repository_impl.dart

### 8.6 Supabase ✅
- [x] schema.dart
- [x] queries.dart
- [x] mutations.dart

### 8.7 Presentation ✅

**Providers:**
- [x] saju_chart_provider.dart
- [x] saju_analysis_repository_provider.dart

**Screens:**
- [x] saju_chart_screen.dart

**Widgets (15개):**
- [x] pillar_display.dart - 사주 기둥 표시
- [x] pillar_column_widget.dart - 기둥 컬럼
- [x] possteller_style_table.dart - 포스텔러 스타일 테이블
- [x] saju_info_header.dart - 사주 정보 헤더
- [x] saju_mini_card.dart - 미니 카드
- [x] saju_detail_sheet.dart - 상세 시트
- [x] saju_detail_tabs.dart - 상세 탭
- [x] oheng_analysis_display.dart - 오행 분석
- [x] day_strength_display.dart - 신강/신약 표시
- [x] sinsal_display.dart - 신살 표시
- [x] sipsung_display.dart - 십성 표시
- [x] unsung_display.dart - 12운성 표시
- [x] hapchung_tab.dart - 합충형파해 탭
- [x] jijanggan_display.dart - 지장간 표시
- [x] gongmang_display.dart - 공망 표시
- [x] gilseong_display.dart - 길성 표시
- [x] fortune_display.dart - 운세 표시

### 8.8 검증 완료 ✅
- [x] 포스텔러 만세력 2.2와 비교 검증
- [x] 12신살 기준 수정 (년지 + 일지)
- [x] 도화살 로직 보완
- [x] 신강/신약 계산 로직 수정
- [x] 삼합/반합/방합 구현
- [x] 음력 변환 2100년까지 확장 (윤달 포함)

---

## iOS IAP (In-App Purchase) 설정 - 미완료

> 현재 상태: iOS 빌드에서 IAP 완전 비활성화 (`revenueCatApiKeyIos = ''`)
> App Store 심사 통과 후 설정 진행
> 상세 TODO: `frontend/lib/purchase/README.md` "iOS 출시 시" 섹션 참조

- [ ] App Store Connect 상품 등록 (sadam_day_pass ₩1,100 / sadam_week_pass ₩4,900 / sadam_monthly ₩12,900)
- [ ] App Store Connect 구독 그룹 생성 + Shared Secret 발급
- [ ] RevenueCat Dashboard iOS 앱 추가 (Bundle ID: com.clickaround.sadam)
- [ ] RevenueCat iOS Products 3개 등록 + premium entitlement 매핑
- [ ] RevenueCat iOS Public API 키 발급
- [ ] `purchase_config.dart` Line 13: `revenueCatApiKeyIos = ''` → 실제 키 교체 (유일한 코드 변경)
- [ ] Xcode > Signing & Capabilities > In-App Purchase capability 추가
- [ ] Sandbox 테스터 등록 + iOS 실기기 테스트
- [ ] 서버 webhook "All apps" 포함 확인

---

## 작업 규칙

### 컨텍스트 관리
1. **Compaction**: 대화 길어지면 이 파일에 진행 상황 업데이트
2. **노트 작성**: 결정 사항, 변경점 기록
3. **서브 Agent**: 복잡한 작업은 Task 도구로 분리

### Git 규칙
- 작업 브랜치: DKBB (DK), Jaehyeon(Test) (JH)
- master 건들지 않음
- 기능 단위로 커밋

### 우선순위
1. Phase 1-2: 기반 설정 (완료)
2. Phase 4: Profile (완료)
3. Phase 5: Saju Chat (완료)
4. Phase 8: 만세력 (완료)
5. **iOS IAP 설정** (앱 심사 통과 후)
6. Phase 6-7: Splash/Onboarding, History/Settings
7. Phase 9-10: MVP 확장, 웹툰형 사주

---

## 진행 기록

| 날짜 | 작업 내용 | 상태 |
|------|-----------|------|
| 2025-12-01 | 프로젝트 시작, 기획 문서 완료 | 완료 |
| 2025-12-02 | TASKS.md 작성 | 완료 |
| 2025-12-02 | CLAUDE.md 생성 | 완료 |
| 2025-12-02 | JH_Agent 서브에이전트 생성 (8개) | 완료 |
| 2025-12-02 | 만세력 정확도 연구 (진태양시, 절입시간 등) | 완료 |
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
| 2025-12-27 | 만세력 전체 서비스 구현 (18개 서비스) | 완료 |
| 2025-12-29 | TypeSet 패키지 적용 (WhatsApp 스타일 포맷팅) | 완료 |
| 2025-12-29 | Gemini 3.0 Flash 모델 적용 | 완료 |
| 2025-12-29 | GPT→Gemini 파이프라인 검증 완료 | 완료 |
| 2025-12-29 | **경쟁앱 분석** (점신, 포스텔러) | 완료 |
| 2025-12-29 | **Phase 9-10 추가**: MVP 확장 + 웹툰형 사주 | 완료 |
| 2025-12-31 | 지장간, 공망, 합충형파해 서비스 구현 | 완료 |
| 2026-01-04 | 12신살/12운성 완전 구현 | 완료 |
| 2026-01-04 | 음력 변환 2100년까지 확장 (윤달 포함) | 완료 |
| 2026-01-04 | 삼합/반합/방합 구현 | 완료 |
| 2026-01-04 | DB ai_summary, content 오행값 연동 | 완료 |
| 2026-01-06 | 12신살 기준 수정 (년지 + 일지) | 완료 |
| 2026-01-06 | 도화살 로직 보완 | 완료 |
| 2026-01-06 | chat_provider.dart 모듈화 (1346→797줄) | 완료 |
| 2026-01-06 | system_prompt_builder.dart 분리 | 완료 |
| 2026-01-06 | ai_summary_prompt_builder.dart 백업 생성 | 완료 |
| 2026-01-06 | **TASKS.md 전면 업데이트** | 완료 |

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

## Phase 9: MVP 확장 기능 (경쟁앱 대응)

> 2025-12-29: 경쟁앱(점신, 포스텔러) 분석 후 추가

### 9.1 P1 - 필수 기능
- [ ] **오늘의 운세 대시보드**
  - [ ] 매일 갱신 운세 요약 API
  - [ ] 4분야 운세 (재물/직장/애정/건강) 별점
  - [ ] 대시보드 UI (카드 스타일)
- [ ] **행운 번호/색상/방향**
  - [ ] 오행 기반 행운 번호 생성
  - [ ] 행운 색상, 방향 추천
- [ ] **푸시 알림**
  - [ ] FCM 설정
  - [ ] 매일 아침 운세 푸시
  - [ ] 알림 설정 화면
- [ ] **시간대별 운세**
  - [ ] 아침/점심/저녁 운세 변화

### 9.2 P2 - 확장 기능
- [ ] **궁합 기능**
  - [ ] 연인/친구/가족 궁합
  - [ ] 궁합 점수 계산 로직
- [ ] **운세 캘린더**
  - [ ] 월별 운세 변화 그래프
  - [ ] 길일/흉일 표시
- [ ] **홈화면 위젯**
  - [ ] 오늘의 운세 미니 위젯
- [ ] **SNS 공유**
  - [ ] 운세 카드 이미지 생성
  - [ ] 카톡/인스타 공유

### 9.3 P3 - 장기 기능
- [ ] 타로 카드
- [ ] 토정비결
- [ ] 꿈 해몽
- [ ] 해외 버전 (영어/일본어)

---

## Phase 10: 웹툰형 사주 설명 (핵심 차별화) ⭐

> 2025-12-29: 나노바나나 스타일 아이디어 - **경쟁앱에 없는 핵심 차별점!**

### 10.1 컨셉
```
복잡한 사주 → 4컷 웹툰으로 쉽게 설명
- MZ세대 타겟
- SNS 바이럴 가능
- 진입장벽 낮춤
```

### 10.2 오행 캐릭터 디자인
- [ ] 🌳 목(木) 캐릭터 - 나무 (성장, 창의)
- [ ] 🔥 화(火) 캐릭터 - 불꽃 (열정, 표현)
- [ ] 🏔️ 토(土) 캐릭터 - 산/땅 (안정, 중재)
- [ ] ⚔️ 금(金) 캐릭터 - 검/보석 (결단, 정의)
- [ ] 💧 수(水) 캐릭터 - 물방울 (지혜, 유연)

### 10.3 구현 단계
- [ ] **1단계**: 오행 5캐릭터 일러스트 (외주 or AI 생성)
- [ ] **2단계**: 결과 화면에 간단 웹툰 1컷 추가
- [ ] **3단계**: 전체 분석을 4컷 스토리로 확장
- [ ] **4단계**: 공유 카드 이미지 생성 기능

### 10.4 기술 옵션
| 방식 | 장점 | 단점 |
|------|------|------|
| Lottie 애니메이션 | 가벼움, 부드러움 | 제작 필요 |
| AI 이미지 생성 | 맞춤형 가능 | API 비용 |
| 프리셋 일러스트 | 빠름, 저비용 | 다양성 ↓ |
| SVG 조합 | 커스텀 가능 | 개발 복잡 |

### 10.5 예시 시나리오
```
[컷 1] 목(木) 캐릭터가 씩씩하게 걸어감
       "오늘은 목의 기운이 강해요!"

[컷 2] 화(火) 캐릭터가 옆에서 응원
       "열정도 있으니 새 프로젝트 시작해봐!"

[컷 3] 수(水) 캐릭터가 살짝 걱정
       "근데 건강은 조심... 물 많이 마셔~"

[컷 4] 다 같이 포즈
       "오늘의 행운 번호: 3, 7, 12! 화이팅!"
```

---

## 경쟁앱 분석 (2025-12-29)

### 만톡 vs 경쟁앱 비교

| 기능 | 만톡 | 점신 | 포스텔러 |
|------|------|------|----------|
| AI 대화 상담 | ✅ | ❌ | ❌ |
| 페르소나 선택 | ✅ 4종 | ❌ | ❌ |
| 듀얼 AI (GPT+Gemini) | ✅ | ❌ | ❌ |
| 웹툰형 설명 | 🔜 계획 | ❌ | ❌ |
| 오늘의 운세 | ❌ | ✅ | ✅ |
| 행운 번호 | ❌ | ✅ | ✅ |
| 푸시 알림 | ❌ | ✅ | ✅ |
| 궁합 | ❌ | ✅ | ✅ |
| 타로 | ❌ | ✅ | ✅ |

### 만톡 차별점 (강점)
1. **AI 대화형 상담** - 경쟁앱에 없음!
2. **4가지 페르소나** - 개인화된 경험
3. **GPT+Gemini 듀얼 AI** - 정확도+재미
4. **웹툰형 설명** - 계획 중 (핵심 차별화)

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
| 10 | a2a_protocol | A2A 프로토콜 구현 | Protocol |
| **11** | **progress_tracker** | Task 통합 관리 | **Tracker 통합** |

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

