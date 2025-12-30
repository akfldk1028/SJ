# 사주 챗봇 기능 명세서

> 만톡의 핵심 기능 - Gemini 기반 AI 사주 상담 채팅

---

## 1. 기본 정보

| 항목 | 내용 |
|------|------|
| 기능명 | 사주 챗봇 (AI 사주 상담) |
| 우선순위 | **P0 (필수 - 핵심 기능)** |
| 라우트 | /saju/chat |
| 상태 | 기획 완료 |

---

## 2. 사용자 스토리

1. **사용자**로서, 내 사주를 바탕으로 **AI와 대화하며 상담**받고 싶다
2. **사용자**로서, "올해 이직해도 될까?" 같은 **구체적인 질문**을 하고 싶다
3. **사용자**로서, AI가 제안하는 **추천 질문**을 눌러서 편하게 대화하고 싶다
4. **사용자**로서, 언제든 **사주 요약**을 확인하면서 대화하고 싶다
5. **사용자**로서, 과거 **대화 내용을 이어가며** 상담받고 싶다

---

## 3. 화면 구성

### 3.1 화면 레이아웃
```
┌────────────────────────────────────────────┐
│ [←] 만톡        [프로필 전환 ▼] [⚙️ 설정]   │  ← AppBar
├────────────────────────────────────────────┤
│ ┌────────────────────────────────────────┐ │
│ │ 🔮 사주는 참고용입니다                  │ │  ← 면책 배너
│ └────────────────────────────────────────┘ │
├────────────────────────────────────────────┤
│                                            │
│  ┌──────────────────────────────────────┐  │
│  │ 안녕하세요! 저는 만톡이에요.          │  │  ← AI 인사
│  │ 오늘 어떤 고민이 있으신가요?          │  │
│  └──────────────────────────────────────┘  │
│                                            │
│                    ┌────────────────────┐  │
│                    │ 올해 이직해도      │  │  ← 사용자 메시지
│                    │ 괜찮을까요?        │  │
│                    └────────────────────┘  │
│                                            │
│  ┌──────────────────────────────────────┐  │
│  │ 사주를 보니 올해는 변화의 기운이      │  │  ← AI 응답
│  │ 강하게 들어와 있어요. 다만...         │  │
│  │                                      │  │
│  │ [현재 직장 힘든 점?] [이직 계기?]    │  │  ← 추천 질문
│  └──────────────────────────────────────┘  │
│                                            │
├────────────────────────────────────────────┤
│ [📊 사주 요약]  [메시지 입력...    ] [➤]  │  ← 입력 영역
└────────────────────────────────────────────┘
```

### 3.2 UI 요소

| 요소 | 타입 | 동작 |
|------|------|------|
| 프로필 전환 버튼 | DropdownButton | 등록된 프로필 목록 표시, 선택 시 전환 |
| 면책 배너 | Container | 스크롤해도 상단 고정, 탭하면 상세 안내 |
| 채팅 리스트 | ListView | 메시지 표시, 자동 스크롤 |
| AI 메시지 버블 | Container | 왼쪽 정렬, 추천 질문 칩 포함 |
| 사용자 메시지 버블 | Container | 오른쪽 정렬, 배경색 다름 |
| 추천 질문 칩 | ActionChip | 탭하면 해당 질문 자동 전송 |
| 사주 요약 버튼 | IconButton | BottomSheet로 요약 표시 |
| 메시지 입력 필드 | TextField | 멀티라인, 최대 500자 |
| 전송 버튼 | IconButton | 입력 내용 전송, 비어있으면 비활성화 |

---

## 4. 수락 조건 (Acceptance Criteria)

### 4.1 채팅 기본 기능
- [ ] 앱 시작 시 AI가 먼저 인사 메시지를 보낸다
- [ ] 사용자가 메시지를 입력하고 전송할 수 있다
- [ ] AI 응답이 올 때까지 로딩 인디케이터를 표시한다
- [ ] AI 응답은 타이핑 효과 또는 즉시 표시 (설정 가능)
- [ ] 새 메시지가 오면 자동으로 하단 스크롤

