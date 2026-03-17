# AI 채팅 다국어 대응 가이드

> AI가 사용자 언어에 맞게 응답하려면 어떤 파일을 어떻게 바꿔야 하는지 정리
>
> 현재 상태: persona_base.dart에 "사용자 언어로 응답하라"는 지시만 있고,
> 시스템 프롬프트 자체는 전부 한국어. locale 파라미터도 채팅 파이프라인에 없음.
>
> 운세 분석(GPT-5.2)은 이미 ko/ja/en 3벌 대응 완료.
> **실시간 채팅(Gemini)만 미대응** — 이 문서는 채팅 파이프라인만 다룸.

---

## 수정 1: 베이스 프롬프트 MD 4종 — "한국어" 하드코딩 제거

### 1-1. `frontend/assets/prompts/general.md` (8행)

**before:**
```
2. 한국어로 대답합니다
```

**after:**
```
2. 사용자가 보낸 언어로 대답합니다 (한국어 메시지 → 한국어, 영어 메시지 → 영어, 일본어 메시지 → 일본어)
```

### 1-2. `frontend/assets/prompts/daily_fortune.md` (8행)

**before:**
```
2. 한국어로 대답합니다
```

**after:**
```
2. 사용자가 보낸 언어로 대답합니다
```

### 1-3. `frontend/assets/prompts/saju_analysis.md` (9행)

**before:**
```
- 한국어로 대답하고, 전문적이면서도 이해하기 쉽게 설명합니다
```

**after:**
```
- 사용자가 보낸 언어로 대답하고, 전문적이면서도 이해하기 쉽게 설명합니다
```

### 1-4. `frontend/assets/prompts/compatibility.md` (10행)

**before:**
```
- 한국어로 대답합니다.
```

**after:**
```
- 사용자가 보낸 언어로 대답합니다.
```

---

## 수정 2: SystemPromptBuilder — locale 파라미터 추가

**파일**: `frontend/lib/features/saju_chat/data/services/system_prompt_builder.dart`

### 2-1. build() 시그니처에 locale 추가 (45~59행)

**before:**
```dart
  String build({
    required String basePrompt,
    AiSummary? aiSummary,
    IntentClassificationResult? intentClassification,
    SajuAnalysis? sajuAnalysis,
    SajuProfile? profile,
    String? personaPrompt,
    bool isFirstMessage = true,
    SajuProfile? targetProfile,
    SajuAnalysis? targetSajuAnalysis,
    CompatibilityAnalysis? compatibilityAnalysis,
    bool isThirdPartyCompatibility = false,
    String? relationType,
    List<({SajuProfile profile, SajuAnalysis? sajuAnalysis})>? additionalParticipants,
  }) {
```

**after:**
```dart
  String build({
    required String basePrompt,
    AiSummary? aiSummary,
    IntentClassificationResult? intentClassification,
    SajuAnalysis? sajuAnalysis,
    SajuProfile? profile,
    String? personaPrompt,
    bool isFirstMessage = true,
    SajuProfile? targetProfile,
    SajuAnalysis? targetSajuAnalysis,
    CompatibilityAnalysis? compatibilityAnalysis,
    bool isThirdPartyCompatibility = false,
    String? relationType,
    List<({SajuProfile profile, SajuAnalysis? sajuAnalysis})>? additionalParticipants,
    String locale = 'ko',  // v13.0: 다국어 채팅 지원
  }) {
```

### 2-2. _addClosingInstructions() 시그니처 + locale 지시 추가 (510~534행)

**before:**
```dart
  void _addClosingInstructions({bool isCompatibilityMode = false, int totalParticipants = 2}) {
    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();
    // ... 기존 코드 ...
    _buffer.writeln();
    _buffer.writeln('**현재 연도: ${DateTime.now().year}년. 반드시 이 연도를 기준으로 답변하세요.**');
  }
```

