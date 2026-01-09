import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';

/// 2026 신년운세 화면
class NewYearFortuneScreen extends ConsumerWidget {
  const NewYearFortuneScreen({super.key});

  static const _primaryColor = Color(0xFFFF6B6B);
  static const _secondaryColor = Color(0xFFFFE66D);
  static const _accentColor = Color(0xFFFFA94D);

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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '2026 신년운세',
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
        const SizedBox(height: 20),
        // 2026년 총운
        _buildOverallFortune(theme),
        const SizedBox(height: 20),
        // 월별 운세
        _buildMonthlyFortune(theme),
        const SizedBox(height: 20),
        // 2026년 행운의 키워드
        _buildLuckyKeywords(theme),
        const SizedBox(height: 20),
        // 주의사항
        _buildCautionSection(theme),
        const SizedBox(height: 28),
        // AI 상담 버튼
        _buildConsultButton(context, theme),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildYearBanner(AppThemeExtension theme) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryColor, _accentColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 배경 패턴
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // 별 아이콘들
          Positioned(
            right: 20,
            top: 20,
            child: Icon(Icons.auto_awesome, size: 24, color: Colors.white.withOpacity(0.4)),
          ),
          Positioned(
            right: 60,
            top: 45,
            child: Icon(Icons.auto_awesome, size: 16, color: Colors.white.withOpacity(0.3)),
          ),
          Positioned(
            right: 30,
            bottom: 50,
            child: Icon(Icons.auto_awesome, size: 20, color: Colors.white.withOpacity(0.35)),
          ),
          // 콘텐츠
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.celebration_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        '병오년 (丙午年)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '2026',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        letterSpacing: -2,
                      ),
                    ),
                    SizedBox(width: 10),
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        '신년운세',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '새해 복 많이 받으세요!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.star_rounded, color: _primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                '2026년 총운',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '2026년은 새로운 시작과 변화의 해입니다. '
            '상반기에는 준비와 계획의 시간을 가지고, '
            '하반기에는 그 결실을 맺을 수 있는 기회가 찾아옵니다.',
            style: TextStyle(
              fontSize: 15,
              height: 1.7,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_rounded, color: _accentColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '특히 대인관계에서 좋은 인연을 만날 수 있으며, 새로운 프로젝트를 시작하기에 좋습니다.',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondary,
                      fontWeight: FontWeight.w500,
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
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_month_rounded, color: _primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                '월별 운세',
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
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
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
                index,
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
    int index,
  ) {
    final scoreColor = _getScoreColor(score);
    final isHighScore = score >= 85;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isHighScore ? scoreColor.withOpacity(0.03) : null,
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: theme.textMuted.withOpacity(0.08),
                ),
              ),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(20))
            : index == 0
                ? const BorderRadius.vertical(top: Radius.circular(20))
                : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scoreColor.withOpacity(0.15),
                  scoreColor.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                month,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scoreColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fortune,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textPrimary,
                  ),
                ),
                if (isHighScore)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_upward_rounded, size: 12, color: scoreColor),
                        const SizedBox(width: 2),
                        Text(
                          '좋은 시기',
                          style: TextStyle(
                            fontSize: 11,
                            color: scoreColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              '$score',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
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

  Widget _buildLuckyKeywords(AppThemeExtension theme) {
    final keywords = [
      {'word': '도전', 'icon': Icons.rocket_launch_rounded, 'color': const Color(0xFFEC4899)},
      {'word': '협력', 'icon': Icons.handshake_rounded, 'color': const Color(0xFF3B82F6)},
      {'word': '성장', 'icon': Icons.trending_up_rounded, 'color': const Color(0xFF10B981)},
      {'word': '인내', 'icon': Icons.hourglass_top_rounded, 'color': const Color(0xFFF59E0B)},
      {'word': '희망', 'icon': Icons.wb_sunny_rounded, 'color': const Color(0xFFFF6B6B)},
    ];

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
        border: Border.all(color: _primaryColor.withOpacity(0.15)),
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
                child: const Icon(Icons.key_rounded, color: _primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                '2026년 행운의 키워드',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: keywords.map((keyword) {
              final color = keyword['color'] as Color;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(keyword['icon'] as IconData, color: color, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '#${keyword['word']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCautionSection(AppThemeExtension theme) {
    final bgColor = theme.isDark
        ? const Color(0xFF3D2E1E)
        : const Color(0xFFFFF3E0);
    final iconColor = theme.isDark
        ? const Color(0xFFFFB74D)
        : const Color(0xFFF57C00);
    final titleColor = theme.isDark
        ? const Color(0xFFFFCC80)
        : const Color(0xFFEF6C00);

    final cautions = [
      '급한 결정은 피하고 충분히 생각한 후 행동하세요',
      '건강 관리에 특별히 신경 쓰는 것이 좋습니다',
      '재정적인 결정은 신중하게 내려주세요',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.warning_amber_rounded, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                '2026년 주의사항',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...cautions.map((caution) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    caution,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: theme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildConsultButton(BuildContext context, AppThemeExtension theme) {
    return GestureDetector(
      onTap: () => context.push('/saju/chat?type=newYearFortune'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_primaryColor, _accentColor],
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
              '신년운세 AI 상담받기',
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
