# HANDOFF — 수만 명 스케일링 병목 전체 분석

> 작성: 2026-03-22 16:00 | DK-DD 브랜치 | v61 Flutter + v59 Edge Function
> 분석 근거: Supabase/OpenAI/Gemini 공식문서 + DB 실시간 조회 + 코드 전량 리뷰

---

## 현재 상태 (DB 실측)

```
max_connections: 60 (Nano plan)
Pooler max clients: 200
현재 연결: 18/60 (active: 1, idle: 9)
오늘 활성 유저: 13명
오늘 ai_tasks: 51건
ai_tasks 테이블: 1,593행 = 36MB (result_data JSON 비대)
리전: ap-southeast-1 (싱가포르)
```

---

## 🔴 병목 #1: DB 연결 한계 — 가장 먼저 터짐

### 현재 한계 (Supabase 공식문서)

| Compute | max_connections | Pooler max clients | 월 비용 |
|---------|----------------|-------------------|---------|
| **Nano (현재)** | **60** | **200** | $0 |
| Micro | 60 | 200 | $7 |
| Small | 90 | 400 | $50 |
| Medium | 120 | 600 | $100 |
| Large | 160 | 800 | $200 |
| XL | 240 | 1,000 | $400 |
| 2XL | 380 | 1,500 | $900 |
| 4XL | 480 | 3,000 | $1,700 |

참고: https://supabase.com/docs/guides/platform/compute-and-disk

### 왜 터지나

모든 Edge Function이 `createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)`로 매 호출마다 새 연결 생성:

```
1명의 Gemini 채팅 요청 = DB 쿼리 5~6개:
  1. isAdminUser() → saju_profiles SELECT
  2. checkAndUpdateQuota() → subscriptions SELECT
  3. checkAndUpdateQuota() → subscriptions SELECT (expired)
  4. checkAndUpdateQuota() → user_daily_token_usage SELECT
  5. recordGeminiCost() → user_daily_token_usage SELECT + UPDATE
  6. chat_messages INSERT 트리거 → update_daily_chat_tokens
```

- **동시 200명 채팅** → Pooler 200 한계 도달 → **503 에러**
- **동시 1,000명** → Pooler 200 × 5배 초과 → **전면 장애**

### 해결

| 단계 | 방법 | 효과 |
|------|------|------|
| 즉시 | Compute → **Small** ($50) | Pooler 400, connections 90 |
| 1만 명 | Compute → **XL** ($400) | Pooler 1,000, connections 240 |
| 수만 명 | Compute → **2XL~4XL** ($900~$1,700) | Pooler 1,500~3,000 |
| 코드 | Edge Function에서 DB 쿼리 병합 (isAdmin + checkQuota를 1 쿼리로) | 연결 50% 감소 |
| 코드 | `user_daily_token_usage` SELECT→UPDATE를 **UPSERT** (ON CONFLICT DO UPDATE)로 변경 | 원자적 + 연결 1개 절약 |

---

## 🔴 병목 #2: 폴링 폭풍 (Polling Storm)

### 현재 구조 (OpenAI background 모드)

```
1명의 saju_base 요청:
  Flutter → ai-openai (Edge Function) → task 생성 → 즉시 응답
  Flutter → ai-openai-result (Edge Function) × 60~120회 (2초 간격 polling)
    각 poll: DB SELECT(ai_tasks) + OpenAI GET(/v1/responses/{id}) + DB UPDATE
```

### 수만 명 시 증폭

| 동시 유저 | Edge Function 호출 | DB 쿼리 | OpenAI API 호출 |
|----------|-------------------|---------|----------------|
| 1명 | 61회 | ~180회 | ~60회 |
| 100명 | 6,100회 | 18,000회 | 6,000회 |
| 1,000명 | 61,000회 | 180,000회 | 60,000회 |
| 10,000명 | **610,000회** | **1,800,000회** | **600,000회** |

- Supabase: 5,000 recursive requests/min 제한에 걸릴 수 있음
- 각 poll의 OpenAI GET도 RPM에 포함

### 해결

