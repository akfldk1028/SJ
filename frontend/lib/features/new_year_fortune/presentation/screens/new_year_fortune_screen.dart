import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';

/// 2026 신년운세 화면
class NewYearFortuneScreen extends ConsumerWidget {
  const NewYearFortuneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;

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
          '2026 신년운세',
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: MysticBackground(
        child: SafeArea(
          child: _buildContent(context, theme),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppThemeExtension theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 신년 배너
        _buildYearBanner(theme),
        const SizedBox(height: 24),
        // 2026년 총운
        _buildOverallFortune(theme),
        const SizedBox(height: 24),
        // 월별 운세
        _buildMonthlyFortune(theme),
        const SizedBox(height: 24),
        // 2026년 행운의 키워드
        _buildLuckyKeywords(theme),
        const SizedBox(height: 24),
        // 주의사항
        _buildCautionSection(theme),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildYearBanner(AppThemeExtension theme) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B6B),
            const Color(0xFFFFE66D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // 배경 패턴
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.auto_awesome,
              size: 150,
              color: Colors.white.withValues(alpha:0.2),
            ),
          ),
          // 콘텐츠
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '병오년 (丙午年)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '2026',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const Text(
                  '신년운세',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallFortune(AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: theme.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                '2026년 총운',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '2026년은 새로운 시작과 변화의 해입니다. '
            '상반기에는 준비와 계획의 시간을 가지고, '
            '하반기에는 그 결실을 맺을 수 있는 기회가 찾아옵니다.\n\n'
            '특히 대인관계에서 좋은 인연을 만날 수 있으며, '
            '새로운 프로젝트나 사업을 시작하기에 좋은 운기가 흐릅니다.',
            style: TextStyle(
              fontSize: 15,
              height: 1.7,
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyFortune(AppThemeExtension theme) {
    final months = [
      {'month': '1월', 'fortune': '새로운 시작의 기운', 'score': 75},
      {'month': '2월', 'fortune': '인내가 필요한 시기', 'score': 65},
      {'month': '3월', 'fortune': '봄의 기운과 함께 상승', 'score': 85},
      {'month': '4월', 'fortune': '대인관계 운 상승', 'score': 88},
      {'month': '5월', 'fortune': '재물운이 좋은 시기', 'score': 90},
      {'month': '6월', 'fortune': '건강 주의', 'score': 70},
      {'month': '7월', 'fortune': '도약의 기회', 'score': 82},
      {'month': '8월', 'fortune': '안정적인 흐름', 'score': 78},
      {'month': '9월', 'fortune': '수확의 계절', 'score': 92},
      {'month': '10월', 'fortune': '변화에 대응', 'score': 75},
      {'month': '11월', 'fortune': '준비의 시간', 'score': 72},
      {'month': '12월', 'fortune': '마무리와 정리', 'score': 80},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            '월별 운세',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: months.asMap().entries.map((entry) {
              final index = entry.key;
              final month = entry.value;
              final isLast = index == months.length - 1;
              return _buildMonthItem(
                theme,
                month['month'] as String,
                month['fortune'] as String,
                month['score'] as int,
                isLast,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthItem(
    AppThemeExtension theme,
    String month,
    String fortune,
    int score,
    bool isLast,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: theme.textMuted.withValues(alpha:0.1),
                ),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                month,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              fortune,
              style: TextStyle(
                fontSize: 14,
                color: theme.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getScoreColor(score).withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _getScoreColor(score),
              ),
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

  Widget _buildLuckyKeywords(AppThemeExtension theme) {
    final keywords = ['도전', '협력', '성장', '인내', '희망'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha:0.15),
            (theme.accentColor ?? theme.primaryColor).withValues(alpha:0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.key, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '2026년 행운의 키워드',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: keywords.map((keyword) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '#$keyword',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCautionSection(AppThemeExtension theme) {
    // 다크모드 대응 색상
    final bgColor = theme.isDark
        ? const Color(0xFF3D2E1E)  // 다크모드: 어두운 오렌지 톤
        : const Color(0xFFFFF3E0); // 라이트모드: 밝은 오렌지 톤
    final iconColor = theme.isDark
        ? const Color(0xFFFFB74D)  // 다크모드: 밝은 오렌지
        : const Color(0xFFF57C00); // 라이트모드: Colors.orange[700]
    final titleColor = theme.isDark
        ? const Color(0xFFFFCC80)  // 다크모드: 더 밝은 오렌지
        : const Color(0xFFEF6C00); // 라이트모드: Colors.orange[800]
    final textColor = theme.isDark
        ? const Color(0xFFFFE0B2)  // 다크모드: 가장 밝은 오렌지
        : const Color(0xFFE65100); // 라이트모드: Colors.orange[900]

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '2026년 주의사항',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '급한 결정은 피하고 충분히 생각한 후 행동하세요.\n'
            '건강 관리에 특별히 신경 쓰는 것이 좋습니다.\n'
            '재정적인 결정은 신중하게 내려주세요.',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
