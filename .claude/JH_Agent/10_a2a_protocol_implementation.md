# A2A Protocol Implementation Analysis

> 2025-12-04 작성 [Claude]
> Google A2A (Agent2Agent) 프로토콜 자체 구현 가능성 분석
> **Updated**: 2025-12-04 - 공식 SDK 및 스펙 상세 추가

---

## 1. A2A 프로토콜 개요

### 1.1 정의
- **발표**: 2025년 4월 Google
- **이관**: 2025년 6월 Linux Foundation
- **버전**: v0.3 (현재)
- **참여사**: 150개+ (Salesforce, SAP, PayPal, MongoDB, Anthropic 등)
- **공식 사이트**: https://a2a-protocol.org

### 1.2 핵심 개념

| 비교 | MCP (Anthropic) | A2A (Google) |
|------|-----------------|--------------|
| 역할 | 에이전트에게 **도구** 제공 | 에이전트끼리 **대화** |
| 비유 | "도구 장착" | "팀 협업" |
| 초점 | 개별 에이전트 능력 | 멀티에이전트 조율 |
| 상태 | 도구는 stateless | Task는 stateful |

> "MCP가 에이전트에게 도구를 주는 거라면, A2A는 에이전트들이 그 도구를 들고 협업하는 대화"

### 1.3 A2A가 해결하는 문제

```
기존 문제:
├── Claude는 Claude끼리만 대화
├── Gemini는 Gemini끼리만 대화
├── 서로 다른 벤더 에이전트 간 협업 불가
└── 각자 다른 프로토콜, 다른 메시지 형식

A2A 해결:
├── 공통 Agent Card (능력 선언)
├── 공통 Task 관리 (생성/조회/취소)
├── 공통 Message 형식 (JSON-RPC 2.0)
└── 벤더 무관 협업 가능
```

### 1.4 프로토콜 3계층 구조

```
┌─────────────────────────────────────────┐
│  Layer 3: Protocol Bindings             │
│  (JSON-RPC 2.0 / gRPC / HTTP+REST)      │
├─────────────────────────────────────────┤
│  Layer 2: Abstract Operations (11개)    │
│  (SendMessage, GetTask, Cancel...)      │
├─────────────────────────────────────────┤
│  Layer 1: Canonical Data Model          │
│  (Task, Message, AgentCard, Artifact)   │
└─────────────────────────────────────────┘
```

---

## 2. A2A 핵심 구성요소

### 2.1 Agent Card (에이전트 명함)

```json
{
  "name": "Claude Code Agent",
  "description": "Code generation and review specialist",
  "url": "https://api.example.com/claude-agent",
  "version": "1.0.0",
  "capabilities": {
    "streaming": true,
    "pushNotifications": false
  },
  "skills": [
    {
      "id": "code-generation",
      "name": "Code Generation",
      "description": "Generate code in multiple languages",
      "inputModes": ["text"],
      "outputModes": ["text", "file"]
    },
    {
      "id": "code-review",
      "name": "Code Review",
      "description": "Review and suggest improvements",
      "inputModes": ["text", "file"],
      "outputModes": ["text"]
    }
  ],
  "authentication": {
    "schemes": ["bearer"]
  }
}
```

### 2.2 핵심 11개 Operations (Layer 2)

| Operation | 설명 |
|-----------|------|
| `SendMessage` | 에이전트에 메시지 전송 → Task/Message 반환 |
| `SendStreamingMessage` | 실시간 스트리밍 응답 |
| `GetTask` | Task 상태/결과 조회 |
| `ListTasks` | Task 목록 (필터/페이징) |
| `CancelTask` | Task 취소 요청 |
| `SubscribeToTask` | Task 업데이트 구독 (스트리밍) |
| `SetPushNotificationConfig` | Webhook 설정 |
| `GetPushNotificationConfig` | Webhook 조회 |
| `ListPushNotificationConfigs` | Webhook 목록 |
| `DeletePushNotificationConfig` | Webhook 삭제 |
| `GetExtendedAgentCard` | 인증된 Agent Card 조회 |

