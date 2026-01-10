import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../../../../router/routes.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../saju_chart/presentation/widgets/saju_mini_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final myProfileAsync = ref.watch(activeProfileProvider);
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
                _buildFortuneCard(theme),

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
                _buildCategoryList(theme),

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
                _buildAdviceCard(theme),

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

  Widget _buildFortuneCard(AppThemeExtension theme) {
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
            Padding(
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
                          Text(
                            '대길(大吉)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: theme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '🌕',
                        style: TextStyle(fontSize: 40),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Score
                  Text(
                    '85',
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

                  const SizedBox(height: 16),

                  // Progress bars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final isFilled = index < 4;
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(AppThemeExtension theme) {
    final categories = [
      {'icon': '💰', 'name': '재물운', 'score': 92},
      {'icon': '💕', 'name': '애정운', 'score': 78},
      {'icon': '💼', 'name': '직장운', 'score': 85},
      {'icon': '🏥', 'name': '건강운', 'score': 70},
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Container(
            width: 90,
            margin: EdgeInsets.only(right: index < categories.length - 1 ? 12 : 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.cardColor,
                  theme.cardColor.withValues(alpha:0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha:0.1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cat['icon'] as String,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  cat['name'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${cat['score']}점',
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
      ),
    );
  }

  Widget _buildAdviceCard(AppThemeExtension theme) {
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha:0.15),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 20,
              right: 20,
              child: Text(
                '🪷',
                style: TextStyle(fontSize: 24, color: Colors.white.withValues(alpha:0.6)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '"오늘은 새로운 시작에 좋은 날입니다.\n중요한 결정을 내리기에 적합하며,\n대인관계에서 좋은 소식이 있을 수 있습니다."',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: theme.textSecondary,
                  height: 1.8,
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