**after:**
```dart
  void _addClosingInstructions({bool isCompatibilityMode = false, int totalParticipants = 2, String locale = 'ko'}) {
    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();
    // ... 기존 코드 그대로 유지 ...
    _buffer.writeln();
    _buffer.writeln('**현재 연도: ${DateTime.now().year}년. 반드시 이 연도를 기준으로 답변하세요.**');

    // v13.0: 다국어 지시
    if (locale != 'ko') {
      _buffer.writeln();
      _buffer.writeln('**LANGUAGE INSTRUCTION: The saju data and system instructions above are in Korean, but you MUST respond in the user\'s language.**');
      _buffer.writeln('**Translate all saju terminology into easy, natural expressions in the target language.**');
      _buffer.writeln('**[SUGGESTED_QUESTIONS] must also be written in the user\'s language.**');
    }
  }
```

### 2-3. build() 안에서 _addClosingInstructions 호출부 수정 (152~158행)

**before:**
```dart
    _addClosingInstructions(
      isCompatibilityMode: isCompatibilityMode,
      totalParticipants: totalParticipants,
    );
```

**after:**
```dart
    _addClosingInstructions(
      isCompatibilityMode: isCompatibilityMode,
      totalParticipants: totalParticipants,
      locale: locale,
    );
```

---

## 수정 3: chat_provider.dart — locale 전달

**파일**: `frontend/lib/features/saju_chat/presentation/providers/chat_provider.dart`

### 3-1. _buildFullSystemPrompt() 시그니처에 locale 추가 (531~545행)

**before:**
```dart
  String _buildFullSystemPrompt({
    required String basePrompt,
    AiSummary? aiSummary,
    IntentClassificationResult? intentClassification,
    SajuAnalysis? sajuAnalysis,
    SajuProfile? profile,
    String? personaPrompt,
    bool isFirstMessage = true,
    SajuProfile? targetProfile,
    SajuAnalysis? targetSajuAnalysis,
    Map<String, dynamic>? compatibilityAnalysis,
    bool isThirdPartyCompatibility = false,
    String? relationType,
    List<({SajuProfile profile, SajuAnalysis? sajuAnalysis})>? additionalParticipants,
  }) {
    final builder = SystemPromptBuilder();
    return builder.build(
      basePrompt: basePrompt,
      // ... 기존 파라미터들 ...
    );
  }
```

**after:**
```dart
  String _buildFullSystemPrompt({
    required String basePrompt,
    AiSummary? aiSummary,
    IntentClassificationResult? intentClassification,
    SajuAnalysis? sajuAnalysis,
    SajuProfile? profile,
    String? personaPrompt,
    bool isFirstMessage = true,
    SajuProfile? targetProfile,
    SajuAnalysis? targetSajuAnalysis,
    Map<String, dynamic>? compatibilityAnalysis,
    bool isThirdPartyCompatibility = false,
    String? relationType,
    List<({SajuProfile profile, SajuAnalysis? sajuAnalysis})>? additionalParticipants,
    String locale = 'ko',  // v13.0: 다국어
  }) {
    final builder = SystemPromptBuilder();
    return builder.build(
      basePrompt: basePrompt,
      // ... 기존 파라미터들 그대로 ...
      locale: locale,  // v13.0: 다국어 전달
    );
  }
```

### 3-2. sendMessage() 안에서 _buildFullSystemPrompt 호출부에 locale 추가 (923~937행)

호출 직전에 locale을 가져오고, 파라미터에 추가:

**before:**
```dart
      final systemPrompt = _buildFullSystemPrompt(
        basePrompt: basePrompt,
        aiSummary: aiSummary,
        intentClassification: intentClassification,
        sajuAnalysis: sajuAnalysis,
        profile: activeProfile,
        personaPrompt: currentPersonaPrompt,
        isFirstMessage: shouldLoadSaju,
        targetProfile: targetProfile,
        targetSajuAnalysis: targetSajuAnalysis,
        compatibilityAnalysis: compatibilityAnalysis,
        isThirdPartyCompatibility: isThirdPartyCompatibility,
        relationType: isCompatibilityMode ? relationType : null,
        additionalParticipants: additionalParticipants.isNotEmpty ? additionalParticipants : null,
      );
```

