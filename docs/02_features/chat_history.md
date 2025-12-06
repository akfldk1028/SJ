# 채팅 히스토리 기능 설계

> ChatGPT/Claude 스타일의 채팅 세션 관리 UI

---

## 1. UI 패턴 분석

### 1.1 ChatGPT/Claude 공통 패턴
- **2-Column Layout**: 왼쪽 사이드바 + 오른쪽 채팅 영역
- **사이드바 구성**:
  - 새 채팅 버튼 (상단)
  - 채팅 세션 목록 (날짜별 그룹핑)
  - 설정/프로필 (하단)
- **세션 관리**: 자동 저장, 제목 자동 생성, 검색

### 1.2 만톡 적용 방식
- **Mobile (< 600px)**: Drawer로 사이드바 표시
- **Desktop/Tablet (>= 600px)**: 2-Column 고정 레이아웃

---

## 2. 데이터 모델

### 2.1 ChatSession (채팅 세션)
```dart
class ChatSession {
  final String id;           // UUID
  final String title;        // 세션 제목 (첫 메시지 요약 또는 수동)
  final ChatType chatType;   // sajuAnalysis, dailyFortune, compatibility, general
  final String? profileId;   // 연결된 사주 프로필 ID
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
}
```

### 2.2 ChatMessage (기존 확장)
```dart
class ChatMessage {
  final String id;
  final String sessionId;    // NEW: 세션 연결
  final String content;
  final MessageRole role;
  final DateTime createdAt;
  // ... 기존 필드
}
```

### 2.3 저장소
- **Hive Boxes**:
  - `chat_sessions`: ChatSession 저장
  - `chat_messages`: ChatMessage 저장 (sessionId로 필터링)

---

## 3. 위젯 트리 설계

### 3.1 전체 구조
```
SajuChatShell (반응형 레이아웃 결정)
├── [Mobile] Scaffold + Drawer
│   ├── AppBar
│   │   ├── DrawerToggle (햄버거 메뉴)
│   │   ├── SessionTitle
│   │   └── NewChatButton
│   ├── Drawer → ChatHistorySidebar
│   └── Body → ChatContent
│
└── [Desktop/Tablet] Row
    ├── ChatHistorySidebar (width: 280)
    └── Expanded → ChatContent
```

### 3.2 ChatHistorySidebar
```
ChatHistorySidebar
├── SidebarHeader
│   ├── AppLogo ("만톡")
│   └── NewChatButton
├── Expanded → SessionList
│   ├── SessionGroupHeader ("오늘", "어제", "지난 7일", "이전")
│   └── ListView.builder
│       └── SessionListTile
│           ├── ChatTypeIcon
│           ├── SessionTitle (1줄)
│           ├── LastMessagePreview (1줄, 회색)
│           └── PopupMenu (이름변경/삭제)
└── SidebarFooter
    ├── ProfileSelector (현재 프로필 표시)
    └── SettingsButton
```

### 3.3 ChatContent (기존 수정)
```
ChatContent
├── EmptyState (세션 없을 때)
│   └── "새 대화를 시작하세요" + ChatTypeSelector
├── ChatMessageList (기존)
└── ChatInputField (기존)
```

---

## 4. 파일 구조

```
lib/features/saju_chat/
├── data/
│   ├── datasources/
│   │   ├── gemini_rest_datasource.dart (기존)
│   │   └── chat_session_local_datasource.dart (NEW)
│   ├── models/
│   │   └── chat_session_model.dart (NEW - Hive)
│   └── repositories/
│       ├── chat_repository_impl.dart (기존)
│       └── chat_session_repository_impl.dart (NEW)
├── domain/
│   ├── entities/
│   │   ├── chat_message.dart (수정 - sessionId)
│   │   └── chat_session.dart (NEW)
│   └── repositories/
│       ├── chat_repository.dart (기존)
│       └── chat_session_repository.dart (NEW)
└── presentation/
    ├── providers/
    │   ├── chat_provider.dart (수정 - 세션 연동)
    │   └── chat_session_provider.dart (NEW)
    ├── screens/
    │   └── saju_chat_screen.dart (수정 - Shell 패턴)
    └── widgets/
        ├── chat_history_sidebar/ (NEW)
        │   ├── chat_history_sidebar.dart
        │   ├── sidebar_header.dart
        │   ├── session_list.dart
        │   ├── session_group_header.dart
        │   ├── session_list_tile.dart
        │   └── sidebar_footer.dart
        └── (기존 위젯들)
```

---

## 5. Provider 설계

### 5.1 ChatSessionProvider
```dart
@riverpod
class ChatSessionNotifier extends _$ChatSessionNotifier {
  // 상태
  List<ChatSession> sessions;
  String? currentSessionId;

  // 메서드
  Future<void> loadSessions();
  Future<ChatSession> createSession(ChatType type);
  Future<void> selectSession(String sessionId);
  Future<void> deleteSession(String sessionId);
  Future<void> renameSession(String sessionId, String newTitle);
}
```

### 5.2 ChatProvider 수정
```dart
// 기존 ChatNotifier 수정
- sessionId 연동
- 메시지 저장 시 sessionId 포함
- 세션 전환 시 메시지 로드
```

---

## 6. 최적화 적용

### 6.1 위젯 트리 최적화
- [x] const 생성자 활용 (SidebarHeader, GroupHeader 등)
- [x] ListView.builder 사용 (SessionList)
- [x] 100줄 이상 위젯 분리
- [x] RepaintBoundary 적용 (SessionListTile)

### 6.2 성능 고려
- 세션 목록: 최대 100개 표시, 이후 페이징
- 메시지: 세션별 lazy loading
- 검색: debounce 적용 (300ms)

---

## 7. 세션 그룹핑 로직

```dart
enum SessionGroup {
  today,      // 오늘
  yesterday,  // 어제
  last7Days,  // 지난 7일
  last30Days, // 지난 30일
  older,      // 이전
}

SessionGroup getSessionGroup(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final sessionDate = DateTime(date.year, date.month, date.day);

  final diff = today.difference(sessionDate).inDays;

  if (diff == 0) return SessionGroup.today;
  if (diff == 1) return SessionGroup.yesterday;
  if (diff <= 7) return SessionGroup.last7Days;
  if (diff <= 30) return SessionGroup.last30Days;
  return SessionGroup.older;
}
```

---

## 8. 구현 순서

1. [ ] ChatSession 엔티티 + Hive 모델
2. [ ] ChatMessage에 sessionId 추가
3. [ ] ChatSessionRepository 구현
4. [ ] ChatSessionProvider 생성
5. [ ] ChatHistorySidebar 위젯들 구현
6. [ ] SajuChatShell (반응형 레이아웃)
7. [ ] 기존 ChatProvider 세션 연동
8. [ ] 테스트 및 최적화

---

## 참고 자료

- [Comparing Conversational AI Tool UIs 2025](https://intuitionlabs.ai/articles/conversational-ai-ui-comparison-2025)
- [TypingMind - LLM Frontend](https://www.typingmind.com/)
- [40 Chatbot UI Examples](https://arounda.agency/blog/chatbot-ui-examples)

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 |
|------|------|-----------|
| 2025-12-05 | 0.1 | 초안 작성 |
