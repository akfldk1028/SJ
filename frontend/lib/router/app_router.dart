import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'routes.dart';
import '../core/widgets/main_shell.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/menu/presentation/screens/menu_screen.dart';
import '../features/profile/presentation/screens/profile_select_screen.dart';
import '../features/profile/presentation/screens/profile_edit_screen.dart';
import '../features/profile/presentation/screens/relationship_screen.dart';
import '../features/saju_chat/presentation/screens/saju_chat_shell.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/calendar/presentation/screens/calendar_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/profile_management_screen.dart';
import '../features/settings/presentation/screens/notification_settings_screen.dart';
import '../features/settings/presentation/screens/terms_of_service_screen.dart';
import '../features/settings/presentation/screens/privacy_policy_screen.dart';
import '../features/settings/presentation/screens/disclaimer_screen.dart';
<<<<<<< Updated upstream
import '../features/saju_chart/presentation/screens/saju_detail_screen.dart';
=======
import '../features/saju_chart/presentation/screens/saju_chart_screen.dart';
>>>>>>> Stashed changes

part 'app_router.g.dart';

/// 현재 경로에서 네비게이션 인덱스 가져오기
int _getNavIndex(String location) {
  if (location.startsWith('/menu') || location.startsWith('/saju/detail')) {
    return 0; // 운세
  } else if (location.startsWith('/relationships')) {
    return 1; // 인맥
  } else if (location.startsWith('/saju/chat')) {
    return 2; // AI 상담
  } else if (location.startsWith('/calendar')) {
    return 3; // 캘린더
  } else if (location.startsWith('/settings')) {
    return 4; // 설정
  }
  return 0;
}

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    routes: [
      // 독립 라우트 (네비게이션 바 없음)
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.profileSelect,
        name: 'profileSelect',
        builder: (context, state) => const ProfileSelectScreen(),
      ),
      GoRoute(
        path: Routes.profileEdit,
        name: 'profileEdit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
<<<<<<< Updated upstream
=======
        path: Routes.relationshipList,
        name: 'relationships',
        builder: (context, state) => const RelationshipScreen(),
      ),
      GoRoute(
        path: Routes.sajuChat,
        name: 'sajuChat',
        builder: (context, state) {
          // Query parameters
          final chatType = state.uri.queryParameters['type'];
          final profileId = state.uri.queryParameters['profileId'];
          return SajuChatShell(
            chatType: chatType,
            targetProfileId: profileId,
          );
        },
      ),
      GoRoute(
        path: Routes.sajuChart,
        name: 'sajuChart',
        builder: (context, state) => const SajuChartScreen(),
      ),
      GoRoute(
>>>>>>> Stashed changes
        path: Routes.history,
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      // 설정 하위 페이지들 (네비게이션 바 없음)
      GoRoute(
        path: Routes.settingsProfile,
        name: 'settingsProfile',
        builder: (context, state) => const ProfileManagementScreen(),
      ),
      GoRoute(
        path: Routes.settingsNotification,
        name: 'settingsNotification',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: Routes.settingsTerms,
        name: 'settingsTerms',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: Routes.settingsPrivacy,
        name: 'settingsPrivacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: Routes.settingsDisclaimer,
        name: 'settingsDisclaimer',
        builder: (context, state) => const DisclaimerScreen(),
      ),

      // ShellRoute - 네비게이션 바 공유
      ShellRoute(
        builder: (context, state, child) {
          final navIndex = _getNavIndex(state.uri.path);
          return MainShell(
            currentIndex: navIndex,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: Routes.menu,
            name: 'menu',
            builder: (context, state) => const MenuScreen(),
          ),
          GoRoute(
            path: Routes.relationshipList,
            name: 'relationships',
            builder: (context, state) => const RelationshipScreen(),
          ),
          GoRoute(
            path: Routes.sajuChat,
            name: 'sajuChat',
            builder: (context, state) {
              final chatType = state.uri.queryParameters['type'];
              return SajuChatShell(chatType: chatType);
            },
          ),
          GoRoute(
            path: Routes.calendar,
            name: 'calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: Routes.settings,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: Routes.sajuDetail,
            name: 'sajuDetail',
            builder: (context, state) => const SajuDetailScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('페이지를 찾을 수 없습니다: ${state.uri}'),
      ),
    ),
  );
}
