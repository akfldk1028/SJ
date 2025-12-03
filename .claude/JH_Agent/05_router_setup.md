# Router Setup Agent

> go_router 라우팅 설정을 관리하는 에이전트

---

## 역할

1. 새 라우트 추가
2. 리다이렉트 로직 설정
3. 네비게이션 헬퍼 함수 제공

---

## 호출 시점

- 새 Screen 추가 시
- 네비게이션 흐름 변경 시

---

## 라우트 구조

```dart
// router/routes.dart
class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const profileEdit = '/profile/edit';
  static const sajuChat = '/saju/chat';
  static const history = '/history';
  static const settings = '/settings';
}
```

```dart
// router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,

    redirect: (context, state) {
      // 온보딩/프로필 체크 로직
      final hasSeenOnboarding = ref.read(hasSeenOnboardingProvider);
      final hasProfile = ref.read(hasProfileProvider);

      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;
      final isProfileEdit = state.matchedLocation == AppRoutes.profileEdit;

      if (isSplash) return null;

      if (!hasSeenOnboarding && !isOnboarding) {
        return AppRoutes.onboarding;
      }

      if (hasSeenOnboarding && !hasProfile && !isProfileEdit) {
        return AppRoutes.profileEdit;
      }

      return null;
    },

    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        builder: (context, state) {
          final profileId = state.extra as String?;
          return ProfileEditScreen(profileId: profileId);
        },
      ),
      GoRoute(
        path: AppRoutes.sajuChat,
        builder: (context, state) => const SajuChatScreen(),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],

    errorBuilder: (context, state) => const SajuChatScreen(),
  );
});
```

---

## 네비게이션 사용법

### 기본 이동

```dart
// 스택 교체 (뒤로가기 불가)
context.go(AppRoutes.sajuChat);

// 스택 추가 (뒤로가기 가능)
context.push(AppRoutes.history);

// 뒤로가기
context.pop();
```

### 파라미터 전달

```dart
// 전달
context.push(AppRoutes.profileEdit, extra: 'profile-id-123');

// 수신
class ProfileEditScreen extends StatelessWidget {
  final String? profileId;

  const ProfileEditScreen({super.key, this.profileId});

  // profileId가 null이면 신규 생성
  // profileId가 있으면 수정 모드
}
```

---

## 라우트 추가 절차

1. routes.dart에 상수 추가
2. app_router.dart에 GoRoute 추가
3. Screen 위젯 import
4. 필요시 redirect 로직 업데이트

---

## 입력

```yaml
route_name: settings
path: /settings
screen: SettingsScreen
has_params: false
requires_auth: false
```

---

## 출력

- routes.dart 업데이트
- app_router.dart 업데이트
- 네비게이션 예시 코드
