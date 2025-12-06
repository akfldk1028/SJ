# ChatHistorySidebar Widgets

ChatGPT/Claude 스타일의 채팅 히스토리 사이드바 위젯 모음

## 파일 구조

```
chat_history_sidebar/
├── README.md                            # 이 파일
├── chat_history_sidebar_widgets.dart    # Barrel export
├── chat_history_sidebar.dart            # 메인 컨테이너
├── sidebar_header.dart                  # 헤더 (앱 타이틀 + 새 채팅 버튼)
├── sidebar_footer.dart                  # 하단 (설정 버튼)
├── session_list.dart                    # 세션 목록 (ConsumerWidget)
├── session_group_header.dart            # 그룹 헤더 (날짜별 구분)
└── session_list_tile.dart               # 개별 세션 아이템
```

## 위젯 설명

### 1. ChatHistorySidebar (메인 컨테이너)

**파일:** `chat_history_sidebar.dart`

메인 사이드바 컨테이너. Header, List, Footer를 Column으로 구성.

**속성:**
- `width: 280px` (고정)
- `onNewChat`: 새 채팅 버튼 클릭 콜백
- `onSessionSelected`: 세션 선택 콜백
- `onSessionDeleted`: 세션 삭제 콜백
- `onSessionRenamed`: 세션 이름 변경 콜백

**사용 예시:**
```dart
ChatHistorySidebar(
  onNewChat: () => print('새 채팅'),
  onSessionSelected: (id) => print('세션 선택: $id'),
  onSessionDeleted: (id) => print('세션 삭제: $id'),
  onSessionRenamed: (id, title) => print('이름 변경: $id -> $title'),
)
```

### 2. SidebarHeader (헤더)

**파일:** `sidebar_header.dart`

사이드바 상단 영역. 앱 타이틀 "만톡" + 새 채팅 버튼.

**기술 스택:**
- shadcn_ui `ShadButton` 사용
- const 생성자 (콜백 제외)

**구성:**
- 앱 타이틀: "만톡" (titleLarge, bold)
- 새 채팅 버튼: ShadButton with icon

### 3. SidebarFooter (하단)

**파일:** `sidebar_footer.dart`

사이드바 하단 영역. 설정 버튼.

**구성:**
- 설정 버튼: OutlinedButton (아이콘 + 텍스트)
- go_router로 `/settings` 이동

**최적화:**
- const 생성자
- 단순 버튼만 표시

### 4. SessionList (세션 목록)

**파일:** `session_list.dart`

세션 목록을 그룹별로 표시하는 ConsumerWidget.

**기능:**
- chatSessionProvider 구독 (TODO: Provider 구현 필요)
- SessionGroup별로 그룹화 (오늘, 어제, 지난 7일, etc)
- ListView.builder 사용 (Lazy loading)
- 빈 목록 처리 (안내 메시지)

**그룹 순서:**
1. 오늘
2. 어제
3. 지난 7일
4. 지난 30일
5. 이전

**임시 데이터:**
- Provider 구현 전까지 더미 데이터 사용
- `_getDummySessions()` 메서드

### 5. SessionGroupHeader (그룹 헤더)

**파일:** `session_group_header.dart`

날짜별 그룹 구분 헤더.

**속성:**
- `group: SessionGroup` (오늘, 어제, 지난 7일, etc)

**최적화:**
- const 생성자
- 단순 텍스트 + 패딩만

**스타일:**
- labelSmall
- onSurfaceVariant 색상
- fontWeight: w600

### 6. SessionListTile (세션 아이템)

**파일:** `session_list_tile.dart`

개별 세션을 표시하는 리스트 타일.

**구성:**
- ChatType 아이콘 (왼쪽)
  - dailyFortune: 🌞 (orange)
  - sajuAnalysis: ✨ (purple)
  - compatibility: ❤️ (pink)
  - general: 💬 (primary)
- 제목 (1줄, ellipsis)
- 마지막 메시지 미리보기 (1줄, grey)
- 팝업 메뉴 (이름 변경/삭제)

**인터랙션:**
- 탭: 세션 선택
- 팝업 메뉴:
  - 이름 변경: AlertDialog로 입력
  - 삭제: 확인 없이 즉시 삭제

