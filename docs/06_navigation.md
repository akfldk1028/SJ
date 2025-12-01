## 6번 — `06_navigation.md`

```markdown
# 네비게이션 설계

> 만톡: AI 사주 챗봇의 화면 흐름과 라우팅 구조를 정의합니다.

---

## 1. 화면 흐름도

### 1.1 전체 흐름 (온보딩 + 프로필 + 사주 챗봇)

```text
                    ┌─────────────┐
                    │   앱 시작    │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │  스플래시    │ (/splash)
                    └──────┬──────┘
                           │
                 ┌─────────┴─────────┐
                 │                   │
          [온보딩 본 적 없음]   [온보딩 완료]
                 │                   │
                 ▼                   ▼
         ┌─────────────┐      ┌─────────────┐
         │  온보딩      │      │ 프로필 존재? │
         │ (/onboarding)│      └──────┬──────┘
         └──────┬──────┘             │
                │               ┌────▼─────┐
                │        [없음] │ 프로필입력│
                │               │ /profile │
                │               └────┬─────┘
                │                    │
                │               [저장 완료]
                │                    │
                ▼                    ▼
         ┌─────────────┐      ┌─────────────┐
         │ 사주 챗봇    │      │ 사주 챗봇    │
         │ (/saju/chat) │      │ (/saju/chat)│
         └──────┬──────┘      └──────┬──────┘
                │                    │
                │            [히스토리/설정 이동]
                │                    │
                ▼                    ▼
        ┌────────────┐       ┌────────────┐
        │ 히스토리    │       │ 설정       │
        │ (/history)  │       │ (/settings)│
        └────────────┘       └────────────┘
1.2 프로필 → 사주 요약 → 사주 챗봇 흐름
text
코드 복사
┌──────────────┐
│ 프로필 입력  │ (/profile)
└──────┬───────┘
       │  [저장]
       ▼
┌──────────────┐
│ 사주 요약    │ (요약 화면 or 바텀시트)
└──────┬───────┘
       │  [챗으로 상담하기]
       ▼
┌──────────────┐
│ 사주 챗봇    │ (/saju/chat)
└──────────────┘
실제 UI에서는 사주 요약은 바텀시트로 열고,
메인 화면은 항상 사주 챗봇으로 두는 것을 목표로 한다.

1.3 메인 액션 (사주 챗봇 화면 내)
text
코드 복사
┌──────────────────────────────────────┐
│ [프로필 전환]  [사주는 참고용입니다] │
├──────────────────────────────────────┤
│  챗 메시지 리스트                     │
│  - AI 인사                           │
│  - 내 질문/응답                      │
│  - 추천 질문 칩                      │
├──────────────────────────────────────┤
│ [사주 요약] [입력창........] [전송]   │
└──────────────────────────────────────┘
2. 라우트 정의
2.1 라우트 목록
화면	경로	인증 필요	파라미터
스플래시	/splash	X	-
온보딩	/onboarding	X	-
프로필 입력/수정	/profile/edit	X	profileId (선택, 수정 시)
사주 챗봇	/saju/chat	X	- (내부적으로 activeProfile 사용)
히스토리 목록	/history	X	profileId (선택)
설정	/settings	X	-

MVP 기준으로 로그인/회원가입 화면은 없음
(추후 계정 기능이 붙으면 /login, /register 등을 추가)

2.2 라우트 관계
text
코드 복사
/splash
/onboarding
/profile/edit
/saju/chat      (메인 화면, 앱 재실행 시 기본 도착점)
/history
/settings
앱 최초 실행: /splash → /onboarding → /profile/edit → /saju/chat

이후 실행: /splash → (온보딩/프로필 여부 체크) → /saju/chat

3. 라우터 구현 (go_router)
3.1 라우트 설정 예시
dart
코드 복사
// router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:mantok/features/splash/presentation/splash_screen.dart';
import 'package:mantok/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mantok/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:mantok/features/saju_chat/presentation/screens/saju_chat_screen.dart';
import 'package:mantok/features/history/presentation/screens/history_screen.dart';
import 'package:mantok/features/settings/presentation/screens/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  debugLogDiagnostics: true,

  // 온보딩 / 프로필 존재 여부에 따라 리다이렉트
  redirect: (context, state) {
    final prefs = /* SharedPreferences or State */;
    final hasSeenOnboarding = prefs.hasSeenOnboarding;
    final hasActiveProfile = prefs.hasActiveProfile; // or ProfileRepository

    final isSplash = state.matchedLocation == '/splash';
    final isOnboarding = state.matchedLocation == '/onboarding';
    final isProfileEdit = state.matchedLocation == '/profile/edit';

    // 스플래시는 항상 허용
    if (isSplash) return null;

    // 온보딩을 안 봤으면 -> 온보딩으로
    if (!hasSeenOnboarding && !isOnboarding) {
      return '/onboarding';
    }

    // 온보딩은 봤는데 프로필이 없으면 -> 프로필 입력
    if (hasSeenOnboarding && !hasActiveProfile && !isProfileEdit) {
      return '/profile/edit';
    }

    // 나머지는 그대로
    return null;
  },

  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const ProfileEditScreen(),
    ),
    GoRoute(
      path: '/saju/chat',
      builder: (context, state) => const SajuChatScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],

  errorBuilder: (context, state) => const SajuChatScreen(),
);
3.2 라우트 상수
dart
코드 복사
// router/routes.dart
class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const profileEdit = '/profile/edit';
  static const sajuChat = '/saju/chat';
  static const history = '/history';
  static const settings = '/settings';
}
4. 네비게이션 사용법
4.1 기본 이동
dart
코드 복사
// 페이지 이동 (현재 스택 교체)
context.go(AppRoutes.sajuChat);

// 뒤로가기
context.pop();

// 프로필 편집으로 이동
context.push(AppRoutes.profileEdit);

// 히스토리 화면으로 이동
context.push(AppRoutes.history);
4.2 Extra / 파라미터 전달
dart
코드 복사
// 특정 프로필을 편집할 때 (profileId 전달)
context.push(
  AppRoutes.profileEdit,
  extra: 'profile-1',
);

// 받는 쪽
class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    final profileId = state.extra as String?;
    // profileId가 null이면 신규 생성 모드
    // profileId가 있으면 수정 모드
    ...
  }
}
5. 딥링크 설정 (선택)
나중에 “공유 링크로 바로 사주 챗봇 열기” 등을 위해 정의

5.1 지원할 딥링크 예시
딥링크	앱 내 경로
mantok://chat	/saju/chat
mantok://history	/history
https://mantok.app/chat	/saju/chat

5.2 설정 파일 예시
yaml
코드 복사
# Android: android/app/src/main/AndroidManifest.xml
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="mantok"/>
  <data android:scheme="https" android:host="mantok.app"/>
</intent-filter>

# iOS: ios/Runner/Info.plist
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>mantok</string>
    </array>
  </dict>
</array>
6. 화면 전환 애니메이션 (선택)
dart
코드 복사
GoRoute(
  path: '/history',
  pageBuilder: (context, state) {
    return CustomTransitionPage(
      child: const HistoryScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  },
);
체크리스트
 전체 화면 흐름도 작성 (온보딩 → 프로필 → 사주 챗봇)

 라우트 목록 정의 (/splash, /onboarding, /profile/edit, /saju/chat, /history, /settings)

 온보딩/프로필 존재 여부 기반 리다이렉트 로직 정의

 go_router 라우터 구현 예시 추가

 기본 네비게이션 사용법 정의

 딥링크 URL 실제 도메인 확정

 화면 전환 애니메이션 실제 적용 여부 결정