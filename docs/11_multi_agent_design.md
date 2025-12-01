# 멀티에이전트 설계서

> Claude CLI 기반 자동화된 Worker Agent 호출 구조

---

## 1. Agent 구조 개요

```
┌─────────────────────────────────────────────────────────────┐
│                    ORCHESTRATOR (Main Agent)                 │
│                     Claude CLI Entry Point                   │
└─────────────────────────────┬───────────────────────────────┘
                              │
    ┌────────┬────────┬───────┼───────┬────────┬────────┐
    │        │        │       │       │        │        │
    ▼        ▼        ▼       ▼       ▼        ▼        ▼
┌──────┐ ┌──────┐ ┌───────┐ ┌──────┐ ┌──────┐ ┌──────┐
│ TODO │ │ LOG  │ │ ARCH  │ │MODULE│ │ TEST │ │DELETE│
│AGENT │ │AGENT │ │ AGENT │ │AGENT │ │AGENT │ │AGENT │
└──────┘ └──────┘ └───────┘ └──────┘ └──────┘ └──────┘
   │        │         │        │        │        │
   ▼        ▼         ▼        ▼        ▼        ▼
 작업     전과정     구조     코드     테스트   파일
 분해     기록      설계     구현     검증     정리
```

---

## 2. Agent 정의

### 2.1 TODO AGENT
| 항목 | 내용 |
|------|------|
| 역할 | 작업 분해, 체크리스트 생성, 진행률 추적 |
| 트리거 | `/todo [기능명]` |
| 출력 | 작업 목록 (TodoWrite 연동) |

**담당 작업:**
- 사용자 명령 → 세부 작업 분해
- 체크리스트 생성 (수락 조건 기반)
- 진행률 실시간 추적
- 다른 Agent에게 작업 할당

**예시:**
```bash
/todo profile_input

# 출력:
# [ ] 1. Domain Layer 구현 (entity, repository interface)
# [ ] 2. Data Layer 구현 (model, datasource, repository impl)
# [ ] 3. Presentation Layer 구현 (provider, screen, widgets)
# [ ] 4. 테스트 작성
# [ ] 5. 코드 정리
```

---

### 2.2 LOG AGENT
| 항목 | 내용 |
|------|------|
| 역할 | 모든 Agent 활동 기록, 에러 수집, 히스토리 관리 |
| 트리거 | 자동 (모든 Agent 활동 감시) |
| 출력 | `.claude/logs/[날짜].md` |

**담당 작업:**
- 모든 Agent 활동 기록 (옵저버 패턴)
- 에러/경고 수집
- 변경 이력 관리
- 디버깅 정보 저장

**로그 포맷:**
```markdown
## 2025-12-01 14:30:00
- [TODO] profile_input 작업 분해 완료 (5개 태스크)
- [ARCH] lib/features/profile/ 폴더 구조 생성
- [MODULE] saju_profile.dart 생성
- [ERROR] ProfileRepository: missing import
- [MODULE] import 추가 후 재생성
- [TEST] profile_test.dart 3/3 통과
- [DELETE] unused_widget.dart 삭제
```

---

### 2.3 ARCHITECTURE AGENT
| 항목 | 내용 |
|------|------|
| 역할 | 폴더 구조 생성, 아키텍처 패턴 적용, 의존성 분석 |
| 트리거 | `/arch [기능명]` |
| 참조 문서 | `03_architecture.md`, `09_state_management.md` |
| 출력 | 폴더 구조, 빈 파일 템플릿 |

**담당 작업:**
- docs/ 문서 기반 구조 설계
- Feature 폴더 구조 자동 생성
- 의존성 분석 (import 관계)
- 패턴 적용 (MVVM, Riverpod 3.0)

**생성 구조:**
```
lib/features/[feature_name]/
├── domain/
│   ├── entities/
│   │   └── [entity].dart          # 빈 템플릿
│   └── repositories/
│       └── [repo]_repository.dart  # interface
├── data/
│   ├── models/
│   │   └── [model]_model.dart
│   ├── datasources/
│   │   └── [feature]_remote_datasource.dart
│   └── repositories/
│       └── [repo]_repository_impl.dart
└── presentation/
    ├── providers/
    │   └── [feature]_provider.dart
    ├── screens/
    │   └── [feature]_screen.dart
    └── widgets/
        └── .gitkeep
```

