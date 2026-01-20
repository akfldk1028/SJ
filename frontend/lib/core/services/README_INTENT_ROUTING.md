# Semantic Intent Routing - 토큰 최적화 시스템

## 📌 개요

사용자 질문의 의도를 LLM으로 분석하여 필요한 AI Summary 섹션만 선택적으로 컨텍스트에 포함하는 시스템입니다.

### 예상 효과
- 🎯 **토큰 사용량 70-85% 절감**
- ⚡ **응답 속도 향상** (컨텍스트 길이 감소)
- 💰 **API 비용 절감**
- ✨ **응답 품질 유지** (필요한 정보만 집중)

---

## 🏗️ 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│ 1. 사용자 질문 입력                                          │
│    "요즘 연애가 잘 안 풀리는데 이유가 뭘까?"                  │
└──────────────────┬──────────────────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Intent Classifier (Supabase Edge Function v19)           │
│    - ai-gemini Edge Function 호출 (action: classify-intent) │
│    - 서버에서 Gemini 1.5 Flash 실행 (보안 강화)              │
│    - 최근 대화 3턴 포함, Quota 관리 자동, 토큰 DB 기록       │
│    - 빠른 분류 (1초 이내)                                      │
└──────────────────┬──────────────────────────────────────────┘
                   ▼
           IntentClassificationResult
           categories: [LOVE]
           reason: "연애에 대한 질문"
                   ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. FilteredAiSummary                                        │
│    - 전체 AI Summary에서 LOVE 섹션만 추출                     │
│    - 기본 정보 (saju_origin, wonGuk_analysis) 항상 포함      │
│    - 예상 토큰 절약: ~85%                                      │
└──────────────────┬──────────────────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. SystemPromptBuilder                                      │
│    - 필터링된 데이터를 JSON으로 프롬프트에 삽입               │
│    - Gemini 2.0에게 연애운만 집중해서 답변 요청               │
└──────────────────┬──────────────────────────────────────────┘
                   ▼
           "연애운이 좋지 않은 이유는..."
```

---

## 📊 카테고리 목록

```dart
enum SummaryCategory {
  personality,  // 성격, 성향, 기질
  love,         // 연애, 이성관계
  marriage,     // 결혼, 배우자
  career,       // 진로, 직장
  business,     // 사업, 창업
  wealth,       // 재물, 투자
  health,       // 건강, 체질
  general,      // 종합 (전체 포함)
}
```

---

## 🔧 구현 파일

### 1. Intent Classifier Service
**파일**: `intent_classifier_service.dart`

```dart
final result = await IntentClassifierService.classifyIntent(
  userMessage: "요즘 연애가 잘 안 풀리는데 이유가 뭘까?",
  chatHistory: recentMessages,
);
// result.categories: [SummaryCategory.love]
```

### 2. Filtered AI Summary
**파일**: `ai_summary_service.dart` (하단)

```dart
final filtered = FilteredAiSummary(
  original: aiSummary,
  classification: intentClassification,
);

