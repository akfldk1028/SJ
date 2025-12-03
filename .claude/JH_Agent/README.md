# JH_Agent - 서브 에이전트 모음

> 만톡 프로젝트를 위한 전문 서브 에이전트 (A2A Orchestration 방식)

---

## 아키텍처

```
┌─────────────────────────────────────────────────────┐
│  Main Claude                                        │
│       ↓                                             │
│  [00_orchestrator] ← 진입점, 자동 파이프라인 구성    │
│       ↓                                             │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐               │
│  │Builder  │→│Generator│→│Provider │               │
│  └─────────┘ └─────────┘ └─────────┘               │
│       ↓                                             │
│  [00_widget_tree_guard] ← 필수 품질 게이트          │
└─────────────────────────────────────────────────────┘
```

---

## 에이전트 목록

| 순서 | 에이전트 | 역할 | 유형 |
|------|----------|------|------|
| **00** | **orchestrator** | 작업 분석 & 파이프라인 구성 | **진입점** |
| **00** | **widget_tree_guard** | 위젯 트리 최적화 검증 | **품질 게이트** |
| 01 | feature_builder | Feature 폴더 구조 생성 | Builder |
| 02 | widget_composer | 화면을 작은 위젯으로 분해 | Builder |
| 03 | provider_builder | Riverpod Provider 생성 | Builder |
| 04 | model_generator | Entity/Model 클래스 생성 | Builder |
| 05 | router_setup | go_router 라우팅 설정 | Config |
| 06 | local_storage | Hive 로컬 저장소 설정 | Config |
| 07 | task_tracker | TASKS.md 진행 관리 | Tracker |
| **08** | **shadcn_ui_builder** | shadcn_ui 모던 UI 구현 | **UI 필수** |
| **09** | **manseryeok_calculator** | 만세력(사주팔자) 계산 로직 | **Domain 전문** |

---

## A2A 사용 방식

### 1. Orchestrator를 통한 자동 파이프라인 (권장)

```
Task 도구:
- prompt: |
    [Orchestrator] 다음 작업 수행:
    - 작업: Profile Feature 구현
    - 참조: docs/02_features/profile_input.md

    자동으로 파이프라인 구성하여 순차 실행.

- subagent_type: general-purpose
```

### 2. 개별 에이전트 직접 호출 (특수 상황)

```
Task 도구:
- prompt: |
    [09_manseryeok_calculator] 역할로 수행:
    - 사주팔자 계산 로직 구현
    - 진태양시 보정 포함
    - 절입시간 처리 포함

- subagent_type: general-purpose
```

### 3. 품질 게이트 (자동 적용)

```
모든 위젯 코드 작성 후 00_widget_tree_guard 자동 검증
```

---

## 파이프라인 정의

### Pipeline A: 새 Feature 구현
```
orchestrator → feature_builder → model_generator → provider_builder
            → widget_composer → shadcn_ui_builder
            → widget_tree_guard (게이트)
            → router_setup → local_storage → task_tracker
```

### Pipeline B: 위젯 수정
```
orchestrator → widget_composer → shadcn_ui_builder
            → widget_tree_guard (게이트) → task_tracker
```

### Pipeline C: 로직 구현
```
orchestrator → model_generator → provider_builder → task_tracker
```

### Pipeline D: 만세력/사주 (특수)
```
orchestrator → manseryeok_calculator → model_generator
            → provider_builder → widget_tree_guard → task_tracker
```

---

## 의존성 규칙

```yaml
widget_composer:
  requires: [feature_builder]

provider_builder:
  requires: [model_generator]

router_setup:
  requires: [widget_composer]
  blocked_by: [widget_tree_guard]  # 검증 통과 필수

local_storage:
  requires: [model_generator]

manseryeok_calculator:
  independent: true  # 독립 실행 가능
```

---

## 에이전트 상세

### 00_widget_tree_guard (최우선)

**검증 항목:**
- const 생성자/인스턴스화
- ListView.builder 사용
- 100줄 이하 위젯
- setState 범위 최소화
- RepaintBoundary 적용

**호출 시점:** 모든 위젯 코드 작성 전/후

---

### 01_feature_builder

**생성 구조:**
```
features/{name}/
├── data/
├── domain/
└── presentation/
```

**호출 시점:** 새 기능 시작 시

---

### 02_widget_composer

**역할:** Screen → 작은 위젯 분해

**규칙:**
- Screen은 50줄 이하 (조립만)
- 개별 위젯 100줄 이하
- const 적용 최대화

---

### 03_provider_builder

**지원 유형:**
- simple: 단순 값
- async: 비동기 조회
- async_notifier: CRUD
- family: 파라미터

---

### 04_model_generator

**생성 클래스:**
- Entity (domain/entities/)
- Model (data/models/)
- Enum
- Freezed State

---

### 05_router_setup

**관리 파일:**
- router/routes.dart (상수)
- router/app_router.dart (GoRouter)

---

### 06_local_storage

**설정 항목:**
- Hive 초기화
- TypeAdapter 생성
- DataSource 구현

---

### 07_task_tracker

**관리 대상:** TASKS.md

**업데이트:**
- 현재 상태
- 체크박스 완료
- 진행 기록
- 메모

---

### 08_shadcn_ui_builder (UI 필수)

**역할:** shadcn_ui 패키지 활용 모던 UI 구현

**주요 컴포넌트:**
- ShadButton (primary, secondary, outline, ghost)
- ShadInput, ShadTextarea
- ShadCard, ShadDialog, ShadSheet
- ShadSelect, ShadDatePicker
- ShadAvatar, ShadBadge, ShadToast

**호출 시점:** 모든 UI 컴포넌트 구현 시

**참고:** Material과 혼용 가능, const 최적화 적용

---

### 09_manseryeok_calculator (Domain 전문)

**역할:** 만세력(사주팔자) 계산 전문 에이전트

**핵심 기능:**
- 사주팔자 계산 (년주, 월주, 일주, 시주)
- 음양력 변환
- 진태양시 보정 (지역별 시차)
- 절입시간 처리 (24절기 기준)
- 서머타임 보정 (1948-1951, 1955-1960, 1987-1988)
- 야자시/조자시 처리

**호출 시점:** 사주 계산 로직 구현 시

**참고:** 독립 실행 가능, 포스텔러 만세력과 검증 필요
