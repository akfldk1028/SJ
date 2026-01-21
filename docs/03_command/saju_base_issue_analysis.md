# saju_base 미생성 이슈 분석

> 작성일: 2026-01-21
> 분석자: Claude
> 상태: 원인 확인됨, 수정 필요

---

## 1. 문제 현상

- 일부 사용자의 `ai_summaries` 테이블에 `saju_base`가 생성되지 않음
- Fortune 데이터(monthly, yearly)는 정상 저장됨
- GPT-5.2 태스크는 `ai_tasks`에 생성되지만 결과가 `ai_summaries`에 저장 안됨

### 영향받은 사용자 예시
- user_id: `6c7bf45c-6015-43ae-8f3c-0439501a9ba3`
- ai_tasks에 GPT-5.2 태스크 존재 (openai_response_id 있음)
- OpenAI는 실제로 완료됨 (수동 확인 시 content 존재)
- ai_summaries에 saju_base 없음

---

## 2. 현재 아키텍처 (문제점)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        현재 GPT-5.2 처리 흐름                            │
└─────────────────────────────────────────────────────────────────────────┘

1. 프로필 저장 시 분석 시작
   └─ saju_analysis_service.dart → _runBothAnalyses()

2. Fortune 분석 먼저 실행 (await로 블로킹)
   └─ gpt-5-mini × 3개 (monthly, yearly_2025, yearly_2026)
   └─ 약 2-3분 소요

3. Fortune 완료 후 GPT-5.2 시작
   └─ ai-openai Edge Function 호출
   └─ OpenAI Responses API (background: true)
   └─ ai_tasks에 태스크 생성 (status: in_progress)

4. 클라이언트 폴링 시작
   └─ _pollForOpenAIResult() in ai_api_service.dart
   └─ 최대 120회 × 2초 = 240초 타임아웃
   └─ ai-openai-result Edge Function 반복 호출

5. OpenAI 완료 시
   └─ ai-openai-result가 ai_tasks 업데이트 (status: completed, result_data 저장)
   └─ ❌ ai_summaries에는 저장 안함!
   └─ 클라이언트가 결과 받아서 saveSajuBaseSummary() 호출해야 함

┌─────────────────────────────────────────────────────────────────────────┐
│                           문제 발생 지점                                 │
└─────────────────────────────────────────────────────────────────────────┘

     클라이언트 폴링 중...
           │
           ├─ 사용자가 앱 종료 ──────────────────┐
           ├─ 사용자가 다른 화면 이동 ───────────┤ → 폴링 중단!
           ├─ 네트워크 끊김 ────────────────────┤
           └─ 폴링 타임아웃 (240초 초과) ────────┘
                                                 │
                                                 ▼
                                    OpenAI 나중에 완료되어도
                                    아무도 결과를 가져가지 않음
                                                 │
                                                 ▼
                                    ai_summaries.saju_base = 영구 미저장!
```

---

## 3. 실제 테스트 결과

### 테스트 1: 앱 껐다 켬 (실패 케이스)
```
User: 6c7bf45c-6015-43ae-8f3c-0439501a9ba3
- 프로필 저장: 09:38:08
- Fortune 완료: 09:41:38 (3분 30초)
- GPT-5.2 시작: 09:41:40
- GPT-5.2 상태: in_progress (26분간 방치)
- 수동으로 ai-openai-result 호출 시: OpenAI는 이미 completed!
- ai_summaries.saju_base: ❌ 없음
```

### 테스트 2: 앱 켜둠 (성공 케이스)
```
User: ce00a93c-081a-4250-9071-fa3a47afa983 (google 프로필)
- 프로필 저장: 10:22:39
- Fortune 완료: 10:25:30 (약 3분)
- GPT-5.2 시작: 10:25:32
- GPT-5.2 완료: 10:32:02 (389초 = 6분 29초)
- 클라이언트가 계속 폴링함
- ai_summaries.saju_base: ✅ 저장됨
```

---

## 4. 근본 원인

```
ai-openai-result Edge Function이 ai_summaries에 직접 저장하지 않음!
```

### 현재 ai-openai-result 코드 (v8)
```typescript
// OpenAI 완료 시 ai_tasks만 업데이트
await supabase.from("ai_tasks").update({
  status: "completed",
  result_data: { success: true, content: outputText, ... },
  completed_at: new Date().toISOString(),
}).eq("id", task_id);

