# ai-gemini Edge Function

Gemini 3.0 Flash 기반 AI 채팅 Edge Function. SSE 스트리밍 응답.

**현재 버전**: v59 (2026-02-08)

## 핵심 기능

| 기능 | 설명 |
|------|------|
| 스트리밍 채팅 | SSE로 실시간 텍스트 전송 |
| Context Caching (v26) | system prompt 캐싱 → input 비용 90% 절감 |
| 캐시 fallback (v27) | 캐시 에러 시 표준 요청으로 자동 재시도 |
| 비용 기록 | gemini_cost_usd → user_daily_token_usage |
| 비용 추산 fallback (v26) | usageMetadata 누락 시 텍스트 길이 기반 추산 |
| Quota 체크 (v50+) | `effective_quota = daily_quota + bonus + rewarded + native_tokens`. 초과 시 429 |
| Premium bypass (v50+) | `subscriptions` 테이블에서 active 상품 확인 → quota 면제 |
| Premium 만료 전환 (v59) | premium→free 전환 시 chatting_tokens가 free quota 3배 초과면 리셋 |

## Context Caching 흐름

```
요청 수신 (session_id 포함)
  │
  ├─ chat_sessions.gemini_cache_name 조회
  │    │
  │    ├─ 캐시 이름 있음 → cachedContent로 Gemini 요청
  │    │    │
  │    │    ├─ 성공 → 캐시 히트 (input $0.05/1M)
  │    │    └─ 실패 → DB 정리 + 캐시 없이 재시도 (v27 fallback)
  │    │
  │    └─ 캐시 이름 없음 + system prompt > 500자
  │         │
  │         ├─ createGeminiCache() 호출
  │         │    → systemInstruction만 캐시 (contents 없음)
  │         │    → TTL 3600초 (1시간)
  │         │    → 생성된 cache_name DB 저장
  │         └─ 생성 실패 → 표준 요청으로 진행
  │
  └─ session_id 없음 → 표준 요청 (캐싱 미사용)
```

## 주요 버전 변경사항

### v59 (2026-02-08)
- Premium 만료 전환 처리: `chatting_tokens > free_quota * 3`이면 리셋

### v50 (2026-02-02)
- Quota 체크 로직: `checkAndUpdateQuota()` 함수 추가
- Premium bypass: `subscriptions` 테이블 조회 → active이면 quota 면제
- `effective_quota = daily_quota + bonus_tokens + rewarded_tokens_earned + native_tokens_earned`

### v27
1. **변수명 오타**: `cachedTokens` → `totalCachedTokens` (비용 기록 에러 수정)
2. **캐시 생성 API**: `contents` 필드 제거 (Gemini API 규격 준수)
3. **캐시 fallback**: 캐시 에러 시 `throw` 대신 캐시 없이 재시도

## 비용 계산 (line 471-472)

```typescript
const nonCachedPrompt = totalPromptTokens - totalCachedTokens;
const cost = (nonCachedPrompt * 0.50 / 1_000_000)    // 표준 input
           + (totalCachedTokens * 0.05 / 1_000_000)   // 캐시 input (90% 할인)
           + (totalCompletionTokens * 3.00 / 1_000_000); // output
```

## 요청 파라미터

| 파라미터 | 필수 | 설명 |
|---------|------|------|
| `messages` | Y | `[{role, content}]` 대화 이력 |
| `model` | N | Gemini 모델 (기본: gemini-3.0-flash) |
| `max_tokens` | N | 최대 출력 토큰 |
| `temperature` | N | 창의성 (기본 1.0) |
| `stream` | N | SSE 스트리밍 (기본 true) |
| `user_id` | N | 비용 기록용 |
| `session_id` | N | Context Caching용 (v27) |
| `is_new_session` | N | 새 세션 플래그 |