**after:**
```dart
      // v13.0: 현재 앱 언어 가져오기
      final locale = WidgetsBinding.instance.platformDispatcher.locale.languageCode;

      final systemPrompt = _buildFullSystemPrompt(
        basePrompt: basePrompt,
        aiSummary: aiSummary,
        intentClassification: intentClassification,
        sajuAnalysis: sajuAnalysis,
        profile: activeProfile,
        personaPrompt: currentPersonaPrompt,
        isFirstMessage: shouldLoadSaju,
        targetProfile: targetProfile,
        targetSajuAnalysis: targetSajuAnalysis,
        compatibilityAnalysis: compatibilityAnalysis,
        isThirdPartyCompatibility: isThirdPartyCompatibility,
        relationType: isCompatibilityMode ? relationType : null,
        additionalParticipants: additionalParticipants.isNotEmpty ? additionalParticipants : null,
        locale: locale,  // v13.0: 다국어
      );
```

> `WidgetsBinding.instance.platformDispatcher.locale.languageCode`는 import 없이 사용 가능.
> Flutter의 `package:flutter/widgets.dart`에 포함되어 있으며 chat_provider.dart에서 이미 import됨.
> 앱 설정에서 언어를 별도 관리한다면 해당 provider로 교체할 것.

---

## 수정 4 (선택): session_restore_service.dart — 세션 복원 시에도 locale 전달

**파일**: `frontend/lib/features/saju_chat/data/services/session_restore_service.dart`

세션 복원 시에도 동일하게 `SystemPromptBuilder.build()`를 호출하므로 locale 전달 필요.
`session_restore_service.dart` 안에서 `builder.build(...)` 호출하는 곳에 `locale:` 파라미터 추가.

---

## 수정하지 않아도 되는 파일

| 파일 | 이유 |
|------|------|
| `persona_base.dart` (401~412행) | 이미 다국어 규칙 있음. 수정 1~3으로 충분 |
| 페르소나 13종 (`*.dart`) | Gemini가 페르소나 톤을 자동 변환. Phase 1에서는 불필요 |
| 운세 프롬프트 (`fortune/*.dart`) | 이미 ko/ja/en 3벌 대응 완료 |
| `prompt_loader.dart` | 변경 불필요 (MD 파일 내용만 바꾸면 됨) |

---

## 전체 요약: 수정 파일 4개 + 선택 1개

| # | 파일 | 수정 내용 | 난이도 |
|---|------|----------|:---:|
| 1 | `assets/prompts/general.md` | 8행: "한국어로" → "사용자가 보낸 언어로" | 낮음 |
| 2 | `assets/prompts/daily_fortune.md` | 8행: 동일 | 낮음 |
| 3 | `assets/prompts/saju_analysis.md` | 9행: 동일 | 낮음 |
| 4 | `assets/prompts/compatibility.md` | 10행: 동일 | 낮음 |
| 5 | `system_prompt_builder.dart` | build()에 `locale` 파라미터 추가 + `_addClosingInstructions()`에 영어 지시 추가 | 중간 |
| 6 | `chat_provider.dart` | `_buildFullSystemPrompt()`에 `locale` 파라미터 추가 + 호출부에 `locale: locale` 전달 | 중간 |
| 7 | `session_restore_service.dart` (선택) | 세션 복원 시 locale 전달 | 낮음 |

---

## 참고: 운세 파이프라인 (이미 대응 완료)

```
lib/AI/fortune/daily/daily_prompt.dart             ← ko/ja/en 3벌 완료
lib/AI/fortune/yearly_2026/yearly_2026_prompt.dart ← ko/ja/en 3벌 완료
lib/AI/fortune/monthly/monthly_prompt.dart         ← locale 있음
lib/AI/fortune/lifetime/lifetime_*.dart            ← locale 있음
```
