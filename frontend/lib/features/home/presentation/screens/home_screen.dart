import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../ad/ad_network_resolver.dart';
import '../../../../ad/adfit/adfit_banner_ad_widget.dart';
import '../../../../ad/widgets/banner_ad_widget.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../../../../router/routes.dart';
import '../../../menu/presentation/providers/daily_fortune_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../saju_chart/presentation/widgets/saju_mini_card.dart';
import '../../../../purchase/providers/purchase_provider.dart';
import '../../../../purchase/widgets/premium_badge_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final myProfileAsync = ref.watch(activeProfileProvider);
    final dailyFortuneAsync = ref.watch(dailyFortuneProvider);
    ref.watch(purchaseNotifierProvider); // 프리미엄 상태 변경 시 리빌드
    final today = DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(DateTime.now());

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: MysticBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Builder(
              builder: (context) {
                // 반응형 패딩
                final horizontalPadding = context.horizontalPadding;
                final isSmall = context.isSmallMobile;

                return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isSmall ? 12 : 16),
                  child: Row(
                    children: [
                      // Menu Button
                      _buildIconButton(theme, Icons.menu, () {}),
                      const SizedBox(width: 16),
                      // Date Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'menu.todayFortune'.tr(),
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.textMuted,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    today,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: theme.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const PremiumBadgeWidget(),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // User Chip
                      myProfileAsync.when(
                        data: (profile) => _buildUserChip(
                          theme,
                          profile?.displayName ?? 'menu.profile'.tr(),
                          () {
                            // 프로필 있으면 수정 모드, 없으면 신규 생성 모드
                            if (profile != null) {
                              context.push('${Routes.profileEdit}?profileId=${profile.id}');
                            } else {
                              context.push(Routes.profileEdit);
                            }
                          },
                        ),
                        loading: () => _buildUserChip(theme, 'menu.loading'.tr(), () {}),
                        error: (_, __) => _buildUserChip(theme, 'menu.profile'.tr(), () {}),
                      ),
                    ],
                  ),
                ),

                // Fortune Card (오늘의 총운 + 사자성어 통합)
                _buildFortuneCard(context, theme, dailyFortuneAsync, horizontalPadding),

                SizedBox(height: isSmall ? 20 : 24),

                // Section Header - 오늘의 운세
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'menu.todayFortune'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: theme.textPrimary,
                        ),
                      ),
                      Text(
                        'menu.seeAll'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isSmall ? 12 : 16),

                // Category Fortune List (재물운, 애정운, 직장운, 건강운)
                _buildCategoryList(context, theme, dailyFortuneAsync, horizontalPadding),

                SizedBox(height: isSmall ? 20 : 24),

                // Saju Mini Card (나의 사주팔자)
                myProfileAsync.when(
                  data: (profile) {
                    if (profile != null) {
                      return GestureDetector(
                        onTap: () => context.push(Routes.sajuChart),
                        child: const SajuMiniCard(),
                      );
                    }
                    return _buildNoProfileCard(theme, context, horizontalPadding);
                  },
                  loading: () => _buildLoadingCard(theme, horizontalPadding),
                  error: (_, __) => _buildNoProfileCard(theme, context, horizontalPadding),
                ),

                SizedBox(height: isSmall ? 24 : 28),

                // Section Header - 오늘의 조언
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Text(
                    'daily_fortune.todayAdvice'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.textPrimary,
                    ),
                  ),
                ),

                SizedBox(height: isSmall ? 12 : 16),

                // Advice Card
                _buildAdviceCard(theme, dailyFortuneAsync, horizontalPadding),

                SizedBox(height: isSmall ? 16 : 20),

                // 배너 광고 (Web 제외, 프리미엄 유저 제외)
                // AdFit primary (Android) → AdMob fallback
                Builder(builder: (_) {
                  final showAds = ref.read(purchaseNotifierProvider.notifier).showAds;
                  debugPrint('[HomeScreen] kIsWeb=$kIsWeb, showAds=$showAds');
                  return const SizedBox.shrink();
                }),
                if (!kIsWeb && ref.read(purchaseNotifierProvider.notifier).showAds)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: const _HomeBannerAd(),
                  ),

                const SizedBox(height: 100), // Bottom nav spacing
              ],
            );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(AppThemeExtension theme, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.cardColor,
              theme.cardColor.withValues(alpha:0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha:0.15),
          ),
        ),
        child: Icon(
          icon,
          color: theme.primaryColor,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildUserChip(AppThemeExtension theme, String name, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.cardColor,
              theme.cardColor.withValues(alpha:0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha:0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person,
              color: theme.primaryColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                color: theme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFortuneCard(BuildContext context, AppThemeExtension theme, AsyncValue<DailyFortuneData?> fortuneAsync, double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.cardColor,
              theme.cardColor.withValues(alpha:0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha:0.2),
          ),
        ),
        child: Stack(
          children: [
            // Radial gradient overlay
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.primaryColor.withValues(alpha:0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            fortuneAsync.when(
              data: (fortune) {
                // fortune이 null이면 분석 중
                final score = fortune?.overallScore ?? 0;
                final message = fortune?.overallMessage ?? '';
                final isLoading = fortune == null;

                // 디버그: idiom 상태 확인
                debugPrint('[HomeScreen] fortune: ${fortune != null}, isLoading: $isLoading');
                if (fortune != null) {
                  debugPrint('[HomeScreen] idiom.korean: "${fortune.idiom.korean}", isValid: ${fortune.idiom.isValid}');
                }

                // 점수 기반 운세 등급
                String gradeText;
                String gradeEmoji;
                if (score >= 90) {
                  gradeText = 'daily_fortune.gradeGreat'.tr();
                  gradeEmoji = '🌕';
                } else if (score >= 75) {
                  gradeText = 'daily_fortune.gradeGood'.tr();
                  gradeEmoji = '🌔';
                } else if (score >= 60) {
                  gradeText = 'daily_fortune.gradeSmallGood'.tr();
                  gradeEmoji = '🌓';
                } else if (score >= 45) {
                  gradeText = 'daily_fortune.gradeNormal'.tr();
                  gradeEmoji = '🌗';
                } else {
                  gradeText = 'daily_fortune.gradeCaution'.tr();
                  gradeEmoji = '🌑';
                }

                return Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'daily_fortune.todayOverall'.tr(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textMuted,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              isLoading
                                  ? _buildShimmerBox(theme, 80, 22)
                                  : Text(
                                      gradeText,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: theme.textPrimary,
                                      ),
                                    ),
                            ],
                          ),
                          Text(
                            isLoading ? '✨' : gradeEmoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Score
                      isLoading
                          ? Column(
                              children: [
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: theme.primaryColor.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'daily_fortune.fortuneAnalyzing'.tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.textMuted,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Text(
                                  '$score',
                                  style: TextStyle(
                                    fontSize: 72,
                                    fontWeight: FontWeight.w700,
                                    foreground: Paint()
                                      ..shader = LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          theme.primaryColor,
                                          theme.accentColor ?? theme.primaryColor,
                                          theme.primaryColor,
                                        ],
                                      ).createShader(const Rect.fromLTWH(0, 0, 100, 80)),
                                  ),
                                ),
                                Text(
                                  'daily_fortune.overallScore'.tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.textMuted,
                                  ),
                                ),
                              ],
                            ),

                      const SizedBox(height: 16),

                      // Progress bars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final filledCount = isLoading ? 0 : (score / 20).ceil().clamp(0, 5);
                          final isFilled = index < filledCount;
                          return Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: isFilled
                                  ? LinearGradient(
                                      colors: [
                                        theme.primaryColor,
                                        theme.accentColor ?? theme.primaryColor,
                                      ],
                                    )
                                  : null,
                              color: isFilled ? null : theme.textMuted.withValues(alpha:0.2),
                            ),
                          );
                        }),
                      ),

                      // 사자성어 섹션 (점수 아래 - 텍스트만)
                      // 무조건 표시 (디버그용)
                      const SizedBox(height: 20),
                      Text(
                        fortune?.idiom.korean ?? '사자성어없음',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${fortune?.idiom.chinese ?? ''} · ${fortune?.idiom.meaning ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => _buildFortuneCardLoading(theme),
              error: (e, _) => _buildFortuneCardError(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFortuneCardLoading(AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'daily_fortune.todayOverall'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildShimmerBox(theme, 80, 22),
                ],
              ),
              const Text('✨', style: TextStyle(fontSize: 40)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.primaryColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'daily_fortune.fortuneAnalyzing'.tr(),
            style: TextStyle(fontSize: 14, color: theme.textMuted),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: theme.textMuted.withValues(alpha: 0.2),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFortuneCardError(AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.textMuted),
          const SizedBox(height: 16),
          Text(
            'daily_fortune.errorLoadFortune'.tr(),
            style: TextStyle(fontSize: 14, color: theme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox(AppThemeExtension theme, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: theme.textMuted.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, AppThemeExtension theme, AsyncValue<DailyFortuneData?> fortuneAsync, double horizontalPadding) {
    // 카테고리 키 매핑 (DB key -> 표시명)
    // NOTE: DB는 'wealth', 'work' 키 사용 (money/career X)
    final categoryMap = [
      {'key': 'wealth', 'icon': '💰', 'name': 'common.category_wealth'.tr()},
      {'key': 'love', 'icon': '💕', 'name': 'common.category_love'.tr()},
      {'key': 'work', 'icon': '💼', 'name': 'common.category_work'.tr()},
      {'key': 'health', 'icon': '🏥', 'name': 'common.category_health'.tr()},
    ];

    // 반응형: 고정 높이 대신 IntrinsicHeight로 콘텐츠에 맞춤
    final isSmall = context.isSmallMobile;
    final cardWidth = isSmall ? 80.0 : 90.0;

    return fortuneAsync.when(
      data: (fortune) {
        final isLoading = fortune == null;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: List.generate(categoryMap.length, (index) {
              final cat = categoryMap[index];
              final score = isLoading ? 0 : fortune.getCategoryScore(cat['key']!);

              return Container(
                width: cardWidth,
                margin: EdgeInsets.only(right: index < categoryMap.length - 1 ? (isSmall ? 10 : 12) : 0),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.cardColor,
                      theme.cardColor.withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cat['icon']!,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat['name']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.primaryColor.withValues(alpha: 0.5),
                            ),
                          )
                        : Text(
                            'daily_fortune.scoreWithValue'.tr(namedArgs: {'score': '$score'}),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.primaryColor,
                            ),
                          ),
                  ],
                ),
              );
            }),
          ),
        );
      },
      loading: () => _buildCategoryListLoading(theme, categoryMap.length),
      error: (e, _) => _buildCategoryListLoading(theme, categoryMap.length),
    );
  }

  Widget _buildCategoryListLoading(AppThemeExtension theme, int count, {double horizontalPadding = 20}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: List.generate(count, (index) {
          return Container(
            width: 90,
            margin: EdgeInsets.only(right: index < count - 1 ? 12 : 0),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.cardColor,
                  theme.cardColor.withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildShimmerBox(theme, 28, 28),
                const SizedBox(height: 8),
                _buildShimmerBox(theme, 40, 14),
                const SizedBox(height: 4),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.primaryColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// 오늘의 사자성어 카드 - 모던 타이포그래피 스타일
  Widget _buildIdiomCard(AppThemeExtension theme, AsyncValue<DailyFortuneData?> fortuneAsync, double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.cardColor,
              theme.cardColor.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.15),
          ),
        ),
        child: fortuneAsync.when(
          data: (fortune) {
            final isLoading = fortune == null;
            final idiom = fortune?.idiom;

            if (isLoading || idiom == null || !idiom.isValid) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildShimmerBox(theme, 120, 32),
                    const SizedBox(height: 12),
                    _buildShimmerBox(theme, 80, 18),
                    const SizedBox(height: 16),
                    _buildShimmerBox(theme, double.infinity, 14),
                    const SizedBox(height: 8),
                    _buildShimmerBox(theme, 200, 14),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              child: Column(
                children: [
                  // 한글 (크게 강조)
                  Text(
                    idiom.korean,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: theme.textPrimary,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 한자
                  Text(
                    idiom.chinese,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: theme.textSecondary.withValues(alpha: 0.7),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 구분선
                  Container(
                    width: 40,
                    height: 2,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 뜻풀이
                  Text(
                    idiom.meaning,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // 오늘의 메시지
                  Text(
                    idiom.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textMuted,
                      height: 1.7,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
          loading: () => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildShimmerBox(theme, 120, 32),
                const SizedBox(height: 12),
                _buildShimmerBox(theme, 80, 18),
                const SizedBox(height: 16),
                _buildShimmerBox(theme, double.infinity, 14),
                const SizedBox(height: 8),
                _buildShimmerBox(theme, 200, 14),
              ],
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'daily_fortune.errorLoadIdiom'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: theme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdviceCard(AppThemeExtension theme, AsyncValue<DailyFortuneData?> fortuneAsync, double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.cardColor,
              theme.cardColor.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.15),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 20,
              right: 20,
              child: Text(
                '🪷',
                style: TextStyle(fontSize: 24, color: Colors.white.withValues(alpha: 0.6)),
              ),
            ),
            fortuneAsync.when(
              data: (fortune) {
                final isLoading = fortune == null;
                final advice = fortune?.affirmation ?? '';

                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: isLoading
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildShimmerBox(theme, double.infinity, 16),
                            const SizedBox(height: 12),
                            _buildShimmerBox(theme, 200, 16),
                            const SizedBox(height: 12),
                            _buildShimmerBox(theme, 150, 16),
                          ],
                        )
                      : Text(
                          '"$advice"',
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: theme.textSecondary,
                            height: 1.8,
                          ),
                        ),
                );
              },
              loading: () => Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(theme, double.infinity, 16),
                    const SizedBox(height: 12),
                    _buildShimmerBox(theme, 200, 16),
                    const SizedBox(height: 12),
                    _buildShimmerBox(theme, 150, 16),
                  ],
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'daily_fortune.errorLoadAdvice'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: theme.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoProfileCard(AppThemeExtension theme, BuildContext context, [double horizontalPadding = 20]) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GestureDetector(
        onTap: () => context.push(Routes.profileEdit),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.cardColor,
                theme.cardColor.withValues(alpha:0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha:0.15),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.person_add_outlined,
                size: 48,
                color: theme.primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'daily_fortune.noProfile'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'daily_fortune.noProfileDesc'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(AppThemeExtension theme, [double horizontalPadding = 20]) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: theme.primaryColor,
          ),
        ),
      ),
    );
  }
}

/// 홈 배너 광고: AdFit primary (Android) → AdMob fallback
class _HomeBannerAd extends StatefulWidget {
  const _HomeBannerAd();

  @override
  State<_HomeBannerAd> createState() => _HomeBannerAdState();
}

class _HomeBannerAdState extends State<_HomeBannerAd> {
  bool _adFitFailed = false;

  @override
  Widget build(BuildContext context) {
    debugPrint('[HomeBanner] build() called, adFitAvailable=${AdNetworkResolver.isAdFitAvailable}, adFitFailed=$_adFitFailed');

    // Android에서 AdFit 가능하고 아직 실패 안 했으면 AdFit 시도
    if (AdNetworkResolver.isAdFitAvailable && !_adFitFailed) {
      return Center(
        child: AdFitBannerAdWidget(
          onFailed: () {
            debugPrint('[HomeBanner] AdFit failed → AdMob fallback');
            if (mounted) setState(() => _adFitFailed = true);
          },
        ),
      );
    }
    // AdFit 미지원 or 실패 → AdMob 배너
    debugPrint('[HomeBanner] Using AdMob banner fallback');
    return const BannerAdWidget();
  }
}
