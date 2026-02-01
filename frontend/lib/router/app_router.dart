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
import '../features/profile/presentation/screens/relationship_add_screen.dart';
import '../features/saju_chat/presentation/screens/saju_chat_shell.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/calendar/presentation/screens/calendar_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/profile_management_screen.dart';
import '../features/settings/presentation/screens/notification_settings_screen.dart';
import '../features/settings/presentation/screens/terms_of_service_screen.dart';
import '../features/settings/presentation/screens/privacy_policy_screen.dart';
import '../features/settings/presentation/screens/disclaimer_screen.dart';
import '../features/saju_chart/presentation/screens/saju_detail_screen.dart';
import '../features/saju_chart/presentation/screens/saju_chart_screen.dart';
import '../features/saju_chart/presentation/screens/saju_graph_screen.dart';
import '../features/daily_fortune/presentation/screens/daily_fortune_detail_screen.dart';
import '../features/daily_fortune/presentation/screens/category_fortune_detail_screen.dart';
import '../features/new_year_fortune/presentation/screens/new_year_fortune_screen.dart';
import '../features/traditional_saju/presentation/screens/lifetime_fortune_screen.dart';
import '../features/compatibility/presentation/screens/compatibility_screen.dart';
import '../features/compatibility/presentation/screens/compatibility_list_screen.dart';
import '../features/compatibility/presentation/screens/compatibility_detail_screen.dart';
import '../features/settings/presentation/screens/icon_generator_screen.dart';
import '../features/monthly_fortune/presentation/screens/monthly_fortune_screen.dart';
import '../features/yearly_2025_fortune/presentation/screens/yearly_2025_fortune_screen.dart';

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
        builder: (context, state) {
          // 쿼리 파라미터에서 profileId 추출 (수정 모드)
          final profileId = state.uri.queryParameters['profileId'];
          // extra에서 ProfileRelationTarget 추출 (관계에서 수정 시)
          final profileData = state.extra;
          return ProfileEditScreen(
            profileId: profileId,
            profileData: profileData,
          );
        },
      ),
      GoRoute(
        path: Routes.sajuChart,
        name: 'sajuChart',
        builder: (context, state) => const SajuChartScreen(),
      ),
      GoRoute(
        path: Routes.relationshipAdd,
        name: 'relationshipAdd',
        builder: (context, state) => const RelationshipAddScreen(),
      ),
      GoRoute(
        path: Routes.sajuGraph,
        name: 'sajuGraph',
        builder: (context, state) => const SajuGraphScreen(),
      ),
      GoRoute(
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
      GoRoute(
        path: Routes.iconGenerator,
        name: 'iconGenerator',
        builder: (context, state) => const IconGeneratorScreen(),
      ),
      // Fortune 페이지
      GoRoute(
        path: Routes.categoryFortuneDetail,
        name: 'categoryFortuneDetail',
        builder: (context, state) {
          final key = state.uri.queryParameters['key'] ?? 'wealth';
          return CategoryFortuneDetailScreen(categoryKey: key);
        },
      ),
      GoRoute(
        path: Routes.dailyFortuneDetail,
        name: 'dailyFortuneDetail',
        builder: (context, state) => const DailyFortuneDetailScreen(),
      ),
      GoRoute(
        path: Routes.newYearFortune,
        name: 'newYearFortune',
        builder: (context, state) => const NewYearFortuneScreen(),
      ),
      GoRoute(
        path: Routes.traditionalSaju,
        name: 'traditionalSaju',
        builder: (context, state) => const LifetimeFortuneScreen(),
      ),
      GoRoute(
        path: Routes.compatibility,
        name: 'compatibility',
        builder: (context, state) => const CompatibilityScreen(),
      ),
      GoRoute(
        path: Routes.compatibilityList,
        name: 'compatibilityList',
        builder: (context, state) {
          final profileId = state.uri.queryParameters['profileId'] ?? '';
          return CompatibilityListScreen(profileId: profileId);
        },
      ),
      GoRoute(
        path: Routes.compatibilityDetail,
        name: 'compatibilityDetail',
        builder: (context, state) {
          final analysisId = state.uri.queryParameters['analysisId'] ?? '';
          return CompatibilityDetailScreen(analysisId: analysisId);
        },
      ),
      GoRoute(
        path: Routes.monthlyFortune,
        name: 'monthlyFortune',
        builder: (context, state) => const MonthlyFortuneScreen(),
      ),
      GoRoute(
        path: Routes.yearly2025Fortune,
        name: 'yearly2025Fortune',
        builder: (context, state) => const Yearly2025FortuneScreen(),
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
            builder: (context, state) {
              // Note: UniqueKey 제거 - 구/신 위젯 동시 존재 시 defunct 에러 유발
              // refresh 로직은 RelationshipScreen.didChangeDependencies()에서 처리
              return const RelationshipScreen();
            },
          ),
          GoRoute(
            path: Routes.sajuChat,
            name: 'sajuChat',
            builder: (context, state) {
              final chatType = state.uri.queryParameters['type'];
              final profileId = state.uri.queryParameters['profileId'];
              final autoMention = state.uri.queryParameters['autoMention'] == 'true';
              return SajuChatShell(
                key: ValueKey('$chatType-$profileId-$autoMention'),
                chatType: chatType,
                targetProfileId: profileId,
                autoMention: autoMention,
              );
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
            builder: (context, state) {
              final profileId = state.uri.queryParameters['profileId'];
              return SajuDetailScreen(profileId: profileId);
            },
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
