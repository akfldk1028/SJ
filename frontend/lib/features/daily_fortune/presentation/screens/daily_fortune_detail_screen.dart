import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
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
          icon: Icon(Icons.arrow_back, color: theme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '오늘의 운세',
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
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
          message: '재물운이 상승하는 시기입니다.',
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
          tip: '창의적인 아이디어를 제안해보세요.',
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

  Widget _buildContent(BuildContext context, AppThemeExtension theme, DailyFortuneData fortune) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 종합 운세 점수
        _buildOverallScore(theme, fortune),
        const SizedBox(height: 24),
        // 종합 메시지
        _buildOverallMessage(theme, fortune),
        const SizedBox(height: 24),
        // 카테고리별 운세
        _buildCategorySection(theme, fortune),
        const SizedBox(height: 24),
        // 행운 정보
        _buildLuckyInfo(theme, fortune),
        const SizedBox(height: 24),
        // 오늘의 조언
        _buildAdviceSection(theme, fortune),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildOverallScore(AppThemeExtension theme, DailyFortuneData fortune) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(0.15),
            (theme.accentColor ?? theme.primaryColor).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            '오늘의 종합 운세',
            style: TextStyle(
              fontSize: 14,
              color: theme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${fortune.overallScore}',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w300,
              color: theme.primaryColor,
            ),
          ),
          Text(
            '점',
            style: TextStyle(
              fontSize: 18,
              color: theme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallMessage(AppThemeExtension theme, DailyFortuneData fortune) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        fortune.overallMessage,
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: theme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildCategorySection(AppThemeExtension theme, DailyFortuneData fortune) {
    final categories = [
      {'key': 'wealth', 'name': '재물운', 'icon': Icons.monetization_on_outlined},
      {'key': 'love', 'name': '애정운', 'icon': Icons.favorite_outline},
      {'key': 'work', 'name': '직장운', 'icon': Icons.work_outline},
      {'key': 'health', 'name': '건강운', 'icon': Icons.favorite_border},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '카테고리별 운세',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...categories.map((cat) {
          final score = fortune.getCategoryScore(cat['key'] as String);
          final message = fortune.getCategoryMessage(cat['key'] as String);
          return _buildCategoryCard(
            theme,
            cat['name'] as String,
            cat['icon'] as IconData,
            score,
            message,
          );
        }),
      ],
    );
  }

  Widget _buildCategoryCard(
    AppThemeExtension theme,
    String name,
    IconData icon,
    int score,
    String message,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getScoreColor(score).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$score점',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getScoreColor(score),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFFFFC107);
    return const Color(0xFFFF5722);
  }

  Widget _buildLuckyInfo(AppThemeExtension theme, DailyFortuneData fortune) {
    final lucky = fortune.lucky;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '행운의 정보',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildLuckyItem(theme, '시간', lucky.time, Icons.access_time),
              _buildLuckyItem(theme, '색상', lucky.color, Icons.palette),
              _buildLuckyItem(theme, '숫자', '${lucky.number}', Icons.looks_one),
              _buildLuckyItem(theme, '방향', lucky.direction, Icons.explore),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLuckyItem(AppThemeExtension theme, String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: theme.primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceSection(AppThemeExtension theme, DailyFortuneData fortune) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '오늘의 조언',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            fortune.caution,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.format_quote, color: theme.textMuted, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fortune.affirmation,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: theme.textSecondary,
                      height: 1.5,
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
}
