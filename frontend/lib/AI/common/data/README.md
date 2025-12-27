# AI Common Data Layer

> 작성: 2024-12-26
> 담당: DK (공통), JH_AI (분석), Jina (대화)

---

## 개요

AI 팀원이 사주 분석/대화에 필요한 데이터에 쉽게 접근할 수 있도록 설계된 모듈입니다.

**기존 방식 (비권장)**
```dart
// 각각 따로 조회
final profile = await profileQueries.getById(id);
final analysis = await sajuAnalysisQueries.getByProfileId(id);
final messages = await chatMessageQueries.getForAiContext(sessionId);
```

**새로운 방식 (권장)**
```dart
import 'package:saju_app/AI/common/data/data.dart';

// 한 번에 모든 데이터 접근
final context = await ref.watch(aiContextProvider.future);
final prompt = context.basicInfoForPrompt;  // 프롬프트용 정보
```

---

## 파일 구조

```
AI/common/data/
├── ai_context.dart       # AIContext 클래스 (데이터 컨테이너)
├── ai_data_provider.dart # Riverpod Provider
├── data.dart             # Barrel export
└── README.md             # 이 파일
```

---

## AIContext 구조

```dart
class AIContext {
  final SajuProfileModel profile;      // 프로필
  final SajuAnalysisDbModel analysis;  // 사주 분석
  final List<ChatMessageModel>? recentMessages;  // 최근 대화
  final String? currentSessionId;      // 현재 세션
  final Map<String, dynamic>? metadata;  // 추가 데이터
}
```

### 주요 Getter

| Getter | 설명 | 예시 |
|--------|------|------|
| `profileId` | 프로필 ID | `abc-123` |
| `displayName` | 표시 이름 | `홍길동` |
| `gender` | 성별 | `male` / `female` |
| `sajuPalza` | 사주팔자 | `갑자 을축 병인 정묘` |
| `dayGan` | 일간 | `병` |
| `isSingang` | 신강 여부 | `true` / `false` |
| `yongsinOheng` | 용신 오행 | `수(水)` |
| `basicInfoForPrompt` | 프롬프트용 기본 정보 | (문자열) |
| `detailedInfoForPrompt` | 프롬프트용 상세 정보 | (문자열) |

---

## Provider 사용법

### 1. 기본 사용 (자동 활성 프로필)

```dart
@riverpod
class MyAiService extends _$MyAiService {
  @override
  Future<void> build() async {
    final context = await ref.watch(aiContextProvider.future);
    if (context == null) {
      // 프로필/분석 데이터 없음
      return;
    }

    // 사주 정보 사용
    print(context.sajuPalza);
    print(context.yongsinOheng);
  }
}
```

### 2. 특정 프로필로 로드

```dart
// 특정 프로필 ID로 조회
final context = await ref.watch(aiContextBasicProvider(profileId).future);
```

### 3. 대화 세션 포함

```dart
// 프로필 + 최근 대화 포함
final context = await ref.watch(
  aiContextWithChatProvider(profileId, sessionId).future,
);

// 최근 대화 확인
final summary = context.conversationSummary;
```

### 4. 개별 데이터 조회

```dart
// 오행만 필요할 때
final oheng = await ref.watch(aiOhengProvider(profileId).future);

// 용신만 필요할 때
final yongsin = await ref.watch(aiYongsinProvider(profileId).future);

// 대운만 필요할 때
final daeun = await ref.watch(aiDaeunProvider(profileId).future);
```

---

## JH_AI (GPT-5.2 분석) 사용 예시

```dart
// lib/AI/jh/services/gpt_analysis_service.dart

import 'package:saju_app/AI/common/data/data.dart';

class GptAnalysisService {
  final Ref ref;

  Future<String> analyzeFortuneToday(String profileId) async {
    // 컨텍스트 로드
    final context = await ref.read(aiContextBasicProvider(profileId).future);
    if (context == null) throw Exception('데이터 없음');

    // GPT 프롬프트 생성
    final prompt = '''
당신은 전문 사주 분석가입니다.

## 분석 대상
${context.basicInfoForPrompt}

## 요청
오늘의 운세를 분석해주세요.
''';

    // GPT-5.2 호출
    return await gptProvider.analyze(prompt);
  }
}
```

---

## Jina (Gemini 3.0 대화) 사용 예시

```dart
// lib/AI/jina/services/gemini_chat_service.dart

import 'package:saju_app/AI/common/data/data.dart';

class GeminiChatService {
  final Ref ref;

  Stream<String> chat(
    String profileId,
    String sessionId,
    String userMessage,
  ) async* {
    // 대화 포함 컨텍스트 로드
    final context = await ref.read(
      aiContextWithChatProvider(profileId, sessionId).future,
    );
    if (context == null) throw Exception('데이터 없음');

    // 시스템 프롬프트
    final systemPrompt = '''
당신은 친근한 사주 상담사입니다.

## 상담 대상
${context.basicInfoForPrompt}

## 이전 대화
${context.conversationSummary}

재미있고 친근하게 대화해주세요.
''';

    // Gemini 3.0 스트리밍 호출
    yield* geminiProvider.chatStream(systemPrompt, userMessage);
  }
}
```

---

## 새로고침

```dart
// 컨텍스트 새로고침
ref.invalidate(aiContextProvider);

// 또는 메서드 호출
await ref.read(aiContextProvider.notifier).refresh();
```

---

## 관련 파일

- `features/profile/data/queries.dart` - 프로필 조회
- `features/saju_chart/data/queries.dart` - 사주 분석 조회
- `features/saju_chat/data/queries.dart` - 대화 조회
- `AI/jh/` - JH_AI GPT-5.2 모듈
- `AI/jina/` - Jina Gemini 3.0 모듈
