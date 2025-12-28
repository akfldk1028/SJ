import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../ad/ad.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../widgets/section_header.dart';
import '../widgets/fortune_summary_card.dart';
import 'package:frontend/features/saju_chart/presentation/widgets/saju_mini_card.dart';
import '../widgets/fortune_category_list.dart';
import '../widgets/daily_advice_section.dart';
import '../widgets/today_message_card.dart';

/// Main menu screen - 테마 적용
class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  DateTime _selectedDate = DateTime.now();

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(theme),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  const FortuneSummaryCard(),
                  const SizedBox(height: 24),
                  const SajuMiniCard(),
                  const SizedBox(height: 24),
                  // Native 광고 1 (사주 카드 아래) - 즉시 로드
                  if (!kIsWeb) const CardNativeAdWidget(loadDelayMs: 0),
                  if (!kIsWeb) const SizedBox(height: 24),
                  const SectionHeader(
                    title: '오늘의 운세',
                  ),
                  const SizedBox(height: 12),
                  const FortuneCategoryList(),
                  const SizedBox(height: 24),
                  // Native 광고 2 - 500ms 지연
                  if (!kIsWeb) const CardNativeAdWidget(loadDelayMs: 500),
                  if (!kIsWeb) const SizedBox(height: 24),
                  const SectionHeader(
                    title: '오늘의 조언',
                  ),
                  const SizedBox(height: 12),
                  const DailyAdviceSection(),
                  const SizedBox(height: 24),
                  const TodayMessageCard(),
                  const SizedBox(height: 24),
                  // Native 광고 3 (맨 하단) - 1000ms 지연
                  if (!kIsWeb) const CardNativeAdWidget(loadDelayMs: 1000),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(theme),
    );
  }

  Widget _buildAppBar(AppThemeExtension theme) {
    final formattedDate = _formatDate(_selectedDate);
    final activeProfileAsync = ref.watch(activeProfileProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
      ),
      child: Row(
        children: [
          // Menu button - 설정 화면으로 이동
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.isDark
                        ? const Color.fromRGBO(0, 0, 0, 0.3)
                        : const Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.menu_rounded,
                color: theme.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Date section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '운세',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      formattedDate['full']!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _previousDay,
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: theme.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: _nextDay,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // User info - 실제 프로필 연동
          GestureDetector(
            onTap: () => context.push('/profile/select'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.isDark
                        ? const Color.fromRGBO(0, 0, 0, 0.3)
                        : const Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: activeProfileAsync.when(
                loading: () => Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '로딩...',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textMuted,
                      ),
                    ),
                  ],
                ),
                error: (_, _) => Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: theme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '프로필 없음',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textMuted,
                      ),
                    ),
                  ],
                ),
                data: (profile) {
                  if (profile == null) {
                    return Row(
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '프로필 추가',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.textPrimary,
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${profile.displayName}님',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        profile.relationType.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: theme.textMuted,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(AppThemeExtension theme) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.isDark
                ? const Color.fromRGBO(0, 0, 0, 0.3)
                : const Color.fromRGBO(0, 0, 0, 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(theme, Icons.auto_awesome_rounded, '운세', true, null),
          _buildNavItem(theme, Icons.chat_bubble_outline_rounded, 'AI 상담', false, () {
            context.push('/saju/chat');
          }),
          _buildNavItem(theme, Icons.people_outline_rounded, '인맥', false, () {
            context.push('/relationships');
          }),
          _buildNavItem(theme, Icons.settings_outlined, '설정', false, () {
            context.push('/settings');
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(AppThemeExtension theme, IconData icon, String label, bool isActive, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? theme.primaryColor : theme.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? theme.primaryColor : theme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _formatDate(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];

    return {
      'full': '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ($weekday)',
    };
  }
}
