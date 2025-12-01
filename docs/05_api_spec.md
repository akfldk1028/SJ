# API 명세서 (Supabase 기반)

> 만톡: AI 사주 챗봇 - Supabase Edge Functions + PostgreSQL 기반 API

---

## 1. 기본 정보

| 항목 | 값 |
|------|-----|
| Supabase URL (Dev) | https://[DEV_PROJECT].supabase.co |
| Supabase URL (Prod) | https://[PROD_PROJECT].supabase.co |
| Edge Functions URL | https://[PROJECT].supabase.co/functions/v1/{function-name} |
| 인증 방식 | Supabase Auth (JWT) |
| Content-Type | application/json |

---

## 2. 인증 방식

### 2.1 Supabase Auth 토큰
```
Authorization: Bearer {SUPABASE_ACCESS_TOKEN}
```

- Supabase Auth로 로그인하면 자동으로 JWT 토큰 발급
- `supabase_flutter` 패키지가 자동으로 토큰 관리
- RLS(Row Level Security)로 데이터 접근 제어

### 2.2 Flutter에서 인증 헤더 자동 처리
```dart
// supabase_flutter가 자동으로 처리
final response = await supabase.from('saju_profiles').select();

// Edge Functions 호출 시에도 자동 처리
final response = await supabase.functions.invoke('saju-chat', body: {...});
```

---

## 3. 데이터베이스 직접 접근 (RLS 적용)

### 3.1 사주 프로필 CRUD

#### 프로필 생성
```dart
// Flutter
final response = await supabase
    .from('saju_profiles')
    .insert({
      'display_name': '나',
      'birth_date': '1996-05-21',
      'birth_time_minutes': 570,
      'birth_time_unknown': false,
      'is_lunar': false,
      'gender': 'female',
      'birth_place': '서울',
    })
    .select()
    .single();
```

#### 프로필 목록 조회
```dart
final profiles = await supabase
    .from('saju_profiles')
    .select()
    .order('created_at', ascending: false);
```

#### 프로필 + 차트 + 요약 조회 (JOIN)
```dart
final profile = await supabase
    .from('saju_profiles')
    .select('''
      *,
      saju_charts (*),
      saju_summaries (*)
    ''')
    .eq('id', profileId)
    .single();
```

#### 프로필 수정
```dart
await supabase
    .from('saju_profiles')
    .update({'display_name': '연인'})
    .eq('id', profileId);
```

#### 프로필 삭제
```dart
await supabase
    .from('saju_profiles')
    .delete()
    .eq('id', profileId);
```

---

### 3.2 채팅 세션/메시지

#### 채팅 세션 목록 조회
```dart
final sessions = await supabase
    .from('chat_sessions')
    .select()
    .eq('profile_id', profileId)
    .order('last_message_at', ascending: false)
    .limit(20);
```

#### 채팅 메시지 조회
```dart
final messages = await supabase
    .from('chat_messages')
    .select()
    .eq('chat_id', chatId)
    .order('created_at', ascending: true);
```

#### 채팅 세션 검색
```dart
final sessions = await supabase
    .from('chat_sessions')
    .select()
    .eq('profile_id', profileId)
    .ilike('title', '%이직%');
```

---

## 4. Edge Functions (서버리스 함수)

### 4.1 사주 챗봇 - saju-chat

> 핵심 API: Gemini LLM을 호출하여 사주 상담 응답 생성

**호출 방법:**
```dart
final response = await supabase.functions.invoke(
  'saju-chat',
  body: {
    'chatId': null,  // 새 세션이면 null
    'profileId': 'profile-uuid',
    'message': '올해 이직해도 괜찮을까요?',
  },
);
```

