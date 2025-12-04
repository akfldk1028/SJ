import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'routes.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/profile/presentation/screens/profile_edit_screen.dart';
import '../features/saju_chart/presentation/screens/saju_chart_screen.dart';
import '../features/saju_chat/presentation/screens/saju_chat_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';

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
        path: Routes.profileEdit,
        name: 'profileEdit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: Routes.sajuChart,
        name: 'sajuChart',
        builder: (context, state) => const SajuChartScreen(),
      ),
      GoRoute(
        path: Routes.sajuChat,
        name: 'sajuChat',
        builder: (context, state) {
          final profileId = state.uri.queryParameters['profileId'] ?? '';
          final sessionId = state.uri.queryParameters['sessionId'];
          return SajuChatScreen(
            profileId: profileId,
            sessionId: sessionId,
          );
        },
      ),
      GoRoute(
        path: Routes.history,
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('페이지를 찾을 수 없습니다: ${state.uri}'),
      ),
    ),
  );
}
