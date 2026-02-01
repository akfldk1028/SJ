# Supabase Edge Functions

만톡 AI 사주 서비스를 위한 Edge Functions 문서입니다.

> **최종 업데이트**: 2026-02-01 (DK)
> **관련 문서**: `EdgeFunction_task.md` (배포 관리), `docs/04_data_models.md` (DB 스키마)

---

## 함수 목록

| 함수명 | 용도 | 모델 | 배포 버전 | 비고 |
|--------|------|------|-----------|------|
| **ai-openai** | GPT-5.2 사주 분석 | `gpt-5.2` | **v37** | Responses API Background Mode |
| **ai-openai-result** | GPT 결과 폴링 | - | **v15** | ai-openai와 연동 |
| **ai-gemini** | Gemini 채팅/일운 | `gemini-3-flash-preview` | v15 | SSE 스트리밍 |
| **generate-ai-summary** | Legacy AI Summary | `gemini-2.0-flash` | v4 | 레거시 (신규 사용 X) |

---

## 1. ai-openai (v37)

**GPT-5.2 Responses API - 평생 사주 분석 (Background Mode)**

### 핵심 설정
```typescript
model = "gpt-5.2"           // 변경 금지
max_tokens = 10000           // 변경 금지 - 전체 응답 보장
reasoning_effort = "medium"  // 추론 강도 (30-60초)
run_in_background = true     // Responses API background 모드
```

### 동작 방식 (Phase 시스템)
```
클라이언트 요청
    │
    ▼
Phase 1: 사주 분석 프롬프트 구성
    │
    ▼
Phase 2: OpenAI Responses API 호출 (background: true)
    │  → 즉시 response_id 반환 (타임아웃 방지)
    │
    ▼
Phase 3: ai_tasks 테이블에 task 저장
    │  → { task_id, openai_response_id, status: "processing" }
    │
    ▼
클라이언트에 task_id 반환 → 클라이언트가 ai-openai-result로 폴링
```

### API키 로드밸런싱
- 3개 API키 순환: `OPENAI_API_KEY`, `OPENAI_API_KEY_2`, `OPENAI_API_KEY_3`
- 요청마다 랜덤 선택하여 rate limit 분산

### 환경변수
```env
OPENAI_API_KEY=sk-...
OPENAI_API_KEY_2=sk-...
OPENAI_API_KEY_3=sk-...
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

### 토큰 기록 (user_daily_token_usage)
| Edge Function 컬럼 | DB 실제 컬럼 | 비고 |
|---------------------|-------------|------|
| `saju_analysis_tokens` | `saju_analysis_tokens` | v37에서 수정됨 |
| `gpt_cost_usd` | `gpt_cost_usd` | USD 비용 |

> **주의**: `gpt_saju_analysis_tokens`, `gpt_saju_analysis_count`는 DB에 존재하지 않음. v37에서 수정 완료.

### 관리자 판별 (isAdminUser)
```typescript
// v37: profile_type 사용 (is_primary가 아님!)
.from("saju_profiles")
.select("id")
.eq("user_id", userId)
.eq("profile_type", "primary")  // ← DB 실제 컬럼
```

> **주의**: `saju_profiles.is_primary` 컬럼은 DB에 존재하지 않음. 실제 컬럼은 `profile_type` (text: 'primary'/'other'). v37에서 수정 완료.

### Reasoning 필터링 (v37 추가)
- `collectStreamResponse()`: `delta.reasoning_content` 무시 (GPT thinking 내용 제외)
- 사용자에게 GPT의 내부 추론 과정이 노출되지 않도록 필터링

### 응답 형식
```typescript
// 성공 (Background Mode)
{
  success: true,
  task_id: "uuid",           // 클라이언트가 폴링에 사용
  status: "processing",
  message: "분석이 시작되었습니다..."
}

// 실패
{
  success: false,
  error: string
}
```

---

## 2. ai-openai-result (v15)

**OpenAI Background Task 결과 폴링**

### 핵심 로직
```
클라이언트: POST /ai-openai-result { task_id: "uuid" }
    │
    ▼
