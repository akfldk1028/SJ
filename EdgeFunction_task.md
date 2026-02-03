# Edge Function 관리 문서

> ⚠️ **중요**: Edge Function 수정 시 반드시 이 문서를 참조하세요.
> 모델명, max_tokens 등 핵심 설정은 임의로 변경하지 마세요.

---

## 현재 배포된 Edge Functions

### ai-gemini (채팅용)

| 항목 | 값 | 비고 |
|------|-----|------|
| **버전** | v15 | 2024-12-30 |
| **모델** | `gemini-3-flash-preview` | ⚠️ 변경 금지 |
| **max_tokens** | `4096` | 채팅 짤림 방지 |
| **temperature** | `0.8` | 대화형 응답 |
| **용도** | 채팅/일운 분석 | Gemini 3.0 Flash |

```typescript
// ai-gemini/index.ts - 핵심 설정
model = "gemini-3-flash-preview"  // 변경 금지
max_tokens = 4096                  // 변경 금지
temperature = 0.8
```

---

### ai-openai (사주 분석용)

| 항목 | 값 | 비고 |
|------|-----|------|
| **버전** | **v37** | 2026-02-01 (DK) |
| **모델** | `gpt-5.2` | ⚠️ 변경 금지 - GPT-5.2 Thinking |
| **max_tokens** | `10000` | 전체 응답 보장 |
| **reasoning_effort** | `medium` | 추론 강도 (30-60초) |
| **용도** | 평생 사주 분석 | OpenAI Responses API Background Mode |
| **API키** | 3개 로드밸런싱 | OPENAI_API_KEY, _2, _3 |

```typescript
// ai-openai/index.ts v37 - 핵심 설정
model = "gpt-5.2"           // 변경 금지 - GPT-5.2 Thinking
max_tokens = 10000          // 변경 금지 - 전체 응답 보장
reasoning_effort = "medium" // 추론 강도 (Supabase 타임아웃 내)
run_in_background = true    // OpenAI Responses API background 모드
```

### ai-openai-result (결과 조회용)

| 항목 | 값 | 비고 |
|------|-----|------|
| **버전** | **v15** | 2026-02-01 (DK) |
| **용도** | OpenAI background task 결과 폴링 | ai-openai v37와 연동 |
| **엔드포인트** | POST /ai-openai-result | `{ task_id: "uuid" }` |

```typescript
// ai-openai-result/index.ts v15 - 핵심 로직
// 1. ai_tasks 테이블에서 task 조회
// 2. openai_response_id로 OpenAI /v1/responses/{id} 폴링
// 3. 상태: queued → in_progress → completed
// 4. 완료 시 결과 캐싱 및 반환
// 5. reasoning 타입 필터링 (GPT thinking 내용 제외)
```

---

## 모델 변경 이력

### ai-gemini
| 버전 | 모델 | 변경 사유 |
|------|------|----------|
| v11 | gemini-3-flash-preview | 모델명 만료 대응 |
| v14 | gemini-3-flash-preview | responseMimeType 제거 |
| v15 | gemini-3-flash-preview | max_tokens 4096 (짤림 방지) |

### ai-openai
| 버전 | 모델 | 변경 사유 |
|------|------|----------|
| v7 | gpt-4o-mini | 초기 버전 |
| v8 | gpt-4o-mini | max_completion_tokens 수정 |
| v9 | gpt-5.2 | GPT-5.2로 업그레이드 |
| v10 | gpt-5.2-thinking | 추론 강화 모델, max_tokens 10000 |
| v24 | gpt-5.2 | OpenAI Responses API background 모드 (DK) |
| **v37** | gpt-5.2 | **DB 컬럼명 수정 + reasoning 필터링 + 3키 로드밸런싱 (DK)** |

#### v37 주요 변경사항 (2026-02-01)
- `isAdminUser()`: `.eq("is_primary", true)` → `.eq("profile_type", "primary")` (DB 컬럼명 불일치 수정)
- `recordTokenUsage()`: `gpt_saju_analysis_tokens` → `saju_analysis_tokens` (DB 컬럼명 불일치 수정)
- `gpt_saju_analysis_count` 참조 제거 (DB에 존재하지 않는 컬럼)
- `collectStreamResponse()`: `delta.reasoning_content` 필터링 (GPT thinking 내용 사용자 노출 방지)
- API키 3개 로드밸런싱: `OPENAI_API_KEY`, `OPENAI_API_KEY_2`, `OPENAI_API_KEY_3`

