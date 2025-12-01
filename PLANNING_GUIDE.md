# AI에게 기획 전달하는 가이드

## 핵심 원칙

> "AI 실패는 모델 실패가 아니라 **컨텍스트 실패**다"

막연한 지시("앱에 사진 공유 기능 추가해줘") → AI가 수천 가지 요구사항을 추측해야 함
명확한 스펙 제공 → AI가 무엇을, 어떻게, 어떤 순서로 만들지 정확히 앎

---

## 1. 기획 문서 구조 (권장 템플릿)

### 1.1 프로젝트 개요
```markdown
## 프로젝트명: [이름]

### 한 줄 요약
[이 앱이 무엇인지 한 문장으로]

### 목표 사용자
- 누가 쓰는가?
- 어떤 문제를 해결하는가?

### 핵심 가치 (MVP 기능)
1. [기능1]
2. [기능2]
3. [기능3]
```

### 1.2 기능 명세 (Feature Spec)
```markdown
## 기능: [기능명]

### 사용자 스토리
"[사용자]로서, [목적]을 위해 [행동]을 하고 싶다"

### 수락 조건 (Acceptance Criteria)
- [ ] 조건1
- [ ] 조건2
- [ ] 조건3

### UI/UX 흐름
1. 사용자가 X를 탭한다
2. Y 화면이 나타난다
3. Z를 입력하면 W가 발생한다

### 예외 케이스
- 네트워크 오류 시: ...
- 빈 입력 시: ...
```

### 1.3 기술 스펙
```markdown
## 시스템 아키텍처

### 레이어 구조
- UI Layer: Flutter (Riverpod/BLoC)
- Domain Layer: Use Cases
- Data Layer: Repository Pattern

### 외부 의존성
- Backend API: [URL/스펙]
- 인증: Firebase Auth / 자체 JWT
- DB: SQLite / Hive / Supabase

### 폴더 구조
lib/
├── core/          # 공통 유틸, 상수
├── features/      # 기능별 모듈
│   └── auth/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── shared/        # 공유 위젯
```

---

## 2. Subagent 설계 패턴

### 2.1 Supervisor/Orchestrator 패턴 (권장)
```
┌─────────────────────────────────────┐
│         Main Orchestrator           │
│   (전체 기획 이해, 작업 분배)         │
└──────────────┬──────────────────────┘
               │
    ┌──────────┼──────────┐
    ▼          ▼          ▼
┌────────┐ ┌────────┐ ┌────────┐
│ UI     │ │ Logic  │ │ Data   │
│ Agent  │ │ Agent  │ │ Agent  │
└────────┘ └────────┘ └────────┘
```

### 2.2 각 Subagent 역할 정의
```markdown
## Agent: UI Builder
- 역할: Flutter 위젯, 화면 레이아웃 구현
- 도구: Flutter SDK, 디자인 시스템
- 입력: 와이어프레임, UI 명세
- 출력: lib/features/*/presentation/*.dart

## Agent: Business Logic
- 역할: 상태 관리, Use Case 구현
- 도구: Riverpod/BLoC, Domain 패턴
- 입력: 기능 명세, 비즈니스 룰
- 출력: lib/features/*/domain/*.dart

## Agent: Data Handler
- 역할: API 연동, 로컬 저장소 구현
- 도구: Dio, Hive, Repository 패턴
- 입력: API 스펙, 데이터 모델
- 출력: lib/features/*/data/*.dart
```

---

## 3. AI에게 전달할 때 체크리스트

### 필수 포함 항목
- [ ] **목표**: 이 작업이 끝나면 뭐가 완성되어야 하는가?
- [ ] **범위**: 무엇을 하고, 무엇을 하지 않는가?
- [ ] **수락 조건**: 어떻게 되면 "완료"인가?
- [ ] **기술 스택**: 어떤 도구/패턴을 쓰는가?
- [ ] **기존 코드**: 참고할 파일/패턴이 있는가?

### 좋은 예시 vs 나쁜 예시

❌ 나쁜 예시:
```
"로그인 기능 만들어줘"
```

✅ 좋은 예시:
```
## 작업: 로그인 화면 구현

### 목표
이메일/비밀번호 로그인 화면 구현

### 수락 조건
- [ ] 이메일 형식 검증 (regex)
- [ ] 비밀번호 6자 이상 검증
- [ ] 로그인 버튼 클릭 시 API 호출
- [ ] 성공 시 홈 화면으로 이동
- [ ] 실패 시 에러 메시지 표시

### 기술 스택
- 상태관리: Riverpod
- API: Dio + Repository 패턴
- 라우팅: go_router

### 참고 파일
- lib/features/auth/data/auth_repository.dart
- lib/shared/widgets/custom_text_field.dart
```

---

## 4. 작업 진행 워크플로우

```
1. SPEC (명세)
   └─ 고수준 설명 → AI가 상세 스펙 생성

2. PLAN (계획)
   └─ 스펙 기반 → 기술 아키텍처 설계

3. TASKS (작업)
   └─ 계획 → 작은 단위 태스크로 분해

4. IMPLEMENT (구현)
   └─ 태스크 하나씩 → 코드 작성 & 리뷰
```

---

## 5. 폴더 구조 제안

```
D:\Data\20_Flutter\01_SJ\
├── docs/                    # 기획 문서
│   ├── 01_overview.md       # 프로젝트 개요
│   ├── 02_features/         # 기능별 명세
│   │   ├── auth.md
│   │   ├── home.md
│   │   └── settings.md
│   ├── 03_architecture.md   # 시스템 아키텍처
│   └── 04_api_spec.md       # API 명세
├── frontend/                # Flutter 앱
├── backend/                 # 백엔드 서버
└── agent/                   # AI 에이전트 설정
```

---

## 6. 다음 단계

1. **`docs/01_overview.md`** 작성
   - 프로젝트가 뭔지, 누가 쓰는지, 핵심 기능 3개

2. **`docs/02_features/`** 기능별 명세
   - 각 기능마다 사용자 스토리 + 수락 조건

3. **`docs/03_architecture.md`** 기술 설계
   - 레이어 구조, 상태관리 방식, API 연동 방식

4. 위 문서 완성 후 AI에게 전달:
   ```
   "docs/ 폴더의 기획 문서를 읽고,
   auth 기능부터 순차적으로 구현해줘.
   각 파일 작성 전에 계획을 먼저 보여줘."
   ```

---

## 참고 자료

- [Flutter 공식 아키텍처 가이드](https://docs.flutter.dev/app-architecture)
- [MVVM 패턴 상세 가이드](https://docs.flutter.dev/app-architecture/guide)
- [GitHub Spec-Driven Development](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)
- [Anthropic Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system)
- [LangChain Multi-Agent 가이드](https://blog.langchain.com/how-and-when-to-build-multi-agent-systems/)
