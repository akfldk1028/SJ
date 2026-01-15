# 대화형 광고 시스템 설계서

> **버전**: v1.0
> **작성일**: 2026-01-15
> **작성자**: DK

---

## 1. 개요

### 1.1 목표
토큰 소진 시 AI 페르소나가 **자연스럽게 광고를 추천**하는 대화형 광고 시스템

### 1.2 핵심 개념
```
일반 대화 → 토큰 소진 감지 → AI 페르소나 광고 전환 → Native Ad 표시
```

### 1.3 기대 효과
| 지표 | 현재 (Native Ad) | 목표 (Conversational Ad) |
|------|-----------------|------------------------|
| eCPM | $3~15 | $10~50+ |
| 클릭률 | 0.5~1% | 3~5% |
| 사용자 거부감 | 중간 | 낮음 |

---

## 2. 아키텍처

### 2.1 레이어 구조 (MVVM + Feature-First)

```
saju_chat/
├── data/
│   ├── models/
│   │   └── conversational_ad_model.dart      # 광고 메시지 모델
│   ├── datasources/
│   │   └── ad_prompt_datasource.dart         # 광고 프롬프트 데이터소스
│   └── services/
│       └── ad_trigger_service.dart           # 광고 트리거 서비스
│
├── domain/
│   ├── entities/
│   │   └── ad_chat_message.dart              # 광고 메시지 엔티티
│   └── models/
│       └── ad_persona_prompt.dart            # 광고 페르소나 프롬프트
│
└── presentation/
    ├── providers/
    │   └── conversational_ad_provider.dart   # 광고 상태 관리
    └── widgets/
        ├── ad_transition_bubble.dart         # 전환 문구 버블
        └── persona_ad_bubble.dart            # 페르소나 광고 버블
```

### 2.2 상태 흐름

```
┌─────────────────────────────────────────────────────────────────┐
│                        ChatProvider                              │
├─────────────────────────────────────────────────────────────────┤
│  tokenUsage: TokenUsageInfo                                      │
│  ├── usedTokens: int                                            │
│  ├── maxTokens: int                                             │
│  └── isNearLimit: bool (>80%)  ←─── 광고 트리거 포인트          │
│                                                                  │
│  messages: List<ChatMessage>                                     │
│  └── 마지막 메시지에 AdChatMessage 삽입                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  ConversationalAdProvider                        │
├─────────────────────────────────────────────────────────────────┤
│  adState: ConversationalAdState                                  │
│  ├── isAdMode: bool                                             │
│  ├── transitionText: String (페르소나 전환 문구)                 │
│  ├── currentAd: NativeAd?                                       │
│  └── adPersonaPrompt: String                                    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. 데이터 모델

### 3.1 AdChatMessage (광고 메시지 엔티티)

```dart
/// 광고 채팅 메시지
///
/// 일반 ChatMessage를 확장하여 광고 정보 포함
class AdChatMessage extends ChatMessage {
  /// 광고 유형
  final AdMessageType adType;

  /// 페르소나 전환 텍스트 (AI가 생성)
  final String? transitionText;

  /// 광고 후 CTA 텍스트
  final String? ctaText;

  /// 보상형 광고 시 제공되는 토큰 수
  final int? rewardTokens;

  const AdChatMessage({
    required super.id,
    required super.sessionId,
    required super.content,
    required super.role,
    required super.createdAt,
    required this.adType,
    this.transitionText,
    this.ctaText,
    this.rewardTokens,
  });
}

/// 광고 메시지 유형
enum AdMessageType {
  /// 토큰 소진 시 자연스러운 광고 전환
  tokenDepletion,

  /// N개 메시지 후 인라인 광고
  inlineInterval,

  /// 보상형 광고 (토큰 충전)
  rewarded,

  /// 프리미엄 기능 해제용
  premiumUnlock,
}
```

### 3.2 ConversationalAdState

```dart
/// 대화형 광고 상태
class ConversationalAdState {
  /// 광고 모드 활성화 여부
  final bool isAdMode;

  /// 현재 토큰 사용률 (0.0 ~ 1.0)
  final double tokenUsageRate;

  /// 페르소나 전환 문구 (AI 생성)
  final String? transitionText;

  /// 로드된 Native Ad
  final NativeAd? nativeAd;

  /// 광고 시청 완료 여부
  final bool adWatched;

