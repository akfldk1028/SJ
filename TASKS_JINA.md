# Jina's Task Log

이 파일은 Jina의 작업 내역과 현재 진행 중인 이슈를 추적합니다.

---

## 📅 2026년 01월 08일 

### ✅ 완료된 작업

1. '아기동자' 페르소나가 사주와 관계 없는 애매한 이야기로 대화를 진행하는 부분 수정 -> 모든 대화는 사주를 기반으로, 사용자가 디테일한 내용을 원할 경우 적극적으로 풀이.
2. 새 페르소나 scenario_writer.dart "송작가" 추가 -> 관계도 추가 이후 수정 예정 / 시나리오의 길이 추후 협의 후 수정필요
3. 새 페르소나 newbie_shaman.dart "장군 신내림받은 하꼬 무당" 추가 -> 구체적 내용 수정 예정
4. 새 페르소나 saeongjima.dart "새옹지마 할배" 추가 (긍정적 해석 중심으로 이야기 진행) -> 구체적 내용 수정 예정
5. 새 페르소나 detail_book.dart "명리의 서" 추가 (디테일한 정보를 원하는 사용자 타겟팅) -> 구체적 내용 수정 예정




### ✅ 완료된 작업 (2026년 01월 19일)

## 📊 [Semantic Intent Routing] 토큰 최적화 - AI Summary 필터링

### 🔍 문제점 (기존 방식)
```
사용자: "요즘 연애가 잘 안 풀리는데 이유가 뭘까?"

[기존] AI Summary를 거의 활용하지 않음
└─ sajuOrigin만 사용 (사주팔자, 오행, 용신 등 기본 정보)
└─ personality, love, career 등 GPT-5.2 상세 분석은 미사용
   (db의 ai_summaries.content에는 있지만 프롬프트에 안 넣음)

문제:
❌ 정확도 손실: GPT-5.2가 분석한 상세 정보 활용 못함
❌ 정보 부족: 연애운에 대한 구체적인 분석 결과 없음
❌ 일관성 부족: 매번 Gemini가 새로 해석 (GPT-5.2 분석 무시)
```

### ✨ 개선 방식 (Intent Routing + AI Summary 전체 활용)
```
사용자: "요즘 연애가 잘 안 풀리는데 이유가 뭘까?"
     ↓
[1단계] GPT-5.2 상세 분석 활용 시작
└─ personality (성격 분석)     ← GPT-5.2 분석 결과
└─ love (연애운 상세)          ← GPT-5.2 분석 결과
└─ marriage (결혼운)           ← GPT-5.2 분석 결과
└─ career, wealth, health...   ← GPT-5.2 분석 결과
     ↓
[2단계] Gemini Flash로 의도 분류 (1초)
     ↓
분류 결과: [LOVE] ← "연애에 대한 질문"
     ↓
[3단계] 필요한 섹션만 필터링
└─ saju_origin (기본)    ← 항상 포함
└─ wonGuk_analysis       ← 항상 포함
└─ love (연애)           ← ✅ 분류 결과만 포함
     ↓
결과:
✅ 정확도 향상: GPT-5.2 연애운 분석 활용
✅ 토큰 최적화: 750 토큰 (불필요한 섹션 제외)
✅ 응답 품질: 일관된 분석 기반 상담
```

---

### 📝 구현된 파일 (4개 + 1개 문서)

#### 1. **Intent Classifier Service** (신규)
📁 `frontend/lib/core/services/intent_classifier_service.dart`

```dart
// 사용자 질문 → 카테고리 분류
final result = await IntentClassifierService.classifyIntent(
  userMessage: "연애운이 궁금해요",
  chatHistory: recentMessages,
  userId: userId,  // v3.0: Quota 관리용
);
// result.categories: [SummaryCategory.love]
// result.reason: "연애에 대한 질문"
```

**역할** (v3.0 - Supabase Edge Function 통합):
- Supabase `ai-gemini` Edge Function 호출 (`action: "classify-intent"`)
- 서버에서 Gemini 1.5 Flash 실행 (API 키 보안 강화)
- 사용자 질문 + 최근 대화 3턴 전달
- userId 파라미터로 Quota 관리 자동화
- 카테고리 분류 결과 반환 (최대 3개)
- 토큰 사용량 DB 자동 기록
- 오류 시 자동 fallback (GENERAL)

