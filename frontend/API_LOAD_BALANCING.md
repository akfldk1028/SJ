# API 키 로드밸런싱 가이드

## 결론: Supabase Edge Function 안에서 직접 구현 가능

별도 서버나 프록시 필요 없음. Edge Function 코드에 로드밸런싱 로직을 넣으면 됨.

---

## 구현 방식

### 1. Supabase Secrets에 API 키 여러 개 등록

```bash
# CLI로 등록
supabase secrets set OPENAI_API_KEY_1=sk-xxx111
supabase secrets set OPENAI_API_KEY_2=sk-xxx222
supabase secrets set OPENAI_API_KEY_3=sk-xxx333

# 또는 Dashboard > Edge Function Secrets에서 직접 추가
```

> 재배포 필요 없음. secrets 설정 즉시 반영됨.

### 2. Edge Function에서 Round-Robin 로드밸런싱

```typescript
// API 키 풀 로드
const API_KEYS = [
  Deno.env.get("OPENAI_API_KEY_1"),
  Deno.env.get("OPENAI_API_KEY_2"),
  Deno.env.get("OPENAI_API_KEY_3"),
].filter(Boolean) as string[];

// Round-Robin 카운터 (isolate 단위)
let keyIndex = 0;

function getNextApiKey(): string {
  const key = API_KEYS[keyIndex % API_KEYS.length];
  keyIndex++;
  return key;
}
```

### 3. 실패 시 다음 키로 자동 전환 (Fallback)

```typescript
async function callOpenAIWithFallback(body: any): Promise<Response> {
  for (let attempt = 0; attempt < API_KEYS.length; attempt++) {
    const apiKey = getNextApiKey();
    try {
      const response = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${apiKey}`,
        },
        body: JSON.stringify(body),
      });

      // Rate limit (429) → 다음 키로 전환
      if (response.status === 429) {
        console.warn(`[LB] Key ${attempt + 1} rate limited, trying next...`);
        continue;
      }

      return response;
    } catch (error) {
      console.error(`[LB] Key ${attempt + 1} failed:`, error);
      continue;
    }
  }
  throw new Error("All API keys exhausted");
}
```

---

## 적용 대상 Edge Functions

| Function | API | 우선순위 |
|----------|-----|---------|
| `ai-openai` | OpenAI GPT-5.2 (사주 분석, 36~260초) | **최우선** |
| `ai-openai-result` | OpenAI (결과 조회) | 높음 |
| `ai-openai-mini` | OpenAI Mini | 중간 |
| `ai-gemini` | Gemini (채팅) | 낮음 (Gemini 자체 한도 넉넉) |

> `ai-openai`가 가장 느리고 무거워서 로드밸런싱 효과가 가장 큼

---

## OpenAI Rate Limit 참고

| Tier | RPM (분당 요청) | TPM (분당 토큰) | 승급 조건 |
|------|----------------|----------------|----------|
| Tier 1 | 500 | 200,000 | $5 결제 |
| Tier 2 | 5,000 | 2,000,000 | $50 결제 + 7일 |
| Tier 3 | 5,000 | 10,000,000 | $100 결제 + 7일 |
| Tier 4 | 10,000 | 50,000,000 | $250 결제 + 14일 |
| Tier 5 | 10,000 | 150,000,000 | $1,000 결제 + 30일 |

**키 2개 = 한도 2배, 키 3개 = 한도 3배**

---

## 단계별 적용 계획

### Phase 1: 지금 (테스터 3~10명)
- 현재 키 1개로 충분
- 문제 없음

### Phase 2: 50명+ (로드밸런싱 적용)
- OpenAI API 키 2~3개 생성 (같은 계정 또는 다른 계정)
- `ai-openai` Edge Function에 Round-Robin + Fallback 적용
- Supabase Secrets에 키 등록

### Phase 3: 100명+ (캐싱 추가)
- 같은 생년월일+시간 → 기존 사주 분석 결과 재사용
- DB에서 캐시 조회 → 없으면 API 호출
- API 비용 대폭 절감

### Phase 4: 500명+ (인프라 확장)
- Azure OpenAI (리전별 별도 한도)
- 큐 기반 비동기 처리 (pgmq + pg_cron)
- 여러 리전에서 분산 처리

---

## Supabase에서 못하는 것

| 항목 | 가능 여부 |
|------|----------|
| Edge Function 내 로드밸런싱 코드 | **가능** |
| Secrets에 여러 API 키 등록 | **가능** |
| Edge Function 자동 스케일링 | **자동** (Supabase가 처리) |
| Edge Function 여러 개로 분산 | **불필요** (자동 스케일링됨) |
| API Gateway 레벨 로드밸런싱 | 불가능 (코드에서 해야 함) |
| 큐 기반 비동기 처리 | **가능** (pgmq + pg_cron) |

---

## 참고 자료
- Supabase Edge Functions Secrets: https://supabase.com/docs/guides/functions/secrets
- Supabase Edge Functions Architecture: https://supabase.com/docs/guides/functions/architecture
- OpenAI Rate Limits: https://platform.openai.com/docs/guides/rate-limits
- OpenAI Production Best Practices: https://platform.openai.com/docs/guides/production-best-practices
- openai-load-balancer (오픈소스): https://github.com/Spryngtime/openai-load-balancer
