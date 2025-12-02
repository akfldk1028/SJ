# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**만톡 (Mantok)** - AI 사주 챗봇
- Flutter 모바일 앱 (Android/iOS)
- 생년월일 입력 → 만세력 계산 → Gemini AI와 대화형 사주 상담
- 채팅 중심 UX (기존 사주 앱의 "긴 리포트" 방식 탈피)

---

## Key Files

| 파일 | 용도 |
|------|------|
| `TASKS.md` | 구현 작업 목록 - **작업 시 항상 확인/업데이트** |
| `docs/01_overview.md` | 프로젝트 개요 |
| `docs/02_features/` | 기능별 상세 명세 |
| `docs/03_architecture.md` | 시스템 아키텍처 |
| `docs/04_data_models.md` | 데이터 모델 + PostgreSQL 스키마 |
| `docs/09_state_management.md` | Riverpod 3.0 가이드 |
| `docs/10_widget_tree_optimization.md` | 위젯 트리 최적화 **(필독)** |
| `.claude/JH_Agent/` | 서브 에이전트 정의 |

---

## Sub Agents (.claude/JH_Agent/) - A2A Orchestration

### 아키텍처
```
Main Claude → [Orchestrator] → Pipeline → [Quality Gate] → 완료
```

### 에이전트 목록

| 에이전트 | 역할 | 유형 |
|----------|------|------|
| **00_orchestrator** | 작업 분석 & 파이프라인 자동 구성 | **진입점** |
| **00_widget_tree_guard** | 위젯 트리 최적화 검증 | **품질 게이트** |
| 01_feature_builder | Feature 폴더 구조 생성 | Builder |
| 02_widget_composer | 화면을 작은 위젯으로 분해 | Builder |
| 03_provider_builder | Riverpod Provider 생성 | Builder |
| 04_model_generator | Entity/Model 클래스 생성 | Builder |
| 05_router_setup | go_router 라우팅 설정 | Config |
| 06_local_storage | Hive 로컬 저장소 설정 | Config |
| 07_task_tracker | TASKS.md 진행 관리 | Tracker |
| **08_shadcn_ui_builder** | shadcn_ui 모던 UI 구현 | **UI 필수** |
| **09_manseryeok_calculator** | 만세력(사주팔자) 계산 로직 | **Domain 전문** |

### 호출 방식

**1. Orchestrator 자동 파이프라인 (권장)**
```
Task 도구:
- prompt: "[Orchestrator] Profile Feature 구현"
- subagent_type: general-purpose
```

**2. 개별 에이전트 직접 호출**
```
Task 도구:
- prompt: "[09_manseryeok_calculator] 사주 계산 로직 구현"
- subagent_type: general-purpose
```

### Widget Tree Guard 필수 검증 항목
- const 생성자/인스턴스화
- ListView.builder 사용
- 위젯 100줄 이하
- setState 범위 최소화

---

## Tech Stack

| 분류 | 기술 |
|------|------|
| Framework | Flutter 3.x (Dart) |
| **UI** | **shadcn_ui** (모던 UI 컴포넌트) |
| State | **Riverpod 3.0** (@riverpod annotation) |
| Routing | **go_router** |
| Local Storage | **Hive** (캐시), flutter_secure_storage (토큰) |
| Backend | Supabase (사용자가 별도 관리) |
| AI | Google Gemini (Edge Functions에서 호출) |

### Shadcn UI 사용 규칙
- **모든 UI 컴포넌트는 shadcn_ui 우선 사용**
- Material 위젯과 혼용 가능
- 주요 컴포넌트: ShadButton, ShadInput, ShadCard, ShadDialog, ShadSheet
- 참조: `.claude/JH_Agent/08_shadcn_ui_builder.md`

---

## Build Commands

```bash
# Flutter 프로젝트 위치
cd frontend

# 의존성 설치
flutter pub get

# 코드 생성 (Riverpod, Freezed)
dart run build_runner build --delete-conflicting-outputs

# 코드 생성 (watch 모드)
dart run build_runner watch -d

# 앱 실행
flutter run

# 빌드
flutter build apk --release
flutter build ios --release
```

---

## Architecture

**MVVM + Feature-First 구조**

```
frontend/lib/
├── main.dart
├── app.dart
├── core/              # 앱 전역 공통
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── errors/
├── features/          # 기능별 모듈 (각각 data/domain/presentation)
│   ├── profile/       # P0: 사주 프로필 입력
│   ├── saju_chat/     # P0: AI 사주 챗봇 (핵심)
│   ├── saju_chart/    # 만세력 표시
│   ├── splash/
│   ├── onboarding/
│   ├── history/
│   └── settings/
├── shared/            # 공통 위젯/익스텐션
└── router/            # go_router 설정
```

**Feature 내부 구조 (MVVM)**
```
features/{feature}/
├── data/
│   ├── datasources/   # Local/Remote 데이터소스
│   ├── models/        # JSON 변환 모델
│   └── repositories/  # Repository 구현체
├── domain/
│   ├── entities/      # 순수 비즈니스 객체
│   └── repositories/  # Repository 인터페이스
└── presentation/
    ├── providers/     # Riverpod Provider
    ├── screens/
    └── widgets/
```

---

## Development Rules

### Git
- 작업 브랜치: **Jaehyeon(Test)**
- master 브랜치 건들지 않음

### Context Management
- **TASKS.md**: 작업할 때마다 확인하고 진행 상황 업데이트
- 복잡한 작업은 서브 Agent(Task 도구)로 분리
- 결정 사항은 TASKS.md 메모 섹션에 기록

### Backend
- Supabase는 사용자가 직접 설정
- 프론트엔드 구현 시 로컬 저장(Hive) 우선, Supabase 연동은 나중에

---

## Routes

| 화면 | 경로 |
|------|------|
| 스플래시 | /splash |
| 온보딩 | /onboarding |
| 프로필 입력 | /profile/edit |
| 사주 챗봇 (메인) | /saju/chat |
| 히스토리 | /history |
| 설정 | /settings |

---

## Priority (MVP)

1. **P0 필수**: Profile 입력, Saju Chat
2. **P1**: 계정/로그인 (v0.2 이후)
3. **P2**: 궁합, 알림