---

#### 2. **AI Summary 필터링** (기존 파일 수정)
📁 `frontend/lib/core/services/ai_summary_service.dart`

**추가된 내용**:
```dart
// 1. 카테고리 enum (상단)
enum SummaryCategory {
  personality, love, marriage, career, 
  business, wealth, health, general
}

// 2. 분류 결과 클래스
class IntentClassificationResult {
  final List<SummaryCategory> categories;
  final String reason;
}

// 3. 필터링 클래스 (하단에 추가)
class FilteredAiSummary {
  final AiSummary original;
  final IntentClassificationResult classification;
  
  Map<String, dynamic> toFilteredJson() {
    // 필요한 섹션만 추출
  }
  
  int get estimatedTokenSavings {
    // 예상 토큰 절약률 계산
  }
}
```

**변경 위치**: 파일 상단 (line 10-50) + 하단 (line 1133-)

---

#### 3. **System Prompt Builder** (기존 파일 수정)
📁 `frontend/lib/features/saju_chat/data/services/system_prompt_builder.dart`

**변경 내용**:
```dart
// [변경 1] build 메서드 파라미터 추가 (line 41)
String build({
  AiSummary? aiSummary,
  IntentClassificationResult? intentClassification,  // ← 추가
  // ...
})

// [변경 2] AI Summary 추가 로직 (line 102-108)
if (isFirstMessage && aiSummary != null) {
  _addAiSummary(aiSummary, intentClassification);  // ← 추가
}

// [변경 3] 새 메서드 추가 (line 961-1009)
void _addAiSummary(
  AiSummary aiSummary,
  IntentClassificationResult? intentClassification,
) {
  if (intentClassification != null && !GENERAL) {
    // 필터링된 데이터만 포함
    final filtered = FilteredAiSummary(...);
    buffer.writeln(jsonEncode(filtered.toFilteredJson()));
  } else {
    // 전체 데이터 포함
    buffer.writeln(jsonEncode(aiSummary.toJson()));
  }
}
```

**추가 import**: `import 'dart:convert';` (line 1)

---

#### 4. **Chat Provider** (기존 파일 수정)
📁 `frontend/lib/features/saju_chat/presentation/providers/chat_provider.dart`

**변경 내용**:

```dart
// [변경 1] import 추가 (line 12)
import '../../../../core/services/intent_classifier_service.dart';

// [변경 2] sendMessage 메서드 내부 (line 674-720)
// 첫 메시지가 아닐 때만 Intent Classification 실행
IntentClassificationResult? intentClassification;
if (!isFirstMessageInSession && aiSummary != null) {
  print('🎯 INTENT CLASSIFICATION');
  
  // 최근 대화 3턴 추출
  final recentMessages = state.messages
      .skip(state.messages.length > 6 ? state.messages.length - 6 : 0)
      .map((m) => '${m.role.name}: ${m.content}')
      .toList();
  
  intentClassification = await IntentClassifierService.classifyIntent(
    userMessage: content,
    chatHistory: recentMessages,
  );
  
  print('📌 분류: ${intentClassification.categories.map((c) => c.korean).join(", ")}');
  print('💰 토큰 절약: ~${filtered.estimatedTokenSavings}%');
}

// [변경 3] _buildFullSystemPrompt 호출 (line 964-975)
final systemPrompt = _buildFullSystemPrompt(
  intentClassification: intentClassification,  // ← 추가
  // ...
);

// [변경 4] _buildFullSystemPrompt 메서드 시그니처 (line 489-514)
String _buildFullSystemPrompt({
  IntentClassificationResult? intentClassification,  // ← 추가
  // ...
})
```

---

### 🎯 주요 기능 & 개선 효과

| 항목 | 내용 |
|------|------|
| **정확도 향상** | ⭐ GPT-5.2 상세 분석 활용 (기존: 미활용) |
| **토큰 절약** | 70-85% 예상 (필요한 섹션만 포함) |
| **응답 품질** | 일관된 분석 기반 (기존: 매번 새로 해석) |
| **응답 속도** | 컨텍스트 길이 감소로 향상 |
| **분류 속도** | Gemini Flash 사용 (1초 이내) |
| **자동 Fallback** | 오류 시 GENERAL 반환 |
| **첫 메시지 예외** | 항상 전체 정보 포함 |
| **기본 정보** | saju_origin, wonGuk_analysis 항상 포함 |

