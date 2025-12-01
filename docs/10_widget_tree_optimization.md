# Flutter Widget Tree 최적화 가이드

> 만톡 앱을 위한 Widget Tree 설계 원칙 및 성능 최적화 전략

---

## 1. Widget Tree 이해하기

### 1.1 Flutter의 3가지 트리
```
Widget Tree (설정/청사진)
    ↓ createElement()
Element Tree (인스턴스/생명주기 관리)
    ↓ createRenderObject()
Render Tree (실제 렌더링/레이아웃)
```

| 트리 | 역할 | 특징 |
|------|------|------|
| **Widget Tree** | UI 설정 정의 | 불변(Immutable), 매 프레임 재생성 가능 |
| **Element Tree** | Widget ↔ RenderObject 연결 | 가변(Mutable), 재사용됨 |
| **Render Tree** | 실제 레이아웃/페인팅 | 비용이 큼, 최소화 필요 |

### 1.2 리빌드의 진실
```dart
// Widget Tree가 재생성되어도
// Element가 같은 Widget 타입을 감지하면 재사용됨
// → const 위젯은 동일 인스턴스이므로 완전히 스킵됨
```

---

## 2. 핵심 최적화 원칙

### 2.1 const 위젯 사용 (가장 중요!)

```dart
// BAD - 매번 새 인스턴스 생성
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),  // 매번 새 EdgeInsets
      child: Text('Hello'),          // 매번 새 Text
    );
  }
}

// GOOD - const로 재사용
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});  // const 생성자

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),  // 컴파일 타임 상수
      child: Text('Hello'),          // 동일 인스턴스 재사용
    );
  }
}
```

**효과:**
- Flutter가 해당 서브트리 리빌드 완전히 스킵
- 메모리 사용량 감소 (단일 인스턴스)
- 린트 규칙으로 자동 감지 가능

### 2.2 작은 위젯으로 분리 (Composition)

```dart
// BAD - 거대한 단일 위젯
class ChatScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(...),        // 200줄
      body: Column(
        children: [
          // 배너, 메시지 목록, 입력창 모두 한 곳에
          // 하나만 변해도 전체 리빌드
        ],
      ),
    );
  }
}

// GOOD - 작은 위젯으로 분리
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: ChatAppBar(),           // 별도 위젯
      body: Column(
        children: [
          DisclaimerBanner(),         // 별도 위젯 (const)
          Expanded(child: ChatMessageList()),  // 별도 위젯
          ChatInputField(),           // 별도 위젯
        ],
      ),
    );
  }
}
```

**규칙:**
- 위젯이 100줄 이상이면 분리 고려
- 독립적으로 리빌드되어야 하는 부분 분리
- 재사용 가능한 부분 분리

### 2.3 setState() 범위 최소화

```dart
// BAD - 전체 화면이 리빌드됨
class ChatScreen extends StatefulWidget {
  bool isTyping = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MessageList(),      // 불필요하게 리빌드됨
        TypingIndicator(isTyping: isTyping),
        TextField(
          onChanged: (_) => setState(() => isTyping = true),
        ),
      ],
    );
  }
}

// GOOD - 타이핑 인디케이터만 별도 StatefulWidget
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const MessageList(),
        const TypingIndicatorWrapper(),  // 내부에서 상태 관리
        const ChatInputField(),
      ],
    );
  }
}

class TypingIndicatorWrapper extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    // 여기서만 리빌드됨
  }
}
```

### 2.4 StatelessWidget vs StatefulWidget 선택

| 상황 | 선택 | 이유 |
|------|------|------|
| 정적 UI | StatelessWidget | 리빌드 오버헤드 없음 |
| 사용자 입력 | StatefulWidget | 로컬 상태 필요 |
| 애니메이션 | StatefulWidget + TickerProvider | 애니메이션 컨트롤러 필요 |
| API 데이터 | StatelessWidget + Riverpod | 상태관리가 처리 |
| 폼 입력 | StatefulWidget | TextEditingController 필요 |

---

## 3. 리스트 최적화

### 3.1 ListView.builder 필수 사용

```dart
// BAD - 모든 아이템 한번에 생성
ListView(
  children: messages.map((m) => MessageBubble(m)).toList(),
)

// GOOD - 화면에 보이는 것만 생성 (Lazy Loading)
ListView.builder(
  itemCount: messages.length,
  itemBuilder: (context, index) {
    return MessageBubble(message: messages[index]);
  },
)
```

