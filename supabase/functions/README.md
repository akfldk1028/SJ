# Supabase Edge Functions

만톡 AI 사주 서비스를 위한 Edge Functions 문서입니다.

---

## 함수 목록

| 함수명 | 용도 | 모델 | 버전 | 로컬 소스 |
|--------|------|------|------|-----------|
| **ai-openai** | GPT-5.2 API (평생 사주) | `gpt-5.2` | v2 | ✓ |
| **ai-gemini** | Gemini API (일운) | `gemini-2.0-flash` | v1 | ✓ |
| **generate-ai-summary** | Legacy AI Summary | `gemini-2.0-flash` | v4 | ✓ |
| **saju-chat** | 사주 채팅 | - | v3 | ✗ (원격만) |
| **migrate-gilseong** | 길성 마이그레이션 | - | v2 | ✗ (원격만) |

---

## 1. ai-openai

**GPT-5.2 API 호출 (평생 사주 분석)**

### 개요
- OpenAI GPT-5.2 모델을 사용한 사주 분석
- API 키는 서버 환경변수로 보안 관리
- Chat Completions API 호출

### 환경변수
```env
OPENAI_API_KEY=sk-...
```

### 요청 형식
```typescript
interface OpenAIRequest {
  messages: ChatMessage[];    // [{role: 'system'|'user'|'assistant', content: string}]
  model?: string;             // 기본값: 'gpt-5.2'
  max_tokens?: number;        // 기본값: 2000
  temperature?: number;       // 기본값: 0.7
  response_format?: {         // 기본값: {type: 'json_object'}
    type: 'json_object' | 'text'
  };
}
```

### 응답 형식
```typescript
// 성공
{
  success: true,
  content: string,            // AI 응답 (JSON 문자열)
  usage: {
    prompt_tokens: number,
    completion_tokens: number,
    total_tokens: number,
    cached_tokens: number     // Prompt Caching (90% 할인)
  },
  model: string,
  finish_reason: string
}

// 실패
{
  success: false,
  error: string
}
```

### 호출 예시 (Flutter)
```dart
final response = await Supabase.instance.client.functions.invoke(
  'ai-openai',
  body: {
    'messages': [
      {'role': 'system', 'content': '사주 분석 전문가입니다.'},
      {'role': 'user', 'content': '갑자년 병인월 무진일 계해시...'}
    ],
    'model': 'gpt-5.2',
    'max_tokens': 4096,
    'temperature': 0.7,
  },
);
```

### 비용 (GPT-5.2)
| 구분 | 가격 (1M 토큰당) |
|------|------------------|
| Input | $1.75 |
| Output | $14.00 |
| Cached | $0.175 (90% 할인) |

---

## 2. ai-gemini

**Gemini API 호출 (일운/빠른 분석)**

### 개요
- Google Gemini 2.0 Flash 모델 사용
- GPT보다 빠름 (1-2초)
- 비용 효율적 (GPT 대비 약 25배 저렴)

### 환경변수
```env
GEMINI_API_KEY=AI...
```

### 요청 형식
```typescript
interface GeminiRequest {
  messages: ChatMessage[];    // OpenAI 형식 그대로 사용
  model?: string;             // 기본값: 'gemini-2.0-flash'
  max_tokens?: number;        // 기본값: 1000
  temperature?: number;       // 기본값: 0.8
}
```

### 응답 형식
```typescript
// 성공
{
  success: true,
  content: string,            // AI 응답 (JSON 문자열)
  usage: {
    prompt_tokens: number,
    completion_tokens: number,
    total_tokens: number
  },
  model: string,
  finish_reason: string
}

// 실패
{
  success: false,
  error: string
}
```

### 호출 예시 (Flutter)
```dart
final response = await Supabase.instance.client.functions.invoke(
  'ai-gemini',
  body: {
    'messages': [
      {'role': 'system', 'content': '오늘의 운세 전문가입니다.'},
      {'role': 'user', 'content': '병화 일간의 오늘 운세...'}
    ],
    'model': 'gemini-2.0-flash',
    'max_tokens': 1000,
  },
);
```

### 비용 (Gemini 2.0 Flash)
| 구분 | 가격 (1M 토큰당) |
|------|------------------|
| Input | $0.10 |
| Output | $0.40 |

### 메시지 형식 변환
OpenAI 형식 → Gemini 형식 자동 변환:
- `system` → `systemInstruction`
- `assistant` → `model`
- `user` → `user`

---

## 3. generate-ai-summary

**Legacy AI Summary 생성**

### 개요
- 기존 버전 호환용 (신규 개발은 ai-openai/ai-gemini 사용)
- Gemini로 성격, 직업, 운세 팁 생성
- DB 직접 저장 (`saju_analyses.ai_summary`)

