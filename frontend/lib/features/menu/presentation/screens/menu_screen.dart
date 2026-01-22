import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../ad/ad.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/mystic_background.dart';
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

  /// 모바일 플랫폼 체크 (광고 표시용)
  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

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
                  SizedBox(height: context.scaledPadding(24)),
                  // 오늘의 운세 섹션 - 내 사주 위로 이동
                  const SectionHeader(
                    title: '오늘의 운세',
                  ),
                  SizedBox(height: context.scaledPadding(12)),
                  const FortuneCategoryList(),
                  SizedBox(height: context.scaledPadding(24)),
                  // 내 사주 카드
                  const SajuMiniCard(),
                  SizedBox(height: context.scaledPadding(24)),
                  // Native 광고 1 (사주 카드 아래) - 즉시 로드
                  if (_isMobile) const CardNativeAdWidget(loadDelayMs: 0),
                  if (_isMobile) SizedBox(height: context.scaledPadding(24)),
                  // Native 광고 2 - 500ms 지연
                  if (_isMobile) const CardNativeAdWidget(loadDelayMs: 500),
                  if (_isMobile) SizedBox(height: context.scaledPadding(24)),
                  // TODO: 2025 신년운세/토정비결 - 임시 비활성화
                  // const SectionHeader(
                  //   title: '오늘의 조언',
                  // ),
                  // SizedBox(height: context.scaledPadding(12)),
                  // const DailyAdviceSection(),
                  // SizedBox(height: context.scaledPadding(24)),
                  const TodayMessageCard(),
                  SizedBox(height: context.scaledPadding(24)),
                  // Native 광고 3 (맨 하단) - 1000ms 지연
                  if (_isMobile) const CardNativeAdWidget(loadDelayMs: 1000),
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