### 4.2 추천 질문
- [ ] AI 응답에 추천 질문이 있으면 칩으로 표시
- [ ] 추천 질문 칩을 탭하면 해당 질문이 자동 전송
- [ ] 추천 질문은 2~4개까지 표시

### 4.3 프로필 전환
- [ ] 현재 활성화된 프로필 이름이 상단에 표시
- [ ] 프로필 전환 시 새 대화 세션 시작 (또는 확인 팝업)
- [ ] 프로필별로 대화 히스토리 분리

### 4.4 사주 요약
- [ ] "사주 요약" 버튼 탭 → BottomSheet로 요약 표시
- [ ] 요약에는 성향, 강점, 약점, 올해 운세 포함
- [ ] 요약 시트에서 "자세히 보기" → 상세 리포트 화면

### 4.5 면책 안내
- [ ] 항상 상단에 "사주는 참고용입니다" 배너 표시
- [ ] 배너 탭 시 상세 면책 안내 다이얼로그

### 4.6 에러 처리
- [ ] 네트워크 오류 시 재시도 버튼 표시
- [ ] AI 응답 실패 시 "다시 시도" 옵션
- [ ] Rate Limit 시 안내 메시지 표시

---

## 5. UI/UX 흐름

### 5.1 기본 대화 흐름
```
화면 진입
    ↓
AI 인사 메시지 표시
"안녕하세요! 저는 만톡이에요. 오늘 어떤 고민이 있으신가요?"
    ↓
사용자 메시지 입력
    ↓
전송 버튼 탭
    ↓
로딩 상태 (AI 응답 대기)
    ↓
AI 응답 표시 + 추천 질문
    ↓
(반복)
```

### 5.2 프로필 전환 흐름
```
프로필 전환 버튼 탭
    ↓
프로필 목록 드롭다운
    ↓
다른 프로필 선택
    ↓
확인 팝업 "대화를 새로 시작할까요?"
    ├─ [네] → 새 세션 시작, AI 인사
    └─ [아니오] → 취소
```

### 5.3 사주 요약 흐름
```
"사주 요약" 버튼 탭
    ↓
BottomSheet 올라옴
    ├─ 성향 요약
    ├─ 강점 / 약점
    ├─ 올해 운세 포커스
    └─ [자세히 보기] 버튼
         ↓
    전체 리포트 화면 이동
```

---

## 6. 예외 처리

| 상황 | 처리 방법 | UI 표시 |
|------|-----------|---------|
| 네트워크 오류 | 재시도 버튼 표시 | "연결 오류. [다시 시도]" |
| AI 응답 지연 (10초+) | 취소 옵션 제공 | "응답이 느려요. [취소]" |
| Rate Limit | 대기 안내 | "요청이 많아요. 잠시 후 다시 시도해주세요" |
| 부적절한 질문 | 안전 응답 | "이 주제는 전문가와 상의해 보세요" |
| 빈 메시지 전송 | 전송 버튼 비활성화 | - |
| 프로필 없음 | 프로필 생성 유도 | "먼저 사주 정보를 입력해주세요" |

---

## 7. 데이터 요구사항 (Supabase)

### 7.1 Supabase 연동
| 방식 | 용도 | 설명 |
|------|------|------|
| Edge Function | saju-chat | 메시지 전송 및 Gemini AI 응답 생성 |
| Direct Query | chat_sessions | 채팅 세션 목록 조회 |
| Direct Query | chat_messages | 특정 세션 메시지 목록 조회 |
| Direct Query | saju_summaries | 사주 요약 조회 |

### 7.2 Edge Function 호출 예시
```dart
// 메시지 전송
final response = await supabase.functions.invoke(
  'saju-chat',
  body: {
    'chatId': null,  // 새 세션이면 null
    'profileId': 'profile-uuid',
    'message': '올해 이직해도 괜찮을까요?',
  },
);

// 응답
{
  "success": true,
  "data": {
    "chatId": "chat-uuid",
    "messageId": "msg-uuid",
    "content": "사주를 보니 올해는 변화의 기운이...",
    "suggestedQuestions": [
      "현재 직장에서 힘든 점은?",
      "이직을 고민하게 된 계기는?"
    ],
    "createdAt": "2025-12-01T12:34:56Z"
  }
}
```