### 2.3 Task Lifecycle (TaskState)

```
┌───────────┐    working    ┌─────────┐    complete   ┌───────────┐
│ SUBMITTED │ ────────────► │ WORKING │ ────────────► │ COMPLETED │
└───────────┘               └─────────┘               └───────────┘
     │                           │
     │                           ├──► FAILED
     │                           ├──► CANCELLED
     │                           ├──► INPUT_REQUIRED (사용자 입력 필요)
     │                           ├──► REJECTED
     └───────────────────────────┴──► AUTH_REQUIRED
```

### 2.4 3가지 응답 전달 방식

| 방식 | 설명 | 용도 |
|------|------|------|
| **Polling** | GetTask 반복 호출 | 단순 작업 |
| **Streaming** | SSE 실시간 전달 | 대화형 |
| **Push** | Webhook POST | 장시간 작업 |

### 2.5 Message Format (JSON-RPC 2.0)

```json
// Request
{
  "jsonrpc": "2.0",
  "id": "task-123",
  "method": "tasks/send",
  "params": {
    "id": "task-123",
    "message": {
      "role": "user",
      "parts": [
        {"type": "text", "text": "Review this Flutter code"}
      ]
    }
  }
}

// Response
{
  "jsonrpc": "2.0",
  "id": "task-123",
  "result": {
    "id": "task-123",
    "status": {"state": "completed"},
    "artifacts": [
      {
        "name": "review-result",
        "parts": [{"type": "text", "text": "Code review completed..."}]
      }
    ]
  }
}
```

### 2.6 Transport Layer (Protocol Bindings)

| 프로토콜 | 용도 | 지원 |
|----------|------|------|
| HTTP + JSON-RPC 2.0 | 기본 요청/응답 | ✅ 필수 |
| SSE | 스트리밍 응답 | ✅ 필수 |
| gRPC | 고성능 통신 | ✅ v0.3+ |
| HTTP + REST | RESTful 패턴 | ✅ 지원 |

### 2.7 인증 방식

- API Key
- OAuth 2.0
- Mutual TLS
- OpenID Connect

---

## 3. 공식 Python SDK (a2a-sdk)

### 3.1 설치

```bash
# 기본 설치
pip install a2a-sdk
# 또는 uv 사용 (권장)
uv add a2a-sdk

# 선택적 패키지
uv add "a2a-sdk[http-server]"  # FastAPI/Starlette 지원
uv add "a2a-sdk[grpc]"          # gRPC 지원
uv add "a2a-sdk[telemetry]"     # OpenTelemetry
uv add "a2a-sdk[encryption]"    # 암호화
uv add "a2a-sdk[sql]"           # PostgreSQL/MySQL/SQLite
uv add "a2a-sdk[all]"           # 모든 기능

# 요구사항: Python 3.10+
```

### 3.2 핵심 코드 패턴 (공식 샘플)

**agent_executor.py** - 에이전트 로직 구현
```python
from a2a.server.agent_execution import AgentExecutor, RequestContext
from a2a.server.events import EventQueue
from a2a.utils import new_agent_text_message


class HelloWorldAgent:
    """실제 AI 로직을 담는 클래스"""

    async def invoke(self) -> str:
        return 'Hello World'


class HelloWorldAgentExecutor(AgentExecutor):
    """A2A 프로토콜과 연결하는 Executor"""

    def __init__(self):
        self.agent = HelloWorldAgent()

    async def execute(
        self,
        context: RequestContext,
        event_queue: EventQueue,
    ) -> None:
        result = await self.agent.invoke()
        await event_queue.enqueue_event(new_agent_text_message(result))

    async def cancel(
        self, context: RequestContext, event_queue: EventQueue
    ) -> None:
        raise Exception('cancel not supported')
```

