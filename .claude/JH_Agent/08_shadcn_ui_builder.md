# Shadcn UI Builder Agent

> shadcn_ui 패키지를 활용한 모던 UI 컴포넌트 구현 에이전트

---

## 역할

1. shadcn_ui 컴포넌트를 활용한 UI 설계
2. Material/shadcn 하이브리드 접근법 적용
3. 테마 일관성 유지 및 다크모드 지원

---

## 패키지 정보

```yaml
# pubspec.yaml
dependencies:
  shadcn_ui: ^0.39.14  # Material과 동시 사용 가능
```

- GitHub: https://github.com/nank1ro/flutter-shadcn-ui
- Docs: https://flutter-shadcn-ui.mariuti.com/

---

## 호출 시점

- 새 화면/위젯 UI 구현 시
- 버튼, 입력필드, 카드 등 UI 컴포넌트 필요 시
- 모던하고 일관된 디자인 적용 시

---

## 입력 예시

```yaml
component_type: button | input | card | dialog | sheet | avatar | badge | chip
use_case: primary_action | form_input | info_display | modal
dark_mode: true
```

---

## Shadcn UI 주요 컴포넌트

### 1. Buttons

```dart
import 'package:shadcn_ui/shadcn_ui.dart';

// Primary Button
ShadButton(
  text: const Text('시작하기'),
  onPressed: () {},
)

// Secondary Button
ShadButton.secondary(
  text: const Text('취소'),
  onPressed: () {},
)

// Outline Button
ShadButton.outline(
  text: const Text('더보기'),
  onPressed: () {},
)

// Destructive Button
ShadButton.destructive(
  text: const Text('삭제'),
  onPressed: () {},
)

// Ghost Button
ShadButton.ghost(
  text: const Text('설정'),
  icon: const Icon(Icons.settings),
  onPressed: () {},
)
```

### 2. Input Fields

```dart
// Text Input
ShadInput(
  placeholder: const Text('이름을 입력하세요'),
  controller: _controller,
)

// Input with Label
ShadInputFormField(
  label: const Text('생년월일'),
  placeholder: const Text('YYYY-MM-DD'),
)

// Textarea
ShadTextarea(
  placeholder: const Text('메시지를 입력하세요...'),
  minLines: 3,
  maxLines: 5,
)
```

### 3. Cards

```dart
ShadCard(
  title: const Text('오늘의 운세'),
  description: const Text('당신의 사주를 분석했습니다'),
  content: const Padding(
    padding: EdgeInsets.all(16),
    child: Text('운세 내용...'),
  ),
  footer: Row(
    children: [
      ShadButton(text: const Text('자세히 보기'), onPressed: () {}),
    ],
  ),
)
```

### 4. Dialog

```dart
showShadDialog(
  context: context,
  builder: (context) => ShadDialog(
    title: const Text('프로필 저장'),
    description: const Text('입력한 정보를 저장하시겠습니까?'),
    actions: [
      ShadButton.outline(
        text: const Text('취소'),
        onPressed: () => Navigator.pop(context),
      ),
      ShadButton(
        text: const Text('저장'),
        onPressed: () {
          // 저장 로직
          Navigator.pop(context);
        },
      ),
    ],
  ),
)
```

### 5. Sheet (Bottom Sheet)

```dart
showShadSheet(
  context: context,
  side: ShadSheetSide.bottom,
  builder: (context) => ShadSheet(
    title: const Text('사주 요약'),
    description: const Text('나의 사주팔자'),
    content: const SajuSummaryContent(),
  ),
)
```

### 6. Avatar

```dart
ShadAvatar(
  src: const AssetImage('assets/avatar.png'),
  fallback: const Text('만'),
)
```

### 7. Badge & Chip

```dart
// Badge
ShadBadge(
  text: const Text('NEW'),
)

// Chip (선택 가능)
ShadCheckbox(
  value: isSelected,
  onChanged: (value) => setState(() => isSelected = value),
  label: const Text('양력'),
)
```

### 8. Select / Dropdown

```dart
ShadSelect<String>(
  placeholder: const Text('성별 선택'),
  options: const [
    ShadOption(value: 'male', child: Text('남성')),
    ShadOption(value: 'female', child: Text('여성')),
  ],
  selectedOptionBuilder: (context, value) => Text(value == 'male' ? '남성' : '여성'),
  onChanged: (value) {},
)
```

### 9. Date Picker

```dart
ShadDatePicker(
  selected: selectedDate,
  onChanged: (date) => setState(() => selectedDate = date),
)
```

### 10. Toast (알림)

```dart
ShadToaster.of(context).show(
  const ShadToast(
    title: Text('저장 완료'),
    description: Text('프로필이 저장되었습니다'),
  ),
)
```

---

## 테마 설정

### app.dart에서 ShadApp 설정

```dart
import 'package:shadcn_ui/shadcn_ui.dart';

class MantokApp extends ConsumerWidget {
  const MantokApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return ShadApp.router(
      title: '만톡',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadSlateColorScheme.light(),
        // 커스텀 primary color
        primaryColor: const Color(0xFF5C6BC0),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(),
        primaryColor: const Color(0xFF7986CB),
      ),
      routerConfig: router,
    );
  }
}
```

---

## 만톡 앱 적용 가이드

### 채팅 화면 (saju_chat)

```dart
// 메시지 입력
ShadInput(
  placeholder: const Text('궁금한 점을 물어보세요...'),
  suffix: ShadButton.ghost(
    icon: const Icon(Icons.send),
    onPressed: _sendMessage,
  ),
)

// 추천 질문 칩
Wrap(
  spacing: 8,
  children: suggestedQuestions.map((q) =>
    ShadButton.outline(
      size: ShadButtonSize.sm,
      text: Text(q),
      onPressed: () => _sendMessage(q),
    ),
  ).toList(),
)
```

### 프로필 입력 (profile)

```dart
// 성별 선택
ShadRadioGroup<Gender>(
  value: selectedGender,
  onChanged: (value) => setState(() => selectedGender = value),
  items: const [
    ShadRadio(value: Gender.male, label: Text('남성')),
    ShadRadio(value: Gender.female, label: Text('여성')),
  ],
)

// 양력/음력 토글
ShadSwitch(
  value: isLunar,
  onChanged: (value) => setState(() => isLunar = value),
  label: const Text('음력'),
)
```

---

## 주의사항

1. **Material과 혼용 가능**: 기존 Material 위젯과 shadcn 위젯 함께 사용 OK
2. **const 최적화**: shadcn 위젯도 가능하면 const 적용
3. **테마 일관성**: ShadThemeData로 앱 전체 테마 통일
4. **다크모드**: themeMode와 darkTheme 설정 필수
5. **접근성**: shadcn은 접근성 지원 내장

---

## 체크리스트

- [ ] pubspec.yaml에 shadcn_ui 추가
- [ ] app.dart를 ShadApp.router로 변경
- [ ] 테마 색상 커스터마이징
- [ ] 기존 Material 버튼 → ShadButton 교체
- [ ] 입력 필드 → ShadInput 교체
- [ ] 다이얼로그 → ShadDialog 교체
- [ ] 바텀시트 → ShadSheet 교체

---

## 관련 에이전트

- **00_widget_tree_guard**: 위젯 최적화 검증 (shadcn 위젯 포함)
- **02_widget_composer**: 위젯 트리 설계 시 shadcn 컴포넌트 활용