**Edge Function 구현 (Deno):**
```typescript
// supabase/functions/saju-chat/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const authHeader = req.headers.get('Authorization')!
    const token = authHeader.replace('Bearer ', '')
    const { data: { user } } = await supabase.auth.getUser(token)

    if (!user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const { chatId, profileId, message } = await req.json()

    // 1. 프로필 + 사주 차트 조회
    const { data: profile } = await supabase
      .from('saju_profiles')
      .select('*, saju_charts(*), saju_summaries(*)')
      .eq('id', profileId)
      .eq('user_id', user.id)
      .single()

    if (!profile) {
      return new Response(JSON.stringify({ error: 'Profile not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // 2. 채팅 세션 생성 또는 조회
    let sessionId = chatId
    if (!sessionId) {
      const { data: newSession } = await supabase
        .from('chat_sessions')
        .insert({ profile_id: profileId })
        .select()
        .single()
      sessionId = newSession.id
    }

    // 3. 사용자 메시지 저장
    await supabase
      .from('chat_messages')
      .insert({
        chat_id: sessionId,
        role: 'user',
        content: message,
      })

    // 4. 이전 대화 히스토리 조회
    const { data: history } = await supabase
      .from('chat_messages')
      .select()
      .eq('chat_id', sessionId)
      .order('created_at', ascending: true)
      .limit(20)

    // 5. Gemini API 호출
    const geminiResponse = await callGemini(profile, history, message)

    // 6. AI 응답 저장
    const { data: aiMessage } = await supabase
      .from('chat_messages')
      .insert({
        chat_id: sessionId,
        role: 'assistant',
        content: geminiResponse.content,
        suggested_questions: geminiResponse.suggestedQuestions,
      })
      .select()
      .single()

    // 7. 세션 제목 업데이트 (첫 메시지인 경우)
    if (!chatId) {
      await supabase
        .from('chat_sessions')
        .update({ title: message.substring(0, 50) })
        .eq('id', sessionId)
    }

    return new Response(JSON.stringify({
      success: true,
      data: {
        chatId: sessionId,
        messageId: aiMessage.id,
        content: geminiResponse.content,
        suggestedQuestions: geminiResponse.suggestedQuestions,
        createdAt: aiMessage.created_at,
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})

async function callGemini(profile: any, history: any[], message: string) {
  const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')

  const systemPrompt = buildSajuPrompt(profile)
  const messages = history.map(m => ({
    role: m.role === 'user' ? 'user' : 'model',
    parts: [{ text: m.content }]
  }))

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: systemPrompt }] },
        contents: messages,
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 1024,
        }
      })
    }
  )

  const data = await response.json()
  const text = data.candidates[0].content.parts[0].text

  // 추천 질문 추출 (응답 끝에 있다고 가정)
  const suggestedQuestions = extractSuggestedQuestions(text)

  return {
    content: text,
    suggestedQuestions,
  }
}

function buildSajuPrompt(profile: any): string {
  const chart = profile.saju_charts
  const summary = profile.saju_summaries

  return `당신은 친절하고 따뜻한 AI 사주 상담사 "만톡이"입니다.

## 사용자 사주 정보
- 생년월일: ${profile.birth_date} (${profile.is_lunar ? '음력' : '양력'})
- 성별: ${profile.gender === 'male' ? '남성' : '여성'}
- 사주팔자:
  - 연주: ${chart?.year_stem}${chart?.year_branch}
  - 월주: ${chart?.month_stem}${chart?.month_branch}
  - 일주: ${chart?.day_stem}${chart?.day_branch}
  - 시주: ${chart?.hour_stem || '?'}${chart?.hour_branch || '?'}

## 성향 요약
${summary?.overview || '아직 요약이 생성되지 않았습니다.'}

## 응답 규칙
1. 한국어로 자연스럽게 대화하세요
2. 사주 용어는 쉽게 풀어서 설명하세요
3. 긍정적이고 격려하는 톤을 유지하세요
4. "사주는 참고용이며, 최종 결정은 본인의 몫입니다"를 적절히 언급하세요
5. 의료, 법률, 재무 조언은 전문가 상담을 권유하세요
6. 응답 마지막에 2-3개의 후속 질문을 제안하세요

## 형식
응답 후 "---" 구분선 아래에 추천 질문을 나열하세요:
---
추천 질문:
1. [질문1]
2. [질문2]
`
}
```

**응답 예시:**
```json
{
  "success": true,
  "data": {
    "chatId": "chat-uuid",
    "messageId": "msg-uuid",
    "content": "사주상 올해는 변화의 기운이 강하게 들어와 있어요...",
    "suggestedQuestions": [
      "현재 직장에서 힘든 점은 무엇인가요?",
      "이직을 고민하게 된 계기가 있나요?"
    ],
    "createdAt": "2025-12-01T12:34:56Z"
  }
}
```

---

### 4.2 만세력 계산 - calculate-saju

> 생년월일 기반 사주팔자 계산

**호출 방법:**
```dart
final response = await supabase.functions.invoke(
  'calculate-saju',
  body: {
    'profileId': 'profile-uuid',
  },
);
```

**Edge Function 구현:**
```typescript
// supabase/functions/calculate-saju/index.ts
serve(async (req) => {
  // ... 인증 처리 ...

  const { profileId } = await req.json()

  // 1. 프로필 조회
  const { data: profile } = await supabase
    .from('saju_profiles')
    .select()
    .eq('id', profileId)
    .single()

  // 2. 만세력 계산 (외부 API 또는 자체 계산)
  const chart = await calculateManseryeok(profile)

  // 3. 사주 차트 저장 (upsert)
  const { data: savedChart } = await supabase
    .from('saju_charts')
    .upsert({
      profile_id: profileId,
      year_stem: chart.yearPillar.stem,
      year_branch: chart.yearPillar.branch,
      month_stem: chart.monthPillar.stem,
      month_branch: chart.monthPillar.branch,
      day_stem: chart.dayPillar.stem,
      day_branch: chart.dayPillar.branch,
      hour_stem: chart.hourPillar?.stem,
      hour_branch: chart.hourPillar?.branch,
      daewoon: chart.daewoon,
      raw_data: chart.rawData,
    })
    .select()
    .single()

  return new Response(JSON.stringify({
    success: true,
    data: savedChart
  }))
})
```