**__main__.py** - 서버 설정
```python
# 핵심 구성요소:
# 1. 기본 스킬 정의 (hello_world)
# 2. 확장 스킬 정의 (super_hello_world - 인증 필요)
# 3. 공개 Agent Card (기본 스킬만)
# 4. 확장 Agent Card (모든 스킬 - 인증된 사용자용)
# 5. DefaultRequestHandler + A2AStarletteApplication
# 6. uvicorn 서버 실행 (localhost:9999)
```

**test_client.py** - 클라이언트
```python
# 1. A2ACardResolver → Agent Card 조회
# 2. 공개/확장 카드 분리 처리
# 3. A2AClient → 메시지 전송
# 4. 스트리밍 응답 처리
```

### 3.3 실행 방법

```bash
# 에이전트 서버 실행
git clone https://github.com/a2aproject/a2a-samples.git
cd a2a-samples/samples/python/agents/helloworld
uv run .

# 클라이언트 테스트 (별도 터미널)
uv run test_client.py
```

### 3.4 SDK 사용 시 이점

| 항목 | 직접 구현 | SDK 사용 |
|------|----------|----------|
| Agent Card | 수동 JSON 작성 | 자동 생성 |
| Task 관리 | Redis 직접 연동 | 내장 기능 |
| SSE 스트리밍 | sse-starlette 설정 | EventQueue 사용 |
| JSON-RPC | 직접 파싱 | 자동 처리 |
| 인증 | 직접 구현 | 내장 스킴 |
| **예상 시간** | 4-6주 | **1-2주** |

---

## 4. 구현 가능성 분석

### 4.1 우리가 가진 리소스

| 리소스 | 상태 | 비고 |
|--------|------|------|
| Claude API | ✅ 접근 가능 | Anthropic |
| Gemini API | ✅ 접근 가능 | Google |
| A2A 스펙 | ✅ 오픈소스 | github.com/a2aproject/A2A |
| **공식 SDK** | ✅ **존재** | `pip install a2a-sdk` |
| 기업 지원 | ✅ 긍정적 답변 | Anthropic, Google |

### 4.2 기술적 도전과 해결책 (SDK 사용 시)

| 과제 | 난이도 | 해결책 |
|------|--------|--------|
| Agent Card 정의 | 🟢 쉬움 | SDK 자동 생성 |
| HTTP 서버 | 🟢 쉬움 | `A2AStarletteApplication` 내장 |
| SSE 스트리밍 | 🟢 쉬움 | `EventQueue` 내장 |
| Task 상태 관리 | 🟢 쉬움 | SDK 내장 (선택: SQL 백엔드) |
| JSON-RPC 핸들러 | 🟢 쉬움 | SDK 자동 처리 |
| **컨텍스트 공유** | 🔴 어려움 | **핵심 과제** - 아래 참조 |
| 오류 복구 | 🟡 중간 | SDK 기본 제공 + 커스텀 |

### 4.3 핵심 과제: 컨텍스트 공유

```
문제:
Claude가 작업 A 완료 → Gemini에게 작업 B 전달
                         ↓
            Gemini가 Claude의 작업 A 결과를
            어떻게 이해하고 이어받을까?
```

**해결 방안:**

| 방안 | 설명 | 장단점 |
|------|------|--------|
| Shared Memory | Redis/DB에 중간 결과 저장 | ✅ 간단 / ❌ 동기화 이슈 |
| Context Injection | 이전 작업 요약을 프롬프트에 주입 | ✅ 유연 / ❌ 토큰 소모 |
| Artifact Passing | 코드/문서를 파일로 전달 | ✅ 명확 / ❌ 크기 제한 |
| Hybrid | 위 방안 조합 | ✅ 최적 / ❌ 복잡도 |

**권장 접근 (Hybrid):**
```
1. 작업 결과 요약 → Context Injection (프롬프트)
2. 코드/문서 → Artifact Passing (파일)
3. 메타데이터 → Shared Memory (Redis)
```

---

## 5. 구현 아키텍처

### 5.1 전체 구조

