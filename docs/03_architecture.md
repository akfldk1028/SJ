# 시스템 아키텍처

> 만톡: AI 사주 챗봇의 Flutter 앱 구조와 설계 원칙을 정의합니다.

---

## 1. 아키텍처 개요

### 1.1 선택한 아키텍처
- [ ] **Clean Architecture** (권장: 대규모 앱)
- [x] **MVVM** (권장: 중규모 앱) ← 만톡 선택
- [ ] **MVC** (간단한 앱)

### 1.2 레이어 구조
```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│              (Screens, Widgets, State Management)            │
├─────────────────────────────────────────────────────────────┤
│                      Domain Layer                            │
│              (Use Cases, Entities, Repositories)             │
├─────────────────────────────────────────────────────────────┤
│                       Data Layer                             │
│         (Repository Impl, Data Sources, DTOs, APIs)          │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. 폴더 구조

### 2.1 만톡 앱 Feature-First 구조
```
lib/
├── main.dart                    # 앱 진입점 (ShadcnApp.router 설정)
├── app.dart                     # 앱 설정 (shadcn_flutter 테마)
│
├── core/                        # 앱 전역 공통
│   ├── constants/               # 상수
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── app_sizes.dart
│   ├── theme/                   # 테마 설정
│   │   └── app_theme.dart
│   ├── utils/                   # 유틸리티 함수
│   │   ├── validators.dart      # 생년월일 검증 등
│   │   ├── formatters.dart      # 날짜 포맷
│   │   └── saju_calculator.dart # 만세력 계산 (로컬)
│   ├── errors/                  # 에러 정의
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   └── network/                 # 네트워크 설정
│       ├── api_client.dart
│       └── api_endpoints.dart
│
├── features/                    # 기능별 모듈
│   │
│   ├── splash/                  # 스플래시 화면
│   │   └── presentation/
│   │       └── screens/
│   │           └── splash_screen.dart
│   │
│   ├── onboarding/              # 온보딩 (서비스 소개)
│   │   └── presentation/
│   │       └── screens/
│   │           └── onboarding_screen.dart
│   │
│   ├── profile/                 # 사주 프로필 (생년월일 입력)
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── profile_remote_datasource.dart
│   │   │   │   └── profile_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── saju_profile_model.dart
│   │   │   └── repositories/
│   │   │       └── profile_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── saju_profile.dart
│   │   │   ├── repositories/
│   │   │   │   └── profile_repository.dart
│   │   │   └── usecases/
│   │   │       ├── save_profile_usecase.dart
│   │   │       └── get_profiles_usecase.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── profile_edit_screen.dart
│   │       ├── widgets/
│   │       │   ├── birth_date_picker.dart
│   │       │   └── birth_time_picker.dart
│   │       └── providers/
│   │           └── profile_provider.dart
│   │
│   ├── saju_chart/              # 만세력 계산/표시
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── saju_chart_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── saju_chart_model.dart
│   │   │   │   └── pillar_model.dart
│   │   │   └── repositories/
│   │   │       └── saju_chart_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── saju_chart.dart
│   │   │   │   └── pillar.dart
│   │   │   └── repositories/
│   │   │       └── saju_chart_repository.dart
│   │   └── presentation/
│   │       ├── widgets/
│   │       │   ├── saju_summary_card.dart
│   │       │   └── pillar_display.dart
│   │       └── providers/
│   │           └── saju_chart_provider.dart
│   │
│   ├── saju_chat/               # 사주 챗봇 (핵심 기능!)
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── chat_remote_datasource.dart
│   │   │   │   └── chat_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── chat_session_model.dart
│   │   │   │   └── chat_message_model.dart
│   │   │   └── repositories/
│   │   │       └── chat_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── chat_session.dart
│   │   │   │   └── chat_message.dart
│   │   │   ├── repositories/
│   │   │   │   └── chat_repository.dart
│   │   │   └── usecases/
│   │   │       ├── send_message_usecase.dart
│   │   │       └── get_chat_history_usecase.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── saju_chat_screen.dart
│   │       ├── widgets/
│   │       │   ├── chat_bubble.dart
│   │       │   ├── chat_input_field.dart
│   │       │   ├── suggested_questions.dart
│   │       │   └── saju_summary_sheet.dart
│   │       └── providers/
│   │           └── chat_provider.dart
│   │
│   ├── history/                 # 대화 히스토리
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       └── screens/
│   │           └── history_screen.dart
│   │
│   ├── settings/                # 설정
│   │   └── presentation/
│   │       └── screens/
│   │           └── settings_screen.dart
│   │
│   └── auth/                    # 인증 (P1 - 나중에)
│       ├── data/
│       ├── domain/
│       └── presentation/
│
├── shared/                      # 공유 컴포넌트
│   ├── widgets/                 # 공통 위젯
│   │   ├── custom_button.dart
│   │   ├── custom_text_field.dart
│   │   ├── loading_indicator.dart
│   │   ├── error_widget.dart
│   │   └── disclaimer_banner.dart  # "사주는 참고용입니다"
│   └── extensions/
│       ├── context_extensions.dart
│       └── datetime_extensions.dart
│
└── router/                      # 라우팅 설정
    ├── app_router.dart
    └── routes.dart
