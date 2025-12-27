import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/daily_fortune_provider.dart';

/// Fortune summary card - AI 데이터 연동
class FortuneSummaryCard extends ConsumerWidget {
  const FortuneSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final fortuneAsync = ref.watch(dailyFortuneProvider);

    return fortuneAsync.when(
      loading: () => _buildLoadingCard(theme),
      error: (error, stack) => _buildErrorCard(theme, error),
      data: (fortune) => _buildFortuneCard(context, theme, fortune),
    );
  }

  Widget _buildLoadingCard(AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: theme.primaryColor),
              const SizedBox(height: 16),
              Text(
                '운세를 불러오는 중...',
                style: TextStyle(color: theme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(AppThemeExtension theme, Object error) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: theme.textMuted, size: 48),
              const SizedBox(height: 16),
              Text(
                '운세를 불러올 수 없습니다',
                style: TextStyle(color: theme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFortuneCard(
    BuildContext context,
    AppThemeExtension theme,
    DailyFortuneData? fortune,
  ) {
    // fortune이 null이면 분석 대기 중
    if (fortune == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: theme.primaryColor, size: 48),
                const SizedBox(height: 16),
                Text(
                  '오늘의 운세를 분석 중입니다',
                  style: TextStyle(color: theme.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  '잠시만 기다려주세요',
                  style: TextStyle(color: theme.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final score = fortune.overallScore;
    final message = fortune.overallMessage;

    // 시간대별 운세 점수 계산 (현재 시간 기준)
    final hour = DateTime.now().hour;
    String timeSlot;
    int timeScore;
    String timeMessage;

    if (hour >= 7 && hour < 12) {
      timeSlot = '오전 운세';
      timeScore = fortune.getCategoryScore('work');
      timeMessage = fortune.getCategoryMessage('work');
    } else if (hour >= 12 && hour < 18) {
      timeSlot = '오후 운세';
      timeScore = fortune.getCategoryScore('wealth');
      timeMessage = fortune.getCategoryMessage('wealth');
    } else {
      timeSlot = '저녁 운세';
      timeScore = fortune.getCategoryScore('love');
      timeMessage = fortune.getCategoryMessage('love');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '오늘의 운세',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '더보기',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formatMessage(message),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: theme.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right side - Large score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w300,
                        color: theme.textPrimary,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Time-based fortune section
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.isDark
                    ? theme.primaryColor.withOpacity(0.1)
                    : theme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '시간대별 운세',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                        ),
                      ),
                      Text(
                        '전체보기',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.isDark
                                ? theme.textMuted.withOpacity(0.3)
                                : Colors.grey[200]!,
                          ),
                        ),
                        child: Text(
                          timeSlot,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getTimeRange(hour),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textMuted,
                        ),
                      ),
                      const Spacer(),
                      // Small circular score
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.primaryColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$timeScore',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _truncateMessage(timeMessage, 50),
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1/3',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textMuted,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(context, '내일의 운세', false),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(context, '지정일 운세', false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 긴 메시지를 3줄로 포맷팅
  String _formatMessage(String message) {
    if (message.length <= 30) return message;

    // 적당한 위치에서 줄바꿈
    final words = message.split(' ');
    final lines = <String>[];
    var currentLine = '';

    for (final word in words) {
      if ((currentLine + word).length > 12 && currentLine.isNotEmpty) {
        lines.add(currentLine.trim());
        currentLine = word + ' ';
        if (lines.length >= 3) break;
      } else {
        currentLine += word + ' ';
      }
    }

    if (lines.length < 3 && currentLine.isNotEmpty) {
      lines.add(currentLine.trim());
    }

    return lines.take(3).join('\n');
  }

  /// 메시지 자르기
  String _truncateMessage(String message, int maxLength) {
    if (message.length <= maxLength) return message;
    return '${message.substring(0, maxLength)}...';
  }

  /// 시간대 범위 반환
  String _getTimeRange(int hour) {
    if (hour >= 7 && hour < 12) {
      return '7:00 - 11:59';
    } else if (hour >= 12 && hour < 18) {
      return '12:00 - 17:59';
    } else {
      return '18:00 - 23:59';
    }
  }

  Widget _buildActionButton(BuildContext context, String text, bool isPrimary) {
    final theme = context.appTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isPrimary ? theme.primaryColor : theme.cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isPrimary
              ? theme.primaryColor
              : theme.isDark
                  ? theme.textMuted.withOpacity(0.3)
                  : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isPrimary ? Colors.white : theme.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: isPrimary ? Colors.white : theme.textMuted,
          ),
        ],
      ),
    );
  }
}
