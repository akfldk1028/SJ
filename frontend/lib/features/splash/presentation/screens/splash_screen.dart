import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  bool _minDelayCompleted = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startMinDelay();
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

  Future<void> _startMinDelay() async {
    // 최소 대기 (애니메이션 + 브랜딩)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    _minDelayCompleted = true;

    // 딜레이 끝났을 때 이미 데이터가 준비되어 있으면 즉시 네비게이션
    final asyncState = ref.read(splashProvider);
    asyncState.when(
      data: (state) => _handleSplashState(state),
      loading: () {}, // ref.listen이 이후 변경 감지
      error: (error, stack) {
        if (kDebugMode) {
          print('[Splash] Error: $error');
        }
        _navigateTo(Routes.zodiacOnboarding);
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
        // 신규 사용자 → zodiac 페르소나 온보딩 (Apple 4.3b 통과 위해 모든 언어 통일)
        _navigateTo(Routes.zodiacOnboarding);

      case PrefetchStatus.noAnalysis:
        // 프로필은 있지만 분석 없음
        // TODO: 분석 계산 화면으로 이동하거나 자동 계산
        // 일단 메인으로 이동 (메인에서 분석 트리거)
        _navigateTo(Routes.menu);

      case PrefetchStatus.loading:
        // 아직 로딩 중 - 대기
        break;

      case PrefetchStatus.error:
        // 에러 → zodiac 온보딩 (재시도 가능)
        _navigateTo(Routes.zodiacOnboarding);
    }
  }

  void _navigateTo(String route) {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    context.go(route);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provider 상태 watch (자동 rebuild — 로딩 인디케이터용)
    final asyncState = ref.watch(splashProvider);

    // ref.listen: 상태 변경 시 네비게이션 (폴링 대신 Riverpod 공식 패턴)
    ref.listen(splashProvider, (previous, next) {
      if (!_minDelayCompleted || _isNavigating) return;
      next.when(
        data: (state) => _handleSplashState(state),
        loading: () {},
        error: (error, stack) {
          if (kDebugMode) {
            print('[Splash] Error: $error');
          }
          _navigateTo(Routes.zodiacOnboarding);
        },
      );
    });

    // 스플래시는 로고(검정)에 맞춰 항상 흰색 배경 + 고정 색상
    const splashText = Color(0xFF1A1A1A);
    const splashMuted = Color(0xFF8E8E8E);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                _buildLogo(context),
                const SizedBox(height: 24),

                // 앱 이름 (비한국어는 로고에 텍스트 포함이라 생략)
                if (context.locale.languageCode == 'ko') ...[
                  const Text(
                    '사담',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: splashText,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // 앱 설명
                Text(
                  'common.appDescription'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: splashMuted,
                  ),
                ),

                const SizedBox(height: 48),

                // 로딩 상태 표시
                _buildLoadingIndicator(context, asyncState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    // 로고는 검정색 — 흰 배경에 맞춤
    if (context.locale.languageCode != 'ko') {
      return Image.asset(
        'assets/images/logo_global.png',
        width: 220,
        height: 220,
        color: const Color(0xFF1A1A1A),
      );
    }

    // 한국어: 그라데이션 원형 로고
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5D4E37),
            Color(0xFF8B7355),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D4E37).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome,
        size: 50,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLoadingIndicator(
    BuildContext context,
    AsyncValue<SplashState> asyncState,
  ) {
    const accent = Color(0xFF5D4E37);
    const muted = Color(0xFF8E8E8E);

    return asyncState.when(
      data: (state) {
        final statusText = _getStatusText(state.status);
        return Column(
          children: [
            if (state.status == PrefetchStatus.loading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accent,
                ),
              )
            else
              Icon(
                _getStatusIcon(state.status),
                color: accent,
                size: 24,
              ),
            const SizedBox(height: 12),
            Text(
              statusText,
              style: const TextStyle(
                fontSize: 12,
                color: muted,
              ),
            ),
          ],
        );
      },
      loading: () => Column(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: accent,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'splash.loading'.tr(),
            style: const TextStyle(
              fontSize: 12,
              color: muted,
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
            style: const TextStyle(
              fontSize: 12,
              color: muted,
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
