import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/compatibility_analysis_model.dart';

/// 궁합 분석 결과 카드 위젯
///
/// 두 프로필 간의 궁합 점수와 요약을 표시
class CompatibilityCard extends StatelessWidget {
  final CompatibilityAnalysisModel analysis;
  final VoidCallback? onTap;
  final bool showDetails;

  const CompatibilityCard({
    super.key,
    required this.analysis,
    this.onTap,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final score = analysis.overallScore ?? 0;
    final scoreColor = _getScoreColor(score);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scoreColor.withValues(alpha:0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.isDark
                  ? Colors.black.withValues(alpha:0.3)
                  : Colors.black.withValues(alpha:0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 점수 + 등급
            Row(
              children: [
                _buildScoreCircle(theme, score, scoreColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '궁합 점수',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${analysis.scoreGrade} 궁합',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // 분석 유형 뱃지
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    analysis.analysisTypeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),

            if (showDetails) ...[
              const SizedBox(height: 16),
              // 합충 요약
              if (analysis.positiveCount > 0 || analysis.negativeCount > 0)
                _buildHapchungSummary(theme, scoreColor),

              if (analysis.summary != null) ...[
                const SizedBox(height: 12),
                Text(
                  analysis.summary!,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: theme.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // 강점/도전 요약
              if (analysis.strengths?.isNotEmpty == true ||
                  analysis.challenges?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                _buildStrengthsChallenges(theme),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCircle(
    AppThemeExtension theme,
    int score,
    Color color,
  ) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color.withValues(alpha:0.2), color.withValues(alpha:0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withValues(alpha:0.5), width: 2),
      ),
      child: Center(
        child: Text(
          '$score',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildHapchungSummary(AppThemeExtension theme, Color scoreColor) {
    return Row(
      children: [
        // 긍정적 (합)
        if (analysis.positiveCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.pink.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite, size: 14, color: Colors.pink[400]),
                const SizedBox(width: 4),
                Text(
                  '합 ${analysis.positiveCount}개',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.pink[600],
                  ),
                ),
              ],
            ),
          ),
        if (analysis.positiveCount > 0 && analysis.negativeCount > 0)
          const SizedBox(width: 8),
        // 부정적 (충/형/해/파)
        if (analysis.negativeCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 14, color: Colors.blue[400]),
                const SizedBox(width: 4),
                Text(
                  '충돌 ${analysis.negativeCount}개',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStrengthsChallenges(AppThemeExtension theme) {
    return Row(
      children: [
        if (analysis.strengths?.isNotEmpty == true)
          Expanded(
            child: _buildBulletList(
              theme,
              icon: Icons.thumb_up_outlined,
              iconColor: Colors.green,
              items: analysis.strengths!.take(2).toList(),
            ),
          ),
        if (analysis.challenges?.isNotEmpty == true) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _buildBulletList(
              theme,
              icon: Icons.lightbulb_outline,
              iconColor: Colors.amber,
              items: analysis.challenges!.take(2).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBulletList(
    AppThemeExtension theme, {
    required IconData icon,
    required Color iconColor,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFFEC4899); // pink
    if (score >= 60) return const Color(0xFF3B82F6); // blue
    if (score >= 40) return const Color(0xFFF59E0B); // amber
    return const Color(0xFF6B7280); // gray
  }
}

/// 컴팩트한 궁합 점수 뱃지
///
/// relationship_graph 노드에서 사용
class CompatibilityScoreBadge extends StatelessWidget {
  final int? score;
  final double size;

  const CompatibilityScoreBadge({
    super.key,
    required this.score,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (score == null) return const SizedBox.shrink();

    final color = _getScoreColor(score!);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha:0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$score',
          style: TextStyle(
            fontSize: size * 0.45,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFFEC4899);
    if (score >= 60) return const Color(0xFF3B82F6);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFF6B7280);
  }
}