### 7.3 Direct Query 예시
```dart
// 채팅 세션 목록
final sessions = await supabase
    .from('chat_sessions')
    .select()
    .eq('profile_id', profileId)
    .order('last_message_at', ascending: false);

// 채팅 메시지 조회
final messages = await supabase
    .from('chat_messages')
    .select()
    .eq('chat_id', chatId)
    .order('created_at', ascending: true);

// 사주 요약 조회
final summary = await supabase
    .from('saju_summaries')
    .select()
    .eq('profile_id', profileId)
    .single();
```

---

## 8. 상태 관리

### 8.1 ChatState
```dart
class ChatState {
  final String? activeChatId;
  final String activeProfileId;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final SajuSummary? summary;
}
```

### 8.2 이벤트/액션
| 액션 | 설명 |
|------|------|
| initChat | 채팅 화면 진입 시 초기화 |
| sendMessage | 사용자 메시지 전송 |
| receiveMessage | AI 응답 수신 |
| loadHistory | 이전 대화 불러오기 |
| switchProfile | 프로필 전환 |
| loadSummary | 사주 요약 로드 |

---

## 9. 의존성

### 9.1 다른 기능과의 관계
- **선행**: profile (프로필 1개 이상 필요)
- **선행**: saju_chart (만세력 계산 완료)
- **연관**: history (대화 기록 저장)

### 9.2 외부 패키지
- `flutter_chat_ui` 또는 커스텀 채팅 UI
- `flutter_markdown` (AI 응답에 마크다운 지원 시)

---

## 10. 테스트 케이스

| TC ID | 시나리오 | 예상 결과 |
|-------|----------|-----------|
| CHAT-001 | 메시지 전송 | AI 응답 수신 |
| CHAT-002 | 추천 질문 탭 | 해당 질문 자동 전송 |
| CHAT-003 | 프로필 전환 | 새 세션 시작 |
| CHAT-004 | 사주 요약 버튼 | BottomSheet 표시 |
| CHAT-005 | 네트워크 오류 | 재시도 버튼 표시 |
| CHAT-006 | 빈 입력 전송 시도 | 전송 버튼 비활성화 |
| CHAT-007 | 스크롤 상단 → 메시지 수신 | 자동 하단 스크롤 |

---

## 11. AI 시스템 프롬프트 아키텍처 (v2.0)

### 11.1 듀얼 AI 구조

```
┌─────────────────────────────────────────────────────────────────┐
│                        GPT-5.2 (분석)                            │
│  saju_analyses → ai-openai Edge Function → ai_summaries         │
│                                                                 │
│  출력: AiSummary (sajuOrigin 포함)                               │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Gemini 3.0 (채팅)                           │
│  AiSummary.sajuOrigin → chat_provider → ai-gemini Edge Function │
│                                                                 │
│  입력: 시스템 프롬프트 (sajuOrigin + 분석결과) + 사용자 메시지    │
└─────────────────────────────────────────────────────────────────┘
```

### 11.2 핵심 문제 해결: sajuOrigin 통합

**문제**: Gemini 채팅이 합충형파해, 십성, 신살 같은 복잡한 사주 정보를 까먹음

**해결책 (v2.0)**:
1. GPT-5.2 결과에 `saju_origin` 섹션 포함 (원본 사주 데이터)
2. `chat_provider.dart`에서 AIContext 제거
3. `AiSummary.sajuOrigin`만 참조하여 시스템 프롬프트 구성

**토큰 최적화 (v2.1)**:
- **첫 메시지**: sajuOrigin 전체 포함 (~2000 토큰)
- **이후 메시지**: sajuOrigin 생략 (대화 히스토리에서 참조)
- **효과**: 세션당 ~10000 토큰 이상 절약 (5회 대화 기준)