// ❌ ai_summaries INSERT 없음!
```

### 클라이언트 코드 (ai_api_service.dart)
```dart
Future<AiApiResponse> _pollForOpenAIResult({...}) async {
  for (int attempt = 0; attempt < _maxPollingAttempts; attempt++) {
    // Edge Function 호출
    final response = await _client.functions.invoke('ai-openai-result', ...);

    if (completed) {
      return AiApiResponse.success(...); // 클라이언트가 이 결과로 ai_summaries 저장
    }

    await Future.delayed(Duration(seconds: 2));
  }
  // 타임아웃 시 저장 안됨!
}
```

---

## 5. 해결 방안

### Option A: Edge Function에서 직접 저장 (권장)

`ai-openai-result` Edge Function 수정:
```typescript
// OpenAI 완료 시
if (status === "completed") {
  // 1. ai_tasks 업데이트 (기존)
  await supabase.from("ai_tasks").update({...});

  // 2. ai_summaries에 직접 저장 (추가!)
  await supabase.from("ai_summaries").upsert({
    user_id: task.user_id,
    profile_id: task.request_data.profile_id,
    summary_type: "saju_base",
    content: outputText,
    model_used: "gpt-5.2",
    created_at: new Date().toISOString(),
  });
}
```

**장점**: 클라이언트 상태와 무관하게 항상 저장됨

### Option B: OpenAI Webhook 사용

OpenAI Responses API의 webhook 기능 활용:
- 완료 시 자동으로 Edge Function 호출
- 클라이언트 폴링 불필요

### Option C: 백그라운드 Job

Supabase pg_cron으로 주기적으로 미완료 태스크 체크:
- in_progress 상태가 오래된 태스크 확인
- OpenAI 상태 체크 후 완료되면 저장

---

## 6. 관련 파일

| 파일 | 역할 |
|------|------|
| `frontend/lib/AI/services/saju_analysis_service.dart` | 분석 오케스트레이션 |
| `frontend/lib/AI/services/ai_api_service.dart` | API 호출 + 폴링 로직 |
| `supabase/functions/ai-openai/index.ts` | GPT-5.2 태스크 생성 |
| `supabase/functions/ai-openai-result/index.ts` | 결과 폴링 (수정 필요!) |

---

## 7. 테이블 스키마 참고

### ai_tasks
```sql
- id: uuid
- user_id: uuid
- task_type: text
- status: text (pending, in_progress, completed, failed)
- model: text
- request_data: jsonb
- result_data: jsonb
- openai_response_id: text
- created_at, started_at, completed_at, expires_at
```

### ai_summaries
```sql
- id: uuid
- user_id: uuid
- profile_id: uuid
- summary_type: text (saju_base, monthly_fortune, yearly_fortune_*, daily_fortune)
- content: text
- model_used: text
- metadata: jsonb
- created_at
```

---

## 8. 다음 작업

- [ ] `ai-openai-result` Edge Function 수정
  - OpenAI 완료 시 `ai_summaries`에 직접 INSERT
  - task의 `request_data`에서 `user_id`, `profile_id` 추출
  - `summary_type: 'saju_base'`로 저장
- [ ] 기존 누락된 사용자 데이터 복구
  - `ai_tasks`에서 completed 상태인데 `ai_summaries`에 saju_base 없는 케이스 찾기
  - `result_data.content`로 ai_summaries 수동 INSERT