```
┌─────────────────────────────────────────────────────────────┐
│                      Client (Flutter App)                    │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTP/SSE
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Orchestrator API                          │
│                   (Python FastAPI)                           │
├─────────────────────────────────────────────────────────────┤
│  GET  /.well-known/agent.json  → Orchestrator Agent Card    │
│  GET  /agents                  → 등록된 Agent 목록           │
│  POST /tasks                   → Task 생성                   │
│  GET  /tasks/{id}              → Task 상태 조회              │
│  POST /tasks/{id}/send         → Message 전송               │
│  POST /tasks/{id}/cancel       → Task 취소                  │
└──────────┬─────────────────────────────┬────────────────────┘
           │                             │
           │ A2A Protocol                │ A2A Protocol
           ▼                             ▼
┌──────────────────────┐      ┌──────────────────────┐
│   Claude Agent       │      │   Gemini Agent       │
│   (Wrapper Server)   │      │   (Wrapper Server)   │
├──────────────────────┤      ├──────────────────────┤
│ /.well-known/        │      │ /.well-known/        │
│   agent.json         │      │   agent.json         │
│ /tasks (CRUD)        │      │ /tasks (CRUD)        │
│ /tasks/{id}/send     │      │ /tasks/{id}/send     │
└──────────┬───────────┘      └──────────┬───────────┘
           │                             │
           │ API Call                    │ API Call
           ▼                             ▼
┌──────────────────────┐      ┌──────────────────────┐
│   Claude API         │      │   Gemini API         │
│   (Anthropic)        │      │   (Google)           │
└──────────────────────┘      └──────────────────────┘
```

### 5.2 Agent Wrapper 상세

```python
# claude_agent/main.py
from fastapi import FastAPI
from sse_starlette.sse import EventSourceResponse

app = FastAPI()

# Agent Card 제공
@app.get("/.well-known/agent.json")
async def agent_card():
    return {
        "name": "Claude Code Agent",
        "description": "Code generation, review, and debugging",
        "url": "https://claude-agent.example.com",
        "version": "1.0.0",
        "capabilities": {"streaming": True},
        "skills": [
            {
                "id": "code-gen",
                "name": "Code Generation",
                "inputModes": ["text"],
                "outputModes": ["text", "file"]
            },
            {
                "id": "code-review",
                "name": "Code Review",
                "inputModes": ["text", "file"],
                "outputModes": ["text"]
            }
        ]
    }

# Task 생성
@app.post("/tasks")
async def create_task(request: TaskRequest):
    task_id = generate_task_id()
    # Redis에 task 상태 저장
    await redis.set(f"task:{task_id}", {"state": "pending"})
    return {"id": task_id, "status": {"state": "pending"}}

# Message 처리 (SSE 스트리밍)
@app.post("/tasks/{task_id}/send")
async def send_message(task_id: str, message: Message):
    async def event_generator():
        # Claude API 호출
        async for chunk in call_claude_api(message):
            yield {"event": "message", "data": json.dumps(chunk)}
        yield {"event": "done", "data": ""}

    return EventSourceResponse(event_generator())
```

### 5.3 Orchestrator 상세

```python
# orchestrator/main.py
from fastapi import FastAPI
import httpx

app = FastAPI()

# 등록된 에이전트 목록
AGENTS = {
    "claude": "https://claude-agent.example.com",
    "gemini": "https://gemini-agent.example.com"
}

# 에이전트 능력 조회 (Discovery)
@app.get("/agents")
async def list_agents():
    agents = []
    async with httpx.AsyncClient() as client:
        for name, url in AGENTS.items():
            resp = await client.get(f"{url}/.well-known/agent.json")
            agents.append(resp.json())
    return agents

# Task 라우팅
@app.post("/tasks")
async def create_task(request: TaskRequest):
    # 1. 요청 분석하여 적합한 에이전트 선택
    agent = select_agent(request.message, await list_agents())

    # 2. 선택된 에이전트에 task 생성
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{AGENTS[agent]}/tasks",
            json=request.dict()
        )
    return resp.json()

# 에이전트 선택 로직
def select_agent(message: str, agents: list) -> str:
    """
    메시지 내용과 에이전트 skills를 매칭하여 최적 에이전트 선택
    """
    # 간단한 키워드 매칭 (추후 LLM 기반 라우팅으로 개선)
    if "code" in message.lower() or "review" in message.lower():
        return "claude"
    elif "analysis" in message.lower() or "research" in message.lower():
        return "gemini"
    return "claude"  # 기본값
```

