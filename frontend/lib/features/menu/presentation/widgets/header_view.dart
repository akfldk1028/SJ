import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// 헤더 뷰 - 환영 메시지 및 날짜 표시
///
/// 위젯 트리 최적화:
/// - const 생성자 사용
/// - 100줄 이하 유지
/// - 애니메이션 별도 처리
/// - 테마 시스템 사용
class HeaderView extends StatelessWidget {
  final AnimationController animationController;

  const HeaderView({
    super.key,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.1, 0.3, curve: Curves.fastOutSlowIn),
      ),
    );

    return AnimatedBuilder(
      animation: headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1.0 - headerAnimation.value)),
          child: Opacity(
            opacity: headerAnimation.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GreetingText(theme: theme),
            const SizedBox(height: 8),
            _DateDisplay(theme: theme),
          ],
        ),
      ),
    );
  }
}

/// 환영 메시지 위젯
class _GreetingText extends StatelessWidget {
  final AppThemeExtension theme;

  const _GreetingText({required this.theme});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'menu.goodMorning'.tr()
        : hour < 18
            ? 'menu.goodAfternoon'.tr()
            : 'menu.goodEvening'.tr();

    return Text(
      greeting,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: theme.textPrimary,
        height: 1.2,
      ),
    );
  }
}

/// 날짜 표시 위젯
/// - 테마 시스템 사용
class _DateDisplay extends StatelessWidget {
  final AppThemeExtension theme;

  const _DateDisplay({required this.theme});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekdayKeys = [
      'menu.weekday_mon', 'menu.weekday_tue', 'menu.weekday_wed',
      'menu.weekday_thu', 'menu.weekday_fri', 'menu.weekday_sat', 'menu.weekday_sun',
    ];
    final weekday = weekdayKeys[now.weekday - 1].tr();
    final formattedDate = 'menu.dateFullFormat'.tr(namedArgs: {
      'year': '${now.year}',
      'month': '${now.month}',
      'day': '${now.day}',
      'weekday': weekday,
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.textPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.textPrimary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today,
            size: 14,
            color: theme.accentColor ?? theme.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            formattedDate,
            style: TextStyle(
              fontSize: 13,
              color: theme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
