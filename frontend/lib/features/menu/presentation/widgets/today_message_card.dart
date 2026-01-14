import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../providers/daily_fortune_provider.dart';

/// Today message card - AI 데이터 연동
class TodayMessageCard extends ConsumerWidget {
  const TodayMessageCard({super.key});

  static const _shadowLight = Color.fromRGBO(0, 0, 0, 0.06);
  static const _shadowDark = Color.fromRGBO(0, 0, 0, 0.3);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;

    final affirmation = ref.watch(
      dailyFortuneProvider.select((asyncValue) {
        return asyncValue.whenData((data) => data?.affirmation);
      }),
    );

    return affirmation.when(
      loading: () => _buildCard(context, theme, '오늘의 메시지를 불러오는 중...'),
      error: (_, __) => _buildCard(context, theme, '메시지를 불러올 수 없습니다.'),
      data: (message) => _buildCard(
        context,
        theme,
        message ?? '긍정적인 마음으로 하루를 시작하세요!',
      ),
    );
  }

  Widget _buildCard(BuildContext context, AppThemeExtension theme, String message) {
    final scale = context.scaleFactor;
    final iconBoxSize = (40 * scale).clamp(36.0, 52.0);
    final iconSize = context.scaledIcon(22);
    final titleSize = context.scaledFont(12);
    final messageSize = context.scaledFont(15);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.scaledPadding(20)),
      child: Container(
        padding: EdgeInsets.all(context.scaledPadding(20)),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.isDark ? _shadowDark : _shadowLight,
              offset: const Offset(0, 4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: theme.primaryColor,
                    size: iconSize,
                  ),
                ),
                SizedBox(width: context.scaledPadding(12)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.scaledPadding(10),
                    vertical: context.scaledPadding(4),
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '오늘의 한마디',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.scaledPadding(16)),
            Text(
              message,
              style: TextStyle(
                fontSize: messageSize,
                height: 1.6,
                fontWeight: FontWeight.w400,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