---

### 2.4 MODULE AGENT
| 항목 | 내용 |
|------|------|
| 역할 | 실제 코드 구현 |
| 트리거 | `/module [기능명]` |
| 참조 문서 | `02_features/*.md`, `04_data_models.md`, `05_api_spec.md` |
| 출력 | Dart 코드 파일 |

**담당 작업:**
- 명세서 기반 코드 구현
- Domain/Data/Presentation 레이어 코드
- Supabase 연동 코드
- Riverpod Provider 생성

**구현 순서:**
```
1. Domain Layer
   └─ entities → repositories (interface)

2. Data Layer
   └─ models → datasources → repositories (impl)

3. Presentation Layer
   └─ providers → screens → widgets
```

**코드 규칙:**
- `09_state_management.md` Riverpod 3.0 패턴 준수
- `10_widget_tree_optimization.md` 위젯 최적화 적용
- const 위젯 사용
- 에러 처리 포함

---

### 2.5 TEST AGENT
| 항목 | 내용 |
|------|------|
| 역할 | 테스트 코드 작성, 테스트 실행 |
| 트리거 | `/test [기능명]` |
| 참조 문서 | `02_features/*.md` (테스트 케이스 섹션) |
| 출력 | 테스트 파일, 실행 결과 |

**담당 작업:**
- Unit Test (Provider, Repository)
- Widget Test (Screen, Widget)
- 테스트 실행 (`flutter test`)
- 커버리지 보고

**테스트 구조:**
```
test/features/[feature_name]/
├── domain/
│   └── repositories/
├── data/
│   └── repositories/
└── presentation/
    ├── providers/
    └── screens/
```

---

### 2.6 DELETE AGENT
| 항목 | 내용 |
|------|------|
| 역할 | 불필요한 파일/코드 삭제, 정리 |
| 트리거 | `/delete` 또는 `/clean` |
| 출력 | 삭제된 파일 목록 |

**담당 작업:**
- 사용하지 않는 import 제거
- 빈 파일/폴더 삭제
- Dead code 제거
- 중복 코드 정리
- 주석 처리된 코드 삭제
- unused 변수/함수 제거

**삭제 대상:**
```dart
// 삭제 대상 예시
import 'package:unused/unused.dart';  // unused import
final _unusedVar = 'test';            // unused variable
void _unusedFunction() {}             // unused function
// final oldCode = 'commented';       // commented code
```

**안전장치:**
- 삭제 전 목록 확인 요청
- `.gitignore` 파일은 삭제 안함
- `pubspec.yaml`, `main.dart` 등 핵심 파일 보호

---

## 3. Agent 실행 흐름

### 3.1 전체 빌드 흐름 (`/build [기능명]`)

```
사용자: /build profile_input
         │
         ▼
┌─────────────────────────────────────────┐
│ TODO AGENT                              │
│ - docs/02_features/profile_input.md 분석│
│ - 작업 5개로 분해                        │
│ - 체크리스트 생성                        │
└────────────────┬────────────────────────┘
                 │
         ┌───────┴───────┐
         │               │
         ▼               ▼
┌─────────────┐   ┌─────────────┐
│ LOG AGENT   │   │ ARCH AGENT  │
│ 시작 로그    │   │ 폴더 구조    │
│ 기록        │   │ 생성        │
└─────────────┘   └──────┬──────┘
                         │
                         ▼
              ┌─────────────────┐
              │ MODULE AGENT    │
              │ - Domain 구현    │
              │ - Data 구현      │
              │ - Presentation  │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │ TEST AGENT      │
              │ - 테스트 작성    │
              │ - 테스트 실행    │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │ DELETE AGENT    │
              │ - unused 정리   │
              │ - 코드 클린업    │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │ LOG AGENT       │
              │ 완료 로그 기록   │
              └─────────────────┘
```