### 환경변수
```env
GEMINI_API_KEY=AI...
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

### 요청 형식
```typescript
interface GenerateSummaryRequest {
  profile_id: string;         // 프로필 UUID
  profile_name: string;       // 사용자 이름
  birth_date: string;         // 생년월일
  saju_analysis: {            // 사주 분석 데이터
    saju: {
      year: {gan: string, ji: string},
      month: {gan: string, ji: string},
      day: {gan: string, ji: string},
      hour?: {gan: string, ji: string}
    },
    oheng: {
      wood: number, fire: number, earth: number,
      metal: number, water: number
    },
    yongsin?: {...},
    singang_singak?: {...}
  };
  force_regenerate?: boolean; // 강제 재생성 (캐시 무시)
}
```

### 응답 형식
```typescript
{
  success: true,
  ai_summary: {
    personality: {
      core: string,           // 핵심 성격
      traits: string[]        // 성격 특성
    },
    strengths: string[],      // 강점
    weaknesses: string[],     // 약점
    career: {
      aptitude: string[],     // 적성 분야
      advice: string          // 조언
    },
    relationships: {
      style: string,          // 대인관계 스타일
      tips: string            // 팁
    },
    fortune_tips: {
      colors: string[],       // 행운 색상
      directions: string[],   // 행운 방향
      activities: string[]    // 추천 활동
    },
    generated_at: string,     // 생성 시간
    model: string,            // 사용 모델
    version: string           // 버전
  },
  cached: boolean,            // 캐시 여부
  db_saved: boolean,          // DB 저장 여부
  db_error?: string           // DB 오류 메시지
}
```

---

## 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App                            │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              AiApiService                               │ │
│  │  callOpenAI() ──────────┐    callGemini() ────────┐    │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────────────┬─────────────────────┬────────┘
                               │                     │
                               ▼                     ▼
            ┌──────────────────────────────────────────────────┐
            │           Supabase Edge Functions                │
            │  ┌─────────────┐   ┌─────────────────────────┐  │
            │  │ ai-openai   │   │ ai-gemini               │  │
            │  │ (GPT-5.2)   │   │ (Gemini 2.0)            │  │
            │  └──────┬──────┘   └──────────┬──────────────┘  │
            └─────────┼────────────────────┼──────────────────┘
                      │                    │
                      ▼                    ▼
            ┌─────────────────┐  ┌─────────────────────────────┐
            │   OpenAI API    │  │   Google Gemini API         │
            │   (GPT-5.2)     │  │   (gemini-2.0-flash)        │
            └─────────────────┘  └─────────────────────────────┘
```

---

## 배포

### Supabase CLI 사용
```bash
# 함수 배포
supabase functions deploy ai-openai
supabase functions deploy ai-gemini
supabase functions deploy generate-ai-summary

# 환경변수 설정
supabase secrets set OPENAI_API_KEY=sk-...
supabase secrets set GEMINI_API_KEY=AI...
```

### MCP 도구 사용 (Claude Code)
```
mcp__supabase__deploy_edge_function 사용
```

---

## 보안

1. **API 키 보안**: 모든 API 키는 Supabase 환경변수로 관리 (클라이언트 노출 없음)
2. **CORS 설정**: 모든 함수에 CORS 헤더 포함
3. **Service Role Key**: `generate-ai-summary`만 사용 (RLS 우회 필요)

---

## 관련 파일

### Flutter 클라이언트
- `frontend/lib/AI/services/ai_api_service.dart` - API 서비스
- `frontend/lib/AI/services/saju_analysis_service.dart` - 분석 오케스트레이터
- `frontend/lib/AI/core/ai_constants.dart` - 모델/가격 상수

### 프롬프트
- `frontend/lib/AI/prompts/saju_base_prompt.dart` - 평생 사주 프롬프트
- `supabase/functions/generate-ai-summary/prompts.ts` - Legacy 프롬프트

---

## 버전 히스토리

### ai-openai
- v1: 초기 버전 (GPT-4o)
- v2: GPT-5.2 업데이트 (2025-12-26)

### ai-gemini
- v1: 초기 버전 (gemini-2.0-flash)

### generate-ai-summary
- v1~v3: 초기 개발
- v4: 안정화 버전

---

## 4. saju-chat (원격 전용)

**사주 채팅 기능**

> ⚠️ 로컬 소스 없음 - Supabase에만 배포됨

### 개요
- 사주 채팅 기능을 위한 Edge Function
- v3 배포됨

---

## 5. migrate-gilseong (원격 전용)

**길성(吉星) 데이터 마이그레이션**

> ⚠️ 로컬 소스 없음 - Supabase에만 배포됨

### 개요
- 길성 데이터를 마이그레이션하는 유틸리티 함수
- 일회성 작업용으로 추정
- v2 배포됨