  /// 보상 토큰 (시청 완료 시)
  final int? rewardedTokens;

  const ConversationalAdState({
    this.isAdMode = false,
    this.tokenUsageRate = 0.0,
    this.transitionText,
    this.nativeAd,
    this.adWatched = false,
    this.rewardedTokens,
  });
}
```

---

## 4. 광고 트리거 로직

### 4.1 트리거 조건

```dart
/// 광고 트리거 서비스
class AdTriggerService {
  /// 토큰 기반 트리거 (메인)
  static AdTriggerResult checkTokenTrigger({
    required TokenUsageInfo tokenUsage,
    required int messageCount,
  }) {
    // 1. 토큰 80% 이상 사용 시
    if (tokenUsage.usageRate >= 0.8) {
      return AdTriggerResult.tokenDepletion;
    }

    // 2. 토큰 100% 소진 시 (필수)
    if (tokenUsage.usageRate >= 1.0) {
      return AdTriggerResult.tokenDepleted;
    }

    return AdTriggerResult.none;
  }

  /// 메시지 간격 트리거 (기존 유지)
  static AdTriggerResult checkIntervalTrigger({
    required int messageCount,
  }) {
    if (messageCount >= AdStrategy.inlineAdMinMessages &&
        messageCount % AdStrategy.inlineAdMessageInterval == 0) {
      return AdTriggerResult.intervalAd;
    }
    return AdTriggerResult.none;
  }
}
```

### 4.2 트리거 결과

```dart
enum AdTriggerResult {
  /// 트리거 없음
  none,

  /// 토큰 80% 도달 (선제적 광고 권유)
  tokenDepletion,

  /// 토큰 100% 소진 (필수 광고)
  tokenDepleted,

  /// 메시지 간격 광고
  intervalAd,
}
```

---

## 5. 페르소나 광고 프롬프트

### 5.1 전환 문구 템플릿

```dart
/// 페르소나별 광고 전환 프롬프트
class AdPersonaPrompt {
  static String getTransitionPrompt(AiPersona persona, AdTriggerResult trigger) {
    final personaStyle = _getPersonaStyle(persona);

    return switch (trigger) {
      AdTriggerResult.tokenDepletion => '''
당신은 ${persona.displayName}입니다.
대화가 길어져 잠시 쉬어가는 것을 자연스럽게 제안하세요.
$personaStyle
예시: "참, 말이 나온 김에... 요즘 제가 추천드리고 싶은 것이 있는데요."
''',
      AdTriggerResult.tokenDepleted => '''
당신은 ${persona.displayName}입니다.
대화를 이어가려면 잠시 광고를 봐야 한다는 것을 정중하게 안내하세요.
$personaStyle
예시: "더 깊은 이야기를 나누고 싶은데, 잠시 후원자님 소개를 보시면 계속할 수 있어요."
''',
      _ => '',
    };
  }

  static String _getPersonaStyle(AiPersona persona) {
    return switch (persona.name) {
      'doryeong' => '조선시대 도령답게 고풍스럽고 정중하게 말하세요.',
      'seonyeo' => '선녀처럼 우아하고 신비롭게 말하세요.',
      'monk' => '스님답게 담담하고 지혜롭게 말하세요.',
      _ => '친근하고 자연스럽게 말하세요.',
    };
  }
}
```

### 5.2 예시 출력

```
[토큰 80% - 도령 페르소나]
도령: "허허, 이야기가 깊어지니 잠시 숨을 고르는 것도 좋겠구려.
       말이 나온 김에, 요즘 제가 눈여겨보는 것이 있사온데...
       혹시 연애운이 궁금하시다면 이 인연앱을 한번 보시겠소?"

       [스폰서: 소개팅 앱 광고]

도령: "광고를 보시면 저와 더 깊은 대화를 이어갈 수 있답니다."
```

---

## 6. 위젯 트리 최적화

### 6.1 최적화 원칙

```dart
/// ✅ 권장 패턴
class PersonaAdBubble extends StatelessWidget {
  final AdChatMessage message;
  final NativeAd? nativeAd;

  // const 생성자 사용
  const PersonaAdBubble({
    super.key,
    required this.message,
    this.nativeAd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 전환 문구 (const 가능한 부분 분리)
        if (message.transitionText != null)
          _TransitionTextBubble(text: message.transitionText!),

        // Native Ad
        if (nativeAd != null)
          _AdContainer(ad: nativeAd!),

        // CTA
        if (message.ctaText != null)
          _CtaBubble(text: message.ctaText!),
      ],
    );
  }
}

