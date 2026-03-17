import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../../../../router/routes.dart';
import '../../data/schema.dart';
import '../providers/splash_provider.dart';

/// 스플래시 화면
///
/// 앱 시작 시 필수 데이터를 Pre-fetch하고
/// 상태에 따라 적절한 화면으로 라우팅
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startPrefetch();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  Future<void> _startPrefetch() async {
    // 최소 1.5초 대기 (애니메이션 + 브랜딩)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Provider가 자동으로 pre-fetch 실행
    // 결과를 listen하고 네비게이션
    _listenToSplashState();
  }

  void _listenToSplashState() {
    // 현재 상태 확인
    final asyncState = ref.read(splashProvider);

    asyncState.when(
      data: (state) => _handleSplashState(state),
      loading: () {
        // 로딩 중이면 다음 빌드에서 다시 확인
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !_isNavigating) {
            _listenToSplashState();
          }
        });
      },
      error: (error, stack) {
        if (kDebugMode) {
          print('[Splash] Error: $error');
        }
        // 에러 시 온보딩으로
        _navigateTo(Routes.onboarding);
      },
    );
  }

  void _handleSplashState(SplashState state) {
    if (_isNavigating) return;

    if (kDebugMode) {
      print('[Splash] State: ${state.status.name}');
      if (state.profile != null) {
        print('[Splash] Profile: ${state.profile!.displayName}');
      }
      if (state.isFromCache) {
        print('[Splash] Data from cache');
      }
    }

    switch (state.status) {
      case PrefetchStatus.hasData:
      case PrefetchStatus.offline:
        // 데이터 있음 → 메인 화면
        _navigateTo(Routes.menu);

      case PrefetchStatus.noProfile:
        // 신규 사용자 → 온보딩
        _navigateTo(Routes.onboarding);

      case PrefetchStatus.noAnalysis:
        // 프로필은 있지만 분석 없음
        // TODO: 분석 계산 화면으로 이동하거나 자동 계산
        // 일단 메인으로 이동 (메인에서 분석 트리거)
        _navigateTo(Routes.menu);

      case PrefetchStatus.loading:
        // 아직 로딩 중 - 대기
        break;

      case PrefetchStatus.error:
        // 에러 → 온보딩 (재시도 가능)
        _navigateTo(Routes.onboarding);
    }
  }

  void _navigateTo(String route) {
    if (_isNavigating || !mounted) return;

    setState(() {
      _isNavigating = true;
    });

    // 부드러운 전환을 위해 약간의 딜레이
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        context.go(route);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provider 상태 watch (자동 rebuild)
    final asyncState = ref.watch(splashProvider);
    final theme = context.appTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: MysticBackground(
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 로고 아이콘
                  _buildLogo(context, theme),
                  const SizedBox(height: 24),

                  // 앱 이름
                  Text(
                    'common.appName'.tr(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 앱 설명
                  Text(
                    'common.appDescription'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 로딩 상태 표시
                  _buildLoadingIndicator(context, asyncState, theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, AppThemeExtension theme) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor,
            theme.accentColor ?? theme.primaryColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        Icons.auto_awesome,
        size: 50,
        color: theme.textPrimary,
      ),
    );
  }

  Widget _buildLoadingIndicator(
    BuildContext context,
    AsyncValue<SplashState> asyncState,
    AppThemeExtension theme,
  ) {
    return asyncState.when(
      data: (state) {
        final statusText = _getStatusText(state.status);
        return Column(
          children: [
            if (state.status == PrefetchStatus.loading)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.primaryColor,
                ),
              )
            else
              Icon(
                _getStatusIcon(state.status),
                color: theme.primaryColor,
                size: 24,
              ),
            const SizedBox(height: 12),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                color: theme.textMuted,
              ),
            ),
          ],
        );
      },
      loading: () => Column(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'splash.loading'.tr(),
            style: TextStyle(
              fontSize: 12,
              color: theme.textMuted,
            ),
          ),
        ],
      ),
      error: (error, stack) => Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            'splash.connectionError'.tr(),
            style: TextStyle(
              fontSize: 12,
              color: theme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(PrefetchStatus status) {
    switch (status) {
      case PrefetchStatus.loading:
        return 'splash.loading'.tr();
      case PrefetchStatus.hasData:
        return 'splash.ready'.tr();
      case PrefetchStatus.noProfile:
        return 'splash.newJourney'.tr();
      case PrefetchStatus.noAnalysis:
        return 'splash.analyzing'.tr();
      case PrefetchStatus.offline:
        return 'splash.offline'.tr();
      case PrefetchStatus.error:
        return 'splash.connectionError'.tr();
    }
  }

  IconData _getStatusIcon(PrefetchStatus status) {
    switch (status) {
      case PrefetchStatus.loading:
        return Icons.hourglass_empty;
      case PrefetchStatus.hasData:
        return Icons.check_circle_outline;
      case PrefetchStatus.noProfile:
        return Icons.person_add_outlined;
      case PrefetchStatus.noAnalysis:
        return Icons.analytics_outlined;
      case PrefetchStatus.offline:
        return Icons.cloud_off_outlined;
      case PrefetchStatus.error:
        return Icons.error_outline;
    }
  }
}