### 📈 정확도가 중요한 이유

사주 상담은 **정확도가 생명**입니다:
- ✅ GPT-5.2가 분석한 연애운 → 구체적, 정확함
- ❌ Gemini가 매번 새로 해석 → 일관성 없음, 부정확

**예시**:
```
[GPT-5.2 분석] love 섹션
- attraction_style: "적극적이고 열정적인 구애"
- dating_pattern: "빠르게 진전되나 식는 것도 빠름"
- ideal_partner_traits: ["차분한 성격", "경제적 안정"]

→ 이 정확한 분석을 바탕으로 Gemini가 상담
→ 일관되고 정확한 답변 가능
```

---

### 🚀 배포 및 실행 방법

**v3.0: Supabase Edge Function 통합** (보안 강화!)
- ✅ API 키가 서버에만 존재 (클라이언트 노출 없음)
- ✅ Quota 관리 자동화
- ✅ 토큰 사용량 DB 자동 기록
- ✅ 일관된 아키텍처 (모든 Gemini 호출이 Edge Function 경유)

**배포 순서**:
```bash
# 1. Edge Function 배포 (최초 1회만)
# supabase/functions/ai-gemini/after.ts 내용을 index.ts로 복사
supabase functions deploy ai-gemini

# 2. Flutter 앱 실행
cd frontend
flutter pub get
flutter run

# 3. 테스트 (콘솔 로그 확인)
# - 채팅 시작
# - "요즘 연애가 잘 안 풀리는데 이유가 뭘까?" 입력
# - 콘솔 로그 확인:
#   🎯 INTENT CLASSIFICATION (v7.0)
#   📌 분류 결과: 연애
#   💰 토큰 절약 예상: ~85%
#   💡 이유: 연애에 대한 질문
```

**✅ 보안 개선**:
- API 키가 Supabase 서버 환경변수에만 존재
- 클라이언트에서는 Edge Function만 호출 (API 키 노출 없음)
- 모든 토큰 사용량이 DB에 자동 기록

---

### 📚 참고 문서

📄 **상세 README**: `frontend/lib/core/services/README_INTENT_ROUTING.md`
- 아키텍처 다이어그램
- 동작 예시
- 트러블슈팅
- 성능 지표

📄 **로그 예시**: `frontend/lib/core/services/LOG_EXAMPLES.md`
- 채팅 진행 시 로그 예시
- 카테고리별 로그 형식
- 문제 발생 시 확인 방법

---

### 💬 실제 사용 예시

**사용자**: "요즘 연애가 잘 안 풀리는데 이유가 뭘까?"

**로그 (콘솔)**:
```
🎯 INTENT CLASSIFICATION
   📌 분류: 연애
   💰 토큰 절약: ~85%

📋 AI SUMMARY 참조 정보
   🎯 참조 범위: 선택적 필터링
   📦 포함 섹션:
      - saju_origin ✅
      - wonGuk_analysis ✅  
      - 💕 연애 (LOVE) ✅
```

**결과**: 
- ✅ GPT-5.2 연애운 분석 활용 (정확도 ↑)
- ✅ 불필요한 섹션 제외 (토큰 85% ↓)
- ✅ 일관된 분석 기반 상담 (품질 ↑)

### ⚠️ 해결할 문제

1. 호칭 rule 수정 필요 -> 사용자 데이터에서 성별 확인 후 해당 성별에 따라 페르소나에게 호칭 절대적 룰로 픽스
2. 노잼이슈,,. 제미나이를 쓰는데 지피티만큼이나 재미가 없음 이거 어떤식으로 수정하면 좋을지 조언을 얻어봐야 할 듯
3. greeting 답변 길이 제한 (3줄?) 후 다음 채팅 제안 (무엇이 궁금한가요? 00? 00?)
4. 구체적 질문이 아닌 노가리 대화는 답변을 짧게 하도록 수정 
5. 3, 4는 chat_provider.dart > _buildFullSystemPrompt 메서드에서 전체 페르소나 절대 규칙으로 적용 예정
6. detail_book.dart 답변 길이 수정 (너무 긺)
7. 암튼 saeongjima.dart와 detail_book.dart는 거진 더미라고 생각해주면 될듯요 동현오빠 체크 후 방향성 확인 부탁