### 3.2 만톡 채팅 화면 최적화

```dart
class ChatMessageList extends ConsumerWidget {
  const ChatMessageList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatProvider).messages;

    return ListView.builder(
      // 역순 스크롤 (최신 메시지가 아래)
      reverse: true,

      // 캐시 범위 설정 (화면 밖 500px까지 미리 빌드)
      cacheExtent: 500,

      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];

        // Key 사용으로 상태 보존
        return MessageBubble(
          key: ValueKey(message.id),
          message: message,
        );
      },
    );
  }
}
```

### 3.3 RepaintBoundary 활용

```dart
// 애니메이션이 있는 위젯을 분리
class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(  // 이 위젯만 독립적으로 리페인트
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(message.content),
            if (message.suggestedQuestions != null)
              SuggestedQuestionsChips(  // 애니메이션 있을 수 있음
                questions: message.suggestedQuestions!,
              ),
          ],
        ),
      ),
    );
  }
}
```

### 3.4 AutomaticKeepAliveClientMixin

```dart
// 스크롤 아웃되어도 상태 유지가 필요한 경우
class ExpensiveWidget extends StatefulWidget {
  @override
  State<ExpensiveWidget> createState() => _ExpensiveWidgetState();
}

class _ExpensiveWidgetState extends State<ExpensiveWidget>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;  // 상태 유지

  @override
  Widget build(BuildContext context) {
    super.build(context);  // 반드시 호출
    return ...;
  }
}
```

---

## 4. build() 메서드 최적화

### 4.1 무거운 작업 피하기

```dart
// BAD - build()에서 계산
class SajuChartWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 매 리빌드마다 계산됨!
    final analysis = analyzeSajuChart(chart);  // 무거운 작업

    return Text(analysis);
  }
}

// GOOD - Provider에서 미리 계산
@riverpod
Future<String> sajuAnalysis(Ref ref, SajuChart chart) async {
  return await analyzeSajuChart(chart);  // 캐시됨
}

class SajuChartWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(sajuAnalysisProvider(chart));

    return analysisAsync.when(
      data: (analysis) => Text(analysis),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
```

### 4.2 조건부 위젯 최적화

```dart
// BAD - 매번 새 위젯 생성
Widget build(BuildContext context) {
  return Column(
    children: [
      if (showBanner) Container(...),  // 조건마다 새 인스턴스
    ],
  );
}

// GOOD - const 또는 캐시된 위젯
class MyWidget extends StatelessWidget {
  // 클래스 레벨에서 캐시
  static const _banner = DisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showBanner) _banner,  // 동일 인스턴스 재사용
      ],
    );
  }
}
```

---

## 5. Composition over Inheritance

### 5.1 Flutter의 핵심 철학

```dart
// BAD - 상속 기반 (안티패턴)
class CustomButton extends ElevatedButton {
  // ElevatedButton 상속은 제한적
}

// GOOD - 조합 기반
class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        // 커스텀 스타일
      ),
      child: child,
    );
  }
}
```

### 5.2 만톡 앱 위젯 조합 예시

```dart
// 사주 프로필 카드 - 작은 위젯들의 조합
class SajuProfileCard extends StatelessWidget {
  final SajuProfile profile;

  const SajuProfileCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 각각 독립적인 작은 위젯
            ProfileHeader(name: profile.displayName),
            const SizedBox(height: 8),
            BirthDateDisplay(
              date: profile.birthDate,
              isLunar: profile.isLunar,
            ),
            if (profile.birthTimeMinutes != null)
              BirthTimeDisplay(minutes: profile.birthTimeMinutes!),
            const SizedBox(height: 12),
            ProfileActionButtons(profileId: profile.id),
          ],
        ),
      ),
    );
  }
}

// 개별 작은 위젯들
class ProfileHeader extends StatelessWidget {
  final String name;
  const ProfileHeader({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

class BirthDateDisplay extends StatelessWidget {
  final DateTime date;
  final bool isLunar;

  const BirthDateDisplay({
    super.key,
    required this.date,
    required this.isLunar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 16),
        const SizedBox(width: 4),
        Text('${date.year}.${date.month}.${date.day}'),
        const SizedBox(width: 4),
        Text(
          isLunar ? '(음력)' : '(양력)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
```

---

## 6. 만톡 앱 Widget 구조 설계

### 6.1 화면별 Widget 분해