### 3.2 개별 Agent 호출

```bash
# TODO만 실행
/todo profile_input

# ARCHITECTURE만 실행
/arch profile_input

# MODULE만 실행 (ARCH 선행 필요)
/module profile_input

# TEST만 실행 (MODULE 선행 필요)
/test profile_input

# DELETE만 실행 (언제든 가능)
/delete

# 전체 흐름
/build profile_input
```

---

## 4. 슬래시 커맨드 정의

| 커맨드 | Agent | 설명 |
|--------|-------|------|
| `/todo [기능]` | TODO | 작업 분해 및 체크리스트 |
| `/arch [기능]` | ARCHITECTURE | 폴더 구조 생성 |
| `/module [기능]` | MODULE | 코드 구현 |
| `/test [기능]` | TEST | 테스트 작성/실행 |
| `/delete` | DELETE | 불필요한 파일 정리 |
| `/clean` | DELETE | `/delete` 별칭 |
| `/build [기능]` | 전체 | TODO→ARCH→MODULE→TEST→DELETE |
| `/log` | LOG | 최근 로그 조회 |
| `/status` | TODO | 현재 진행 상황 |

---

## 5. 문서-Agent 매핑

| 문서 | 참조하는 Agent |
|------|----------------|
| `01_overview.md` | TODO, ARCH |
| `02_features/*.md` | TODO, MODULE, TEST |
| `03_architecture.md` | ARCH, MODULE |
| `04_data_models.md` | ARCH, MODULE |
| `05_api_spec.md` | MODULE |
| `06_navigation.md` | MODULE |
| `07_design_system.md` | MODULE |
| `09_state_management.md` | MODULE |
| `10_widget_tree_optimization.md` | MODULE |

---

## 6. 파일 구조

```
D:\Data\20_Flutter\01_SJ\
├── docs/                          # 기획 문서
│   ├── 01_overview.md
│   ├── 02_features/
│   │   ├── profile_input.md       # P0
│   │   ├── saju_chat.md           # P0
│   │   └── auth.md                # P1
│   ├── 03_architecture.md
│   ├── ...
│   └── 11_multi_agent_design.md   # 이 문서
│
├── frontend/                      # Flutter 프로젝트
│   ├── lib/
│   │   ├── core/
│   │   ├── features/
│   │   └── shared/
│   └── test/
│
└── .claude/                       # Claude CLI 설정
    ├── commands/                  # 슬래시 커맨드
    │   ├── todo.md
    │   ├── arch.md
    │   ├── module.md
    │   ├── test.md
    │   ├── delete.md
    │   └── build.md
    └── logs/                      # LOG AGENT 출력
        └── 2025-12-01.md
```

---

## 7. 사용 예시

### 7.1 새 기능 전체 구현
```bash
# 프로필 입력 기능 전체 구현
claude "/build profile_input"

# 결과:
# [TODO] 5개 작업 생성
# [ARCH] lib/features/profile/ 구조 생성
# [MODULE] 12개 파일 생성
# [TEST] 8개 테스트 작성, 8/8 통과
# [DELETE] 2개 unused import 제거
# [LOG] 완료 - 총 15분 소요
```

### 7.2 특정 단계만 실행
```bash
# 구조만 먼저 생성
claude "/arch saju_chat"

# 나중에 코드 구현
claude "/module saju_chat"
```

### 7.3 정리 작업
```bash
# 전체 프로젝트 정리
claude "/delete"

# 결과:
# - 삭제 대상 3개 발견
#   1. lib/features/profile/unused_helper.dart
#   2. 5개 unused import
#   3. 2개 commented code block
# 삭제하시겠습니까? (y/n)
```

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 | 작성자 |
|------|------|-----------|--------|
| 2025-12-01 | 0.1 | 초안 작성 | - |
| 2025-12-01 | 0.2 | Agent 구조 변경 (TODO/LOG/ARCH/MODULE/TEST/DELETE) | - |
