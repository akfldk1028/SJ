# Orchestrator Agent (오케스트레이터)

> 모든 작업의 진입점. 작업 유형을 분석하고 적절한 Agent 파이프라인을 구성하여 실행

---

## 역할

1. **작업 분석**: 요청을 분석하여 필요한 Agent들 식별
2. **파이프라인 구성**: Agent 실행 순서와 의존성 결정
3. **결과 조율**: Agent 간 결과 전달 및 통합
4. **품질 게이트**: 각 단계별 검증 포인트 관리

---

## 자동 호출 조건

Main Claude가 다음 키워드/패턴 감지 시 자동 활성화:

```yaml
triggers:
  - "새 기능 구현"
  - "Feature 추가"
  - "화면 만들어"
  - "위젯 구현"
  - "Provider 생성"
  - "로직 구현"
  - 파일 생성 요청 (3개 이상)
  - 복잡도 > 3단계
```

---

## 파이프라인 정의

### Pipeline A: 새 Feature 구현

```
[요청] → [Orchestrator]
            ↓
        ① 01_feature_builder
            ├── 폴더 구조 생성
            └── 기본 파일 스캐폴딩
            ↓
        ② 04_model_generator
            ├── Entity 정의
            └── Model (fromJson/toJson)
            ↓
        ③ 03_provider_builder
            ├── Provider 생성
            └── State 정의
            ↓
        ④ 02_widget_composer
            ├── Screen 구조 설계
            └── Widget 분해
            ↓
        ⑤ 08_shadcn_ui_builder
            ├── UI 컴포넌트 적용
            └── 테마 일관성
            ↓
        ⑥ 00_widget_tree_guard ← (필수 게이트)
            ├── const 검증
            └── 최적화 체크
            ↓
        ⑦ 05_router_setup
            └── 라우트 등록
            ↓
        ⑧ 06_local_storage (필요시)
            └── Hive 설정
            ↓
        ⑨ 07_task_tracker
            └── TASKS.md 업데이트
```

### Pipeline B: 위젯만 수정

```
[요청] → [Orchestrator]
            ↓
        ① 02_widget_composer (분석)
            ↓
        ② 08_shadcn_ui_builder
            ↓
        ③ 00_widget_tree_guard ← (필수 게이트)
            ↓
        ④ 07_task_tracker
```

### Pipeline C: 로직 구현 (비즈니스 로직)

```
[요청] → [Orchestrator]
            ↓
        ① 04_model_generator (필요시)
            ↓
        ② 03_provider_builder
            ↓
        ③ 07_task_tracker
```

### Pipeline D: 만세력/사주 계산 (특수)

```
[요청] → [Orchestrator]
            ↓
        ① 09_manseryeok_calculator ← (NEW)
            ├── 사주팔자 계산
            ├── 음양력 변환
            ├── 진태양시 보정
            └── 절입시간 처리
            ↓
        ② 04_model_generator
            └── SajuChart Entity/Model
            ↓
        ③ 03_provider_builder
            ↓
        ④ 00_widget_tree_guard (표시 위젯)
            ↓
        ⑤ 07_task_tracker
```

---

## 호출 방법 (Main Claude용)

```
Task 도구 사용:
- prompt: |
    [Orchestrator] 다음 작업 수행:
    - 작업: {작업 설명}
    - 참조: docs/02_features/{feature}.md
    - 우선순위: {P0/P1/P2}

    Pipeline 자동 선택 후 순차 실행.
    각 단계 완료 시 결과 리포트.

- subagent_type: general-purpose
```

---

## 출력 형식

```markdown
## Orchestrator 실행 결과

### 선택된 Pipeline
- Type: Pipeline A (새 Feature 구현)
- 이유: 새 기능 + UI 포함

### 실행 단계

| 순서 | Agent | 상태 | 결과 |
|------|-------|------|------|
| ① | feature_builder | ✅ | 8 files created |
| ② | model_generator | ✅ | SajuProfile, Gender |
| ③ | provider_builder | ✅ | profile_provider.dart |
| ④ | widget_composer | ✅ | 5 widgets designed |
| ⑤ | shadcn_ui_builder | ✅ | UI applied |
| ⑥ | widget_tree_guard | ⚠️ | 2 issues found |
| ⑦ | router_setup | ⏳ | waiting |

### 품질 게이트 결과
- widget_tree_guard: 2 issues → 자동 수정됨
- const 누락 2건 → 수정 완료

### 다음 단계
- router_setup 진행 대기
- TASKS.md 업데이트 필요
```

---

## 의존성 규칙

```yaml
dependencies:
  02_widget_composer:
    requires: [01_feature_builder]
  03_provider_builder:
    requires: [04_model_generator]
  05_router_setup:
    requires: [02_widget_composer]
  06_local_storage:
    requires: [04_model_generator]
  00_widget_tree_guard:
    required_before: [commit, PR]
    blocks: [05_router_setup] # 통과해야 진행
```

---

## 병렬 실행 최적화

```
독립적인 Agent는 병렬 실행:

Serial (의존성 있음):
  feature_builder → model_generator → provider_builder

Parallel (독립적):
  ┌ widget_composer ─┐
  │                  ├→ widget_tree_guard
  └ shadcn_ui_builder┘

Serial (마무리):
  router_setup → local_storage → task_tracker
```
