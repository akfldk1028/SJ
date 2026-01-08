import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'routes.dart';
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

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    routes: [
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
        path: Routes.menu,
        name: 'menu',
        builder: (context, state) => const MenuScreen(),
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
        path: Routes.relationshipList,
        name: 'relationships',
        builder: (context, state) => const RelationshipScreen(),
      ),
      GoRoute(
        path: Routes.sajuChat,
        name: 'sajuChat',
        builder: (context, state) {
          // Query parameter에서 chatType 가져오기
          final chatType = state.uri.queryParameters['type'];
          return SajuChatShell(chatType: chatType);
        },
      ),
      GoRoute(
        path: Routes.history,
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
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
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('페이지를 찾을 수 없습니다: ${state.uri}'),
      ),
    ),
  );
}
