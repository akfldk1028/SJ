# JH_Agent - 서브 에이전트 모음

> 만톡 프로젝트를 위한 전문 서브 에이전트

---

## 에이전트 목록

| 순서 | 에이전트 | 역할 | 우선순위 |
|------|----------|------|----------|
| **00** | **widget_tree_guard** | 위젯 트리 최적화 검증 | **최우선** |
| 01 | feature_builder | Feature 폴더 구조 생성 | - |
| 02 | widget_composer | 화면을 작은 위젯으로 분해 | - |
| 03 | provider_builder | Riverpod Provider 생성 | - |
| 04 | model_generator | Entity/Model 클래스 생성 | - |
| 05 | router_setup | go_router 라우팅 설정 | - |
| 06 | local_storage | Hive 로컬 저장소 설정 | - |
| 07 | task_tracker | TASKS.md 진행 관리 | - |
| **08** | **shadcn_ui_builder** | shadcn_ui 모던 UI 구현 | **UI 필수** |

---

## 사용 규칙

### 1. Widget Tree Guard는 필수

```
모든 위젯 코드 작성 전/후에 00_widget_tree_guard 호출
```

### 2. 작업 흐름

```
1. 07_task_tracker → 현재 할 일 확인
2. 01_feature_builder → 폴더 구조 생성 (새 기능 시)
3. 04_model_generator → Entity/Model 생성
4. 03_provider_builder → Provider 생성
5. 02_widget_composer → 위젯 트리 설계
6. 00_widget_tree_guard → 코드 검증 (필수!)
7. 05_router_setup → 라우트 추가
8. 06_local_storage → 로컬 저장 설정
9. 07_task_tracker → 완료 표시
```

### 3. 호출 방법

Main Claude가 Task 도구로 서브 에이전트 역할을 수행:

```
Task 도구 사용:
- prompt: "00_widget_tree_guard 역할로 다음 코드 검증: ..."
- subagent_type: general-purpose
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
