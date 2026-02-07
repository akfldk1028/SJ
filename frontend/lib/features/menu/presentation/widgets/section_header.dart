import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';

/// Section header - 반응형 폰트 적용
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final titleSize = context.scaledFont(16);
    final subtitleSize = context.scaledFont(12);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.scaledPadding(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: subtitleSize,
                    color: theme.textMuted,
                  ),
                ),
            ],
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'menu.seeAll'.tr(),
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: theme.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
