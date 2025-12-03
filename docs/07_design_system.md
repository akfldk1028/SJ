# 디자인 시스템

> 만톡: AI 사주 챗봇의 시각적 일관성을 위한 디자인 가이드라인입니다.

---

## 1. UI 프레임워크

### 1.1 shadcn_flutter (v0.0.28)
- React의 shadcn/ui 스타일을 Flutter로 포팅한 UI 컴포넌트 라이브러리
- 모던하고 일관된 디자인 시스템 제공
- 다크 테마 기본 지원

### 1.2 앱 루트 설정
```dart
// main.dart
ShadcnApp.router(
  theme: ThemeData(
    colorScheme: ColorSchemes.darkDefaultColor,
    radius: 0.5,
    scaling: 1.0,
  ),
  routerConfig: router,
)
```

---

## 2. 컬러 시스템

### 2.1 Shadcn 테마 컬러
- `ColorSchemes.darkDefaultColor` - 다크 테마 기본 색상

### 2.2 컬러 접근 방법
```dart
final theme = Theme.of(context);

// Primary (주요 색상)
theme.colorScheme.primary           // 주요 버튼, 강조
theme.colorScheme.primaryForeground // Primary 위 텍스트

// Secondary (보조 색상)
theme.colorScheme.secondary           // 보조 버튼, 카드 배경
theme.colorScheme.secondaryForeground // Secondary 위 텍스트

// Muted (흐린 색상)
theme.colorScheme.muted           // 비활성 배경
theme.colorScheme.mutedForeground // 보조 텍스트, 힌트

// Destructive (경고/삭제)
theme.colorScheme.destructive           // 에러, 삭제 버튼
theme.colorScheme.destructiveForeground // Destructive 위 텍스트

// 기타
theme.colorScheme.background      // 배경
theme.colorScheme.foreground      // 기본 텍스트
theme.colorScheme.card            // 카드 배경
theme.colorScheme.border          // 테두리
```

### 2.3 색상 투명도 조절
```dart
// shadcn_flutter에서는 scaleAlpha 사용
color.scaleAlpha(0.5)  // 50% 투명도

// ❌ withOpacity 사용 금지
// color.withOpacity(0.5)  // 사용하지 않음
```

---

## 3. 타이포그래피

### 3.1 텍스트 스타일 접근
```dart
final theme = Theme.of(context);

// 제목
theme.typography.h1    // 가장 큰 제목
theme.typography.h2    // 페이지 제목
theme.typography.h3    // 섹션 제목
theme.typography.h4    // 서브 제목

// 본문
theme.typography.lead  // 리드 텍스트 (큰 본문)
theme.typography.large // 큰 본문
theme.typography.base  // 기본 본문
theme.typography.small // 작은 본문
theme.typography.xSmall // 매우 작은 텍스트
```

### 3.2 텍스트 스타일 커스터마이징
```dart
Text(
  '보조 텍스트',
  style: theme.typography.small.copyWith(
    color: theme.colorScheme.mutedForeground,
    fontWeight: FontWeight.bold,
  ),
)
```

---

## 4. 컴포넌트

### 4.1 레이아웃

#### Scaffold
```dart
Scaffold(
  headers: [
    AppBar(
      leading: [IconButton.ghost(...)],
      title: Text('타이틀'),
      trailing: [IconButton.ghost(...)],
    ),
  ],
  child: ...,
)
```

#### Card
```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: ...,
  ),
)
```

### 4.2 버튼

#### PrimaryButton
```dart
PrimaryButton(
  onPressed: () {},
  child: Text('주요 버튼'),
)
```

#### OutlineButton
```dart
OutlineButton(
  size: ButtonSize.small,
  onPressed: () {},
  child: Text('아웃라인 버튼'),
)
```

#### GhostButton
```dart
GhostButton(
  size: ButtonSize.small,
  onPressed: () {},
  child: Text('고스트 버튼'),
)
```

#### IconButton
```dart
IconButton.ghost(
  icon: Icon(RadixIcons.arrowLeft),
  onPressed: () {},
)
```

### 4.3 입력 필드

#### TextField
```dart
TextField(
  placeholder: Text('힌트 텍스트'),
  onChanged: (value) {},
)
```

#### Select (드롭다운)
```dart
Select<int>(
  value: selectedValue,
  itemBuilder: (context, item) => Text('$item'),
  onChanged: (value) { ... },
  placeholder: Text('선택'),
  popup: SelectPopup(
    items: SelectItemList(
      children: [
        SelectItemButton(value: 1, child: Text('옵션 1')),
        SelectItemButton(value: 2, child: Text('옵션 2')),
      ],
    ),
  ),
)
```

