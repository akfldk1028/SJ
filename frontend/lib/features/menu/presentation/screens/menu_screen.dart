import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../../../../purchase/providers/purchase_provider.dart';
import '../../../../purchase/widgets/premium_badge_widget.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../widgets/ai_chat_cta_card.dart';
import '../widgets/section_header.dart';
import '../widgets/fortune_summary_card.dart';
import 'package:frontend/features/saju_chart/presentation/widgets/saju_mini_card.dart';
import '../widgets/fortune_category_list.dart';

/// Main menu screen - 테마 적용
class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  DateTime _selectedDate = DateTime.now();

  // TODO: 이전/다음 날짜 기능 - 추후 구현
  // void _previousDay() {
  //   setState(() {
  //     _selectedDate = _selectedDate.subtract(const Duration(days: 1));
  //   });
  // }

  // void _nextDay() {
  //   setState(() {
  //     _selectedDate = _selectedDate.add(const Duration(days: 1));
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Column(
        children: [
          // 상태바 영역을 배경색으로 채움
          Container(
            height: statusBarHeight,
            color: theme.backgroundColor,
          ),
          // 앱바
          _buildAppBar(theme),
          // 나머지 콘텐츠
          Expanded(
            child: MysticBackground(
              child: ListView(
                padding: EdgeInsets.only(bottom: context.scaledPadding(100)),
                children: [
                  const FortuneSummaryCard(),
                  SizedBox(height: context.scaledPadding(16)),
                  // 오늘의 운세 섹션 - 내 사주 위로 이동
                  const SectionHeader(
                    title: '오늘의 운세',
                  ),
                  SizedBox(height: context.scaledPadding(8)),
                  const FortuneCategoryList(),
                  SizedBox(height: context.scaledPadding(16)),
                  const AiChatCtaCard(),
                  SizedBox(height: context.scaledPadding(16)),
                  // 내 사주 카드
                  const SajuMiniCard(),
                  // 오늘의 한마디는 FortuneSummaryCard 내 시간대별 운세 아래에 배치됨
                ],
              ),
            ),
          ),
        ],
      ),
      // bottomNavigationBar는 MainShell에서 제공 (ShellRoute)
    );
  }

  Widget _buildAppBar(AppThemeExtension theme) {
    final formattedDate = _formatDate(_selectedDate);
    final activeProfileAsync = ref.watch(activeProfileProvider);
    final horizontalPadding = context.horizontalPadding;
    final isSmall = context.isSmallMobile;

    // 프리미엄 상태 확인 (상태 변경 감지 + 값 읽기)
    ref.watch(purchaseNotifierProvider); // 상태 변경 시 rebuild
    final isPremium = ref.read(purchaseNotifierProvider.notifier).isPremium;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isSmall ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
      ),
      child: Row(
        children: [
          // 비프리미엄: 프리미엄 버튼 → Paywall
          // 프리미엄: 숨김
          if (!isPremium) ...[
            GestureDetector(
              onTap: () => context.push('/settings/premium'),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.primaryColor.withValues(alpha: 0.3),
                  ),
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
                  Icons.workspace_premium_rounded,
                  color: theme.primaryColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          // Date section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '운세',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const PremiumBadgeWidget(),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate['full']!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
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

  Map<String, String> _formatDate(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];

    return {
      'full': '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ($weekday)',
    };
  }
}
