# 만톡 (Mantok) - AI 사주 챗봇

AI 기반 사주 상담 Flutter 앱. 생년월일 입력 → 만세력 계산 → AI 대화형 사주 상담.

**현재 버전**: v0.1.2+31 (2026-02-08)

## 기술 스택

| 분류 | 기술 |
|------|------|
| Framework | Flutter 3.x (Dart) |
| UI | **shadcn_ui** (v0.39.14) - 모던 UI 컴포넌트 |
| State | **Riverpod 3.0** (`@riverpod` annotation, `keepAlive`) |
| Routing | **go_router** |
| Backend | **Supabase** (PostgreSQL + Edge Functions + Realtime) |
| AI 분석 | **GPT-5.2** (사주 분석, OpenAI Responses API background mode) |
| AI 대화 | **Gemini 3.0 Flash** (SSE 스트리밍 채팅) |
| AI 이미지 | DALL-E 3, Imagen 3 |
| 결제 | **RevenueCat** (IAP - day_pass, week_pass, monthly) |
| 광고 | **Google AdMob** (Native, Rewarded, Banner, Interstitial) |
| Local Storage | **Hive** (캐시), flutter_secure_storage (토큰) |
| i18n | easy_localization (ko, en, ja) |

## 프로젝트 구조

```
frontend/lib/
├── main.dart              # 앱 진입점
├── app.dart               # ShadApp.router 루트 위젯
├── core/                  # 앱 전역 공통
│   ├── theme/             # 다크/라이트 테마 + AppThemeExtension
│   ├── data/              # BaseQueryMixin, QueryResult
│   ├── services/          # ErrorLoggingService, PromptLoader, AiSummaryService
│   ├── supabase/          # Supabase 연동 (generated 쿼리)
│   └── widgets/           # 공통 일러스트 (YinYang, Lotus, Moon)
├── router/                # go_router 설정
├── AI/                    # AI 모듈 (GPT-5.2 + Gemini 3.0)
│   ├── fortune/           # 운세 프롬프트 (daily, monthly, yearly, lifetime)
│   ├── common/providers/  # OpenAI, Google, Image providers
│   ├── services/          # SajuAnalysisService, CompatibilityAnalysisService
│   └── data/              # AI 쿼리/뮤테이션
├── features/              # 기능별 모듈 (MVVM)
│   ├── menu/              # 메인 화면 (운세 요약, 캘린더)
│   ├── saju_chat/         # AI 사주 챗봇 (핵심)
│   ├── profile/           # 사주 프로필 입력/관리
│   ├── saju_chart/        # 만세력 차트 표시
│   ├── traditional_saju/  # 평생운세
│   ├── monthly_fortune/   # 월별운세
│   ├── new_year_fortune/  # 신년운세
│   ├── settings/          # 설정 (구독 관리, 테마)
│   ├── splash/            # 스플래시
│   └── onboarding/        # 온보딩
├── ad/                    # AdMob 광고 모듈
├── purchase/              # RevenueCat IAP 모듈
├── shared/                # 공통 위젯/익스텐션
└── i18n/                  # 다국어 (ko, en, ja)
```

## 빌드 명령어

```bash
cd frontend

flutter pub get
dart run build_runner build --delete-conflicting-outputs  # Riverpod/Freezed 코드 생성
flutter run                                               # 디버그 실행
flutter build appbundle --release                         # 릴리즈 AAB (Google Play)
flutter build ios --release                               # iOS 빌드
```

## 환경 설정

`.env` 파일 (frontend/.env):
```
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=xxx
```

## 주요 파일

| 파일 | 설명 |
|------|------|
| `lib/app.dart` | ShadApp.router + 테마 + 자정 갱신 |
| `lib/router/app_router.dart` | go_router 라우트 정의 |
| `lib/features/saju_chat/presentation/providers/chat_provider.dart` | 채팅 상태 관리 (핵심) |
| `lib/features/saju_chat/presentation/providers/conversational_ad_provider.dart` | 대화형 광고 + 토큰 보상 |
| `lib/features/menu/presentation/providers/daily_fortune_provider.dart` | 오늘의 운세 (keepAlive + 타임아웃) |
| `lib/purchase/providers/purchase_provider.dart` | RevenueCat 구매 상태 (keepAlive) |
| `lib/AI/fortune/fortune_coordinator.dart` | 운세 분석 조율 |
| `lib/core/services/error_logging_service.dart` | Supabase 에러 로깅 |

## 릴리즈 이력

| 버전 | 날짜 | 주요 변경 |
|------|------|----------|
| v0.1.2+31 | 2026-02-08 | 운세 로딩 무한대기 수정, Native 광고 토큰 race condition 수정, QUOTA_EXCEEDED 에러 피드백, 에러 로깅 강화 |
| v0.1.1+30 | 2026-02-07 | 다국어 세팅 (ko, en, ja) |
| v0.1.0 | 2026-02-02 | IAP 모듈 (RevenueCat), 광고 시스템 (AdMob) |
