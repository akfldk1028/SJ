# 만톡 (Mantok) - AI 사주 상담 앱

Flutter 기반 AI 사주 상담 챗봇 앱입니다. Google Gemini AI를 활용하여 실시간 스트리밍 채팅으로 사주 상담을 제공합니다.

## 프로젝트 구조

```
01_SJ/
├── frontend/                 # Flutter 앱 (메인 프로젝트)
│   ├── lib/
│   │   ├── main.dart        # 앱 진입점
│   │   ├── core/            # 공통 코어 모듈
│   │   │   ├── constants/   # 상수 (colors, sizes, strings)
│   │   │   ├── router/      # GoRouter 라우팅
│   │   │   ├── theme/       # 앱 테마
│   │   │   ├── providers/   # 전역 Provider (Supabase)
│   │   │   └── services/    # 서비스 (GeminiService)
│   │   └── features/        # 기능별 모듈 (Clean Architecture)
│   │       ├── splash/      # 스플래시 화면
│   │       ├── home/        # 메인 메뉴 화면
│   │       ├── profile/     # 프로필(사주정보) 관리
│   │       └── chat/        # AI 채팅
│   ├── pubspec.yaml         # 의존성 관리
│   ├── .env.example         # 환경변수 템플릿
│   └── .env                 # 환경변수 (gitignore됨)
└── README.md
```

## 아키텍처

### Clean Architecture + Feature-First 구조

각 feature는 3개 레이어로 구성:

```
feature/
├── domain/           # 비즈니스 로직 (순수 Dart)
│   ├── entities/     # 엔티티 (SajuProfile, ChatMessage 등)
│   └── repositories/ # Repository 인터페이스
├── data/             # 데이터 레이어
│   ├── models/       # DTO/Model (JSON 변환)
│   ├── datasources/  # API 호출 (Supabase)
│   └── repositories/ # Repository 구현체
└── presentation/     # UI 레이어
    ├── screens/      # 화면 위젯
    ├── widgets/      # 재사용 위젯
    └── providers/    # Riverpod Provider
```

### 상태관리: Riverpod 2.x + riverpod_generator

```dart
// Provider 정의 예시 (lib/features/profile/presentation/providers/profile_provider.dart)
@riverpod
class ProfileList extends _$ProfileList {
  @override
  Future<List<SajuProfile>> build() async {
    return repository.getProfiles();
  }
}
```

**중요**: `*.g.dart` 파일은 자동 생성되므로 build_runner 실행 필요

## 앱 플로우

```
Splash (/) → Home (/home) → Profile Input (/profile/new) → Chat (/chat/:profileId)
                 ↓
         Profile List (/profiles) → Profile Edit (/profile/:id/edit)
```

1. **Splash Screen**: 앱 로고 애니메이션, 2.5초 후 Home으로 이동
2. **Home Screen**: 메인 메뉴 (새 상담 시작 / 이전 상담 보기)
3. **Profile Edit Screen**: 사주 정보 입력 (이름, 성별, 생년월일, 출생시간, 출생지)
4. **Chat Screen**: Gemini AI와 실시간 스트리밍 채팅

## 주요 기술 스택

| 카테고리 | 기술 |
|---------|------|
| Framework | Flutter 3.x |
| 상태관리 | Riverpod 2.x + riverpod_generator |
| 라우팅 | go_router |
| 백엔드 | Supabase (Auth, Database) |
| AI | Google Generative AI (Gemini 2.0 Flash) |
| 코드생성 | build_runner, freezed, json_serializable |

## 필수 명령어

### 1. 의존성 설치
```bash
cd frontend
flutter pub get
```

### 2. 코드 생성 (*.g.dart, *.freezed.dart)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. 앱 실행
```bash
# Chrome (웹)
flutter run -d chrome

# Windows
flutter run -d windows

# Android/iOS
flutter run
```

### 4. 빌드
```bash
# Web
flutter build web

# Android APK
flutter build apk

# Windows
flutter build windows
```

## 환경 설정

### 1. .env 파일 생성
```bash
cp frontend/.env.example frontend/.env
```

### 2. API 키 설정 (.env)
```env
# Supabase - https://supabase.com/dashboard 에서 발급
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# Gemini - https://aistudio.google.com/apikey 에서 발급 (무료)
GEMINI_API_KEY=your-gemini-api-key
```

## 주요 파일 설명

### Core
- `lib/core/router/app_router.dart` - 라우팅 설정
- `lib/core/theme/app_theme.dart` - 테마 (라이트/다크)
- `lib/core/services/gemini_service.dart` - Gemini AI 스트리밍 서비스
- `lib/core/providers/supabase_provider.dart` - Supabase 클라이언트

### Features
- `lib/features/splash/presentation/screens/splash_screen.dart` - 스플래시
- `lib/features/home/presentation/screens/home_screen.dart` - 메인 메뉴
- `lib/features/profile/domain/entities/saju_profile.dart` - 프로필 엔티티
- `lib/features/profile/presentation/screens/profile_edit_screen.dart` - 프로필 입력
- `lib/features/chat/presentation/screens/saju_chat_screen.dart` - AI 채팅
- `lib/features/chat/presentation/providers/chat_provider.dart` - 채팅 상태관리

## 개발 가이드

### 새 Feature 추가 시
1. `lib/features/{feature_name}/` 폴더 생성
2. domain → data → presentation 순으로 구현
3. `flutter pub run build_runner build` 실행

### Provider 추가 시
1. `@riverpod` 어노테이션 사용
2. `part '{파일명}.g.dart';` 추가
3. build_runner 실행

### 주의사항
- domain 레이어에는 Flutter import 금지 (순수 Dart만)
- `.env` 파일은 절대 커밋하지 않음
- `*.g.dart`, `*.freezed.dart` 파일은 생성되므로 수동 편집 금지

## 현재 상태 (v0.1.0)

### 구현 완료
- [x] Splash Screen
- [x] Home Screen (메인 메뉴)
- [x] Profile 입력/수정/목록
- [x] Gemini AI 스트리밍 채팅
- [x] 라이트/다크 테마

### TODO
- [ ] Supabase 연동 (현재 로컬 상태만)
- [ ] 채팅 히스토리 저장
- [ ] 사용자 인증
- [ ] 푸시 알림

## 문제 해결

### build_runner 오류 시
```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Gemini API 오류 시
1. `.env` 파일에 `GEMINI_API_KEY` 확인
2. API 키가 유효한지 https://aistudio.google.com 에서 확인
3. 한국에서는 VPN 필요할 수 있음

## 라이선스

Private Project