```
세션 시작  → 시스템 프롬프트 (sajuOrigin 전체) + "안녕하세요"
          → AI 응답에 사주 정보 기반 인사

메시지 2  → 시스템 프롬프트 (sajuOrigin 생략) + "올해 운세?"
          → 대화 히스토리에 이미 사주 정보 있음 → Gemini 기억

메시지 3  → 시스템 프롬프트 (sajuOrigin 생략) + "이직 해도 돼?"
          → 대화 히스토리 참조 → 합충형파해 기반 답변 가능
```

**코드 (v2.1)**:
```dart
// 첫 메시지 여부 확인 (AI 응답이 아직 없으면 첫 메시지)
final isFirstMessage = state.messages.where((m) => m.role == 'assistant').isEmpty;

final systemPrompt = _buildFullSystemPrompt(
  basePrompt: basePrompt,
  aiSummary: aiSummary,
  persona: currentPersona,
  isFirstMessage: isFirstMessage,  // v2.1: 토큰 최적화
);
```

```dart
// _buildFullSystemPrompt 내부
if (isFirstMessage && aiSummary.sajuOrigin != null) {
  // 첫 메시지: sajuOrigin 전체 포함
  _addSajuOriginToPrompt(buffer, aiSummary.sajuOrigin!);
} else if (!isFirstMessage) {
  // 이후 메시지: 간략 참조만
  buffer.writeln('(이전 대화에서 제공된 상세 사주 정보를 참조하세요)');
}
```

### 11.3 시스템 프롬프트 구조 (chat_provider.dart)

```dart
String _buildFullSystemPrompt({
  required String basePrompt,
  AiSummary? aiSummary,
  AiPersona? persona,
}) {
  // 1. 베이스 프롬프트 (페르소나 말투, 역할)
  buffer.writeln(basePrompt);

  // 2. sajuOrigin - 원본 사주 데이터 (v2.0 핵심)
  if (aiSummary?.sajuOrigin != null) {
    _addSajuOriginToPrompt(buffer, aiSummary.sajuOrigin!);
  }

  // 3. GPT 분석 결과
  // - 원국 분석 (wonGukAnalysis)
  // - 십성 분석 (sipsungAnalysis)
  // - 합충 분석 (hapchungAnalysis)
  // - 성격 (personality)
  // - 재물운 (wealth)
  // - 연애운 (love)
  // - 결혼운 (marriage)
  // - 직장운 (career)
  // - 사업운 (business)
  // - 건강운 (health)
  // - 신살길성 (sinsalGilseong)
  // - 인생주기 (lifeCycles)
  // - 행운요소 (luckyElements)
  // - 종합조언 (overallAdvice)
}
```

### 11.4 sajuOrigin 데이터 구조

| 필드 | 내용 | 예시 |
|------|------|------|
| saju | 사주팔자 (년월일시) | `년: 기묘, 월: 신미, 일: 경진, 시: 계미` |
| oheng | 오행 분포 | `목1, 화0, 토4, 금2, 수1` |
| day_master | 일간 | `경(庚) - 금(金)` |
| yongsin | 용신 정보 | `용신:수, 희신:금, 기신:토, 구신:목` |
| singang_singak | 신강/신약 | `태강(75점)` |
| gyeokguk | 격국 | `정인격(正印格)` |
| sipsin | 십성 배치 | `년간:정인, 월간:겁재, 시간:상관...` |
| hapchung | 합충형파해 | `삼합:묘미, 해:묘진...` |
| sinsal | 신살 목록 | `장성, 화개...` |
| gilseong | 길성 목록 | `천을귀인, 문창귀인...` |
| twelve_unsung | 12운성 | `년:태, 월:관대, 일:양, 시:관대` |
| daeun | 대운 | `현재: 갑술 (24~33세)` |

### 11.5 관련 파일

| 파일 | 역할 |
|------|------|
| `chat_provider.dart` | 시스템 프롬프트 구성 + Gemini 호출 |
| `ai_summary_service.dart` | AiSummary 모델 정의 (sajuOrigin 포함) |
| `saju_base_prompt.dart` | GPT-5.2 분석 프롬프트 (sajuOrigin 출력 스키마) |

### 11.6 디버그 로그 가이드 (순차 흐름)

#### 📍 전체 로그 태그 목록

