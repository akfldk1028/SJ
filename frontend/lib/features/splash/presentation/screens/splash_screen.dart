import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../router/routes.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

/// 스플래시 화면 - 동양풍 다크 테마
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    _navigateToNext();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final activeProfile = await ref.read(activeProfileProvider.future);

    if (activeProfile != null) {
      if (kDebugMode) {
        print('[Splash] 활성 프로필 존재: ${activeProfile.displayName}');
      }
      if (mounted) context.go(Routes.menu);
      return;
    }

    final allProfiles = await ref.read(allProfilesProvider.future);

    if (allProfiles.isNotEmpty) {
      if (kDebugMode) {
        print('[Splash] 프로필 ${allProfiles.length}개 발견, 첫 번째 활성화');
      }

      final repository = ref.read(profileRepositoryProvider);
      await repository.setActive(allProfiles.first.id);
      ref.invalidate(activeProfileProvider);

      if (mounted) context.go(Routes.menu);
      return;
    }

    if (kDebugMode) {
      print('[Splash] 프로필 없음 -> 온보딩');
    }
    if (mounted) context.go(Routes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Stack(
        children: [
          // 배경 그라데이션 오브
          Positioned(
            top: -100,
            left: -100,
            child: _buildBlurOrb(200, theme.primaryColor.withOpacity(0.15)),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: _buildBlurOrb(300, const Color(0xFF4ECDC4).withOpacity(0.1)),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            right: -80,
            child: _buildBlurOrb(180, theme.primaryColor.withOpacity(0.1)),
          ),
          // 메인 콘텐츠
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 달 아이콘
                        Text(
                          '🌙',
                          style: TextStyle(
                            fontSize: 80,
                            shadows: [
                              Shadow(
                                color: theme.primaryColor.withOpacity(0.5),
                                blurRadius: 30,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // 앱 이름
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              theme.primaryColor,
                              theme.accentColor ?? theme.primaryColor,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            AppStrings.appName,
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 앱 설명
                        Text(
                          AppStrings.appDescription,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.textSecondary,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 60),
                        // 연꽃 장식
                        Text(
                          '🪷',
                          style: TextStyle(
                            fontSize: 32,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurOrb(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60, tileMode: TileMode.decal),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
