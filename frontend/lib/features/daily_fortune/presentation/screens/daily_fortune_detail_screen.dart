import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../../../menu/presentation/providers/daily_fortune_provider.dart';

/// 오늘의 운세 상세 화면
class DailyFortuneDetailScreen extends ConsumerWidget {
  const DailyFortuneDetailScreen({super.key});

  static const _primaryColor = Color(0xFFFFA500);
  static const _secondaryColor = Color(0xFFFFD700);

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
        const SizedBox(height: 20),
        // 종합 메시지
        _buildOverallMessage(theme, fortune),
        const SizedBox(height: 20),
        // 카테고리별 운세
        _buildCategorySection(theme, fortune),
        const SizedBox(height: 20),
        // 행운 정보
        _buildLuckyInfo(theme, fortune),
        const SizedBox(height: 20),
        // 오늘의 조언
        _buildAdviceSection(theme, fortune),
        const SizedBox(height: 28),
        // AI 상담 버튼
        _buildConsultButton(context, theme),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildOverallScore(AppThemeExtension theme, DailyFortuneData fortune) {
    final score = fortune.overallScore;
    final scoreColor = _getScoreColor(score);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor.withOpacity(0.15),
            _secondaryColor.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wb_sunny_rounded, color: _primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                '오늘의 종합 운세',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 점수 표시 (원형 게이지 효과)
          Stack(
            alignment: Alignment.center,
            children: [
              // 배경 원
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: scoreColor.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // 점수 원
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      scoreColor.withOpacity(0.15),
                      scoreColor.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: scoreColor.withOpacity(0.3), width: 3),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: scoreColor,
                          height: 1,
                        ),
                      ),
                      Text(
                        '점',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: scoreColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 점수 등급
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scoreColor.withOpacity(0.3)),
            ),
            child: Text(
              _getScoreGrade(score),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scoreColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getScoreGrade(int score) {
    if (score >= 90) return '최고의 날';
    if (score >= 80) return '좋은 날';
    if (score >= 70) return '괜찮은 날';
    if (score >= 60) return '보통의 날';
    return '주의가 필요한 날';
  }

  Widget _buildOverallMessage(AppThemeExtension theme, DailyFortuneData fortune) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.format_quote_rounded, color: _primaryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              fortune.overallMessage,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: theme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(AppThemeExtension theme, DailyFortuneData fortune) {
    final categories = [
      {'key': 'wealth', 'name': '재물운', 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFF10B981)},
      {'key': 'love', 'name': '애정운', 'icon': Icons.favorite_rounded, 'color': const Color(0xFFEC4899)},
      {'key': 'work', 'name': '직장운', 'icon': Icons.work_rounded, 'color': const Color(0xFF3B82F6)},
      {'key': 'health', 'name': '건강운', 'icon': Icons.favorite_border_rounded, 'color': const Color(0xFFF59E0B)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.category_rounded, color: _primaryColor, size: 18),
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
        ...categories.map((cat) {
          final score = fortune.getCategoryScore(cat['key'] as String);
          final message = fortune.getCategoryMessage(cat['key'] as String);
          return _buildCategoryCard(
            theme,
            cat['name'] as String,
            cat['icon'] as IconData,
            cat['color'] as Color,
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
    Color color,
    int score,
    String message,
  ) {
    final scoreColor = _getScoreColor(score);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          // 상단
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: scoreColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: scoreColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$score점',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 하단
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 85) return const Color(0xFF10B981);
    if (score >= 70) return const Color(0xFF3B82F6);
    if (score >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _buildLuckyInfo(AppThemeExtension theme, DailyFortuneData fortune) {
    final lucky = fortune.lucky;
    final items = [
      {'label': '시간', 'value': lucky.time, 'icon': Icons.access_time_rounded, 'color': const Color(0xFF6B48FF)},
      {'label': '색상', 'value': lucky.color, 'icon': Icons.palette_rounded, 'color': const Color(0xFFEC4899)},
      {'label': '숫자', 'value': '${lucky.number}', 'icon': Icons.tag_rounded, 'color': const Color(0xFF10B981)},
      {'label': '방향', 'value': lucky.direction, 'icon': Icons.explore_rounded, 'color': const Color(0xFF3B82F6)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: _primaryColor, size: 18),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: items.map((item) {
              final color = item['color'] as Color;
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  margin: item != items.last ? const EdgeInsets.only(right: 10) : null,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item['icon'] as IconData, color: color, size: 20),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['value'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAdviceSection(AppThemeExtension theme, DailyFortuneData fortune) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor.withOpacity(0.1),
            _secondaryColor.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb_rounded, color: _primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                '오늘의 조언',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: const Color(0xFFF59E0B), size: 18),
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
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.format_quote_rounded, color: _primaryColor.withOpacity(0.6), size: 22),
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

  Widget _buildConsultButton(BuildContext context, AppThemeExtension theme) {
    return GestureDetector(
      onTap: () => context.push('/saju/chat?type=dailyFortune'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_primaryColor, _secondaryColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              '오늘 운세 AI 상담받기',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
