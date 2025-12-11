import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../router/routes.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

/// 스플래시 화면
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // 2초 대기 (로고 노출)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 1. 활성 프로필 확인 (Hive 로컬 먼저)
    final activeProfile = await ref.read(activeProfileProvider.future);

    if (activeProfile != null) {
      if (kDebugMode) {
        print('[Splash] 활성 프로필 존재: ${activeProfile.displayName}');
      }
      if (mounted) context.go(Routes.menu);
      return;
    }

    // 2. 활성 프로필이 없으면 전체 프로필 확인
    final allProfiles = await ref.read(allProfilesProvider.future);

    if (allProfiles.isNotEmpty) {
      if (kDebugMode) {
        print('[Splash] 프로필 ${allProfiles.length}개 발견, 첫 번째 활성화');
      }

      // 첫 번째 프로필 활성화
      final repository = ref.read(profileRepositoryProvider);
      await repository.setActive(allProfiles.first.id);

      // Provider 갱신
      ref.invalidate(activeProfileProvider);

      if (mounted) context.go(Routes.menu);
      return;
    }

    // 3. 프로필이 없으면 온보딩
    if (kDebugMode) {
      print('[Splash] 프로필 없음 -> 온보딩');
    }
    if (mounted) context.go(Routes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.appDescription,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