```

---

## 3. 상태 관리

### 3.1 선택 옵션
| 옵션 | 복잡도 | 적합한 규모 | 특징 |
|------|--------|-------------|------|
| **Riverpod** | 중간 | 중~대규모 | 컴파일 안전성, 테스트 용이 |
| **BLoC** | 높음 | 대규모 | 엄격한 구조, 예측 가능 |
| **Provider** | 낮음 | 소규모 | 간단, 학습 쉬움 |
| **GetX** | 낮음 | 소~중규모 | 간단, 올인원 |

### 3.2 상태 관리 선택
- [x] Riverpod ← 만톡 선택
- [ ] BLoC
- [ ] Provider
- [ ] GetX

### 3.3 상태 구조 예시 (Riverpod)
```dart
// providers/auth_provider.dart
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// state
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });
}
```

---

## 4. 의존성 주입

### 4.1 방식 선택
- [x] **Riverpod** (상태관리와 통합) ← 만톡 선택
- [ ] **get_it** (서비스 로케이터)
- [ ] **injectable** (코드 생성)

### 4.2 의존성 그래프
```
App
 └─ AuthFeature
     ├─ AuthProvider
     │   └─ AuthRepository
     │       ├─ AuthRemoteDataSource
     │       │   └─ ApiClient
     │       └─ AuthLocalDataSource
     │           └─ SecureStorage
     └─ Screens
         └─ AuthProvider (watch)
```

---

## 5. 네트워크 레이어

### 5.1 HTTP 클라이언트
- [x] **Dio** (권장: 인터셉터, 에러 핸들링) ← 만톡 선택
- [ ] **http** (간단한 요청)

### 5.2 API 클라이언트 구조
```dart
// core/network/api_client.dart
class ApiClient {
  final Dio _dio;

