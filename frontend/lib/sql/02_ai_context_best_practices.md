# AI 컨텍스트 저장 베스트 프랙티스

> 만톡(Mantok) - Gemini AI와 사주 상담 시 토큰 최적화 및 컨텍스트 관리

---

## 1. 왜 컨텍스트 저장이 필요한가?

### 1.1 문제점

```
[사용자 A가 매번 대화할 때마다]
─────────────────────────────────
"저는 1990년 5월 15일생 여자입니다"    ← 매번 입력 필요
"제 사주에서 용신이 뭔가요?"
"지난번에 말씀하신 대운 설명해주세요"   ← AI가 기억 못함!
```

### 1.2 해결책: 컨텍스트 저장

```
[DB에 사주 분석 결과 저장]
─────────────────────────────
┌─────────────────────────────────────┐
│ saju_analyses 테이블                 │
│ ├── 만세력 (4주)                    │
│ ├── 오행 분포                       │
│ ├── 용신/희신/기신                   │
│ ├── 대운 리스트                     │
│ └── AI 요약 (ai_summary JSONB)       │
└─────────────────────────────────────┘
           ↓
[채팅 시작 시 자동 로드]
           ↓
"을목 일간이시고, 용신이 수(水)이시네요.
 지난번 말씀드린 대운에서..."           ← 연속성 있는 대화!
```

---

## 2. 현재 구현된 스키마 검토

### 2.1 saju_analyses 테이블 (사주 컨텍스트)

```sql
-- 핵심 JSONB 필드들 (토큰 절약용)
oheng_distribution  -- 오행 분포 {"mok":2, "hwa":1, ...}
yongsin            -- 용신/희신/기신
gyeokguk           -- 격국
daeun              -- 대운 리스트
ai_summary         -- Gemini가 생성한 요약 (★중요)
```

**✅ 베스트 프랙티스 적용됨**:
- 복잡한 사주 데이터를 JSONB로 저장
- 매번 재계산 없이 DB에서 로드
- `ai_summary`로 LLM이 생성한 요약 저장

### 2.2 chat_sessions 테이블 (대화 컨텍스트)

```sql
context_summary TEXT  -- 긴 대화 요약 (토큰 절약용)
```

**✅ 베스트 프랙티스 적용됨**:
- 긴 대화를 요약하여 저장
- 다음 세션에서 요약만 로드

---

## 3. 토큰 관리 베스트 프랙티스 (2025 기준)

### 3.1 메모리 관리 전략