**응답 예시:**
```json
{
  "success": true,
  "data": {
    "id": "chart-uuid",
    "profile_id": "profile-uuid",
    "year_stem": "갑",
    "year_branch": "자",
    "month_stem": "병",
    "month_branch": "인",
    "day_stem": "신",
    "day_branch": "사",
    "hour_stem": "경",
    "hour_branch": "오",
    "daewoon": [...],
    "calculated_at": "2025-12-01T12:00:00Z"
  }
}
```

---

### 4.3 사주 요약 생성 - generate-summary

> LLM으로 사주 요약 리포트 생성

**호출 방법:**
```dart
final response = await supabase.functions.invoke(
  'generate-summary',
  body: {
    'profileId': 'profile-uuid',
  },
);
```

**응답 예시:**
```json
{
  "success": true,
  "data": {
    "id": "summary-uuid",
    "profile_id": "profile-uuid",
    "overview": "전체적으로 균형 잡힌 성향이며...",
    "strengths": ["책임감이 강함", "타인 공감 능력"],
    "weaknesses": ["혼자 감당하려는 경향"],
    "career": "조직 내에서 신뢰를 쌓으며...",
    "love": "상대를 배려하는 편...",
    "money": "투자에는 신중할 필요...",
    "yearly_focus": "2025년은 변화의 해...",
    "created_at": "2025-12-01T12:00:00Z"
  }
}
```

---

## 5. 에러 처리

### 5.1 에러 코드
| 코드 | HTTP | 설명 |
|------|------|------|
| UNAUTHORIZED | 401 | 인증 필요 |
| NOT_FOUND | 404 | 리소스 없음 |
| VALIDATION_ERROR | 400 | 입력값 검증 실패 |
| SAJU_CALCULATION_FAILED | 500 | 만세력 계산 실패 |
| LLM_ERROR | 500 | LLM 호출 실패 |
| LLM_SAFETY_BLOCKED | 400 | 안전 정책으로 차단 |
| RATE_LIMIT | 429 | 요청 과다 |

### 5.2 에러 응답 형식
```json
{
  "success": false,
  "error": {
    "code": "LLM_ERROR",
    "message": "AI 응답 생성 중 오류가 발생했습니다"
  }
}
```

### 5.3 Flutter 에러 처리
```dart
try {
  final response = await supabase.functions.invoke('saju-chat', body: {...});

  if (response.status != 200) {
    final error = response.data['error'];
    throw ApiException(error['code'], error['message']);
  }

  return response.data['data'];
} on FunctionException catch (e) {
  // Edge Function 호출 실패
  throw NetworkException('서버 연결 실패');
} catch (e) {
  throw UnknownException(e.toString());
}
```

---

## 6. Supabase Realtime (선택)

### 6.1 채팅 메시지 실시간 구독
```dart
final subscription = supabase
    .from('chat_messages')
    .stream(primaryKey: ['id'])
    .eq('chat_id', chatId)
    .order('created_at')
    .listen((messages) {
      // 새 메시지 도착 시 UI 업데이트
      ref.read(chatMessagesProvider.notifier).updateMessages(messages);
    });

// 구독 해제
subscription.cancel();
```

---

## 7. Edge Functions 배포

### 7.1 로컬 개발
```bash
# Supabase CLI 설치
npm install -g supabase

# 로컬 Supabase 시작
supabase start

# Edge Function 개발 서버
supabase functions serve saju-chat --env-file .env.local
```

### 7.2 환경 변수 설정
```bash
# Supabase Dashboard > Edge Functions > Secrets
GEMINI_API_KEY=your-gemini-api-key
```

### 7.3 배포
```bash
supabase functions deploy saju-chat
supabase functions deploy calculate-saju
supabase functions deploy generate-summary
```

---

## 8. Rate Limiting

### 8.1 Edge Function 레벨
```typescript
// 간단한 Rate Limiting (Redis 또는 Supabase 테이블 활용)
const rateLimitKey = `rate_limit:${user.id}`
const currentCount = await getCount(rateLimitKey)

if (currentCount > 50) { // 분당 50회 제한
  return new Response(JSON.stringify({
    success: false,
    error: { code: 'RATE_LIMIT', message: '요청이 너무 많습니다' }
  }), { status: 429 })
}

await incrementCount(rateLimitKey, 60) // 60초 TTL
```

---

## 체크리스트

- [x] Supabase 기본 정보 정의
- [x] 인증 방식 정의 (Supabase Auth)
- [x] 데이터베이스 직접 접근 API
- [x] Edge Function: saju-chat
- [x] Edge Function: calculate-saju
- [x] Edge Function: generate-summary
- [x] 에러 처리 가이드
- [x] Realtime 구독 예시
- [x] 배포 가이드
