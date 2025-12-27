import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/daily_fortune_provider.dart';

/// Today's message card - AI 데이터 연동
class TodayMessageCard extends ConsumerWidget {
  const TodayMessageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final fortuneAsync = ref.watch(dailyFortuneProvider);

    return fortuneAsync.when(
      loading: () => _buildCard(theme, '오늘의 메시지를 불러오는 중...'),
      error: (_, __) => _buildCard(theme, '메시지를 불러올 수 없습니다.'),
      data: (fortune) => _buildCard(
        theme,
        fortune?.affirmation ?? '긍정적인 마음으로 하루를 시작하세요!',
      ),
    );
  }

  Widget _buildCard(AppThemeExtension theme, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.06),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: theme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '오늘의 한마디',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
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
