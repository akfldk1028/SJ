import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../widgets/section_header.dart';
import '../widgets/fortune_summary_card.dart';
import 'package:frontend/features/saju_chart/presentation/widgets/saju_mini_card.dart';
import '../widgets/fortune_category_list.dart';
import '../widgets/daily_advice_section.dart';

/// Main menu screen - 기존 레이아웃 + 새 디자인 스타일
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
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
      body: MysticBackground(
        child: SafeArea(
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
                    const SectionHeader(
                      title: '오늘의 운세',
                      actionText: '전체보기',
                    ),
                    const SizedBox(height: 12),
                    const FortuneCategoryList(),
                    const SizedBox(height: 24),
                    const SectionHeader(
                      title: '오늘의 조언',
                    ),
                    const SizedBox(height: 12),
                    const DailyAdviceSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(theme),
    );
  }

  Widget _buildAppBar(AppThemeExtension theme) {
    final formattedDate = _formatDate(_selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Menu button - 설정 화면으로 이동
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.15),
                ),
              ),
              child: Icon(
                Icons.menu_rounded,
                color: theme.textSecondary,
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
                    Flexible(
                      child: Text(
                        formattedDate['full']!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
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
          // User info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '김은지님',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '본인',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textMuted,
                  ),
                ),
              ],
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
        border: Border(
          top: BorderSide(
            color: theme.primaryColor.withOpacity(theme.isDark ? 0.1 : 0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.isDark ? 0.2 : 0.08),
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