/// 분리된 위젯 (const 가능)
class _TransitionTextBubble extends StatelessWidget {
  final String text;
  const _TransitionTextBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    // ...
  }
}
```

### 6.2 리빌드 최소화

```dart
/// ❌ 피해야 할 패턴
Widget build(BuildContext context) {
  return Consumer(
    builder: (context, ref, child) {
      final adState = ref.watch(conversationalAdProvider);
      // 전체 위젯이 리빌드됨
      return Column(children: [...]);
    },
  );
}

/// ✅ 권장 패턴
Widget build(BuildContext context) {
  return Column(
    children: [
      // 광고 상태만 감시하는 부분 분리
      Consumer(
        builder: (context, ref, child) {
          final isAdMode = ref.watch(
            conversationalAdProvider.select((s) => s.isAdMode),
          );
          return isAdMode ? const _AdModeIndicator() : const SizedBox.shrink();
        },
      ),
      // 나머지는 리빌드되지 않음
      const _ChatContent(),
    ],
  );
}
```

---

## 7. 통합 시퀀스

```
┌──────────┐     ┌──────────────┐     ┌─────────────────┐
│  User    │────▶│ ChatProvider │────▶│ AdTriggerService│
└──────────┘     └──────────────┘     └─────────────────┘
     │                  │                      │
     │                  │                      ▼
     │                  │           ┌─────────────────────┐
     │                  │           │ tokenUsage >= 80%?  │
     │                  │           └─────────────────────┘
     │                  │                      │ Yes
     │                  │                      ▼
     │                  │           ┌─────────────────────┐
     │                  │           │ ConversationalAd    │
     │                  │           │ Provider 활성화     │
     │                  │           └─────────────────────┘
     │                  │                      │
     │                  ▼                      ▼
     │           ┌──────────────┐    ┌─────────────────────┐
     │           │ 전환 문구 생성│◀───│ AdPersonaPrompt     │
     │           │ (Gemini)     │    │ .getTransitionPrompt│
     │           └──────────────┘    └─────────────────────┘
     │                  │
     │                  ▼
     │           ┌──────────────┐
     │           │ AdChatMessage│
     │           │ 생성 & 표시  │
     │           └──────────────┘
     │                  │
     │                  ▼
     │           ┌──────────────┐
     │           │ NativeAd 로드│
     │           │ & 표시       │
     │           └──────────────┘
     │                  │
     │                  ▼
     │           ┌──────────────┐
     ◀───────────│ 광고 시청 후 │
   토큰 충전     │ 대화 재개    │
                └──────────────┘
```

---

## 8. 파일 목록 (구현 순서)

### Phase 1: 데이터 레이어
1. `data/models/conversational_ad_model.dart`
2. `data/services/ad_trigger_service.dart`
3. `data/services/ad_prompt_datasource.dart`

### Phase 2: 도메인 레이어
4. `domain/entities/ad_chat_message.dart`
5. `domain/models/ad_persona_prompt.dart`

### Phase 3: 프레젠테이션 레이어
6. `presentation/providers/conversational_ad_provider.dart`
7. `presentation/widgets/ad_transition_bubble.dart`
8. `presentation/widgets/persona_ad_bubble.dart`

### Phase 4: 통합
9. `chat_provider.dart` 수정 (AdTrigger 통합)
10. `chat_message_list.dart` 수정 (AdChatMessage 렌더링)

---

## 9. 위험 요소 및 대응

| 위험 | 영향 | 대응 |
|-----|------|------|
| 광고 로드 실패 | 사용자 이탈 | Fallback UI + 재시도 버튼 |
| 토큰 계산 오차 | 광고 타이밍 어긋남 | 안전 마진 20% 적용 |
| 페르소나 프롬프트 길이 | 추가 토큰 소비 | 프롬프트 최적화 (< 200 토큰) |
| 광고 클릭 후 앱 이탈 | 세션 손실 | 상태 자동 저장 |

---

## 10. 성공 지표

- [ ] 광고 표시 시점의 자연스러움 (사용자 설문)
- [ ] 광고 클릭률 3% 이상
- [ ] eCPM $15 이상
- [ ] 광고 후 대화 재개율 70% 이상
