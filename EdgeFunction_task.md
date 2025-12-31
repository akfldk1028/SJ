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
| **버전** | v24 | 2026-01-01 |
| **모델** | `gpt-5.2-2025-12-11` | ⚠️ 변경 금지 - 최신 모델 |
| **max_tokens** | `10000` | 전체 응답 보장 |
| **temperature** | `0.7` | 분석용 |
| **용도** | 평생 사주 분석 | OpenAI Responses API Background 모드 |
| **Background** | `true` | Supabase 150초 제한 회피! |

```typescript
// ai-openai/index.ts - 핵심 설정 (v24)
model = "gpt-5.2-2025-12-11"  // 변경 금지 - 최신 모델
max_tokens = 10000             // 변경 금지 - 전체 응답 보장
temperature = 0.7
background = true              // OpenAI Responses API 비동기 모드
```

---

### ai-openai-result (결과 조회용) - NEW!

| 항목 | 값 | 비고 |
|------|-----|------|
| **버전** | v24 | 2026-01-01 |
| **용도** | Background task 결과 polling | ai-openai와 연동 |
| **verify_jwt** | `false` | 401 에러 방지 |

```typescript
// ai-openai-result/index.ts - 핵심 설정 (v24)
// task_id로 OpenAI Responses API 결과 조회
// ai_tasks 테이블에 결과 캐싱
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
| **v24** | gpt-5.2-2025-12-11 | **OpenAI Responses API Background 모드** - Supabase 150초 제한 완전 회피! |

### ai-openai-result (NEW)
| 버전 | 용도 | 변경 사유 |
|------|------|----------|
| **v24** | 결과 조회 | ai-openai background 모드용 polling endpoint |

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
'model': 'gpt-5.2',            // 변경 금지 - Edge Function이 최신 모델로 오버라이드
'max_tokens': 10000,           // 변경 금지 - 전체 응답 보장
'run_in_background': true,     // v24: Background 모드 (Responses API)

// Polling 설정
_maxPollingAttempts = 120      // 최대 120회 (240초)
_pollingInterval = 2초         // 2초 간격
```

---

## 배포 명령어

```bash
# ai-gemini 배포
cd e:/SJ && npx supabase functions deploy ai-gemini --project-ref kfciluyxkomskyxjaeat

# ai-openai 배포
cd e:/SJ && npx supabase functions deploy ai-openai --project-ref kfciluyxkomskyxjaeat

# ai-openai-result 배포 (v24 NEW - polling endpoint)
cd e:/SJ && npx supabase functions deploy ai-openai-result --project-ref kfciluyxkomskyxjaeat
```

---

## 백업 파일 위치

```
supabase/backups/
├── ai-gemini_v15_2024-12-30.ts      (현재 배포됨)
├── ai-openai_v24_2026-01-01.ts      (현재 배포됨 - Responses API background)
├── ai-openai-result_v24_2026-01-01.ts (현재 배포됨 - polling endpoint)
└── ...
```

---

## 문제 발생 시

1. Supabase Dashboard에서 로그 확인
2. 백업 파일에서 이전 버전 복원
3. `supabase_Jaehyeon_Task.md` 에러 기록 확인

---

## 담당자

- **JH_BE (Jaehyeon)**: Supabase Backend, Edge Functions
- 문의: 이 문서 또는 `supabase_Jaehyeon_Task.md` 참조