1. ai_tasks 테이블에서 task 조회
2. openai_response_id로 OpenAI /v1/responses/{id} 호출
3. 상태 확인:
   - queued → { status: "processing" } 반환
   - in_progress → { status: "processing" } 반환
   - completed → 결과 파싱 후 반환
   - failed → 에러 반환
4. reasoning 타입 출력 필터링 (GPT thinking 내용 제외)
5. 완료 시 ai_tasks에 결과 캐싱
```

### Reasoning 필터링 (v15 추가)
```typescript
// output 배열에서 reasoning 타입 제외
if (outputItem.type === "reasoning") continue;

// content 배열에서도 reasoning 타입 제외
if (contentItem.type === "reasoning") continue;
```

### 토큰 기록
- ai-openai와 동일: `saju_analysis_tokens`, `gpt_cost_usd` 사용
- `gpt_saju_analysis_tokens`, `gpt_saju_analysis_count`는 DB에 없음 (v15에서 수정)

### 응답 형식
```typescript
// 아직 처리 중
{
  success: true,
  status: "processing",
  message: "분석 중입니다..."
}

// 완료
{
  success: true,
  status: "completed",
  content: "사주 분석 결과 텍스트...",
  usage: { prompt_tokens, completion_tokens, total_tokens }
}
```

### Flutter 폴링 설정
```dart
static const int _maxPollingAttempts = 120;  // 최대 120회
static const Duration _pollingInterval = Duration(seconds: 2);  // 2초 간격
// 최대 대기: 120 * 2 = 240초 (4분)
```

---

## 3. ai-gemini (v15)

**Gemini 3.0 Flash - 채팅/일운 분석 (SSE 스트리밍)**

### 핵심 설정
```typescript
model = "gemini-3-flash-preview"  // 변경 금지
max_tokens = 4096                  // 변경 금지 - 짤림 방지
temperature = 0.8
```

### 환경변수
```env
GEMINI_API_KEY=AI...
```

### 알려진 이슈
> **토큰 기록 컬럼명 불일치 (미수정)**
> - 코드: `gemini_chat_tokens`, `gemini_chat_message_count`
> - DB 실제 컬럼: `chatting_tokens`, `chatting_message_count`
> - 토큰 기록이 실패하지만 채팅 기능 자체에는 영향 없음
> - 수정 시 Edge Function 재배포 필요

### 메시지 형식 변환
OpenAI 형식 → Gemini 형식 자동 변환:
- `system` → `systemInstruction`
- `assistant` → `model`
- `user` → `user`

---

## 4. generate-ai-summary (v4) - Legacy

> **레거시**: 신규 개발은 ai-openai + ai-openai-result 사용

- Gemini로 성격, 직업, 운세 팁 생성
- DB 직접 저장 (`saju_analyses.ai_summary`)

---

## DB 컬럼 참고 (중요!)

### saju_profiles 테이블
| 문서/코드에서 | DB 실제 컬럼 | 타입 | 비고 |
|---------------|-------------|------|------|
| ~~is_primary~~ | `profile_type` | TEXT | 'primary' / 'other' |

### user_daily_token_usage 테이블
| 용도 | DB 실제 컬럼 | 비고 |
|------|-------------|------|
| 사주 분석 | `saju_analysis_tokens` | ~~gpt_saju_analysis_tokens~~ 아님 |
| 일운 | `daily_fortune_tokens` | |
| 월운 | `monthly_fortune_tokens` | |
| 2025 회고 | `yearly_fortune_2025_tokens` | |
| 2026 신년 | `yearly_fortune_2026_tokens` | |
| 채팅 | `chatting_tokens` | ~~gemini_chat_tokens~~ 아님 |
| GPT 비용 | `gpt_cost_usd` | USD |
| Gemini 비용 | `gemini_cost_usd` | USD |
| 합산 | `total_tokens` | GENERATED (자동 합산) |
| 할당 초과 | `is_quota_exceeded` | GENERATED (자동 판단) |

> **참고**: `gpt_saju_analysis_count` 컬럼은 DB에 존재하지 않음

---

## 아키텍처

```
┌──────────────────────────────────────────────────────────────────┐
│                       Flutter App                                 │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  ai_pipeline_manager.dart                                  │   │
│  │    1. ai-openai 호출 → task_id 받음                         │   │
│  │    2. ai-openai-result 폴링 → GPT 분석 결과                 │   │
│  │    3. GPT 결과 + Gemini 프롬프트 → ai-gemini SSE 스트리밍    │   │
│  └────────────────────────────────────────────────────────────┘   │
└───────────┬──────────────────┬──────────────────┬────────────────┘
            │                  │                  │
            ▼                  ▼                  ▼
  ┌─────────────────┐ ┌────────────────┐ ┌─────────────────────┐
  │   ai-openai     │ │ ai-openai-     │ │    ai-gemini        │
  │   (v37)         │ │ result (v15)   │ │    (v15)            │
  │   GPT-5.2       │ │ 폴링 조회      │ │    Gemini 3.0       │
  │   Background    │ │                │ │    SSE 스트리밍      │
  └────────┬────────┘ └───────┬────────┘ └──────────┬──────────┘
           │                  │                     │
           ▼                  ▼                     ▼
  ┌─────────────────┐ ┌────────────────┐ ┌─────────────────────┐
  │   OpenAI API    │ │   ai_tasks     │ │  Google Gemini API  │
  │   Responses API │ │   (Supabase)   │ │  (streaming)        │
  └─────────────────┘ └────────────────┘ └─────────────────────┘
