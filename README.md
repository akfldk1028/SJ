# 만톡 (Mantok) - AI 사주 챗봇

AI 기반 사주 상담 모바일 앱. 생년월일 입력 → 만세력 계산 → AI 대화형 사주 상담.

**현재 버전**: v0.1.2+31 (2026-02-08)

## 기술 스택

| 분류 | 기술 |
|------|------|
| Framework | Flutter 3.x (Dart) |
| UI | shadcn_ui (v0.39.14) |
| State | Riverpod 3.0 (`@riverpod` annotation, `keepAlive`) |
| Routing | go_router |
| Backend | Supabase (PostgreSQL + Edge Functions + Realtime) |
| AI 분석 | GPT-5.2 (OpenAI Responses API background mode) |
| AI 대화 | Gemini 3.0 Flash (SSE 스트리밍) |
| AI 이미지 | DALL-E 3, Imagen 3 |
| 결제 | RevenueCat (day_pass, week_pass, monthly) |
| 광고 | Google AdMob (Native, Rewarded, Banner, Interstitial) |
| Local Storage | Hive (캐시), flutter_secure_storage (토큰) |
| i18n | easy_localization (ko, en, ja) |

## 프로젝트 구조

```
├── frontend/              # Flutter 앱
│   ├── lib/
│   │   ├── main.dart      # 앱 진입점
│   │   ├── app.dart       # ShadApp.router 루트 위젯
│   │   ├── core/          # 전역 공통 (테마, 서비스, Supabase)
│   │   ├── features/      # 기능별 모듈 (MVVM)
│   │   │   ├── saju_chat/ # AI 사주 챗봇 (핵심)
│   │   │   ├── menu/      # 메인 화면 (운세 요약, 캘린더)
│   │   │   ├── profile/   # 사주 프로필 입력/관리
│   │   │   └── settings/  # 설정 (구독 관리, 테마)
│   │   ├── AI/            # AI 모듈 (GPT-5.2 + Gemini 3.0)
│   │   ├── ad/            # AdMob 광고 모듈
│   │   ├── purchase/      # RevenueCat IAP 모듈
│   │   └── i18n/          # 다국어 (ko, en, ja)
│   └── pubspec.yaml
├── supabase/
│   └── functions/         # Edge Functions (ai-gemini, ai-openai, purchase-webhook)
├── sql/                   # DB 마이그레이션
├── docs/                  # 기획 문서
└── CLAUDE.md              # Claude Code 가이드
```

## 빌드

```bash
cd frontend
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
flutter build appbundle --release    # Google Play AAB
flutter build ios --release          # iOS
```

## AI 파이프라인

```
사용자 입력
    │
    ├── GPT-5.2 (사주 분석, background mode)
    │     └── ai-openai Edge Function → polling → ai-openai-result
    │
    └── Gemini 3.0 Flash (대화, SSE 스트리밍)
          └── ai-gemini Edge Function (v59)
               ├── Context Caching (system prompt 캐싱, 비용 90% 절감)
               ├── Quota 체크 (daily_quota + bonus + rewarded + native tokens)
               └── Premium bypass (subscriptions 테이블 active → 무제한)
```

## 수익 모델

| 유형 | 상품 | 가격 |
|------|------|------|
| 1일 이용권 | `sadam_day_pass` (Consumable) | ₩1,100 |
| 1주일 이용권 | `sadam_week_pass` (Consumable) | ₩4,900 |
| 월간 구독 | `sadam_monthly` (Auto-renewable) | ₩12,900/월 |
| 광고 | Banner, Native, Interstitial, Rewarded | AdMob |

## 릴리즈 이력

| 버전 | 날짜 | 주요 변경 |
|------|------|----------|
| v0.1.2+31 | 2026-02-08 | 운세 로딩 무한대기 수정, Native 광고 토큰 race condition 수정, QUOTA_EXCEEDED 에러 피드백, Premium 만료 전환 처리, 에러 로깅 강화 |
| v0.1.1+30 | 2026-02-07 | 다국어 세팅 (ko, en, ja) |
| v0.1.0 | 2026-02-02 | IAP 모듈 (RevenueCat), 광고 시스템 (AdMob) |