| 태그 | 파일 경로 | 역할 |
|------|-----------|------|
| `[ChatNotifier]` | `features/saju_chat/presentation/providers/chat_provider.dart` | 채팅 상태 관리 |
| `[chat_provider.dart]` | 동일 | 프롬프트 빌드, AI 호출 |
| `[AiChatService]` | `core/services/ai_chat_service.dart` | Gemini Edge Function 호출 |
| `[AiSummaryService]` | `core/services/ai_summary_service.dart` | GPT 평생사주 분석 |
| `[AiApiService]` | `AI/services/ai_api_service.dart` | OpenAI/Gemini API 직접 호출 |
| `[SajuAnalysisService]` | `AI/services/saju_analysis_service.dart` | 사주 분석 파이프라인 |
| `[AiQueries]` | `AI/data/queries.dart` | DB → AI 입력 변환 |
| `[AuthService]` | `core/services/auth_service.dart` | 인증/세션 관리 |
| `[QuotaService]` | `core/services/quota_service.dart` | 토큰 할당량 관리 |
| `[Supabase]` | `core/services/supabase_service.dart` | DB 연결 |

---

#### 📍 채팅 메시지 전송 흐름

```
┌─────────────────────────────────────────────────────────────────────────┐
│ [1] 사용자 메시지 입력                                                   │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ [ChatNotifier] sendMessage 중복 호출 차단 - 이미 메시지 전송 중          │
│ [chat_provider.dart] sendMessage: 현재 페르소나 = mantok                 │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ [2] AI Summary 준비 (첫 메시지만)                                        │
├─────────────────────────────────────────────────────────────────────────┤
│ [ChatNotifier] 첫 메시지 - AI Summary 확인/생성                          │
│ [ChatNotifier] AI Summary 캐시에서 로드: {profileId}                     │
│   OR                                                                     │
│ [ChatNotifier] AI Summary 새로 생성 시작: {profileId}                    │
│ [AiSummaryService] Edge Function 호출: ai-openai                         │
│ [AiSummaryService] Profile: {profileId}                                  │
│ [AiSummaryService] 생성 완료 및 DB 저장: {profileId}                     │
│ [ChatNotifier] AI Summary 생성 완료 (cached: true/false)                 │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ [3] 메시지 추가                                                          │
├─────────────────────────────────────────────────────────────────────────┤
│ [ChatNotifier] 사용자 메시지 추가됨: messages.length=N                   │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ [4] 시스템 프롬프트 구성                                                 │
├─────────────────────────────────────────────────────────────────────────┤
│ [ChatNotifier] 페르소나 적용: 만톡이                                     │
│ [ChatNotifier] isFirstMessage: true/false                                │
│ [ChatNotifier] AI Summary가 시스템 프롬프트에 추가됨                     │
│                                                                          │
│ ┌── 첫 메시지일 때 ──────────────────────────────────────────────────┐  │
│ │ [ChatNotifier] sajuOrigin 전체 포함 (첫 메시지 - 합충형파해, 십성, 신살 등) │
│ └────────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│ ┌── 이후 메시지 ─────────────────────────────────────────────────────┐  │
│ │ [ChatNotifier] sajuOrigin 생략 (이후 메시지 - 대화 히스토리 참조)   │  │
│ └────────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│ [chat_provider.dart] _buildFullSystemPrompt: 페르소나 ID = mantok        │
│ [chat_provider.dart] _buildFullSystemPrompt: 최종 프롬프트 길이 = XXXX   │
│ [chat_provider.dart] _buildFullSystemPrompt: sajuOrigin 포함됨           │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ [5] Gemini API 호출                                                      │
├─────────────────────────────────────────────────────────────────────────┤
│ [AiChatService] Edge Function 호출: ai-gemini-chat                       │
│ [AiChatService] 메시지 수: N                                             │
│ [AiChatService] 응답 수신 완료                                           │
│ [AiChatService] 토큰: {totalTokens}                                      │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ [6] 응답 처리                                                            │
├─────────────────────────────────────────────────────────────────────────┤
│ [chat_provider.dart] sendMessage: AI 응답 수신 완료.                     │
│ [chat_provider.dart] sendMessage: 전체 응답 내용 = {content}             │
│ [chat_provider.dart] sendMessage: 토큰 사용량 = {tokens}                 │
│ [ChatNotifier] 토큰 사용량: {tokens}                                     │
│ [ChatNotifier] 후속 질문 추출: [질문1, 질문2, ...]                       │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ [7] Realtime 동기화 (옵션)                                               │
├─────────────────────────────────────────────────────────────────────────┤
│ [ChatNotifier] Realtime 메시지 추가: assistant                           │
└─────────────────────────────────────────────────────────────────────────┘
```