| 우선순위 | 방법 | 효과 |
|---------|------|------|
| **1 (권장)** | **OpenAI streaming 복원** (collectStreamResponse 버퍼 수정) | polling 완전 제거, 1 요청 = 1 Edge Function |
| 2 | **Supabase Realtime** (ai_tasks status 변경 구독) | polling → push, Edge Function 호출 60배 감소 |
| 3 | polling 간격 2초→5초 | 호출 60% 감소 (UX 저하) |

**Streaming 복원 코드 (ai-openai index.ts):**

```typescript
// 현재 (v59): json_schema일 때 stream=false 강제
// 문제: collectStreamResponse()의 SSE 라인 분할 버그

// 수정: buffer 패턴으로 불완전한 라인 보존
async function collectStreamResponse(response: Response) {
  const reader = response.body?.getReader();
  if (!reader) throw new Error("No response body");
  const decoder = new TextDecoder();
  let content = "";
  let usage = null;
  let finishReason = null;
  let buffer = '';  // ← 핵심 수정: 라인 버퍼

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split('\n');
    buffer = lines.pop() || '';  // ← 불완전한 마지막 라인은 다음 청크로
    for (const line of lines) {
      if (!line.startsWith('data: ')) continue;
      const data = line.slice(6).trim();
      if (data === '[DONE]') continue;
      try {
        const parsed = JSON.parse(data);
        const delta = parsed.choices?.[0]?.delta;
        if (delta?.content) content += delta.content;
        if (parsed.choices?.[0]?.finish_reason) finishReason = parsed.choices[0].finish_reason;
        if (parsed.usage) usage = parsed.usage;
      } catch { /* 파싱 실패 = 무시 (다음 청크에서 완성) */ }
    }
  }
  // 잔여 버퍼 처리
  if (buffer.startsWith('data: ') && buffer.slice(6).trim() !== '[DONE]') {
    try {
      const parsed = JSON.parse(buffer.slice(6).trim());
      if (parsed.choices?.[0]?.delta?.content) content += parsed.choices[0].delta.content;
      if (parsed.usage) usage = parsed.usage;
    } catch { /* ignore */ }
  }
  return { content, usage, finishReason };
}
```

이 수정 후 `stream: true`를 항상 사용 → json_schema도 streaming 가능 (OpenAI 공식 지원).

---

## 🔴 병목 #3: Gemini API 단일 키 + Rate Limit

### 현재

```
GEMINI_API_KEY: 1개
채팅용: gemini-3-flash-preview
의도분류: gemini-2.5-flash-lite
fallback: 없음
```

### Gemini Rate Limits (공식 — ai.google.dev/gemini-api/docs/rate-limits)

| Tier | RPM | 도달 조건 |
|------|-----|----------|
| Free | ~15 | 가입 즉시 |
| Tier 1 | ~1,000 | 빌링 활성화 |
| Tier 2 | ~2,000 | $100 누적 + 3일 |
| Tier 3 | ~5,000 | $1,000 누적 + 30일 |

- **동시 100명 채팅 = 100+ RPM** → Free 즉시 초과
- **동시 1,000명 = 1,000+ RPM** → Tier 1도 한계
- OpenAI는 3개 키 로테이션이 있지만 **Gemini는 0개**

### 해결

| 방법 | 효과 |
|------|------|
| **Gemini API Key 복수 등록** (3~5개) + 로테이션 | RPM 3~5배 증가 |
| Tier 업그레이드 (빌링 활성화) | 15 RPM → 1,000+ RPM |
| **대기열 (Queue)**: 동시 요청을 서버에서 순차 처리 | rate limit 제어 |
| 응답 캐싱: 같은 사주/같은 질문 패턴이면 캐시 반환 | API 호출 자체 감소 |

---

## 🔴 병목 #4: OpenAI API Rate Limits

### 현재

```
API Key: 3개 (round-robin)
모델: gpt-5-mini (saju_base), gpt-5.2 (미사용 중)
Tier: 확인 필요 (Tier에 따라 RPM 크게 다름)
```