  ApiClient() : _dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(seconds: 30),
  )) {
    _dio.interceptors.addAll([
      AuthInterceptor(),
      LogInterceptor(),
      ErrorInterceptor(),
    ]);
  }
}
```

### 5.3 인터셉터
| 인터셉터 | 역할 |
|----------|------|
| AuthInterceptor | 토큰 자동 추가, 갱신 |
| LogInterceptor | 요청/응답 로깅 |
| ErrorInterceptor | 에러 변환, 공통 처리 |

---

## 6. 로컬 저장소

### 6.1 용도별 선택
| 데이터 | 저장소 | 이유 |
|--------|--------|------|
| 토큰, 민감정보 | flutter_secure_storage | 암호화 저장 |
| 설정, 간단한 값 | SharedPreferences | Key-Value |
| 구조화된 데이터 | Hive / SQLite | 복잡한 쿼리 |
| 캐시 | Hive | 빠른 읽기/쓰기 |

### 6.2 선택
- [x] flutter_secure_storage (토큰용) ← 만톡 선택
- [x] SharedPreferences (설정용) ← 만톡 선택
- [x] Hive (캐시, 오프라인 데이터) ← 만톡 선택 (프로필, 채팅 히스토리)
- [ ] SQLite (복잡한 관계형 데이터)

---

## 7. 라우팅

### 7.1 라우터 선택
- [x] **go_router** (권장: 선언적, 딥링크 지원) ← 만톡 선택
- [ ] **auto_route** (코드 생성)
- [ ] **Navigator 2.0** (기본)

### 7.2 라우트 구조
```dart
// router/app_router.dart
final goRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isLoggedIn = // check auth state
    final isLoggingIn = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoggingIn) return '/login';
    if (isLoggedIn && isLoggingIn) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    // ... more routes
  ],
);
```

---

## 8. 에러 핸들링

### 8.1 에러 타입
```dart
// core/errors/failures.dart
abstract class Failure {
  final String message;
  Failure(this.message);
}

class ServerFailure extends Failure {
  ServerFailure([String message = '서버 오류가 발생했습니다']) : super(message);
}

class NetworkFailure extends Failure {
  NetworkFailure([String message = '네트워크 연결을 확인해주세요']) : super(message);
}

class CacheFailure extends Failure {
  CacheFailure([String message = '캐시 오류가 발생했습니다']) : super(message);
}
```

### 8.2 Result 패턴
```dart
// Either 패턴 (dartz 패키지) 또는 Result 클래스
abstract class Result<T> {}

class Success<T> extends Result<T> {
  final T data;
  Success(this.data);
}

class Error<T> extends Result<T> {
  final Failure failure;
  Error(this.failure);
}
```

---

## 9. 테스트 전략

### 9.1 테스트 구조
```
test/
├── unit/                    # 단위 테스트
│   ├── features/
│   │   └── auth/
│   │       ├── data/
│   │       └── domain/
│   └── core/
├── widget/                  # 위젯 테스트
│   └── features/
│       └── auth/
│           └── presentation/
└── integration/             # 통합 테스트
    └── auth_flow_test.dart
```

### 9.2 테스트 커버리지 목표
- [ ] Unit Tests: 80%+
- [ ] Widget Tests: 주요 화면
- [ ] Integration Tests: 주요 흐름

---

## 10. Supabase 연동

### 10.1 Supabase 클라이언트 설정
```dart
// core/supabase/supabase_client.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://[PROJECT_ID].supabase.co';
  static const String supabaseAnonKey = '[ANON_KEY]';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
```

### 10.2 main.dart 초기화
```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://[PROJECT_ID].supabase.co',
    anonKey: '[ANON_KEY]',
  );

  runApp(const ProviderScope(child: MyApp()));
}
```

### 10.3 Supabase Provider (Riverpod)
```dart
// core/supabase/supabase_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final supabaseAuthProvider = Provider<GoTrueClient>((ref) {
  return ref.watch(supabaseClientProvider).auth;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseClientProvider).auth.currentUser;
});
```

### 10.4 Supabase Auth 사용 예시
```dart
// features/auth/data/datasources/auth_remote_datasource.dart
class AuthRemoteDataSource {
  final SupabaseClient _client;

  AuthRemoteDataSource(this._client);

  // 이메일 로그인
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // 소셜 로그인 (Google)
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.mantok://login-callback/',
    );
  }

  // 소셜 로그인 (Kakao)
  Future<void> signInWithKakao() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.kakao,
      redirectTo: 'io.supabase.mantok://login-callback/',
    );
  }

  // 로그아웃
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
```

### 10.5 Supabase Database 사용 예시
```dart
// features/profile/data/datasources/profile_remote_datasource.dart
class ProfileRemoteDataSource {
  final SupabaseClient _client;