---

## 6. 구현 로드맵 (SDK 활용)

### Phase 1: Agent Wrapper (1주)

```
목표: Claude/Gemini를 A2A 호환 에이전트로 래핑

├── [ ] 프로젝트 구조 설정
│   ├── claude-agent/
│   └── gemini-agent/
│
├── [ ] Agent Card 구현
│   ├── /.well-known/agent.json
│   └── 능력(skills) 정의
│
├── [ ] Task CRUD API
│   ├── POST /tasks (생성)
│   ├── GET /tasks/{id} (조회)
│   └── DELETE /tasks/{id} (취소)
│
├── [ ] Message Handler
│   ├── POST /tasks/{id}/send
│   └── SSE 스트리밍 응답
│
└── [ ] API 연동
    ├── Claude API 호출
    └── Gemini API 호출
```

### Phase 2: Orchestrator (1주)

```
목표: 에이전트 발견, 라우팅, 조율

├── [ ] Agent Discovery
│   ├── Agent Card 수집
│   └── 능력 인덱싱
│
├── [ ] Task Router
│   ├── 요청 분석
│   ├── 에이전트 매칭
│   └── 라우팅 결정
│
├── [ ] Task Coordinator
│   ├── 멀티에이전트 작업 분해
│   ├── 순차/병렬 실행
│   └── 결과 통합
│
└── [ ] State Management
    ├── Redis 연동
    └── Task 상태 추적
```

### Phase 3: Context Sharing (1주)

```
목표: 에이전트 간 컨텍스트 공유

├── [ ] Context Store
│   ├── Redis 기반 공유 메모리
│   └── TTL 관리
│
├── [ ] Context Injection
│   ├── 이전 작업 요약 생성
│   └── 프롬프트 주입
│
├── [ ] Artifact Management
│   ├── 파일 저장/조회
│   └── 참조 전달
│
└── [ ] Handoff Protocol
    ├── 작업 인계 표준화
    └── 컨텍스트 직렬화
```

### Phase 4: 고도화 (2주+)

```
목표: 프로덕션 수준 완성

├── [ ] 인증/인가
│   ├── OAuth 2.0
│   └── API Key 관리
│
├── [ ] 모니터링
│   ├── 로깅
│   ├── 메트릭
│   └── 대시보드
│
├── [ ] 오류 처리
│   ├── 재시도 로직
│   ├── Circuit Breaker
│   └── Fallback
│
└── [ ] 성능 최적화
    ├── 캐싱
    ├── Connection Pooling
    └── Rate Limiting
```

---

## 7. 기술 스택 권장

### 7.1 Backend

| 컴포넌트 | 기술 | 이유 |
|----------|------|------|
| Framework | FastAPI (Python) | 비동기, SSE 지원, 타입 힌트 |
| Task Queue | Celery + Redis | 비동기 작업, 상태 관리 |
| Database | PostgreSQL | Task 영속성, 히스토리 |
| Cache | Redis | 세션, 컨텍스트 공유 |
| Message Format | JSON-RPC 2.0 | A2A 표준 |

### 7.2 Libraries (SDK 사용 시 간소화)

