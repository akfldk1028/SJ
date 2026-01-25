# Saju Chat - AI 대화 모듈

> **담당자**: JH_AI, Jina
> **최종 검증**: 2025-01-25 (v7.1)
> **상태**: ✅ 배포 가능

---

## 개요

사주 기반 AI 챗봇 핵심 모듈. GPT-5.2 분석 + Gemini 3.0 대화 파이프라인.

---

## 폴더 구조

```
saju_chat/
├── README.md                    # 이 파일
├── data/
│   ├── datasources/
│   │   ├── gemini_edge_datasource.dart   # Edge Function 호출 (핵심!)
│   │   ├── gemini_rest_datasource.dart   # REST API (레거시)
│   │   ├── ai_pipeline_manager.dart      # GPT→Gemini 파이프라인
│   │   └── saju_chat_edge_datasource.dart
│   ├── repositories/
│   │   ├── chat_repository_impl.dart     # 채팅 Repository 구현
│   │   └── chat_session_repository_impl.dart
│   ├── services/
│   │   ├── conversation_window_manager.dart  # 토큰 윈도우 관리
│   │   ├── system_prompt_builder.dart        # 시스템 프롬프트 조립
│   │   ├── token_counter.dart                # 토큰 추정
│   │   ├── sse_stream_client.dart            # SSE 스트리밍
│   │   └── chat_realtime_service.dart        # Supabase Realtime
│   └── models/
├── domain/
│   ├── entities/
│   │   ├── chat_message.dart
│   │   └── ad_chat_message.dart
│   ├── models/
│   │   ├── ai_persona.dart
│   │   ├── chat_type.dart
│   │   └── compatibility_context.dart
│   └── repositories/
└── presentation/
    ├── providers/
    │   ├── chat_provider.dart            # 채팅 상태 관리 (핵심!)
    │   ├── chat_session_provider.dart
    │   ├── chat_persona_provider.dart
    │   └── conversational_ad_provider.dart
    ├── screens/
    │   └── saju_chat_screen.dart
    └── widgets/
        ├── conversational_ad_widget.dart  # 광고 토큰 보상
        ├── chat_message_bubble.dart
        └── ...
```

---

## 핵심 흐름

### 1. 세션 라이프사이클

```
┌─────────────────────────────────────────────────────────────────┐
│                    세션 시작/복원 흐름                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [새 세션]                      [기존 세션 복원]                  │
│      │                              │                           │
│      ▼                              ▼                           │
│  ChatNotifier.build()          loadSessionMessages()            │
│      │                              │                           │
│      ▼                              ▼                           │
│  _repository 생성              DB에서 메시지 로드                 │
│      │                              │                           │
│      ▼                              ▼                           │
│  startNewSession()             _buildRestoreSystemPrompt()      │
│      │                          (v7.1: 사주 정보 포함!)          │
│      ▼                              │                           │
│  _isNewSession = true               ▼                           │
│      │                         restoreExistingSession()         │
│      ▼                              │                           │
│  시스템 프롬프트 설정                ▼                           │
│                                대화 히스토리 동기화               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**중요 (v7.1)**: 앱 복귀 시 `_buildRestoreSystemPrompt()`가 사주 정보를 포함한 완전한 프롬프트 생성

### 2. 메시지 전송 흐름

```
┌─────────────────────────────────────────────────────────────────┐
│                    메시지 전송 흐름                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  사용자 입력                                                     │
│      │                                                          │
│      ▼                                                          │
│  ChatNotifier.sendMessage()                                     │
│      │                                                          │
│      ├── 더블클릭 방지 (_isSendingMessage)                       │
│      ├── 사용자 메시지 UI 추가                                    │
│      ├── DB 저장 (sessionRepository.saveMessage)                │
│      │                                                          │
│      ▼                                                          │
│  _buildFullSystemPrompt()                                       │
│      │                                                          │
│      ├── 페르소나 프롬프트                                        │
│      ├── 프로필 정보 (첫 메시지만)                                │
│      ├── 사주 데이터 (첫 메시지만)                                │
│      ├── AI Summary (Intent 기반 필터링)                         │
│      └── 궁합 정보 (궁합 모드 시)                                 │
│                                                                 │
│      ▼                                                          │
│  _repository.sendMessageStream()                                │
│      │                                                          │
│      ▼                                                          │
│  GeminiEdgeDatasource.sendMessageStream()                       │
│      │                                                          │
│      ├── 토큰 윈도우잉 (_windowManager.windowMessages)           │
│      ├── Edge Function 호출 (SSE 스트리밍)                       │
│      │                                                          │
│      ▼                                                          │
│  스트리밍 응답 → UI 업데이트                                      │
│      │                                                          │
│      ▼                                                          │
│  완료 시 DB 저장 + 토큰 사용량 업데이트                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 3. 토큰 관리

