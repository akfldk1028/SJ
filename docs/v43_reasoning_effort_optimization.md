# v43: GPT-5.2 reasoning_effort 최적화

## 변경 날짜
2026-02-04

## 배경
- GPT-5.2 Thinking 모델은 reasoning (추론) 단계에서 토큰을 소비하며, 이 시간이 60-150초 소요
- `reasoning_effort` 파라미터로 추론 깊이를 조절할 수 있음
- saju_base (평생운세)는 프로필당 1회만 실행되므로 속도 개선이 UX에 직접 영향

## OpenAI 공식 문서 기준

### reasoning_effort 옵션
| 값 | 설명 | 추론 토큰 | 속도 |
|-----|------|----------|------|
| `none` | 추론 없음 (비추) | 0 | 매우 빠름 |
| `low` | 가벼운 추론 | 적음 | 빠름 |
| `medium` | 기본값 | 보통 | 보통 |
| `high` | 깊은 추론 | 많음 | 느림 |
| `xhigh` | 최대 추론 | 최대 | 매우 느림 |

### API 형식
- **Responses API** (background mode): `reasoning: { effort: "low" }`
- **Chat Completions API** (sync mode): `reasoning_effort: "low"`

### 비용 영향
- reasoning tokens은 output token 가격으로 과금 ($14.00/1M)
- `low`는 reasoning tokens 수를 줄여서 비용 절감
- 예상: medium 대비 30-50% 비용 절감

## 변경 내용

### 1. Edge Function (`supabase/functions/ai-openai/index.ts`)
- `OpenAIRequest` 인터페이스에 `reasoning_effort` 필드 추가
- 요청 body에서 `reasoning_effort` 파싱 (기본값: "medium")
- Background mode (Responses API): `reasoning: { effort: reasoning_effort }` 전달
- Sync mode (Chat Completions): 하드코딩된 "medium" → 파라미터 사용
- `processInBackground` 함수에 `reasoningEffort` 파라미터 추가
- `ai_tasks.request_data`에 `reasoning_effort` 저장 (디버깅용)

### 2. Flutter `AiApiService` (`ai_api_service.dart`)
- `callOpenAI()` 메서드에 `reasoningEffort` 파라미터 추가 (기본값: "medium")
- `chat()` 메서드에 `reasoningEffort` 파라미터 추가 (기본값: "medium")
- Edge Function body에 `'reasoning_effort': reasoningEffort` 전달

### 3. Flutter `SajuAnalysisService` (`saju_analysis_service.dart`)
- `runSajuBaseAnalysisWithPhases()`: `reasoningEffort` 파라미터 추가 (기본값: "low")
- 각 Phase 메서드(`_runPhase1~4`): `reasoningEffort` 파라미터 추가
- 각 Phase의 `callOpenAI()` 호출에 `reasoningEffort` 전달
- 비phased `_runSajuBaseAnalysis()`: `reasoningEffort: 'low'` 하드코딩

### 4. 폴백 로직
```
saju_base 분석 시작
  → reasoning_effort: "low"로 Phase 1~4 실행
  → 성공? → 완료!
  → 실패? → reasoning_effort: "medium"으로 전체 재시도
```

## 적용 범위

| 분석 유형 | reasoning_effort | 비고 |
|-----------|-----------------|------|
| **saju_base (평생운세)** | **low** → medium 폴백 | v43 변경 |
| monthly_fortune | medium (기본) | 변경 없음 (GPT-5-mini) |
| yearly_2026 | medium (기본) | 변경 없음 (GPT-5-mini) |
| yearly_2025 | medium (기본) | 변경 없음 (GPT-5-mini) |
| daily_fortune | N/A | Gemini 사용 |
| 채팅 | medium (기본) | 변경 없음 |

## 모니터링

### Supabase에서 확인
```sql
-- reasoning_effort별 성공률 확인
SELECT
  request_data->>'reasoning_effort' as effort,
  status,
  COUNT(*) as cnt,
  AVG(EXTRACT(EPOCH FROM (completed_at - started_at))) as avg_seconds
FROM ai_tasks
WHERE task_type LIKE 'saju_base%'
  AND created_at >= NOW() - INTERVAL '7 days'
GROUP BY 1, 2
ORDER BY 1, 2;
```

### low → medium 폴백 빈도 확인
- 앱 로그에서 `reasoning_effort: low 실패 → medium으로 재시도` 검색
- 폴백이 너무 잦으면 (>20%) medium으로 기본값 변경 고려

## 롤백 방법
- `saju_analysis_service.dart`에서 `reasoningEffort: 'low'` → `'medium'`으로 변경
- Edge Function은 하위 호환 (기본값 "medium")이므로 롤백 불필요
