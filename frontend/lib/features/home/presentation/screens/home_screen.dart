import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../../../../router/routes.dart';
import '../../../menu/presentation/providers/daily_fortune_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../saju_chart/presentation/widgets/saju_mini_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final myProfileAsync = ref.watch(activeProfileProvider);
    final dailyFortuneAsync = ref.watch(dailyFortuneProvider);
    final today = DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(DateTime.now());

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: MysticBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                              '오늘의 운세',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.textMuted,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  today,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: theme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '◀ ▶',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // User Chip
                      myProfileAsync.when(
                        data: (profile) => _buildUserChip(
                          theme,
                          profile?.displayName ?? '프로필',
                          () => context.push(Routes.profileEdit),
                        ),
                        loading: () => _buildUserChip(theme, '로딩...', () {}),
                        error: (_, __) => _buildUserChip(theme, '프로필', () {}),
                      ),
                    ],
                  ),
                ),

                // Fortune Card (오늘의 총운)
                _buildFortuneCard(theme, dailyFortuneAsync),

                const SizedBox(height: 24),

                // Section Header - 오늘의 운세
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '오늘의 운세',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: theme.textPrimary,
                        ),
                      ),
                      Text(
                        '전체보기',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Category Fortune List (재물운, 애정운, 직장운, 건강운)
                _buildCategoryList(theme, dailyFortuneAsync),

                const SizedBox(height: 24),

                // Saju Mini Card (나의 사주팔자)
                myProfileAsync.when(
                  data: (profile) {
                    if (profile != null) {
                      return GestureDetector(
                        onTap: () => context.push(Routes.sajuChart),
                        child: const SajuMiniCard(),
                      );
                    }
                    return _buildNoProfileCard(theme, context);
                  },
                  loading: () => _buildLoadingCard(theme),
                  error: (_, __) => _buildNoProfileCard(theme, context),
                ),

                const SizedBox(height: 28),

                // Section Header - 오늘의 조언
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '오늘의 조언',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Advice Card
                _buildAdviceCard(theme, dailyFortuneAsync),

                const SizedBox(height: 100), // Bottom nav spacing
              ],
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

  Widget _buildFortuneCard(AppThemeExtension theme, AsyncValue<DailyFortuneData?> fortuneAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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

                // 점수 기반 운세 등급
                String gradeText;
                String gradeEmoji;
                if (score >= 90) {
                  gradeText = '대길(大吉)';
                  gradeEmoji = '🌕';
                } else if (score >= 75) {
                  gradeText = '길(吉)';
                  gradeEmoji = '🌔';
                } else if (score >= 60) {
                  gradeText = '소길(小吉)';
                  gradeEmoji = '🌓';
                } else if (score >= 45) {
                  gradeText = '보통(普通)';
                  gradeEmoji = '🌗';
                } else {
                  gradeText = '주의(注意)';
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
                                '오늘의 총운',
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
                                  '운세 분석 중...',
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
                                  '종합 운세 점수',
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
                    '오늘의 총운',
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
            '운세 분석 중...',
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
            '운세를 불러올 수 없습니다',
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

  Widget _buildCategoryList(AppThemeExtension theme, AsyncValue<DailyFortuneData?> fortuneAsync) {
    // 카테고리 키 매핑 (DB key -> 표시명)
    const categoryMap = [
      {'key': 'money', 'icon': '💰', 'name': '재물운'},
      {'key': 'love', 'icon': '💕', 'name': '애정운'},
      {'key': 'career', 'icon': '💼', 'name': '직장운'},
      {'key': 'health', 'icon': '🏥', 'name': '건강운'},
    ];

    return SizedBox(
      height: 120,
      child: fortuneAsync.when(
        data: (fortune) {
          final isLoading = fortune == null;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categoryMap.length,
            itemBuilder: (context, index) {
              final cat = categoryMap[index];
              final score = isLoading ? 0 : fortune.getCategoryScore(cat['key']!);

              return Container(
                width: 90,
                margin: EdgeInsets.only(right: index < categoryMap.length - 1 ? 12 : 0),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cat['icon']!,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      cat['name']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
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
                            '$score점',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.primaryColor,
                            ),
                          ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => _buildCategoryListLoading(theme, categoryMap.length),
        error: (e, _) => _buildCategoryListLoading(theme, categoryMap.length),
      ),
    );
  }

  Widget _buildCategoryListLoading(AppThemeExtension theme, int count) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: count,
      itemBuilder: (context, index) {
        return Container(
          width: 90,
          margin: EdgeInsets.only(right: index < count - 1 ? 12 : 0),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildShimmerBox(theme, 28, 28),
              const SizedBox(height: 10),
              _buildShimmerBox(theme, 40, 14),
              const SizedBox(height: 6),
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
      },
    );
  }

  Widget _buildAdviceCard(AppThemeExtension theme, AsyncValue<DailyFortuneData?> fortuneAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  '조언을 불러올 수 없습니다.',
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

  Widget _buildNoProfileCard(AppThemeExtension theme, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                '프로필을 등록해주세요',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '생년월일을 입력하면 사주팔자를 분석해드립니다',
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

  Widget _buildLoadingCard(AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