```
┌─────────────────────────────────────────────────────────────────┐
│                    토큰 관리 시스템                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [ConversationWindowManager]                                    │
│      │                                                          │
│      ├── _baseMaxInputTokens = 100,000 (기본)                   │
│      ├── _bonusTokens = 광고 시청으로 획득                        │
│      └── maxInputTokens = base + bonus                          │
│                                                                 │
│  [토큰 추적]                                                     │
│      │                                                          │
│      ├── TokenCounter.estimateTokens() - 한글/영문 비율 반영     │
│      ├── TokenUsageInfo - 사용량/남은토큰/사용률                  │
│      │                                                          │
│      ├── isNearLimit = 80% 이상 → 경고                          │
│      └── isDepleted = 100% → 광고 트리거                        │
│                                                                 │
│  [윈도우잉]                                                      │
│      │                                                          │
│      ├── 한도 초과 시 오래된 메시지 트리밍                         │
│      ├── minMessagePairs = 3 (6개 메시지 최소 유지)              │
│      └── 시스템 프롬프트는 항상 포함                              │
│                                                                 │
│  [광고 토큰 보상]                                                 │
│      │                                                          │
│      ├── 80% 도달 → warningRewardTokens = 5,000                │
│      ├── 100% 도달 → depletedRewardTokens = 10,000             │
│      │                                                          │
│      └── ConversationalAdWidget._handleAdComplete()             │
│              │                                                  │
│              └── chatNotifier.addBonusTokens(rewardedTokens)    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 핵심 파일 상세

### chat_provider.dart (채팅 상태 관리)

```dart
@riverpod
class ChatNotifier extends _$ChatNotifier {
  // 핵심 메서드

  /// 세션 메시지 로드 + 복원
  Future<void> loadSessionMessages(String sessionId);

  /// 세션 복원용 시스템 프롬프트 (v7.1: 사주 정보 포함)
  Future<String> _buildRestoreSystemPrompt();

  /// 메시지 전송
  Future<void> sendMessage(String content, ChatType chatType, {...});

  /// 시스템 프롬프트 빌드
  String _buildFullSystemPrompt({...});

  /// 보너스 토큰 추가 (광고 시청 시)
  void addBonusTokens(int tokens);
}
```

### gemini_edge_datasource.dart (Edge Function 호출)

```dart
class GeminiEdgeDatasource {
  // 핵심 필드
  bool _isNewSession = false;  // 첫 메시지 플래그
  String? _systemPrompt;
  List<Map<String, dynamic>> _conversationHistory = [];

  // 핵심 메서드

  /// 새 세션 시작
  void startNewSession(String systemPrompt);

  /// 기존 세션 복원 (v7.1: 대화 히스토리 포함)
  void restoreSession(String systemPrompt, {List<Map<String, dynamic>>? messages});

  /// 스트리밍 메시지 전송
  Stream<String> sendMessageStream(String message);

  /// 보너스 토큰 추가
  void addBonusTokens(int tokens);
}
```

### conversation_window_manager.dart (토큰 윈도우)

```dart
class ConversationWindowManager {
  final int _baseMaxInputTokens;  // 기본 100,000
  int _bonusTokens = 0;           // 광고로 획득

  int get maxInputTokens => _baseMaxInputTokens + _bonusTokens;

  /// 토큰 한도에 맞게 메시지 트리밍
  WindowedConversation windowMessages(List<Map<String, dynamic>> messages);

  /// 보너스 토큰 추가
  void addBonusTokens(int tokens);
}
```

### system_prompt_builder.dart (프롬프트 조립)

```dart
class SystemPromptBuilder {
  /// 최종 시스템 프롬프트 빌드
  ///
  /// 조립 순서:
  /// 1. 현재 날짜 + 년도 간지
  /// 2. 페르소나 프롬프트
  /// 3. 대화 규칙
  /// 4. 프로필 정보 (첫 메시지만)
  /// 5. 사주 데이터 (첫 메시지만)
  /// 6. AI Summary (Intent 기반 필터링)
  /// 7. 궁합 정보 (궁합 모드 시)
  String build({...});
}
```

---

## 광고 토큰 보상 흐름

```
┌─────────────────────────────────────────────────────────────────┐
│                 Rewarded 광고 토큰 충전 흐름                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  토큰 80%/100% 도달                                              │
│      │                                                          │
│      ▼                                                          │
│  AdTriggerService.checkTrigger()                                │
│      │                                                          │
│      ▼                                                          │
│  ConversationalAdNotifier.triggerAd()                           │
│      │                                                          │
│      ▼                                                          │
│  AdTransitionBubble 표시 (CTA 버튼)                              │
│      │                                                          │
│      ▼                                                          │
│  사용자 CTA 클릭                                                  │
│      │                                                          │
│      ▼                                                          │
│  showRewardedAd() → 전체화면 광고 시청                            │
│      │                                                          │
│      ▼                                                          │
│  onUserEarnedReward 콜백                                         │
│      │                                                          │
│      ▼                                                          │
│  _onRewardEarned() → adWatched = true                           │
│      │                                                          │
│      ▼                                                          │
│  "대화 재개" 버튼 표시                                            │
│      │                                                          │
│      ▼                                                          │
│  _handleAdComplete()                                            │
│      │                                                          │
│      ├── chatNotifier.addBonusTokens(rewardedTokens)            │
│      └── adNotifier.dismissAd()                                 │
│                                                                 │
│  ⚠️ 중요: Rewarded 광고는 끝까지 봐야 토큰 충전!                   │
│          (클릭만 해서는 충전 안 됨)                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 궁합 모드

