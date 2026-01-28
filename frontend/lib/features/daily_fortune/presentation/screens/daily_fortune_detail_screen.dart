import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../../../menu/presentation/providers/daily_fortune_provider.dart';

/// 오늘의 운세 상세 화면
class DailyFortuneDetailScreen extends ConsumerWidget {
  const DailyFortuneDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final fortuneAsync = ref.watch(dailyFortuneProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '오늘의 운세',
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: MysticBackground(
        child: SafeArea(
          child: fortuneAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildContent(context, theme, _getSampleData()),
            data: (fortune) => _buildContent(context, theme, fortune ?? _getSampleData()),
          ),
        ),
      ),
    );
  }

  DailyFortuneData _getSampleData() {
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
          message: '대인관계에서 좋은 소식이 있을 수 있습니다. 진심어린 대화가 관계를 발전시킵니다.',
          tip: '진심어린 대화가 관계를 발전시킵니다.',
        ),
        'work': const CategoryScore(
          score: 85,
          message: '업무에서 인정받을 수 있는 기회가 있습니다. 창의적인 아이디어를 제안해보세요.',
          tip: '창의적인 아이디어를 제안해보세요.',
        ),
        'health': const CategoryScore(
          score: 70,
          message: '건강 관리에 신경 쓰세요. 충분한 휴식과 가벼운 운동을 권합니다.',
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

  Widget _buildContent(BuildContext context, AppThemeExtension theme, DailyFortuneData fortune) {
    // 반응형 패딩 적용
    final horizontalPadding = context.horizontalPadding;
    final isSmall = context.isSmallMobile;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isSmall ? 16 : 20),
      children: [
        // 상단 종합 점수 카드 (그라데이션 + 애니메이션 느낌)
        _buildOverallScoreCard(context, theme, fortune),
        const SizedBox(height: 24),

        // 오늘의 한마디
        _buildTodayMessageCard(theme, fortune),
        const SizedBox(height: 24),

        // 카테고리별 운세 (가로 스크롤 카드)
        _buildCategoryScrollSection(context, theme, fortune),
        const SizedBox(height: 24),

        // 오늘의 행운 (가로 4등분 그리드)
        _buildLuckyGridSection(theme, fortune),
        const SizedBox(height: 24),

        // 오늘의 조언
        _buildAdviceCard(theme, fortune),
        const SizedBox(height: 24),

        // AI 상담 버튼
        _buildConsultButton(context, theme),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildOverallScoreCard(BuildContext context, AppThemeExtension theme, DailyFortuneData fortune) {
    final score = fortune.overallScore;
    final scoreColor = _getScoreColor(score);
    final grade = _getScoreGrade(score);
    final message = fortune.overallMessage;

    // 날짜 포맷
    final now = DateTime.now();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final dateStr = '${now.month}월 ${now.day}일 ${weekdays[now.weekday - 1]}요일';

    // 시간대별 인사말
    final hour = now.hour;
    String greeting;
    IconData greetingIcon;
    if (hour >= 5 && hour < 12) {
      greeting = '좋은 아침이에요';
      greetingIcon = Icons.wb_sunny_rounded;
    } else if (hour >= 12 && hour < 18) {
      greeting = '활기찬 오후에요';
      greetingIcon = Icons.wb_sunny_outlined;
    } else if (hour >= 18 && hour < 22) {
      greeting = '편안한 저녁이에요';
      greetingIcon = Icons.nightlight_round;
    } else {
      greeting = '고요한 밤이에요';
      greetingIcon = Icons.bedtime_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor.withOpacity(0.15),
            theme.cardColor,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scoreColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 상단: 날짜 + 인사말
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 날짜
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.cardColor.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 12, color: theme.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // 인사말
                Row(
                  children: [
                    Icon(greetingIcon, size: 16, color: scoreColor),
                    const SizedBox(width: 6),
                    Text(
                      greeting,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 중앙: 점수 + 등급
            Row(
              children: [
                // 점수 원형
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scoreColor.withOpacity(0.2),
                        scoreColor.withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(color: scoreColor.withOpacity(0.5), width: 3),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: scoreColor,
                            height: 1,
                          ),
                        ),
                        Text(
                          '점',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: scoreColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // 등급 + 설명
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 등급 뱃지
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: scoreColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getGradeIcon(score), color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              grade,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 운세 요약 메시지
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 하단: 4가지 카테고리 미니 요약
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat(theme, '재물', fortune.getCategoryScore('wealth'), const Color(0xFFF59E0B)),
                  _buildMiniStat(theme, '애정', fortune.getCategoryScore('love'), const Color(0xFFEC4899)),
                  _buildMiniStat(theme, '직장', fortune.getCategoryScore('work'), const Color(0xFF3B82F6)),
                  _buildMiniStat(theme, '건강', fortune.getCategoryScore('health'), const Color(0xFF10B981)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(AppThemeExtension theme, String label, int score, Color color) {
    return Column(
      children: [
        Text(
          '$score',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.textMuted,
          ),
        ),
      ],
    );
  }

  IconData _getGradeIcon(int score) {
    if (score >= 90) return Icons.emoji_events_rounded;
    if (score >= 80) return Icons.thumb_up_rounded;
    if (score >= 70) return Icons.sentiment_satisfied_rounded;
    if (score >= 60) return Icons.sentiment_neutral_rounded;
    return Icons.warning_amber_rounded;
  }

  Widget _buildTodayMessageCard(AppThemeExtension theme, DailyFortuneData fortune) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.textMuted.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFB800),
                  const Color(0xFFFF8A00),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB800).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.format_quote_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오늘의 한마디',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  fortune.overallMessage,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryScrollSection(BuildContext context, AppThemeExtension theme, DailyFortuneData fortune) {
    final categories = [
      {'key': 'wealth', 'name': '재물운', 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFFF59E0B)},
      {'key': 'love', 'name': '애정운', 'icon': Icons.favorite_rounded, 'color': const Color(0xFFEC4899)},
      {'key': 'work', 'name': '직장운', 'icon': Icons.work_rounded, 'color': const Color(0xFF3B82F6)},
      {'key': 'health', 'name': '건강운', 'icon': Icons.monitor_heart_rounded, 'color': const Color(0xFF10B981)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B48FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6B48FF), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                '카테고리별 운세',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        // 반응형 2x2 그리드
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 12) / 2;
            final cardHeight = cardWidth * 0.85;

            // 반응형 크기 계산 (기준: 너비 400px)
            final scaleFactor = (constraints.maxWidth / 400).clamp(0.8, 1.5);
            final iconSize = (36 * scaleFactor).clamp(32.0, 48.0);
            final scoreSize = (14 * scaleFactor).clamp(12.0, 18.0);
            final titleSize = (14 * scaleFactor).clamp(12.0, 18.0);
            final descSize = (11 * scaleFactor).clamp(10.0, 14.0);
            final padding = (14 * scaleFactor).clamp(12.0, 20.0);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: categories.map((cat) {
                final score = fortune.getCategoryScore(cat['key'] as String);
                final message = fortune.getCategoryMessage(cat['key'] as String);
                final color = cat['color'] as Color;

                return GestureDetector(
                  onTap: () => context.push(
                    '/fortune/daily/category?key=${cat['key']}',
                  ),
                  child: SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: Container(
                      padding: EdgeInsets.all(padding),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.15),
                            color.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: iconSize,
                                height: iconSize,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(cat['icon'] as IconData, color: Colors.white, size: iconSize * 0.5),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10 * scaleFactor, vertical: 4 * scaleFactor),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$score',
                                  style: TextStyle(
                                    fontSize: scoreSize,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10 * scaleFactor),
                          Text(
                            cat['name'] as String,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w600,
                              color: theme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4 * scaleFactor),
                          Expanded(
                            child: Text(
                              message,
                              style: TextStyle(
                                fontSize: descSize,
                                color: theme.textSecondary,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLuckyGridSection(AppThemeExtension theme, DailyFortuneData fortune) {
    final lucky = fortune.lucky;
    final items = [
      {'label': '행운의 시간', 'value': lucky.time, 'icon': Icons.schedule_rounded, 'color': const Color(0xFF6B48FF)},
      {'label': '행운의 색상', 'value': lucky.color, 'icon': Icons.palette_rounded, 'color': const Color(0xFFEC4899)},
      {'label': '행운의 숫자', 'value': '${lucky.number}', 'icon': Icons.tag_rounded, 'color': const Color(0xFF10B981)},
      {'label': '행운의 방향', 'value': lucky.direction, 'icon': Icons.explore_rounded, 'color': const Color(0xFF3B82F6)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                '오늘의 행운',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        // 2x2 레이아웃 (텍스트 길이에 따라 높이 자동 조절)
        for (int i = 0; i < items.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildLuckyCard(theme, items[i])),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < items.length
                      ? _buildLuckyCard(theme, items[i + 1])
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLuckyCard(AppThemeExtension theme, Map<String, dynamic> item) {
    final color = item['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item['icon'] as IconData, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            item['label'] as String,
            style: TextStyle(
              fontSize: 11,
              color: theme.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item['value'] as String,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceCard(AppThemeExtension theme, DailyFortuneData fortune) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF59E0B).withOpacity(0.1),
            const Color(0xFFEF4444).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb_rounded, color: Color(0xFFF59E0B), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                '오늘의 조언',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 주의사항
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: const Color(0xFFEF4444), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    fortune.caution,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: theme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 확언
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.self_improvement_rounded, color: const Color(0xFF10B981), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    fortune.affirmation,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                      color: theme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultButton(BuildContext context, AppThemeExtension theme) {
    return GestureDetector(
      onTap: () => context.go('/saju/chat?type=dailyFortune'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6B48FF), Color(0xFF8B5CF6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B48FF).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'AI에게 더 자세히 물어보기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _truncateMessage(String message, int maxLength) {
    if (message.length <= maxLength) return message;
    return '${message.substring(0, maxLength)}...';
  }

  String _getScoreGrade(int score) {
    if (score >= 90) return '최고의 하루';
    if (score >= 80) return '좋은 하루';
    if (score >= 70) return '괜찮은 하루';
    if (score >= 60) return '보통의 하루';
    return '조심해야 할 하루';
  }

  Color _getScoreColor(int score) {
    // 운세 앱 분위기에 맞는 따뜻한 색상
    if (score >= 85) return const Color(0xFFD4A574); // 골드
    if (score >= 70) return const Color(0xFF8B7EC8); // 라벤더
    if (score >= 60) return const Color(0xFFB8860B); // 다크골드
    return const Color(0xFF9E7676); // 로즈브라운
  }
}
