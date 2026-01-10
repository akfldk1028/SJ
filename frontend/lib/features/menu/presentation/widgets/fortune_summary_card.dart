import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/daily_fortune_provider.dart';

/// Fortune summary card - AI 데이터 연동
/// ⚡ 성능 최적화: withOpacity → const Color 캐싱
class FortuneSummaryCard extends ConsumerWidget {
  const FortuneSummaryCard({super.key});

  // ⚡ 캐싱된 색상 상수 (매 빌드마다 새 객체 생성 방지)
  static const _shadowLight = Color.fromRGBO(0, 0, 0, 0.06);
  static const _shadowDark = Color.fromRGBO(0, 0, 0, 0.3);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final fortuneAsync = ref.watch(dailyFortuneProvider);

    return fortuneAsync.when(
      loading: () => _buildLoadingCard(theme),
      error: (error, stack) => _buildErrorCard(context, theme, error),
      data: (fortune) => _buildFortuneCard(context, theme, fortune ?? _getSampleFortuneData()),
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

  Widget _buildErrorCard(BuildContext context, AppThemeExtension theme, Object error) {
    // 오류 시에도 샘플 데이터로 UI 표시
    return _buildFortuneCard(context, theme, _getSampleFortuneData());
  }

  /// 샘플 운세 데이터 (오프라인/에러 시 표시용)
  DailyFortuneData _getSampleFortuneData() {
    return DailyFortuneData(
      overallScore: 85,
      overallMessage: '오늘은 새로운 시작에 좋은 날입니다. 중요한 결정을 내리기에 적합합니다.',
      date: DateTime.now().toString().split(' ')[0],
      categories: {
        'wealth': const CategoryScore(
          score: 92,
          message: '재물운이 상승하는 시기입니다. 투자에 좋은 기회가 올 수 있습니다.',
          tip: '오전 중에 중요한 재정 결정을 하세요.',
        ),
        'love': const CategoryScore(
          score: 78,
          message: '대인관계에서 좋은 소식이 있을 수 있습니다.',
          tip: '진심어린 대화가 관계를 발전시킵니다.',
        ),
        'work': const CategoryScore(
          score: 85,
          message: '업무에서 인정받을 수 있는 기회가 있습니다.',
          tip: '창의적인 아이디어를 적극적으로 제안해보세요.',
        ),
        'health': const CategoryScore(
          score: 70,
          message: '건강 관리에 신경 쓰세요.',
          tip: '충분한 휴식과 가벼운 운동을 권합니다.',
        ),
      },
      lucky: const LuckyInfo(
        time: '오전 10시',
        color: '파랑',
        number: 7,
        direction: '동쪽',
      ),
      caution: '급한 결정은 피하고 신중하게 행동하세요.',
      affirmation: '나는 오늘도 최선을 다하며 좋은 기운을 받아들입니다.',
    );
  }

  Widget _buildFortuneCard(
    BuildContext context,
    AppThemeExtension theme,
    DailyFortuneData fortune,
  ) {
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
              color: theme.isDark ? _shadowDark : _shadowLight,
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '오늘의 운세',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.textPrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/fortune/daily'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withValues(alpha: 0.1),
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
            // Time-based fortune section (푸른 계열)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: theme.isDark
                    ? const Color(0xFF1E3A5F).withValues(alpha: 0.6) // 다크 블루
                    : const Color(0xFFE8F4FC), // 라이트 블루
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // 해/달 아이콘 - 오른쪽 하단
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Icon(
                      _getTimeIcon(hour),
                      size: 64,
                      color: _getTimeIconColor(hour).withValues(alpha: 0.6),
                    ),
                  ),
                  // 메인 콘텐츠
                  Column(
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
                          GestureDetector(
                            onTap: () => context.push('/fortune/daily'),
                            child: Text(
                              '전체보기',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
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
                                    ? theme.textMuted.withValues(alpha: 0.3)
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
                          Flexible(
                            child: Text(
                              _getTimeRange(hour),
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Small circular score
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.primaryColor.withValues(alpha: 0.3),
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
                      const SizedBox(height: 14),
                      Text(
                        timeMessage,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(context, '내일의 운세', false, '/fortune/daily'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(context, '지정일 운세', false, '/fortune/daily'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 메시지 포맷팅 - 문장 마침표 뒤에 줄바꿈 추가
  String _formatMessage(String message) {
    // 마침표 뒤에 공백이 있으면 줄바꿈으로 대체
    return message.replaceAll('. ', '.\n');
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

  /// 시간대에 따른 아이콘 반환 (해/달)
  IconData _getTimeIcon(int hour) {
    if (hour >= 6 && hour < 18) {
      // 낮 (6시-18시): 해
      return Icons.wb_sunny_rounded;
    } else {
      // 밤 (18시-6시): 달
      return Icons.nightlight_round;
    }
  }

  /// 시간대에 따른 아이콘 색상 반환
  Color _getTimeIconColor(int hour) {
    if (hour >= 6 && hour < 18) {
      // 낮: 흰색 베이스 (살짝 연한 노랑)
      return const Color(0xFFFFF8E1);
    } else {
      // 밤: 흰색 베이스 (살짝 연한 파랑)
      return const Color(0xFFE8EAF6);
    }
  }

  Widget _buildActionButton(BuildContext context, String text, bool isPrimary, String route) {
    final theme = context.appTheme;

    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? theme.primaryColor : theme.cardColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isPrimary
                ? theme.primaryColor
                : theme.isDark
                    ? theme.textMuted.withValues(alpha: 0.3)
                    : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
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
          ),
        ),
      ),
    );
  }
}