---

#### 📍 에러 발생 시 로그

```
┌─ 토큰 할당량 초과 ──────────────────────────────────────────────────────┐
│ [AiChatService] QUOTA_EXCEEDED: {quotaInfo}                              │
│ [AiSummaryService] QUOTA_EXCEEDED: {quotaInfo}                           │
└──────────────────────────────────────────────────────────────────────────┘

┌─ API 오류 ───────────────────────────────────────────────────────────────┐
│ [AiChatService] Error: {errorMessage}                                    │
│ [AiApiService] OpenAI 오류: {error}                                      │
│ [AiApiService] Gemini 오류: {error}                                      │
└──────────────────────────────────────────────────────────────────────────┘

┌─ 예외 ───────────────────────────────────────────────────────────────────┐
│ [AiChatService] Exception: {e}                                           │
│ [AiSummaryService] Exception: {e}                                        │
│ [ChatNotifier] AI Summary 오류: {e}                                      │
└──────────────────────────────────────────────────────────────────────────┘
```

---

#### 📍 토큰 최적화 확인 방법

**첫 메시지 (sajuOrigin 전체 포함):**
```
[ChatNotifier] isFirstMessage: true
[ChatNotifier] sajuOrigin 전체 포함 (첫 메시지 - 합충형파해, 십성, 신살 등)
[chat_provider.dart] _buildFullSystemPrompt: 최종 프롬프트 길이 = 5000+
```

**두 번째 메시지 이후 (sajuOrigin 생략):**
```
[ChatNotifier] isFirstMessage: false
[ChatNotifier] sajuOrigin 생략 (이후 메시지 - 대화 히스토리 참조)
[chat_provider.dart] _buildFullSystemPrompt: 최종 프롬프트 길이 = 3000
```

---

#### 📍 GPT 평생사주 분석 흐름 (별도)

```
┌─────────────────────────────────────────────────────────────────────────┐
│ [SajuAnalysisService] 평생 사주 분석 시작...                             │
│ [SajuAnalysisService] 평생 사주 분석 캐시 존재 - 스킵 (캐시 있으면)       │
│   OR                                                                     │
│ [AiApiService] OpenAI 호출: gpt-4o                                       │
│ [AiApiService] OpenAI 완료: prompt=XXX, completion=XXX                   │
│ [SajuAnalysisService] 백그라운드 분석 완료                               │
└─────────────────────────────────────────────────────────────────────────┘
```

---

#### 📍 일운 분석 흐름 (별도)

```
┌─────────────────────────────────────────────────────────────────────────┐
│ [SajuAnalysisService] 오늘의 운세 분석 시작...                           │
│ [SajuAnalysisService] 오늘의 운세 캐시 존재 - 스킵 (캐시 있으면)          │
│   OR                                                                     │
│ [AiApiService] Gemini 호출: gemini-2.0-flash                             │
│ [AiApiService] Gemini 완료: prompt=XXX, completion=XXX                   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 | 작성자 |
|------|------|-----------|--------|
| 2025-12-01 | 0.1 | 초안 작성 | - |
| 2025-12-30 | 2.0 | AIContext 제거, AiSummary.sajuOrigin 통합 | JH_AI |
| 2025-12-30 | 2.1 | 토큰 최적화: 첫 메시지에만 sajuOrigin 포함 | JH_AI |
| 2025-12-30 | 2.2 | 디버그 로그 가이드 전면 개편 (순차 흐름도, 파일 매핑, 에러 로그) | JH_AI |