> 참고: [LLM Chat History Summarization Guide](https://mem0.ai/blog/llm-chat-history-summarization-guide-2025)

| 전략 | 설명 | 토큰 절약 | 만톡 적용 |
|------|------|---------|----------|
| **Buffer Window** | 최근 K개 메시지만 유지 | 중간 | `getRecentMessages(limit: 20)` |
| **Summary Memory** | 과거 대화 요약 | 높음 | `context_summary` 필드 |
| **Hybrid** | 요약 + 최근 대화 | 최고 | ✅ 권장 방식 |

### 3.2 권장 구현 (Hybrid 방식)

```dart
/// AI 요청 시 컨텍스트 구성
Future<String> buildAiContext(String profileId, String sessionId) async {
  // 1. 사주 기본 정보 (DB에서 로드)
  final analysis = await sajuAnalysisRepo.getByProfileId(profileId);

  // 2. 과거 대화 요약 (DB에서 로드)
  final summary = await chatRepo.getContextSummary(sessionId);

  // 3. 최근 대화 (최근 10개만)
  final recentMessages = await chatRepo.getRecentMessages(sessionId, limit: 10);

  return '''
## 사용자 사주 정보
- 일간: ${analysis.chart.dayPillar.gan}
- 용신: ${analysis.yongsin.yongsin.korean}
- 격국: ${analysis.gyeokguk.name}

## 이전 대화 요약
$summary

## 최근 대화
${recentMessages.map((m) => "${m.role}: ${m.content}").join('\n')}
''';
}
```

### 3.3 토큰 절약 효과

| 방식 | 토큰 사용량 | 비용 (예상) |
|------|------------|-----------|
| 전체 대화 히스토리 전송 | ~10,000 tokens | 높음 |
| 요약 + 최근 10개 | ~2,000 tokens | **80% 절약** |

---

## 4. 컨텍스트 요약 타이밍

### 4.1 언제 요약을 생성할까?

> 참고: [OVHcloud - Chatbot Memory Management](https://blog.ovhcloud.com/chatbot-memory-management-with-langchain-and-ai-endpoints/)

```
[요약 트리거 조건]
───────────────────
1. 메시지 수 기준: message_count > 20
2. 토큰 수 기준: 누적 토큰 > 4000
3. 시간 기준: 1시간 이상 대화 지속
4. 세션 종료 시: 항상 요약 저장
```

### 4.2 요약 생성 프롬프트

```dart
const String summaryPrompt = '''
다음 대화 내용을 3-5문장으로 요약해주세요.
중요한 정보:
- 사용자가 물어본 주요 질문
- AI가 제공한 핵심 조언
- 사용자의 관심사/걱정거리

대화 내용:
{messages}
''';
```

### 4.3 구현 예시

```dart
/// 세션 요약 생성 및 저장
Future<void> summarizeAndSave(String sessionId) async {
  final messages = await chatRepo.getMessagesBySession(sessionId);

  if (messages.length < 20) return; // 짧은 대화는 요약 불필요

  // Gemini로 요약 생성
  final summary = await geminiService.summarize(messages);

  // DB에 저장
  await chatRepo.updateContextSummary(sessionId, summary);
}
```

---

## 5. 외부 저장소 분리 원칙

> 참고: [CustomGPT - Pass User Context](https://customgpt.ai/pass-user-context/)

### 5.1 핵심 원칙

```
┌─────────────────────────────────────────────────────┐
│  "LLM에게 모든 것을 보내지 마라"                      │
│                                                     │
│  ✅ 저장: Supabase DB (전체 사주 데이터)              │
│  ✅ 전송: 필요한 슬라이스만 (용신, 격국 요약)          │
│                                                     │
│  ❌ 안티패턴: 매번 전체 만세력 데이터 전송             │
└─────────────────────────────────────────────────────┘
```

### 5.2 데이터 분류

| 데이터 | 저장 위치 | LLM 전송 |
|--------|----------|----------|
| 생년월일, 성별 | saju_profiles | ❌ (민감정보) |
| 만세력 원본 | saju_analyses | ❌ (너무 큼) |
| 오행 분포 요약 | saju_analyses.oheng_distribution | ✅ 요약만 |
| 용신/희신 | saju_analyses.yongsin | ✅ |
| 격국 | saju_analyses.gyeokguk | ✅ |
| AI 요약 | saju_analyses.ai_summary | ✅ |
| 전체 대화 | chat_messages | ❌ |
| 대화 요약 | chat_sessions.context_summary | ✅ |

---

## 6. ai_summary 필드 활용

### 6.1 저장 구조

```json
{
  "personality": "을목 일간으로 부드럽고 유연한 성격",
  "strengths": "창의력이 뛰어나고 적응력이 좋음",
  "weaknesses": "우유부단할 수 있음",
  "career_advice": "예술, 교육, 상담 분야 적합",
  "relationship_style": "헌신적이나 의존적일 수 있음",
  "current_luck": "2025년은 목(木) 기운이 강해 발전의 해"
}
```

### 6.2 생성 시점

```dart
/// 사주 분석 완료 후 AI 요약 생성
Future<void> generateAiSummary(String profileId, SajuAnalysis analysis) async {
  final prompt = '''
다음 사주 분석 결과를 바탕으로 JSON 형태로 요약해주세요:
- personality: 성격 특성 (1-2문장)
- strengths: 강점 (1-2문장)
- weaknesses: 약점 (1-2문장)
- career_advice: 직업 조언 (1-2문장)
- relationship_style: 대인관계 스타일 (1-2문장)
- current_luck: 올해 운세 (1-2문장)

사주 데이터:
일간: ${analysis.chart.dayPillar.gan}
격국: ${analysis.gyeokguk.name}
용신: ${analysis.yongsin.yongsin.korean}
오행: 목${analysis.ohengDistribution.mok} 화${analysis.ohengDistribution.hwa} ...
''';

  final summary = await geminiService.generateJson(prompt);
  await sajuAnalysisRepo.updateAiSummary(profileId, summary);
}
```

---

## 7. 구현 체크리스트

### 7.1 완료된 항목

- [x] saju_analyses 테이블에 JSONB 필드 설계
- [x] ai_summary 필드 추가
- [x] chat_sessions.context_summary 필드 추가
- [x] SajuAnalysisRepository 구현
- [x] ChatRepository.getRecentMessages() 구현
- [x] ChatRepository.updateContextSummary() 구현

### 7.2 TODO 항목

- [ ] 채팅 시작 시 사주 컨텍스트 자동 로드
- [ ] Gemini 프롬프트에 컨텍스트 주입
- [ ] 세션 종료 시 자동 요약 생성
- [ ] ai_summary 생성 로직 구현

---

## 8. 참고 자료

### 8.1 토큰 관리

- [LLM Chat History Summarization Guide 2025](https://mem0.ai/blog/llm-chat-history-summarization-guide-2025)
- [How Token Limits Impact GPT Chatbot Performance](https://www.softude.com/blog/how-token-limits-affect-chatbot-performance/)
- [Managing Context in Conversation Bot](https://community.openai.com/t/managing-context-in-a-conversation-bot-with-fixed-token-limits/1093181)

### 8.2 메모리 관리

- [Chatbot Memory Management with LangChain](https://blog.ovhcloud.com/chatbot-memory-management-with-langchain-and-ai-endpoints/)
- [AI Chatbot Memory Techniques](https://www.softude.com/blog/ai-chatbot-memory-management-techniques/)

### 8.3 컨텍스트 전달

- [Pass User Context Into Chatbots](https://customgpt.ai/pass-user-context/)

---

## 9. 결론

### 현재 구현 평가

| 항목 | 상태 | 설명 |
|------|------|------|
| 스키마 설계 | ✅ 정석 | JSONB 활용, 요약 필드 분리 |
| 토큰 절약 | ✅ 정석 | context_summary로 요약 저장 |
| 외부 저장소 분리 | ✅ 정석 | DB에 저장, 필요한 것만 전송 |
| 메시지 윈도우 | ✅ 정석 | getRecentMessages(limit) |
| AI 요약 생성 | ⏳ 구현 필요 | ai_summary 필드 활용 |

> **결론: 현재 스키마와 Repository 설계는 2025 베스트 프랙티스를 따르고 있습니다.**
> 남은 작업은 실제 Gemini 연동 시 컨텍스트 주입 로직 구현입니다.
