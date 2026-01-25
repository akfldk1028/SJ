import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../../data/models/compatibility_analysis_model.dart';
import '../providers/compatibility_provider.dart';

/// 궁합 분석 상세 화면
///
/// 분석 결과 전체 내용 표시
class CompatibilityDetailScreen extends ConsumerWidget {
  final String analysisId;

  const CompatibilityDetailScreen({
    super.key,
    required this.analysisId,
  });

  static const _primaryColor = Color(0xFFEC4899);
  static const _secondaryColor = Color(0xFFF472B6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final analysisAsync =
        ref.watch(compatibilityByIdWithDetailsProvider(analysisId));

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: theme.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '궁합 분석 결과',
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: theme.textPrimary),
            color: theme.cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) =>
                _handleMenuAction(context, ref, value, analysisAsync.value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'reanalyze',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded,
                        size: 20, color: theme.textPrimary),
                    const SizedBox(width: 12),
                    Text('재분석', style: TextStyle(color: theme.textPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_rounded,
                        size: 20, color: Colors.red),
                    const SizedBox(width: 12),
                    const Text('삭제', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: MysticBackground(
        child: SafeArea(
          child: analysisAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildError(theme, error.toString()),
            data: (analysis) => analysis == null
                ? _buildNotFound(theme)
                : _buildContent(context, theme, analysis),
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    CompatibilityAnalysisModel? analysis,
  ) async {
    if (analysis == null) return;

    final theme = context.appTheme;

    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: theme.cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('궁합 분석 삭제', style: TextStyle(color: theme.textPrimary)),
          content: Text(
            '이 궁합 분석 결과를 삭제하시겠습니까?',
            style: TextStyle(color: theme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('취소', style: TextStyle(color: theme.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        await ref.read(compatibilityNotifierProvider.notifier).delete(
              analysisId: analysis.id,
              profileId: analysis.profile1Id,
            );
        if (context.mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('궁합 분석이 삭제되었습니다')),
          );
        }
      }
    } else if (action == 'reanalyze') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('재분석을 시작합니다...')),
      );
      final result =
          await ref.read(compatibilityNotifierProvider.notifier).reanalyze(
                fromProfileId: analysis.profile1Id,
                toProfileId: analysis.profile2Id,
                relationType: analysis.relationType ?? 'general',
              );
      if (context.mounted) {
        if (result.success) {
          ref.invalidate(compatibilityByIdWithDetailsProvider(analysisId));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('재분석이 완료되었습니다')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('재분석 실패: ${result.error}')),
          );
        }
      }
    }
  }

  Widget _buildError(AppThemeExtension theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: theme.textMuted),
            const SizedBox(height: 16),
            Text(
              '오류가 발생했습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 14, color: theme.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound(AppThemeExtension theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: theme.textMuted),
          const SizedBox(height: 16),
          Text(
            '분석 결과를 찾을 수 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppThemeExtension theme,
    CompatibilityAnalysisModel analysis,
  ) {
    final score = analysis.overallScore ?? 0;
    final scoreColor = _getScoreColor(score);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 점수 헤더
        _buildScoreHeader(theme, analysis, score, scoreColor),
        const SizedBox(height: 20),

        // 요약
        if (analysis.summary != null) ...[
          _buildSummaryCard(theme, analysis.summary!),
          const SizedBox(height: 16),
        ],

        // 카테고리별 점수
        if (analysis.categoryScores != null &&
            analysis.categoryScores!.isNotEmpty) ...[
          _buildCategoryScores(theme, analysis.categoryScores!),
          const SizedBox(height: 16),
        ],

        // 합충형해파 분석
        _buildHapchungSection(theme, analysis),
        const SizedBox(height: 16),

        // 강점
        if (analysis.strengths != null && analysis.strengths!.isNotEmpty) ...[
          _buildListSection(
            theme,
            title: '강점',
            icon: Icons.thumb_up_rounded,
            iconColor: Colors.green,
            items: analysis.strengths!,
          ),
          const SizedBox(height: 16),
        ],

        // 도전 과제
        if (analysis.challenges != null &&
            analysis.challenges!.isNotEmpty) ...[
          _buildListSection(
            theme,
            title: '주의할 점',
            icon: Icons.lightbulb_rounded,
            iconColor: Colors.amber,
            items: analysis.challenges!,
          ),
          const SizedBox(height: 16),
        ],

        // 조언
        if (analysis.advice != null && analysis.advice!.isNotEmpty) ...[
          _buildAdviceCard(theme, analysis.advice!),
          const SizedBox(height: 16),
        ],

        // 분석 정보
        _buildAnalysisInfo(theme, analysis),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildScoreHeader(
    AppThemeExtension theme,
    CompatibilityAnalysisModel analysis,
    int score,
    Color scoreColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withValues(alpha: 0.15),
            scoreColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // 점수 원형
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [scoreColor, scoreColor.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: scoreColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$score',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 등급
          Text(
            '${analysis.scoreGrade} 궁합',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: scoreColor,
            ),
          ),
          const SizedBox(height: 8),
          // 분석 유형
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              analysis.analysisTypeLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scoreColor,
              ),
            ),
          ),
          // 합/충 요약
          if (analysis.positiveCount > 0 || analysis.negativeCount > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (analysis.positiveCount > 0)
                  _buildCountBadge(
                    icon: Icons.favorite,
                    count: analysis.positiveCount,
                    label: '합',
                    color: Colors.pink,
                  ),
                if (analysis.positiveCount > 0 && analysis.negativeCount > 0)
                  const SizedBox(width: 16),
                if (analysis.negativeCount > 0)
                  _buildCountBadge(
                    icon: Icons.warning_amber_rounded,
                    count: analysis.negativeCount,
                    label: '충돌',
                    color: Colors.blue,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountBadge({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            '$label $count개',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AppThemeExtension theme, String summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.summarize_rounded, color: _primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                '종합 요약',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            summary,
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryScores(
      AppThemeExtension theme, Map<String, dynamic> scores) {
    final categoryIcons = {
      'love': Icons.favorite_rounded,
      'communication': Icons.chat_rounded,
      'values': Icons.balance_rounded,
      'lifestyle': Icons.home_rounded,
      'growth': Icons.trending_up_rounded,
      'conflict': Icons.flash_on_rounded,
    };

    final categoryLabels = {
      'love': '애정운',
      'communication': '소통',
      'values': '가치관',
      'lifestyle': '생활방식',
      'growth': '성장',
      'conflict': '갈등해결',
    };

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                '카테고리별 점수',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...scores.entries.map((entry) {
            final categoryScore = (entry.value as num?)?.toInt() ?? 0;
            final color = _getScoreColor(categoryScore);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        categoryIcons[entry.key] ?? Icons.circle,
                        size: 18,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        categoryLabels[entry.key] ?? entry.key,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$categoryScore점',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: categoryScore / 100,
                      backgroundColor: theme.isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHapchungSection(
      AppThemeExtension theme, CompatibilityAnalysisModel analysis) {
    final pairHapchung = analysis.pairHapchung;
    if (pairHapchung == null) return const SizedBox.shrink();

    final hapList =
        (pairHapchung['hap'] as List<dynamic>?)?.cast<String>() ?? [];
    final chungList =
        (pairHapchung['chung'] as List<dynamic>?)?.cast<String>() ?? [];
    final hyungList =
        (pairHapchung['hyung'] as List<dynamic>?)?.cast<String>() ?? [];
    final haeList =
        (pairHapchung['hae'] as List<dynamic>?)?.cast<String>() ?? [];
    final paList =
        (pairHapchung['pa'] as List<dynamic>?)?.cast<String>() ?? [];
    final wonjinList =
        (pairHapchung['wonjin'] as List<dynamic>?)?.cast<String>() ?? [];

    final hasContent = hapList.isNotEmpty ||
        chungList.isNotEmpty ||
        hyungList.isNotEmpty ||
        haeList.isNotEmpty ||
        paList.isNotEmpty ||
        wonjinList.isNotEmpty;

    if (!hasContent) return const SizedBox.shrink();

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sync_alt_rounded,
                    color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                '합충형해파 분석',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...hapList.map((h) => _buildHapchungChip(h, '합', Colors.pink)),
              ...chungList.map((c) => _buildHapchungChip(c, '충', Colors.red)),
              ...hyungList
                  .map((h) => _buildHapchungChip(h, '형', Colors.orange)),
              ...haeList.map((h) => _buildHapchungChip(h, '해', Colors.amber)),
              ...paList.map((p) => _buildHapchungChip(p, '파', Colors.blue)),
              ...wonjinList
                  .map((w) => _buildHapchungChip(w, '원진', Colors.indigo)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHapchungChip(String text, String type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              type,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(
    AppThemeExtension theme, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
  }) {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 7),
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: theme.textSecondary,
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

  Widget _buildAdviceCard(AppThemeExtension theme, String advice) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor.withValues(alpha: 0.1),
            _secondaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tips_and_updates_rounded,
                    color: _primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                '관계 조언',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            advice,
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisInfo(
      AppThemeExtension theme, CompatibilityAnalysisModel analysis) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow(theme, '분석 유형', analysis.analysisTypeLabel),
          if (analysis.modelName != null)
            _buildInfoRow(theme, '분석 모델', analysis.modelName!),
          if (analysis.tokensUsed != null)
            _buildInfoRow(theme, '토큰 사용량', '${analysis.tokensUsed}'),
          if (analysis.processingTimeMs != null)
            _buildInfoRow(
                theme, '처리 시간', '${analysis.processingTimeMs}ms'),
          _buildInfoRow(
            theme,
            '분석 일시',
            _formatDate(analysis.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(AppThemeExtension theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: theme.textMuted),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFFEC4899);
    if (score >= 60) return const Color(0xFF3B82F6);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFF6B7280);
  }
}