  ProfileRemoteDataSource(this._client);

  // 프로필 생성
  Future<SajuProfileModel> createProfile(SajuProfileModel profile) async {
    final response = await _client
        .from('saju_profiles')
        .insert(profile.toJson())
        .select()
        .single();
    return SajuProfileModel.fromJson(response);
  }

  // 프로필 목록 조회
  Future<List<SajuProfileModel>> getProfiles() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('saju_profiles')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response.map((e) => SajuProfileModel.fromJson(e)).toList();
  }

  // 프로필 + 사주차트 조회 (JOIN)
  Future<SajuProfileModel> getProfileWithChart(String profileId) async {
    final response = await _client
        .from('saju_profiles')
        .select('*, saju_charts(*)')
        .eq('id', profileId)
        .single();
    return SajuProfileModel.fromJson(response);
  }
}
```

### 10.6 Supabase Edge Functions 호출
```dart
// core/supabase/edge_functions.dart
class EdgeFunctions {
  final SupabaseClient _client;

  EdgeFunctions(this._client);

  // 사주 챗봇 메시지 전송
  Future<Map<String, dynamic>> sendChatMessage({
    required String profileId,
    required String message,
    String? chatId,
  }) async {
    final response = await _client.functions.invoke(
      'saju-chat',
      body: {
        'profileId': profileId,
        'message': message,
        'chatId': chatId,
      },
    );

    if (response.status != 200) {
      throw Exception('Edge Function error: ${response.data}');
    }

    return response.data as Map<String, dynamic>;
  }

  // 만세력 계산
  Future<Map<String, dynamic>> calculateSajuChart(String profileId) async {
    final response = await _client.functions.invoke(
      'calculate-saju',
      body: {'profileId': profileId},
    );
    return response.data as Map<String, dynamic>;
  }
}
```

---

## 11. 환경 설정

### 11.1 환경 구분
| 환경 | Supabase URL | 용도 |
|------|--------------|------|
| dev | https://[DEV_PROJECT].supabase.co | 로컬 개발 |
| staging | https://[STAGING_PROJECT].supabase.co | 테스트 |
| prod | https://[PROD_PROJECT].supabase.co | 운영 |

### 11.2 환경 설정 파일
```dart
// core/config/app_config.dart
enum Environment { dev, staging, prod }

class AppConfig {
  static late Environment environment;

  static String get supabaseUrl {
    switch (environment) {
      case Environment.dev:
        return 'https://[DEV_PROJECT].supabase.co';
      case Environment.staging:
        return 'https://[STAGING_PROJECT].supabase.co';
      case Environment.prod:
        return 'https://[PROD_PROJECT].supabase.co';
    }
  }

  static String get supabaseAnonKey {
    switch (environment) {
      case Environment.dev:
        return '[DEV_ANON_KEY]';
      case Environment.staging:
        return '[STAGING_ANON_KEY]';
      case Environment.prod:
        return '[PROD_ANON_KEY]';
    }
  }
}
```

### 11.3 .env 파일 (git 제외)
```env
# .env.dev
SUPABASE_URL=https://[DEV_PROJECT].supabase.co
SUPABASE_ANON_KEY=[DEV_ANON_KEY]

