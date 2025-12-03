import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/chat/presentation/screens/saju_chat_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_edit_screen.dart';
import '../../features/profile/presentation/screens/profile_list_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

part 'app_router.g.dart';

/// Route Names
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String home = '/home';
  static const String profileList = '/profiles';
  static const String profileNew = '/profile/new';
  static const String profileEdit = '/profile/:id/edit';
  static const String profileDetail = '/profile/:id';
  static const String chat = '/chat/:profileId';
  static const String settings = '/settings';
}

/// GoRouter Provider
@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen (앱 시작)
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Home Screen (메인 메뉴)
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Profile List Screen (이전 상담 목록)
      GoRoute(
        path: AppRoutes.profileList,
        name: 'profileList',
        builder: (context, state) => const ProfileListScreen(),
      ),

      // Profile New (새 프로필 생성 = 사주 정보 입력)
      GoRoute(
        path: AppRoutes.profileNew,
        name: 'profileNew',
        builder: (context, state) => const ProfileEditScreen(),
      ),

      // Profile Edit (프로필 수정)
      GoRoute(
        path: AppRoutes.profileEdit,
        name: 'profileEdit',
        builder: (context, state) {
          final profileId = state.pathParameters['id'];
          return ProfileEditScreen(profileId: profileId);
        },
      ),

      // Profile Detail (프로필 상세)
      GoRoute(
        path: AppRoutes.profileDetail,
        name: 'profileDetail',
        builder: (context, state) {
          final profileId = state.pathParameters['id'];
          return ProfileEditScreen(profileId: profileId);
        },
      ),

      // Chat Screen (AI 사주 실시간 채팅)
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        builder: (context, state) {
          final profileId = state.pathParameters['profileId']!;
          final sessionId = state.uri.queryParameters['sessionId'];
          return SajuChatScreen(
            profileId: profileId,
            sessionId: sessionId,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('페이지를 찾을 수 없습니다: ${state.uri}'),
      ),
    ),
  );
}
