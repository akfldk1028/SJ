# 만톡 (Mantok) - AI 사주 챗봇

AI 기반 사주 상담 Flutter 앱입니다.

## 기술 스택

### UI Framework
- **shadcn_flutter** (v0.0.28) - React의 shadcn/ui 스타일 Flutter UI 컴포넌트
  - `ShadcnApp.router` - 앱 루트 위젯
  - `ThemeData`, `ColorSchemes.darkDefaultColor` - 다크 테마
  - 주요 컴포넌트: `Scaffold`, `AppBar`, `Card`, `PrimaryButton`, `OutlineButton`, `TextField`, `Select`, `DatePicker`, `Checkbox`, `Gap`
  - 아이콘: `RadixIcons` (arrowLeft, plus, star, clock, person, trash, pencil1, reload 등)

### 상태 관리
- **Riverpod 2.x** with `@riverpod` annotation
- 코드 생성: `flutter pub run build_runner build --delete-conflicting-outputs`

### 라우팅
- **go_router** - 선언적 라우팅

### 백엔드
- **Supabase** - 인증 및 데이터 저장
- **Google Generative AI (Gemini 2.0 Flash)** - AI 채팅 스트리밍

### 데이터
- **Hive** - 로컬 저장소
- **Freezed** - Immutable 모델 클래스

## 프로젝트 구조

```
lib/
├── main.dart                 # 앱 진입점 (ShadcnApp.router)
├── core/
│   ├── router/app_router.dart    # go_router 설정
│   ├── providers/                # Supabase providers
│   └── services/gemini_service.dart  # Gemini AI 서비스
└── features/
    ├── splash/              # 스플래시 화면
    ├── home/                # 메인 메뉴 화면
    ├── profile/             # 사주 프로필 관리
    │   ├── domain/entities/ # SajuProfile, Gender
    │   ├── data/            # ProfileRepository
    │   └── presentation/    # ProfileEditScreen, ProfileListScreen
    └── chat/                # AI 채팅
        ├── domain/entities/ # ChatMessage
        ├── presentation/
        │   ├── screens/     # SajuChatScreen
        │   ├── widgets/     # ChatInputField, ChatMessageBubble
        │   └── providers/   # chat_provider (스트리밍 지원)
```

## 앱 플로우

1. **Splash Screen** - 앱 시작 (2.5초)
2. **Home Screen** - 메뉴 선택 (새 상담 / 이전 상담)
3. **Profile Edit Screen** - 사주 정보 입력
4. **Chat Screen** - AI 실시간 스트리밍 채팅

## 필수 명령어

```bash
# 패키지 설치
cd frontend
flutter pub get

# 코드 생성 (riverpod, freezed)
flutter pub run build_runner build --delete-conflicting-outputs

# 웹 실행
flutter run -d chrome

# 분석
flutter analyze
```

## 환경 설정

`.env` 파일 생성:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
GEMINI_API_KEY=your-gemini-api-key
```

## Shadcn Flutter 사용 패턴

```dart
// 테마 설정
ShadcnApp.router(
  theme: ThemeData(
    colorScheme: ColorSchemes.darkDefaultColor,
    radius: 0.5,
    scaling: 1.0,
  ),
  routerConfig: router,
)

// Scaffold with AppBar
Scaffold(
  headers: [
    AppBar(
      leading: [IconButton.ghost(icon: Icon(RadixIcons.arrowLeft), ...)],
      title: Text('타이틀'),
      trailing: [IconButton.ghost(...)],
    ),
  ],
  child: ...,
)

// Select 드롭다운
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

// 테마 접근
final theme = Theme.of(context);
theme.colorScheme.primary
theme.colorScheme.secondary
theme.colorScheme.destructive
theme.colorScheme.mutedForeground
theme.typography.h1, h2, h3, h4
theme.typography.base, large, small, xSmall
```

## 주요 파일

| 파일 | 설명 |
|------|------|
| `lib/main.dart` | ShadcnApp.router 설정 |
| `lib/core/router/app_router.dart` | 라우트 정의 |
| `lib/core/services/gemini_service.dart` | AI 스트리밍 서비스 |
| `lib/features/chat/presentation/providers/chat_provider.dart` | 채팅 상태 관리 |
| `lib/features/profile/domain/entities/saju_profile.dart` | 사주 프로필 모델 |