# .env.prod
SUPABASE_URL=https://[PROD_PROJECT].supabase.co
SUPABASE_ANON_KEY=[PROD_ANON_KEY]
```

---

## 12. 사용 패키지 목록

### 12.1 필수 패키지
```yaml
dependencies:
  flutter:
    sdk: flutter

  # UI 프레임워크
  shadcn_flutter: ^0.0.28             # shadcn/ui 스타일 Flutter UI

  # Supabase
  supabase_flutter: ^2.3.0

  # 상태 관리
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

  # 라우팅
  go_router: ^14.6.2

  # AI
  google_generative_ai: ^0.4.6        # Gemini 2.0 Flash

  # 로컬 저장소
  hive_flutter: ^1.1.0

  # 유틸리티
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  uuid: ^4.5.1

  # 환경 변수
  flutter_dotenv: ^5.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter

  # 코드 생성
  build_runner: ^2.4.14
  freezed: ^2.5.8
  json_serializable: ^6.9.0
  riverpod_generator: ^2.6.4
  custom_lint:
  riverpod_lint: ^2.6.4

  # 테스트
  mockito: ^5.4.0
  mocktail: ^1.0.0
```

---

## 13. Widget 설계 원칙

> 상세 내용: [10_widget_tree_optimization.md](./10_widget_tree_optimization.md)

### 13.1 핵심 원칙

| 원칙 | 설명 | 효과 |
|------|------|------|
| **const 위젯** | 불변 위젯에 const 적용 | 리빌드 스킵 |
| **작은 위젯** | 100줄 이상이면 분리 | 부분 리빌드 |
| **Composition** | 상속보다 조합 | 유연성, 재사용성 |
| **Lazy Loading** | ListView.builder 사용 | 메모리 절약 |
| **setState 최소화** | 상태 변경 범위 축소 | 성능 향상 |

### 13.2 위젯 분리 규칙
```
화면 (Screen)
├── 섹션 위젯 (AppBar, Body, BottomBar)
│   ├── 컴포넌트 위젯 (Card, List, Form)
│   │   └── 기본 위젯 (Text, Icon, Button)
```

### 13.3 필수 적용 사항
```dart
// 1. const 생성자 정의
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});  // const 생성자
  ...
}

// 2. const 위젯 사용
const DisclaimerBanner(),  // const로 인스턴스화

// 3. ListView.builder 사용
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(item: items[index]),
)

// 4. RepaintBoundary (애니메이션 분리)
RepaintBoundary(
  child: AnimatedWidget(),
)
```

### 13.4 shadcn_flutter 위젯 패턴
```dart
// 테마 접근
final theme = Theme.of(context);

// 색상 사용
theme.colorScheme.primary
theme.colorScheme.secondary
theme.colorScheme.mutedForeground

// 타이포그래피 사용
theme.typography.h1
theme.typography.base
theme.typography.small.copyWith(color: theme.colorScheme.mutedForeground)

// 투명도 조절 (scaleAlpha 사용)
color.scaleAlpha(0.5)  // ✅
// color.withOpacity(0.5)  // ❌ 사용하지 않음

// Scaffold 구조
Scaffold(
  headers: [AppBar(...)],
  child: ...,
)
```

### 13.5 린트 설정 (analysis_options.yaml)
```yaml
linter:
  rules:
    prefer_const_constructors: true
    prefer_const_declarations: true
    prefer_const_literals_to_create_immutables: true
    avoid_unnecessary_containers: true
    sized_box_for_whitespace: true
```

---

## 14. 레이어 의존성 규칙 (핵심!)

> Flutter Clean Architecture의 핵심은 **의존성 방향**입니다.

### 14.1 의존성 방향 다이어그램
```
┌─────────────────────────────────────────────────────────────┐
│                   Presentation Layer                         │
│            (Screens, Widgets, Providers)                     │
│                         │                                    │
│                         │ depends on                         │
│                         ▼                                    │
├─────────────────────────────────────────────────────────────┤
│                     Domain Layer                             │
│           (Entities, Repository Interfaces)                  │
│                         ▲                                    │
│                         │ depends on                         │
│                         │                                    │
├─────────────────────────────────────────────────────────────┤
│                      Data Layer                              │
│        (Models, DataSources, Repository Impl)                │
└─────────────────────────────────────────────────────────────┘