```
saju_chat_screen.dart
├── ChatAppBar                    # AppBar 위젯
│   ├── ProfileSwitchButton       # 프로필 전환
│   └── SettingsButton            # 설정 버튼
├── DisclaimerBanner              # 면책 배너 (const)
├── ChatMessageList               # 메시지 목록
│   ├── MessageBubble             # 개별 메시지
│   │   ├── UserMessageBubble     # 사용자 메시지
│   │   └── AiMessageBubble       # AI 메시지
│   │       └── SuggestedQuestionChips
│   └── TypingIndicator           # 타이핑 표시
├── SajuSummarySheet              # 사주 요약 (BottomSheet)
│   ├── SummaryHeader
│   ├── StrengthsList
│   └── WeaknessesList
└── ChatInputField                # 입력 영역
    ├── SajuSummaryButton         # 요약 버튼
    ├── MessageTextField          # 텍스트 입력
    └── SendButton                # 전송 버튼
```

### 6.2 폴더 구조

```
lib/features/saju_chat/presentation/
├── screens/
│   └── saju_chat_screen.dart     # 화면 조립
├── widgets/
│   ├── chat_app_bar.dart
│   ├── disclaimer_banner.dart
│   ├── chat_message_list.dart
│   ├── message_bubble/
│   │   ├── message_bubble.dart
│   │   ├── user_message_bubble.dart
│   │   └── ai_message_bubble.dart
│   ├── suggested_question_chips.dart
│   ├── typing_indicator.dart
│   ├── saju_summary_sheet.dart
│   └── chat_input_field.dart
└── providers/
    └── chat_provider.dart
```

### 6.3 공통 위젯 (shared/widgets/)

```dart
// shared/widgets/disclaimer_banner.dart
class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 16),
          SizedBox(width: 8),
          Text('사주는 참고용입니다'),
        ],
      ),
    );
  }
}
```

---

## 7. 디버깅 및 프로파일링

### 7.1 리빌드 추적

```dart
// main.dart에 추가
void main() {
  // 모든 위젯 리빌드 출력 (디버그 모드에서만)
  debugPrintRebuildDirtyWidgets = true;

  runApp(const MyApp());
}
```

### 7.2 DevTools 활용

1. **Widget Inspector**: 위젯 트리 구조 확인
2. **Performance Overlay**: FPS, 레이어 수 확인
3. **Widget Rebuild Stats**: 리빌드 횟수 확인

```bash
# DevTools 실행
flutter pub global activate devtools
flutter pub global run devtools
```

### 7.3 린트 설정

```yaml
# analysis_options.yaml
linter:
  rules:
    # const 사용 권장
    prefer_const_constructors: true
    prefer_const_declarations: true
    prefer_const_literals_to_create_immutables: true

    # 불필요한 리빌드 방지
    avoid_unnecessary_containers: true
    sized_box_for_whitespace: true

    # 위젯 분리 권장
    prefer_stateless_widget: true
```

---

## 8. 체크리스트

### 8.1 코드 리뷰 시 확인사항

- [ ] const 생성자 사용 가능한 곳에 const 적용?
- [ ] 100줄 이상 위젯은 분리?
- [ ] setState() 범위가 최소화되어 있는지?
- [ ] ListView는 .builder() 사용?
- [ ] build()에서 무거운 계산 없는지?
- [ ] 애니메이션 위젯에 RepaintBoundary 적용?

### 8.2 성능 목표

| 지표 | 목표값 |
|------|--------|
| 평균 FPS | 60 |
| 프레임 빌드 시간 | < 16ms |
| 불필요한 리빌드 | 0 |
| 초기 로드 시간 | < 2초 |

---

## 참고 자료

- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Flutter Architectural Overview](https://docs.flutter.dev/resources/architectural-overview)
- [Building an Efficient Widget Tree](https://medium.com/flutterdude/flutter-performance-series-building-an-efficient-widget-tree-84fd236e9868)
- [Composition Over Inheritance in Flutter](https://medium.com/@mouhanedakermi383/composition-over-inheritance-in-flutter-a-smarter-way-to-build-apps-5b183393a9e2)
- [Optimizing Flutter UI with RepaintBoundary](https://ms3byoussef.medium.com/optimizing-flutter-ui-with-repaintboundary-2402052224c7)
- [Flutter Performance Optimization 2025](https://www.f22labs.com/blogs/13-flutter-performance-optimization-techniques-in-2025/)

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 | 작성자 |
|------|------|-----------|--------|
| 2025-12-01 | 0.1 | 초안 작성 | - |