**최적화:**
- RepaintBoundary로 독립적 리페인트
- ValueKey로 리스트 아이템 식별

## 위젯 트리 최적화 준수 사항

### ✅ const 생성자 사용
- SidebarHeader: const (콜백 제외)
- SidebarFooter: const
- SessionGroupHeader: const
- ChatHistorySidebar: const 가능한 부분 최대화

### ✅ ListView.builder 사용
- SessionList에서 ListView.builder 사용
- Lazy loading으로 성능 최적화

### ✅ 작은 위젯으로 분리
- 모든 위젯 100줄 이하
- 단일 책임 원칙 준수
- Header, Footer, List, Tile 모두 별도 파일

### ✅ RepaintBoundary 활용
- SessionListTile에 RepaintBoundary 적용
- 독립적 리페인트로 성능 향상

## shadcn_ui 사용

### ShadButton
- 파일: `sidebar_header.dart`
- 용도: 새 채팅 버튼
- 특징: 아이콘 + 텍스트

```dart
ShadButton(
  onPressed: onNewChat,
  icon: const Icon(Icons.add, size: 18),
  child: const Text('새 채팅'),
)
```

## TODO: Provider 구현

SessionList는 현재 더미 데이터를 사용합니다.
다음 Provider 구현 필요:

```dart
@riverpod
class ChatSessionNotifier extends _$ChatSessionNotifier {
  @override
  List<ChatSession> build() {
    return [];
  }

  void addSession(ChatSession session) { ... }
  void deleteSession(String id) { ... }
  void renameSession(String id, String title) { ... }
}
```

**파일 위치:**
- `lib/features/saju_chat/presentation/providers/chat_session_provider.dart`

**연결:**
```dart
// session_list.dart
final sessions = ref.watch(chatSessionNotifierProvider);
```

## 스타일 가이드

### 색상
- 그룹 헤더: `theme.colorScheme.onSurfaceVariant`
- 미리보기: `theme.colorScheme.onSurfaceVariant`
- 구분선: `theme.colorScheme.outlineVariant` (width: 0.5)

### 패딩
- 헤더/하단: `16px` 전체
- 그룹 헤더: `left: 16, right: 16, top: 16, bottom: 8`
- 리스트 타일: `horizontal: 12, vertical: 8`

### 아이콘 크기
- ChatType 아이콘: `20px`
- 버튼 아이콘: `18px`

## 사용 예시

### 기본 사용

```dart
import 'package:frontend/features/saju_chat/presentation/widgets/chat_history_sidebar/chat_history_sidebar_widgets.dart';

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 사이드바
        ChatHistorySidebar(
          onNewChat: () {
            // 새 채팅 시작
          },
          onSessionSelected: (id) {
            // 세션 로드
          },
          onSessionDeleted: (id) {
            // 세션 삭제
          },
          onSessionRenamed: (id, title) {
            // 세션 이름 변경
          },
        ),
        // 메인 채팅 영역
        Expanded(
          child: ChatMessageList(),
        ),
      ],
    );
  }
}
```

### Provider 연결 (구현 후)

```dart
// session_list.dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final sessions = ref.watch(chatSessionNotifierProvider);

  // 현재는 _getDummySessions() 사용
  // Provider 구현 후 위 코드로 교체
}
```

## 참고 문서

- [Widget Tree 최적화 가이드](../../../../../../docs/10_widget_tree_optimization.md)
- [Shadcn UI 컴포넌트](.claude/JH_Agent/08_shadcn_ui_builder.md)
- [ChatSession 엔티티](../../../domain/entities/chat_session.dart)
- [ChatType 모델](../../../domain/models/chat_type.dart)

## 체크리스트

위젯 구현 시 확인:
- [x] const 생성자 사용
- [x] 100줄 이하 유지
- [x] ListView.builder 사용
- [x] RepaintBoundary 적용
- [x] shadcn_ui 사용
- [x] 작은 위젯으로 분리
- [ ] Provider 구현 (TODO)
- [x] 타입 안전성 확보
- [x] 접근성 고려 (tooltip, label)