의존성 방향: Presentation → Domain ← Data
(Domain이 중심, 아무것도 의존하지 않음)
```

### 14.2 레이어별 규칙

#### Domain Layer (가장 안쪽, 순수)
```dart
// ✅ 허용
import 'dart:core';
import 'package:equatable/equatable.dart';  // 순수 Dart 패키지만

// ❌ 금지
import 'package:flutter/material.dart';     // Flutter 의존성
import 'package:supabase_flutter/...';      // 외부 서비스
import '../data/...';                        // Data Layer
import '../presentation/...';                // Presentation Layer
```

**포함 요소:**
- `entities/` - 비즈니스 객체 (순수 Dart 클래스)
- `repositories/` - Repository 인터페이스 (abstract class)
- `usecases/` - 비즈니스 로직 (선택적)

#### Data Layer (중간)
```dart
// ✅ 허용
import '../domain/entities/...';            // Domain Entity
import '../domain/repositories/...';        // Domain Repository Interface
import 'package:supabase_flutter/...';      // 외부 서비스
import 'package:hive/hive.dart';            // 로컬 저장소

// ❌ 금지
import '../presentation/...';                // Presentation Layer
import 'package:flutter/material.dart';     // Flutter UI (필요 없음)
```

**포함 요소:**
- `models/` - Entity를 상속하고 JSON 변환 추가
- `datasources/` - Remote/Local 데이터 접근
- `repositories/` - Repository 구현체

#### Presentation Layer (가장 바깥)
```dart
// ✅ 허용
import '../domain/entities/...';            // Domain Entity
import '../domain/repositories/...';        // Domain Repository (DI로 주입)
import 'package:flutter/material.dart';     // Flutter UI
import 'package:flutter_riverpod/...';      // 상태 관리

// ❌ 금지
import '../data/datasources/...';           // Data Layer 직접 접근
import '../data/models/...';                // Model 직접 사용 (Entity 사용)
```

**포함 요소:**
- `providers/` - Riverpod Provider
- `screens/` - 화면 위젯
- `widgets/` - 재사용 위젯

### 14.3 의존성 주입 (DI) 패턴
```dart
// Domain Layer - Repository Interface
abstract class ProfileRepository {
  Future<List<SajuProfile>> getProfiles();
}

// Data Layer - Repository Implementation
class ProfileRepositoryImpl implements ProfileRepository {
  final SupabaseClient _client;
  ProfileRepositoryImpl(this._client);

  @override
  Future<List<SajuProfile>> getProfiles() async {
    // Supabase 호출
  }
}

// Presentation Layer - Provider (DI 연결)
@riverpod
ProfileRepository profileRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProfileRepositoryImpl(client);  // 구현체 주입
}

// Presentation Layer - 사용
@riverpod
Future<List<SajuProfile>> profileList(Ref ref) async {
  final repo = ref.watch(profileRepositoryProvider);  // Interface로 접근
  return repo.getProfiles();
}
```

### 14.4 왜 이렇게 해야 하는가?

| 이점 | 설명 |
|------|------|
| **테스트 용이** | Domain Layer를 독립적으로 테스트 가능 |
| **유지보수** | Supabase → Firebase 변경 시 Data Layer만 수정 |
| **확장성** | 새 기능 추가 시 영향 범위 최소화 |
| **협업** | 레이어별 담당자 분리 가능 |

---

## 15. Import 규칙

### 15.1 절대 경로 사용 (권장)
```dart
// ✅ 권장 - 절대 경로 (package:)
import 'package:mantok/features/profile/domain/entities/saju_profile.dart';
import 'package:mantok/core/constants/app_colors.dart';

// ❌ 지양 - 상대 경로 (같은 feature 내에서만 허용)
import '../../../core/constants/app_colors.dart';
```

### 15.2 Import 순서
```dart
// 1. Dart 기본 패키지
import 'dart:async';
import 'dart:convert';

// 2. Flutter 패키지
import 'package:flutter/material.dart';

// 3. 외부 패키지 (pub.dev)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 4. 프로젝트 내부 패키지 - core
import 'package:mantok/core/constants/app_colors.dart';