#### DatePicker
```dart
DatePicker(
  value: selectedDate,
  onChanged: (date) {},
)
```

#### Checkbox
```dart
Checkbox(
  value: isChecked,
  onChanged: (value) {},
  trailing: Text('체크박스 라벨'),
)
```

### 4.4 간격

#### Gap
```dart
// 수직/수평 간격
const Gap(8)
const Gap(16)
const Gap(24)
```

---

## 5. 아이콘

### 5.1 RadixIcons
shadcn_flutter는 RadixIcons를 기본으로 사용합니다.

```dart
// 자주 사용하는 아이콘
RadixIcons.arrowLeft    // 뒤로가기
RadixIcons.arrowRight   // 앞으로
RadixIcons.plus         // 추가
RadixIcons.star         // 별 (AI 아바타)
RadixIcons.clock        // 시계 (히스토리)
RadixIcons.person       // 사람 (사용자)
RadixIcons.trash        // 삭제
RadixIcons.pencil1      // 수정
RadixIcons.reload       // 새로고침
RadixIcons.checkCircled // 성공
RadixIcons.crossCircled // 에러/닫기
RadixIcons.paperPlane   // 전송
```

### 5.2 아이콘 사용
```dart
Icon(
  RadixIcons.star,
  size: 24,
  color: theme.colorScheme.primary,
)
```

---

## 6. 채팅 UI 패턴

### 6.1 메시지 버블
```dart
// 사용자 메시지 (오른쪽)
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: theme.colorScheme.primary,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
      bottomLeft: Radius.circular(12),
      bottomRight: Radius.circular(4),
    ),
  ),
  child: Text(
    message,
    style: theme.typography.base.copyWith(
      color: theme.colorScheme.primaryForeground,
    ),
  ),
)

// AI 메시지 (왼쪽)
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: theme.colorScheme.secondary,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(12),
    ),
  ),
  child: Text(
    message,
    style: theme.typography.base.copyWith(
      color: theme.colorScheme.secondaryForeground,
    ),
  ),
)
```

### 6.2 AI 아바타
```dart
Container(
  width: 32,
  height: 32,
  decoration: BoxDecoration(
    color: theme.colorScheme.primary,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Icon(
    RadixIcons.star,
    size: 18,
    color: Colors.white,
  ),
)
```

---

## 7. 반응형 디자인

### 7.1 Breakpoints
| 이름 | 너비 | 기기 |
|------|------|------|
| Mobile | < 600px | 스마트폰 |
| Tablet | 600-1024px | 태블릿 |
| Desktop | > 1024px | 데스크톱 |

### 7.2 MediaQuery 활용
```dart
final width = MediaQuery.of(context).size.width;

if (width < 600) {
  // 모바일 레이아웃
} else if (width < 1024) {
  // 태블릿 레이아웃
} else {
  // 데스크톱 레이아웃
}
```

---

## 8. 애니메이션

### 8.1 Duration
| 이름 | 시간 | 용도 |
|------|------|------|
| Fast | 150ms | 호버, 탭 피드백 |
| Normal | 300ms | 페이지 전환, 모달 |
| Slow | 500ms | 복잡한 애니메이션 |

### 8.2 Easing Curve
- 기본: `Curves.easeInOut`
- 진입: `Curves.easeOut`
- 퇴장: `Curves.easeIn`

### 8.3 AnimatedBuilder (shadcn)
```dart
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) {
    return Opacity(
      opacity: _controller.value,
      child: child,
    );
  },
  child: ...,
)
```

---

## 9. 주요 위젯 파일

| 파일 | 설명 |
|------|------|
| `lib/main.dart` | ShadcnApp.router 설정 |
| `lib/features/chat/presentation/widgets/chat_message_bubble.dart` | 채팅 메시지 버블 |
| `lib/features/chat/presentation/widgets/streaming_message_bubble.dart` | 스트리밍 메시지 버블 |
| `lib/features/chat/presentation/widgets/chat_input_field.dart` | 채팅 입력 필드 |
| `lib/features/home/presentation/screens/home_screen.dart` | 홈 화면 (메뉴 카드) |
| `lib/features/profile/presentation/screens/profile_edit_screen.dart` | 프로필 폼 |

---

## 체크리스트

- [x] UI 프레임워크 선택 (shadcn_flutter)
- [x] 컬러 시스템 정의 (ColorSchemes.darkDefaultColor)
- [x] 타이포그래피 스케일 정의 (theme.typography)
- [x] 주요 컴포넌트 정리 (Button, Card, TextField, Select)
- [x] 아이콘 라이브러리 선택 (RadixIcons)
- [x] 다크 모드 지원 (기본 적용)
- [x] 채팅 UI 패턴 정의