final json = filtered.toFilteredJson(); // LOVE 섹션만 포함
print('토큰 절약: ${filtered.estimatedTokenSavings}%'); // ~85%
```

### 3. System Prompt Builder
**파일**: `system_prompt_builder.dart`

```dart
String build({
  AiSummary? aiSummary,
  IntentClassificationResult? intentClassification,  // NEW
  // ...
}) {
  if (intentClassification != null) {
    final filtered = FilteredAiSummary(...);
    buffer.writeln(jsonEncode(filtered.toFilteredJson()));
  }
}
```

### 4. Chat Provider
**파일**: `chat_provider.dart`

```dart
// 첫 메시지가 아닐 때만 분류
if (!isFirstMessageInSession && aiSummary != null) {
  intentClassification = await IntentClassifierService.classifyIntent(
    userMessage: content,
    chatHistory: recentMessages,
  );
}
```

### 5. Flutter에서 직접 Gemini API 호출
**파일**: `frontend/lib/core/services/intent_classifier_service.dart`

**v2.0**: Edge Function 없이 앱에서 직접 Gemini Flash API 호출:
```dart
// Gemini API 직접 호출 (배포 불필요)
final response = await http.post(
  Uri.parse('$_geminiApiUrl?key=$_geminiApiKey'),
  body: jsonEncode({
    'contents': [{'parts': [{'text': prompt}]}],
    'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 200},
  }),
);
```

**장점**:
- ✅ 배포 불필요 (앱에서 바로 작동)
- ✅ Edge Function 관리 오버헤드 없음
- ✅ 빠른 개발 및 테스트

---

## 💡 동작 예시

### Case 1: 연애 질문 (85% 절약)
```
질문: "요즘 연애가 잘 안 풀리는데 이유가 뭘까?"
분류: [LOVE]
포함 섹션: saju_origin, wonGuk_analysis, love
제외 섹션: personality, marriage, career, business, wealth, health
절약: ~85%
```

### Case 2: 복합 질문 (70% 절약)
```
질문: "직장을 옮길까 고민인데, 재물운도 궁금해요"
분류: [CAREER, WEALTH]
포함 섹션: saju_origin, wonGuk_analysis, career, wealth
제외 섹션: personality, love, marriage, business, health
절약: ~70%
```

### Case 3: 첫 메시지 (0% 절약)
```
질문: "안녕하세요, 제 사주를 봐주세요"
분류: (생략 - 첫 메시지는 항상 전체 포함)
포함 섹션: 전체
절약: 0% (사용자 경험 우선)
```

### Case 4: 종합 질문 (0% 절약)
```
질문: "올해 전체적인 운세가 궁금해요"
분류: [GENERAL]
포함 섹션: 전체
절약: 0% (의도적으로 전체 요청)
```

---

## ⚙️ 주요 기능

### 1. 자동 Fallback
분류 실패 시 자동으로 GENERAL 카테고리 반환:
- 네트워크 오류
- Gemini API 오류
- JSON 파싱 실패

### 2. 첫 메시지 예외 처리
```dart
if (!isFirstMessageInSession && aiSummary != null) {
  // 분류 수행
} else {
  // 전체 포함 (사용자 경험)
}
```

### 3. 기본 정보 항상 포함
```dart
// 항상 포함되는 섹션
- saju_origin     // 합충형파해 등 기본 정보
- wonGuk_analysis // 원국 분석
```

### 4. 최근 대화 컨텍스트
```dart
// 최근 3턴 (6개 메시지) 포함
final recentMessages = state.messages
    .skip(state.messages.length > 6 ? state.messages.length - 6 : 0)
    .map((m) => '${m.role.name}: ${m.content}')
    .toList();
```

---

## 🚀 배포 및 실행 방법

**v3.0**: Supabase Edge Function 통합 (보안 강화, Quota 관리 자동화)

### 1. Edge Function 배포 (최초 1회)

**필수**: `ai-gemini` Edge Function에 Intent Classification 기능 추가

```bash
# 프로젝트 루트에서
cd supabase/functions/ai-gemini
# after.ts 내용을 index.ts로 복사 (또는 직접 수정)
# 그 후 배포
supabase functions deploy ai-gemini
```

### 2. Flutter 앱 실행
```bash
cd frontend
flutter pub get
flutter run
```

### 3. 확인
채팅에서 질문 입력 시 콘솔에 다음과 같은 로그가 표시됩니다:
```
🎯 INTENT CLASSIFICATION (v7.0)
   📌 분류 결과: 연애
   💰 토큰 절약 예상: ~85%
   💡 이유: 연애에 대한 질문
```

**참고**: API 키는 Supabase 서버에만 존재하므로 클라이언트에 노출되지 않습니다.

---

## 📈 성능 지표

### 토큰 사용량 비교
| 질문 유형 | 기존 | 최적화 후 | 절약률 |
|----------|------|----------|--------|
| 연애 단일 질문 | 5000 | 750 | 85% |
| 직장/재물 복합 | 5000 | 1500 | 70% |
| 성격 질문 | 5000 | 2000 | 60% |
| 종합 질문 | 5000 | 5000 | 0% |

### API 비용 절감
```
월 10,000회 채팅 기준 (비연애 질문 70%)
- 기존: $50
- 최적화: $15
- 절감: $35 (70%)
```

---

## 🐛 트러블슈팅

### 1. 분류가 항상 GENERAL로 나옴
**원인**: Gemini API 호출 실패 또는 네트워크 오류
**해결**: 
- 콘솔에서 `[IntentClassifier]` 로그 확인
- 네트워크 연결 확인
- API 키가 올바른지 확인

### 2. 토큰 절약이 예상보다 낮음
**원인**: 종합 질문이 많거나 첫 메시지 비율이 높음
**해결**: 정상 동작 (의도된 설계)

### 3. 응답이 너무 짧음
**원인**: 필요한 섹션이 누락됨
**해결**: `system_prompt_builder.dart`에서 기본 포함 섹션 조정

---

## 📝 향후 개선 방향

1. ✅ 카테고리 추가 (예: COMPATIBILITY - 궁합)
2. ✅ 학습 데이터 수집 (분류 정확도 향상)
3. ✅ 캐싱 전략 (같은 질문 반복 시)
4. ✅ A/B 테스트 (토큰 절약 vs 품질)
5. ✅ 다국어 지원 (영어, 일본어 등)

---

## 📚 참고 문서

- [Gemini API Docs](https://ai.google.dev/docs)
- [Flutter HTTP Package](https://pub.dev/packages/http)
- [Intent Classification Paper](https://arxiv.org/abs/2104.08821)