### v6.0 단순화된 궁합 로직

```dart
// 궁합 = 그냥 2명의 profileId
sendMessage(
  content,
  ChatType.compatibility,
  compatibilityParticipantIds: [person1Id, person2Id],
);
```

| 파라미터 | 설명 |
|---------|------|
| `compatibilityParticipantIds` | 2명의 프로필 ID 배열 |
| `isThirdPartyCompatibility` | "나 제외" 모드 여부 |

### 시스템 프롬프트에 포함되는 정보

1. Person1 프로필 + 사주
2. Person2 프로필 + 사주
3. 궁합 분석 결과 (CompatibilityAnalysisService)
4. 합충형해파 분석

---

## 에러 처리

| 에러 | 처리 |
|------|------|
| 네트워크 오류 | DioException 캐치 → 에러 메시지 표시 |
| SSE 실패 | 비스트리밍 API로 폴백 |
| 타임아웃 | 5분 (스트리밍), 2분 (일반) |
| 토큰 소진 | 광고 트리거 → 보너스 토큰 |
| 프로필 없음 | 페르소나 프롬프트만 사용 |

---

## 상수 정의

### 토큰 관련 (ai_constants.dart)

```dart
// 입력 토큰 한도
static const int defaultMaxInputTokens = 100000;

// 응답 토큰 한도
static const int questionAnswerMaxTokens = 1024;  // 채팅 응답

// 안전 마진
static const int safetyMargin = 500;
```

### 광고 토큰 보상 (ad_trigger_service.dart)

```dart
static const int warningRewardTokens = 5000;   // 80% 도달 시
static const int depletedRewardTokens = 10000; // 100% 도달 시
```

---

## 주의사항

### 1. 세션 복원 시 AI Summary

```dart
// ❌ 잘못됨 - Edge Function 호출로 비용 발생
final aiSummary = await _ensureAiSummary(activeProfile.id);

// ✅ 올바름 - 캐시만 확인
final aiSummary = _cachedAiSummary;
```

### 2. 첫 메시지 판단

```dart
// 첫 메시지 = assistant 메시지가 없는 경우
final isFirstMessageInSession = !state.messages.any(
  (m) => m.role == MessageRole.assistant
);
```

### 3. 토큰 충전은 Rewarded 광고 완료 시에만

```dart
// CTA 클릭만으로는 토큰 충전 안 됨!
// 광고를 끝까지 봐야 onUserEarnedReward 콜백 호출
// → adWatched = true
// → "대화 재개" 버튼 클릭 시 토큰 충전
```

---

## 버전 히스토리

| 버전 | 날짜 | 변경사항 |
|------|------|----------|
| v7.1 | 2025-01-25 | 세션 복원 시 사주 정보 포함 (`_buildRestoreSystemPrompt`) |
| v7.0 | 2025-01-20 | Intent Classification 토큰 최적화 |
| v6.0 | 2025-01-15 | 궁합 로직 단순화 (2인만) |
| v5.2 | 2025-01-10 | 연속 궁합 채팅 시스템 프롬프트 업데이트 |

---

## 검증 상태 (2025-01-25)

| 영역 | 상태 | 비고 |
|------|------|------|
| 세션 시작 | ✅ | 새 세션 초기화 완료 |
| 세션 복원 | ✅ | v7.1 사주 정보 포함 |
| 메시지 전송 | ✅ | 스트리밍 + 에러 핸들링 |
| 토큰 관리 | ✅ | 추적/한도/보너스 |
| 광고 연동 | ✅ | Rewarded 토큰 충전 |
| 궁합 모드 | ✅ | 2인 궁합 지원 |

**결론: 배포 가능**