### ai-openai-result
| 버전 | 용도 | 변경 사유 |
|------|------|----------|
| v4 | 결과 폴링 | OpenAI /v1/responses/{id} 폴링 엔드포인트 (DK) |
| **v15** | 결과 폴링 | **DB 컬럼명 수정 + reasoning 타입 필터링 (DK)** |

#### v15 주요 변경사항 (2026-02-01)
- `recordTokenUsage()`: `gpt_saju_analysis_tokens` → `saju_analysis_tokens` (DB 컬럼명 불일치 수정)
- `gpt_saju_analysis_count` 참조 제거
- output 배열에서 `type === "reasoning"` 항목 명시적 제외 (GPT thinking 내용 제외)
- content 배열에서 `type === "reasoning"` 항목도 제외

---

## 수정 규칙

### ❌ 절대 하지 말 것
1. **모델명 임의 변경** - 반드시 이 문서의 모델 사용
2. **max_tokens 축소** - 응답 짤림 발생
3. **테스트 없이 배포** - 반드시 로컬 테스트 후 배포

### ✅ 수정 시 필수 작업
1. 이 문서(`EdgeFunction_task.md`) 먼저 확인
2. 백업 파일 생성 (`supabase/backups/`)
3. 버전 번호 증가
4. 문서 업데이트
5. 배포 후 테스트

---

## Flutter 클라이언트 설정

### gemini_edge_datasource.dart
```dart
'model': 'gemini-3-flash-preview',  // 변경 금지
'max_tokens': 2048,                  // Edge Function이 4096으로 오버라이드
```

### openai_edge_datasource.dart
```dart
'model': 'gpt-5.2',           // 변경 금지 - GPT-5.2 Thinking
'max_tokens': 10000,          // 변경 금지 - 전체 응답 보장
'run_in_background': true,    // v24: Async + Polling 모드

// 폴링 설정
static const int _maxPollingAttempts = 120;  // 최대 120회
static const Duration _pollingInterval = Duration(seconds: 2);  // 2초 간격
```

---

## 배포 명령어

```bash
# ai-gemini 배포
cd e:/SJ && npx supabase functions deploy ai-gemini --project-ref kfciluyxkomskyxjaeat

# ai-openai 배포
cd e:/SJ && npx supabase functions deploy ai-openai --project-ref kfciluyxkomskyxjaeat

# ai-openai-result 배포 (v24 신규)
cd e:/SJ && npx supabase functions deploy ai-openai-result --project-ref kfciluyxkomskyxjaeat
```

---

## 백업 파일 위치

```
supabase/backups/
├── ai-gemini_v15_2024-12-30.ts  (현재 배포됨)
├── ai-openai_v10_2024-12-31.ts  (이전 버전)
└── ...

supabase/functions/
├── ai-openai/index.ts         (v37 - 현재 배포됨)
├── ai-openai/index_DK.ts      (DK 원본 백업)
└── ai-openai-result/index.ts  (v15 - 현재 배포됨)
```

---

## 문제 발생 시

1. Supabase Dashboard에서 로그 확인
2. 백업 파일에서 이전 버전 복원
3. `supabase_Jaehyeon_Task.md` 에러 기록 확인

---

## 알려진 이슈 (Known Issues)

### ai-gemini: DB 컬럼명 불일치 (미수정)
- `ai-gemini/index.ts`에서 `gemini_chat_tokens`, `gemini_chat_message_count` 사용
- **실제 DB 컬럼**: `chatting_tokens`, `chatting_message_count`
- 현재 토큰 기록이 실패하고 있으나 채팅 기능 자체에는 영향 없음
- 수정 시 ai-gemini Edge Function 재배포 필요

### DB 컬럼명 참고 (user_daily_token_usage 실제 스키마)
```
saju_analysis_tokens      -- 사주분석 (ai-openai)
daily_fortune_tokens      -- 일운 (ai-gemini)
monthly_fortune_tokens    -- 월운
yearly_fortune_2025_tokens -- 2025 회고
yearly_fortune_2026_tokens -- 2026 신년
chatting_tokens           -- 채팅 (ai-gemini) ← gemini_chat_tokens 아님!
gpt_cost_usd             -- GPT 비용
gemini_cost_usd           -- Gemini 비용
total_tokens (GENERATED)  -- 자동 합산
is_quota_exceeded (GENERATED) -- 자동 판단
```

---

## 담당자

- **JH_BE (Jaehyeon)**: Supabase Backend, Edge Functions
- **DK**: Edge Function 배포/관리, AI 파이프라인
- 문의: 이 문서 또는 `supabase_Jaehyeon_Task.md` 참조