```

---

## 배포

### Supabase MCP (Claude Code 권장)
```
mcp__supabase__deploy_edge_function 사용
```

### Supabase CLI
```bash
# ai-openai v37
cd e:/SJ && npx supabase functions deploy ai-openai --project-ref kfciluyxkomskyxjaeat

# ai-openai-result v15
cd e:/SJ && npx supabase functions deploy ai-openai-result --project-ref kfciluyxkomskyxjaeat

# ai-gemini v15
cd e:/SJ && npx supabase functions deploy ai-gemini --project-ref kfciluyxkomskyxjaeat
```

---

## 보안

1. **API 키 보안**: 모든 API 키는 Supabase 환경변수로 관리 (클라이언트 노출 없음)
2. **CORS 설정**: 모든 함수에 CORS 헤더 포함
3. **Service Role Key**: DB 직접 접근 시 사용 (RLS 우회)
4. **Reasoning 필터링**: GPT thinking 내용이 사용자에게 노출되지 않도록 필터링

---

## 관련 파일

### Flutter 클라이언트
- `frontend/lib/features/saju_chat/data/datasources/openai_edge_datasource.dart` - OpenAI API 호출 + 폴링
- `frontend/lib/features/saju_chat/data/datasources/gemini_rest_datasource.dart` - Gemini SSE 스트리밍
- `frontend/lib/core/services/ai_summary_service.dart` - AI 요약 관리 (upsert → delete+insert 패턴)
- `frontend/lib/AI/data/mutations.dart` - DB upsert 로직

### Edge Function 소스
- `supabase/functions/ai-openai/index.ts` - v37 (현재 배포)
- `supabase/functions/ai-openai-result/index.ts` - v15 (현재 배포)
- `supabase/functions/ai-gemini/index.ts` - v15 (현재 배포)

### 문서
- `EdgeFunction_task.md` - 배포 관리 + 수정 규칙
- `docs/04_data_models.md` - DB 스키마

---

## 버전 히스토리

### ai-openai
| 버전 | 변경 사유 |
|------|----------|
| v1~v2 | 초기 (GPT-4o → GPT-5.2) |
| v10 | GPT-5.2-thinking, max_tokens 10000 |
| v24 | Responses API background 모드 (DK) |
| **v37** | **DB 컬럼명 수정 (profile_type, saju_analysis_tokens) + reasoning 필터 + 3키 로드밸런싱 (DK)** |

### ai-openai-result
| 버전 | 변경 사유 |
|------|----------|
| v4 | 초기 폴링 엔드포인트 (DK) |
| **v15** | **DB 컬럼명 수정 + reasoning 타입 필터링 (DK)** |

### ai-gemini
| 버전 | 변경 사유 |
|------|----------|
| v1 | 초기 (gemini-2.0-flash) |
| v11 | gemini-3-flash-preview 모델 변경 |
| v15 | max_tokens 4096 (짤림 방지) |