// 5. 프로젝트 내부 패키지 - features (같은 feature)
import 'package:mantok/features/profile/domain/entities/saju_profile.dart';

// 6. 상대 경로 (같은 폴더 내)
import 'saju_profile_model.dart';
```

### 15.3 Barrel File (선택적)
```dart
// features/profile/domain/domain.dart (barrel file)
export 'entities/saju_profile.dart';
export 'repositories/profile_repository.dart';

// 사용처
import 'package:mantok/features/profile/domain/domain.dart';
// → SajuProfile, ProfileRepository 모두 사용 가능
```

---

## 16. Feature 간 통신 규칙

### 16.1 원칙
```
Feature A ──X──> Feature B (직접 import 금지)
     │                │
     └──────┬─────────┘
            ▼
      shared/ 또는 core/
```

### 16.2 통신 방법

#### 방법 1: shared/ 모듈 사용
```dart
// shared/models/common_types.dart
enum Gender { male, female }

// Feature A, B 모두에서 사용
import 'package:mantok/shared/models/common_types.dart';
```

#### 방법 2: Provider를 통한 간접 참조
```dart
// Feature A의 Provider
@riverpod
SajuProfile? activeProfile(Ref ref) => ...;

// Feature B에서 사용 (Provider만 import)
@riverpod
Future<void> startChat(Ref ref) async {
  final profile = ref.watch(activeProfileProvider);
  // profile 사용
}
```

#### 방법 3: Event/Callback 패턴
```dart
// core/events/app_events.dart
class ProfileChangedEvent {
  final String profileId;
  ProfileChangedEvent(this.profileId);
}

// Event Bus 또는 Riverpod의 ref.listen 사용
```

### 16.3 Feature 간 의존성 매트릭스
```
              profile  saju_chart  saju_chat  history  settings
profile         -          X           X         X         X
saju_chart     ✓          -           X         X         X
saju_chat      ✓          ✓           -         X         X
history        ✓          X           ✓         -         X
settings       ✓          X           X         X         -

✓ = 의존 가능 (Provider 통해)
X = 의존 불가
```

---

## 17. 폴더 구조 검증 체크리스트

### 17.1 새 Feature 추가 시
```
□ domain/ 폴더에 Flutter import 없는지 확인
□ data/ 폴더에 presentation/ import 없는지 확인
□ presentation/ 폴더에 data/ 직접 import 없는지 확인
□ 다른 feature 직접 import 없는지 확인
□ Entity는 순수 Dart 클래스인지 확인
□ Repository Interface가 domain/에 있는지 확인
□ Repository Impl이 data/에 있는지 확인
```

### 17.2 dart analyze 활용
```bash
# 전체 분석
flutter analyze

# 특정 폴더만
flutter analyze lib/features/profile/
```

### 17.3 커스텀 린트 규칙 (analysis_options.yaml)
```yaml
analyzer:
  errors:
    # import 규칙 위반 시 에러
    import_of_legacy_library_into_null_safe: error

linter:
  rules:
    # import 관련
    directives_ordering: true
    always_use_package_imports: true  # 절대 경로 강제

    # 아키텍처 관련
    avoid_relative_lib_imports: true
```

---

## 체크리스트

- [x] 아키텍처 패턴 선택 (MVVM)
- [x] 상태 관리 방식 선택 (Riverpod)
- [x] 라우팅 라이브러리 선택 (go_router)
- [x] 폴더 구조 확정 (만톡 앱 전용)
- [x] 필수 패키지 목록 확정
- [x] 환경별 설정 정의
- [x] Supabase 연동 설정 추가
- [x] Supabase Auth/DB/Edge Functions 예시 코드
- [x] Widget 설계 원칙 정의
- [x] 레이어 의존성 규칙 정의
- [x] Import 규칙 정의
- [x] Feature 간 통신 규칙 정의