```python
# requirements.txt (SDK 사용)
a2a-sdk[http-server,sql]>=0.3.0  # 핵심! A2A 프로토콜 SDK
anthropic>=0.18.0                 # Claude API
google-generativeai>=0.4.0        # Gemini API
redis>=5.0.0                      # 컨텍스트 공유용
pydantic>=2.6.0                   # 데이터 검증

# SDK가 내부적으로 포함하는 것들 (별도 설치 불필요):
# - fastapi, uvicorn (http-server)
# - sse-starlette (스트리밍)
# - jsonrpc 처리
# - PostgreSQL/SQLite 드라이버 (sql)
```

### 7.3 Infrastructure

```yaml
# docker-compose.yml
services:
  orchestrator:
    build: ./orchestrator
    ports: ["8000:8000"]
    depends_on: [redis, postgres]

  claude-agent:
    build: ./claude-agent
    ports: ["8001:8000"]
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}

  gemini-agent:
    build: ./gemini-agent
    ports: ["8002:8000"]
    environment:
      - GOOGLE_API_KEY=${GOOGLE_API_KEY}

  redis:
    image: redis:alpine
    ports: ["6379:6379"]

  postgres:
    image: postgres:16
    environment:
      - POSTGRES_DB=a2a
```

---

## 8. 참고 자료

### 공식 문서
- [A2A Protocol 공식 사이트](https://a2a-protocol.org)
- [A2A GitHub Repository (google-a2a)](https://github.com/google-a2a/A2A)
- [A2A Specification](https://a2a-protocol.org/latest/specification/)
- [Google Developers Blog - A2A Announcement](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/)
- [Linux Foundation A2A Project](https://www.linuxfoundation.org/press/linux-foundation-launches-the-agent2agent-protocol-project)

### SDK & 샘플
- [A2A Python SDK](https://github.com/a2aproject/a2a-python) - `pip install a2a-sdk`
- [A2A Samples Repository](https://github.com/a2aproject/a2a-samples)
- [A2A Python Quickstart](https://a2a-protocol.org/latest/learn/quickstart/python/)
- [A2A Codelab](https://codelabs.developers.google.com/intro-a2a-purchasing-concierge)

### 관련 프로토콜
- [MCP (Model Context Protocol)](https://modelcontextprotocol.io/) - Anthropic
- [OpenAPI Specification](https://swagger.io/specification/)

---

## 9. 결론

### 가능성 평가

| 항목 | 직접 구현 | SDK 활용 |
|------|----------|----------|
| 기술적 실현 가능성 | ✅ 높음 | ✅ 매우 높음 |
| 필요 리소스 | 1-2명, 4-6주 | **1-2명, 1-2주** |
| 위험 요소 | 컨텍스트 공유, 오류 처리 | 컨텍스트 공유 |
| 기대 효과 | 멀티 LLM 협업, 벤더 독립성 | 동일 |

### 핵심 메시지

> **공식 SDK(`a2a-sdk`)가 존재하므로 직접 구현 불필요.**
>
> `AgentExecutor`를 상속받아 `execute()` 메서드만 구현하면
> Claude/Gemini를 A2A 호환 에이전트로 래핑 가능.

### 수정된 구현 전략

```
기존 계획 (직접 구현):
├── Agent Card 수동 정의
├── JSON-RPC 파싱
├── SSE 스트리밍 설정
├── Task 상태 관리
└── 예상: 4-6주

새 계획 (SDK 활용):
├── pip install a2a-sdk
├── ClaudeAgentExecutor(AgentExecutor) 구현
├── GeminiAgentExecutor(AgentExecutor) 구현
├── Orchestrator 로직만 직접 구현
└── 예상: 1-2주
```

### 다음 단계

1. ~~A2A GitHub 스펙 상세 분석~~ ✅ 완료
2. `a2a-sdk` 설치 및 helloworld 예제 실행
3. Claude용 `AgentExecutor` 구현
4. Gemini용 `AgentExecutor` 구현
5. Orchestrator 개발
6. 통합 테스트
7. 만톡 프로젝트에 적용

---

> 작성: Claude 4.5 Opus
> 날짜: 2025-12-04
> 버전: 1.1 (SDK 정보 추가)