### OpenAI Rate Limits (공식 — developers.openai.com/docs/guides/rate-limits)

| Tier | RPM (예시) | TPM (예시) | 도달 조건 |
|------|-----------|-----------|----------|
| Tier 1 | ~500 | ~200,000 | $5 결제 |
| Tier 2 | ~5,000 | ~2,000,000 | $50 + 7일 |
| Tier 3 | ~10,000 | ~10,000,000 | $100 + 7일 |
| Tier 5 | ~30,000 | ~150,000,000 | $1,000 + 30일 |

- **3개 키 × Tier 2 = ~15,000 RPM** → 채팅용은 충분
- **문제는 폴링**: 1명 = 60 polling → 10,000명 = 600,000 API 호출/2분 = **300,000 RPM** → 어떤 Tier도 초과
- 해결: **streaming 복원 (병목 #2 해결)으로 polling 제거**

---

## 🟡 병목 #5: ai_tasks 테이블 비대화

### 현재

```
행 수: 1,593
크기: 36MB (행당 ~22KB — result_data에 전체 사주 JSON)
정리 정책: 없음
```

### 수만 명 시

```
10,000명/일 × 22KB = 220MB/일
1달 = ~6.6GB
1년 = ~80GB
+ 인덱스 크기 추가
```

- `(user_id, task_type, locale, status)` 복합 인덱스 없음
- 중복 검사 쿼리: `.eq("user_id").eq("task_type").eq("locale").in("status")` → 효율적 인덱스 없이 느려짐

### 해결

```sql
-- 1. 복합 인덱스 추가 (중복 검사 + 조회 최적화)
CREATE INDEX idx_ai_tasks_user_type_locale_status
ON ai_tasks (user_id, task_type, locale, status, created_at DESC);

-- 2. pg_cron으로 7일 이상 completed 태스크 정리
SELECT cron.schedule(
  'cleanup_old_ai_tasks',
  '0 4 * * *',  -- 매일 새벽 4시 KST
  $$DELETE FROM ai_tasks
    WHERE status IN ('completed', 'failed')
    AND created_at < now() - interval '7 days'$$
);

-- 3. result_data를 별도 테이블로 분리 (선택)
-- ai_tasks는 메타데이터만, ai_task_results에 큰 JSON 저장
```

---

## 🟡 병목 #6: user_daily_token_usage 경합

### 현재 패턴 (모든 Edge Function에서)

```typescript
// SELECT 후 UPDATE 또는 INSERT — 2번 왕복 + race condition 가능
const { data: existing } = await supabase
  .from("user_daily_token_usage")
  .select("id, ...")
  .eq("user_id", userId)
  .eq("usage_date", today)
  .single();

if (existing) {
  await supabase.from("user_daily_token_usage").update({...}).eq("id", existing.id);
} else {
  await supabase.from("user_daily_token_usage").insert({...});
}
```

### 문제

- 같은 유저가 채팅 + 운세를 동시에 → 같은 행에 SELECT→UPDATE 2개 동시 → **stale read + overwrite**
- `gpt_cost_usd`: 두 Edge Function이 동시에 기존값 읽고 각각 더해 쓰면 하나가 소실

### 해결

```sql
-- RPC로 원자적 UPSERT (서버 사이드)
CREATE OR REPLACE FUNCTION update_token_usage(
  p_user_id uuid,
  p_usage_date date,
  p_column text,
  p_tokens int,
  p_gpt_cost numeric DEFAULT 0,
  p_gemini_cost numeric DEFAULT 0
) RETURNS void AS $$
BEGIN
  INSERT INTO user_daily_token_usage (user_id, usage_date)
  VALUES (p_user_id, p_usage_date)
  ON CONFLICT (user_id, usage_date) DO NOTHING;

  -- 원자적 증분 업데이트
  EXECUTE format(
    'UPDATE user_daily_token_usage SET %I = COALESCE(%I, 0) + $1,
     gpt_cost_usd = COALESCE(gpt_cost_usd, 0) + $2,
     gemini_cost_usd = COALESCE(gemini_cost_usd, 0) + $3,
     updated_at = now()
     WHERE user_id = $4 AND usage_date = $5',
    p_column, p_column
  ) USING p_tokens, p_gpt_cost, p_gemini_cost, p_user_id, p_usage_date;
END;
$$ LANGUAGE plpgsql;
```

---

## 전체 요약 — 유저 수별 필요 조치

| 유저 수 | 터지는 것 | 필수 조치 |
|---------|----------|----------|
| **~200명** | DB Pooler 200 한계 | Compute 업그레이드 (Small $50) |
| **~500명** | Gemini Free 15 RPM 초과 | Gemini 빌링 활성화 (Tier 1) |
| **~1,000명** | OpenAI polling 폭풍 | **Streaming 복원** (collectStreamResponse 버퍼 수정) |
| **~2,000명** | Gemini Tier 1 1,000 RPM 한계 | Gemini Key 복수 등록 + Tier 2 |
| **~5,000명** | DB connections 부족 | Compute → XL ($400) |
| **~10,000명** | ai_tasks 테이블 비대 | pg_cron 정리 + 복합 인덱스 |
| **수만 명** | 전체적 한계 | Compute → 2XL+ / OpenAI Tier 5 / Gemini Tier 3 |

---

## 즉시 실행 순서 (비용 0원부터)

1. **collectStreamResponse 버퍼 수정** → stream:true 복원 → polling 제거 (비용 $0)
2. **ai_tasks 복합 인덱스 추가** + pg_cron 정리 (비용 $0)
3. **user_daily_token_usage UPSERT RPC** (비용 $0)
4. **Gemini 빌링 활성화** → 15 RPM → 1,000+ RPM (비용 사용량 비례)
5. **Supabase Compute 업그레이드** → Small/Medium (비용 $50~$100/월)
6. **Gemini Key 복수 등록** (비용 $0, Google Cloud 프로젝트 추가)

---

## 이전 완료 작업

### 평생사주 Phase 4→1 통합 호출 + json_schema strict ✅

- `ai_api_service.dart`: `callOpenAI()`에 `responseFormat` 파라미터 추가
- `lifetime_unified_schema.dart`: Phase 1~4 전체 strict json_schema (19개 키)
- `lifetime_unified_prompt.dart`: 통합 프롬프트 (ko/ja/en)
- `saju_analysis_service.dart`: 기본=통합 1회, 실패 시 Phase 분할 fallback
- `ai-openai v59`: json_schema일 때 `stream: false` + non-streaming 응답 파싱
- 테스트: 90초, prompt=2847, completion=6974, $0.016, 19키 전부 생성, JSON 파싱 0에러

### 기타 완료

- 토큰 소진 광고 버그 수정 ✅
- RPC 보안 패치 ✅
- ai-openai sync 모드 전환 ✅

---

## Key Files

| 파일 | 상태 | 수정 필요 |
|------|------|----------|
| `supabase/functions/ai-openai/index.ts` | v59 | collectStreamResponse 버퍼 수정 |
| `supabase/functions/ai-gemini/index.ts` | v36 | API Key 로테이션 추가 |
| `supabase/functions/ai-openai-result/index.ts` | v32 | streaming 복원 후 사실상 불필요 |
| `frontend/lib/AI/services/ai_api_service.dart` | v61 | streaming 복원 시 polling 로직 제거 |

## 참고 문서

- Supabase Compute & Disk: https://supabase.com/docs/guides/platform/compute-and-disk
- Supabase Connection Pooling: https://supabase.com/docs/guides/database/connecting-to-postgres
- Supabase Edge Function Limits: https://supabase.com/docs/guides/functions/limits
- Supabase Edge Function Architecture: https://supabase.com/docs/guides/functions/architecture
- OpenAI Rate Limits: https://developers.openai.com/docs/guides/rate-limits
- OpenAI Structured Outputs: https://developers.openai.com/api/docs/guides/structured-outputs
- Gemini Rate Limits: https://ai.google.dev/gemini-api/docs/rate-limits
- Gemini Structured Output: https://ai.google.dev/gemini-api/docs/structured-output
