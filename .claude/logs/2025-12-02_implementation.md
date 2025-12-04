# 구현 로그: 2025-12-02

> 다음 AI를 위한 구현 진행 상황 및 컨텍스트 메모

---

## 1. 프로젝트 상태

### 1.1 시작 상태
- **frontend/lib/**: main.dart만 존재 (기본 Flutter 카운터 템플릿)
- **pubspec.yaml**: 기본 패키지만 있음 (cupertino_icons)
- **문서**: docs/ 폴더에 상세 명세 완료

### 1.2 현재 상태 (구현 완료)
- **Phase 1-5 완료**: Profile Feature MVP 구현됨
- **Clean Architecture 적용**: Domain → Data → Presentation 레이어 분리
- **Riverpod 3.0 적용**: @riverpod 어노테이션 + AsyncNotifier 패턴

---

## 2. 생성된 파일 목록

### 2.1 프로젝트 설정
```
frontend/
├── pubspec.yaml (업데이트됨)
├── .env (Supabase 환경변수)
└── lib/
    └── main.dart (업데이트됨)
```

### 2.2 Core 모듈
```
frontend/lib/core/
├── constants/
│   ├── app_colors.dart      # 앱 컬러 팔레트
│   ├── app_strings.dart     # 문자열 상수 (한글)
│   └── app_sizes.dart       # 사이즈 상수
├── theme/
│   └── app_theme.dart       # Material 3 테마
├── providers/
│   └── supabase_provider.dart  # Supabase 클라이언트 Provider
└── router/
    ├── app_router.dart      # go_router 설정
    └── app_router.g.dart    # 생성된 코드
```

### 2.3 Profile Feature - Domain Layer (순수 Dart)
```
frontend/lib/features/profile/domain/
├── entities/
│   ├── gender.dart          # Gender enum
│   └── saju_profile.dart    # SajuProfile 엔티티
└── repositories/
    └── profile_repository.dart  # Repository 인터페이스
```

### 2.4 Profile Feature - Data Layer
```
frontend/lib/features/profile/data/
├── models/
│   └── saju_profile_model.dart  # JSON 변환 모델
├── datasources/
│   └── profile_remote_datasource.dart  # Supabase 쿼리
└── repositories/
    └── profile_repository_impl.dart  # Repository 구현
```

### 2.5 Profile Feature - Presentation Layer
```
frontend/lib/features/profile/presentation/
├── providers/
│   ├── profile_provider.dart      # 프로필 목록 관리
│   ├── profile_provider.g.dart    # 생성된 코드
│   ├── profile_form_provider.dart # 폼 상태 관리
│   └── profile_form_provider.g.dart
├── screens/
│   ├── profile_edit_screen.dart   # 프로필 입력/수정 화면
│   └── profile_list_screen.dart   # 프로필 목록 화면
└── widgets/
    ├── gender_selector.dart       # 성별 선택 위젯
    ├── birth_date_picker.dart     # 생년월일 선택 위젯
    └── birth_time_picker.dart     # 출생시간 선택 위젯
```

---

## 3. 기술 스택 적용 내역

### 3.1 Riverpod 3.0 패턴 적용
```dart
// AsyncNotifier 패턴 - profile_provider.dart
@riverpod
class ProfileList extends _$ProfileList {
  @override
  Future<List<SajuProfile>> build() async {
    final repository = ref.watch(profileRepositoryProvider);
    return repository.getProfiles();
  }

  Future<void> addProfile(SajuProfile profile) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(profileRepositoryProvider);
      await repository.createProfile(profile);
      return repository.getProfiles();
    });
  }
}

// Notifier 패턴 - profile_form_provider.dart
@riverpod
class ProfileForm extends _$ProfileForm {
  @override
  ProfileFormState build() => const ProfileFormState();

  void setDisplayName(String value) {
    state = state.copyWith(displayName: value);
  }
}
```

### 3.2 Clean Architecture 레이어 의존성
```
┌─────────────────────────────────────────────────────────────┐
│   Presentation ───→ Domain ←─── Data                        │
│   (Domain이 중심, 아무것도 의존하지 않음)                      │
└─────────────────────────────────────────────────────────────┘

✅ Domain Layer: 순수 Dart만!
   - gender.dart: enum만 정의
   - saju_profile.dart: 순수 데이터 클래스 + copyWith
   - profile_repository.dart: 추상 인터페이스만

✅ Data Layer: Domain만 import
   - profile_remote_datasource.dart → Supabase 의존
   - profile_repository_impl.dart → Domain 인터페이스 구현

✅ Presentation Layer: Domain만 직접 import, Data는 DI
   - profile_provider.dart → Repository 인터페이스만 사용
   - DI: profileRepositoryProvider에서 구현체 주입
```

### 3.3 라우팅 설정 (go_router)
```dart
// app_router.dart
GoRouter(
  initialLocation: '/profile/new',  // MVP: 프로필 입력부터 시작
  routes: [
    GoRoute(path: '/', redirect: => '/profiles'),
    GoRoute(path: '/profiles', builder: => ProfileListScreen()),
    GoRoute(path: '/profile/new', builder: => ProfileEditScreen()),
    GoRoute(path: '/profile/:id/edit', builder: => ProfileEditScreen(id)),
    GoRoute(path: '/profile/:id', builder: => ProfileEditScreen(id)), // TODO: Detail
  ],
)
```

---

## 4. 다음 단계 (Phase 2 - Saju Chat)

### 4.1 구현해야 할 파일
```
frontend/lib/features/chat/
├── domain/
│   ├── entities/chat_message.dart
│   ├── entities/chat_session.dart
│   └── repositories/chat_repository.dart
├── data/
│   ├── models/chat_message_model.dart
│   ├── datasources/chat_remote_datasource.dart
│   └── repositories/chat_repository_impl.dart
└── presentation/
    ├── providers/chat_provider.dart
    ├── screens/saju_chat_screen.dart
    └── widgets/
        ├── chat_message_bubble.dart
        └── chat_input_field.dart
```

### 4.2 Supabase Edge Function 연동
```dart
// chat_remote_datasource.dart 예상 구조
Future<ChatMessage> sendMessage(String message, SajuProfile profile) async {
  final response = await supabase.functions.invoke(
    'saju-chat',
    body: {
      'message': message,
      'profile': profile.toJson(),
    },
  );
  return ChatMessage.fromJson(response.data);
}
```

---

## 5. 실행 전 필수 작업

### 5.1 Supabase 설정
1. `.env` 파일에 실제 값 입력:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```

2. Supabase 테이블 생성 (docs/04_data_models.md 참조):
   ```sql
   CREATE TABLE saju_profiles (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     user_id UUID REFERENCES auth.users,
     display_name TEXT NOT NULL,
     birth_date DATE NOT NULL,
     birth_time_minutes INT,
     birth_time_unknown BOOLEAN DEFAULT false,
     is_lunar BOOLEAN DEFAULT false,
     gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),
     birth_place TEXT,
     is_active BOOLEAN DEFAULT false,
     created_at TIMESTAMPTZ DEFAULT now(),
     updated_at TIMESTAMPTZ DEFAULT now()
   );
   ```

### 5.2 코드 생성 (실제 환경)
```bash
cd frontend

# 의존성 설치
flutter pub get

# 코드 생성 (필수!)
dart run build_runner build --delete-conflicting-outputs

# 실행
flutter run
```

### 5.3 주의: .g.dart 파일들
현재 `.g.dart` 파일들은 수동으로 생성됨. 실제 환경에서는 `build_runner`로 재생성 권장:
- `app_router.g.dart`
- `profile_provider.g.dart`
- `profile_form_provider.g.dart`

---

## 6. 코드 품질 체크리스트

### 6.1 적용된 패턴
- [x] Clean Architecture 레이어 분리
- [x] Repository Pattern
- [x] @riverpod 어노테이션 (legacy Provider 미사용)
- [x] AsyncNotifier for 비동기 상태
- [x] SRP - ProfileFormProvider와 ProfileListProvider 분리
- [x] const 위젯 최대한 적용
- [x] snake_case 파일명, PascalCase 클래스명

### 6.2 확인 필요 사항
- [ ] Supabase 연결 테스트
- [ ] 한국어 로케일 정상 동작
- [ ] 다크모드 테마 확인
- [ ] 폼 유효성 검사 완전성

---

## 7. 변경 이력

| 시간 | 작업 | 상태 |
|------|------|------|
| 시작 | 프로젝트 상태 파악 | 완료 |
| - | Context7 문서 확인 (Riverpod 3.0, Supabase) | 완료 |
| - | 구현 계획 수립 | 완료 |
| - | Phase 1: pubspec.yaml, core/ 모듈 | 완료 |
| - | Phase 2: Domain Layer | 완료 |
| - | Phase 3: Data Layer | 완료 |
| - | Phase 4: Presentation Layer | 완료 |
| - | Phase 5: main.dart 통합 | 완료 |
| - | Code Generation (.g.dart) | 완료 |
| 현재 | 구현 로그 MD 업데이트 | 완료 |

---

## 8. 참고 문서

- **기능 명세**: `docs/02_features/profile_input.md`
- **아키텍처**: `docs/03_architecture.md`
- **상태관리**: `docs/09_state_management.md`
- **데이터 모델**: `docs/04_data_models.md`
- **API 스펙**: `docs/05_api_spec.md`
