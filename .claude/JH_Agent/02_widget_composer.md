# Widget Composer Agent

> 화면을 작은 위젯으로 분해하고 조합하는 에이전트

---

## 역할

1. 화면 레이아웃을 분석하여 위젯 트리 설계
2. 100줄 이하의 작은 위젯으로 분리
3. const 최적화가 적용된 위젯 코드 생성

---

## 호출 시점

- 새 Screen 구현 시
- 기존 위젯이 100줄 초과 시
- 리빌드 최적화 필요 시

---

## 입력

```yaml
screen_name: saju_chat
layout_description: |
  - AppBar (프로필 전환, 설정 버튼)
  - 면책 배너 (상단 고정)
  - 채팅 메시지 리스트 (스크롤)
  - 입력 영역 (요약 버튼, 텍스트 입력, 전송 버튼)
reference_doc: docs/02_features/saju_chat.md
```

---

## 출력: 위젯 트리 설계

```
SajuChatScreen (StatelessWidget, const)
├── Scaffold
│   ├── appBar: ChatAppBar (StatelessWidget, const)
│   │   ├── ProfileSwitchButton (ConsumerWidget)
│   │   └── SettingsButton (StatelessWidget, const)
│   │
│   └── body: Column
│       ├── DisclaimerBanner (StatelessWidget, const) ← shared/widgets/
│       ├── Expanded
│       │   └── ChatMessageList (ConsumerWidget)
│       │       └── ListView.builder
│       │           └── MessageBubble (StatelessWidget)
│       │               ├── UserMessageBubble (const 가능)
│       │               └── AiMessageBubble
│       │                   └── SuggestedQuestionChips
│       └── ChatInputField (StatefulWidget) ← TextEditingController 필요
│           ├── SajuSummaryButton (StatelessWidget, const)
│           ├── TextField
│           └── SendButton (StatelessWidget)
```

---

## 위젯 분류 기준

| 유형 | 위젯 타입 | 이유 |
|------|-----------|------|
| 정적 UI | StatelessWidget + const | 리빌드 없음 |
| 상태 구독 | ConsumerWidget | Riverpod watch |
| 폼 입력 | StatefulWidget | Controller 필요 |
| 애니메이션 | StatefulWidget + Ticker | Animation Controller |

---

## 폴더 구조 생성

```
features/{feature}/presentation/
├── screens/
│   └── {feature}_screen.dart      # 조립만 담당 (50줄 이하)
└── widgets/
    ├── {widget_1}.dart
    ├── {widget_2}.dart
    └── {sub_feature}/              # 관련 위젯 그룹
        ├── {widget_a}.dart
        └── {widget_b}.dart
```

---

## 생성 규칙

### 1. Screen은 조립만

```dart
class SajuChatScreen extends StatelessWidget {
  const SajuChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: ChatAppBar(),
      body: Column(
        children: [
          DisclaimerBanner(),
          Expanded(child: ChatMessageList()),
          ChatInputField(),
        ],
      ),
    );
  }
}
```

### 2. 개별 위젯은 단일 책임

```dart
// chat_app_bar.dart - AppBar만 담당
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('만톡'),
      actions: const [
        ProfileSwitchButton(),
        SettingsButton(),
      ],
    );
  }
}
```

---

## 주의사항

- 생성된 모든 위젯은 **00_widget_tree_guard** 검증 필수
- const 적용 가능한 곳은 모두 const
- 100줄 초과 금지
