# GEMINI.md

이 파일은 Gemini Agent가 작업을 수행할 때 반드시 준수해야 할 규칙과 가이드라인을 정의합니다.

---

## 🚨 핵심 작업 수칙 (Critical Rules)

### 1. 선(先) 승인, 후(後) 작업 (Ask Before Action)
- **절대 사용자의 명시적인 지시 없이 코드를 생성하거나 수정하지 않는다.**
- 계획(Plan) 단계에서 멈추고, 사용자의 승인을 받은 후에만 실행(Execution) 단계로 넘어간다.
- "진행해", "시작해", "구현해" 등의 명확한 명령이 있을 때만 코드를 작성한다.

### 2. SubAgent 활용 (Leverage SubAgents)
- Claude가 생성해둔 `.claude/JH_Agent/` 경로의 SubAgent 정의 파일들을 적극 활용한다.
- 각 작업의 성격에 맞는 SubAgent의 가이드라인을 참고하여 개발한다.

#### 📂 SubAgent 목록 (.claude/JH_Agent/)
| 파일명 | 역할 | 활용 시점 |
|--------|------|-----------|
| `00_orchestrator.md` | 작업 분석 & 파이프라인 구성 | 복잡한 작업 시작 전 전체 흐름 설계 시 |
| `00_widget_tree_guard.md` | **위젯 최적화 검증 (품질 게이트)** | UI 구현 시 필수 체크 (const, 100줄 이하 등) |
| `01_feature_builder.md` | Feature 폴더 구조 생성 | 새로운 기능(Feature) 추가 시 |
| `02_widget_composer.md` | 화면 분해 | 복잡한 화면을 작은 위젯으로 나눌 때 |
| `03_provider_builder.md` | Riverpod Provider 생성 | 상태 관리 로직 구현 시 |
| `04_model_generator.md` | Entity/Model 생성 | 데이터 모델링 시 |
| `05_router_setup.md` | GoRouter 설정 | 라우팅 경로 추가 시 |
| `06_local_storage.md` | Hive 저장소 설정 | 로컬 데이터 저장 로직 구현 시 |
| `07_task_tracker.md` | TASKS.md 관리 | 작업 진행 상황 업데이트 시 |
| `08_shadcn_ui_builder.md` | **Shadcn UI 구현** | 모든 UI 컴포넌트 개발 시 (디자인 시스템 준수) |
| `09_manseryeok_calculator.md` | 만세력 계산 로직 | 사주/만세력 관련 도메인 로직 구현 시 |

---

## 📝 작업 프로세스 (Workflow)

1.  **지시 확인**: 사용자의 요청을 분석하고, `TASKS.md`를 확인하여 현재 프로젝트 상태를 파악한다.
2.  **SubAgent 참조**: 해당 작업에 필요한 SubAgent 파일(`md`)을 읽고 가이드라인을 숙지한다.
3.  **계획 수립 (Planning)**: `implementation_plan.md`를 작성하거나 수정하여 사용자에게 제안한다.
4.  **승인 대기**: **반드시 사용자의 승인을 기다린다.**
5.  **구현 (Execution)**: 승인 후, 계획에 따라 코드를 작성한다. 이때 `00_widget_tree_guard.md` 등의 품질 기준을 준수한다.
6.  **기록 (Documentation)**: 작업 완료 후 `TASKS.md`를 업데이트하고, 필요 시 `walkthrough.md`를 작성한다.

---

## ⚠️ 주의사항 (Reminders)

- **TASKS.md 업데이트**: 작업이 끝나면 반드시 `TASKS.md`를 최신 상태로 업데이트한다. (Claude와의 협업을 위해 필수)
- **UI/UX**: `shadcn_ui`를 기본으로 사용하며, `08_shadcn_ui_builder.md`의 규칙을 따른다.
- **최적화**: 위젯은 100줄 이하로 유지하고, `const` 생성자를 적극 사용한다 (`00_widget_tree_guard.md`).
