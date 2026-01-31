# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**만톡 (Mantok)** - AI 사주 챗봇
- Flutter 모바일 앱 (Android/iOS)
- 생년월일 입력 → 만세력 계산 → AI 대화형 사주 상담
- 채팅 중심 UX (기존 사주 앱의 "긴 리포트" 방식 탈피)
- **AI 파이프라인**: GPT-5.2 분석 → Gemini 3.0 대화 → DALL-E/Imagen 이미지

---

## Team (5명)

| 이니셜 | 역할 | 담당 폴더 |
|--------|------|----------|
| **DK** | 총괄 + 광고 | `router/`, `features/ads/`, `core/interfaces/` |
| **JH_BE** | Supabase | `sql/`, `core/services/supabase/` |
| **JH_AI** | AI 분석 | `AI/jh/`, `AI/common/` (공동) |
| **Jina** | AI 대화 | `AI/jina/`, `AI/common/` (공동) |
| **SH** | UI/UX | `shared/`, `features/*/presentation/` |

> 상세 역할: `.claude/team/` 폴더 참조

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
| `.claude/team/` | **팀 역할 정의 (DK, JH_BE, JH_AI, Jina, SH)** |
| `.claude/JH_Agent/` | 서브 에이전트 정의 |
| `frontend/lib/AI/` | AI 모듈 (GPT-5.2 + Gemini 3.0) |

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
| 07_task_tracker | Task_Jaehyeon.md 진행 관리 | Tracker |
| **08_shadcn_ui_builder** | shadcn_ui 모던 UI 구현 | **UI 필수** |
| **09_manseryeok_calculator** | 만세력(사주팔자) 계산 로직 | **Domain 전문** |
| 10_a2a_protocol | A2A 프로토콜 구현 | Protocol |
| **11_progress_tracker** | Task_Jaehyeon.md + supabase_Jaehyeon_Task.md 통합 관리 | **Tracker 통합** |

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

**3. Progress Tracker 통합 상태 확인 (권장)**
```
Task 도구:
- prompt: "[11_progress_tracker] 현재 상태 확인"
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
| Backend | Supabase (JH_BE 담당) |
| AI | **GPT-5.2** (분석) + **Gemini 3.0** (대화) + DALL-E/Imagen (이미지) |

### Shadcn UI 사용 규칙
- **모든 UI 컴포넌트는 shadcn_ui 우선 사용**
- Material 위젯과 혼용 가능
- 주요 컴포넌트: ShadButton, ShadInput, ShadCard, ShadDialog, ShadSheet
- 참조: `.claude/JH_Agent/08_shadcn_ui_builder.md`

### AI 모듈 구조
```
frontend/lib/AI/
├── ai.dart             # 모듈 exports (barrel)
├── core/               # 설정, 로거, 캐시 (통합)
├── fortune/            # 운세 프롬프트 통합
│   ├── common/         # prompt_template, input_data, state
│   ├── lifetime/       # 평생운세 (saju_base)
│   ├── daily/          # 오늘운세
│   ├── monthly/        # 월별운세
│   ├── yearly_2025/    # 2025 회고
│   └── yearly_2026/    # 2026 신년
├── common/             # JH_AI + Jina 공동
│   ├── providers/
│   │   ├── openai/     # GPT-5.2 (JH_AI 주담당)
│   │   ├── google/     # Gemini 3.0 (Jina 주담당)
│   │   └── image/      # DALL-E, Imagen
│   ├── pipelines/      # 분석 파이프라인
│   └── prompts/        # 공통 프롬프트
├── jh/                 # JH_AI 전용
└── jina/               # Jina 전용
```

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

## Conflict Prevention (필수!!!)

> **모든 Claude CLI 사용자 필독**: 5명이 동시 작업하므로 충돌 방지 필수

### 공유 폴더 수정 전 Lock 체크

**반드시** 아래 폴더 수정 전에 lock 확인:

| 폴더 | Lock 파일 |
|------|----------|
| `core/` | `.claude/locks/core.lock` |
| `shared/` | `.claude/locks/shared.lock` |
| `AI/common/` | `.claude/locks/ai-common.lock` |
| `router/` | `.claude/locks/router.lock` |
| `pubspec.yaml` | `.claude/locks/pubspec.lock` |

### Lock 체크 절차

```
1. ls .claude/locks/ 실행
2. 관련 lock 파일 있으면:
   → "⚠️ [폴더명] 작업 중입니다 (owner: XXX). 기다리거나 연락하세요."
   → 작업 중단
3. lock 파일 없으면:
   → lock 파일 생성
   → 작업 진행
4. 작업 완료 후:
   → lock 파일 삭제
   → 커밋 + 푸시
```

### Lock 파일 형식
```
owner: DK
task: 광고 모듈 설정 추가
started: 2024-12-20T10:30:00
```

### 작업 시작 전 필수
```bash
git pull origin develop  # 항상 최신 상태 유지
```

---

## Development Rules

### Git 브랜치 전략
```
master (배포)
  └── develop (통합)
        ├── DK      # 총괄
        ├── BE      # Supabase
        ├── AI      # JH_AI + Jina
        └── UI      # SH
```

### 커밋 컨벤션
```
[이니셜] type: 설명

예시:
[DK] feat: 광고 모듈 초기화
[JH_BE] migration: 채팅 테이블 추가
[JH_AI] fix: GPT 응답 파싱 오류
[Jina] refactor: 프롬프트 개선
[SH] style: 다크모드 적용
```

### PR 규칙
| 변경 영역 | 승인자 |
|----------|--------|
| 자기 전용 폴더 | 셀프 머지 |
| `AI/common/` | JH_AI + Jina 둘 다 |
| `core/`, `shared/` | DK 승인 |

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
