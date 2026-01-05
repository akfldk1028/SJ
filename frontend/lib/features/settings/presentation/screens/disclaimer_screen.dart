import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';

/// 면책 안내 화면
class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: MysticBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, theme),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 주요 안내 카드
                      _buildMainNoticeCard(context, theme),
                      const SizedBox(height: 16),

                      // 상세 면책 조항
                      _buildDetailCard(context, theme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.15),
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: theme.primaryColor,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          Text(
            '면책 안내',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMainNoticeCard(BuildContext context, AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.isDark
              ? [
                  const Color(0xFF2A3540),
                  const Color(0xFF1E2830),
                ]
              : [
                  const Color(0xFFFFF8E1),
                  const Color(0xFFFFECB3),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.amber.withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.isDark
                  ? theme.primaryColor.withOpacity(0.2)
                  : Colors.amber.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline,
              size: 32,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '사주 상담은 참고용입니다',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '만톡에서 제공하는 사주 분석 및 운세 정보는\n재미와 참고를 위한 것입니다.\n\n중요한 인생의 결정은 반드시\n전문가와 상담하시기 바랍니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.06),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '면책 조항',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildBulletPoint(
            theme,
            '서비스 성격',
            '만톡의 AI 사주 상담 서비스는 전통적인 사주명리학을 기반으로 한 AI 분석 결과를 제공합니다. 이는 재미와 교양을 위한 것으로, 과학적으로 검증된 정보가 아닙니다.',
          ),
          _buildBulletPoint(
            theme,
            '의사결정',
            '사주 분석 결과를 근거로 중요한 의사결정(진로, 결혼, 투자, 건강 등)을 내리지 마시기 바랍니다. 이러한 결정은 해당 분야의 전문가와 상담하시기 바랍니다.',
          ),
          _buildBulletPoint(
            theme,
            '정확성',
            '만톡은 AI 기반 서비스의 특성상 결과의 정확성이나 신뢰성을 보장하지 않습니다. 분석 결과는 참고용으로만 활용하시기 바랍니다.',
          ),
          _buildBulletPoint(
            theme,
            '책임 제한',
            '만톡 서비스 이용으로 인해 발생하는 어떠한 직접적, 간접적 손해에 대해서도 회사는 책임지지 않습니다.',
          ),
          _buildBulletPoint(
            theme,
            '건강 관련',
            '건강에 관한 정보는 의료적 조언이 아닙니다. 건강 문제는 반드시 의료 전문가와 상담하시기 바랍니다.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.isDark
                  ? Colors.amber.withOpacity(0.1)
                  : Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amber.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber[700],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '만톡 서비스를 이용하시면 위의 면책 조항에 동의한 것으로 간주됩니다.',
                    style: TextStyle(
                      fontSize: 13,
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

  Widget _buildBulletPoint(
    AppThemeExtension theme,
    String title,
    String content,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: theme.textSecondary,
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
