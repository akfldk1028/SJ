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

  // ===== 합충형해파 분석 (Modern Redesign) =====

  Widget _buildHapchungSection(
      AppThemeExtension theme, CompatibilityAnalysisModel analysis) {
    final ph = analysis.pairHapchung;
    if (ph == null) return const SizedBox.shrink();

    final positiveWidgets = <Widget>[];
    final negativeWidgets = <Widget>[];

    // 긍정적 관계 (합)
    _addCategoryIfNotEmpty(positiveWidgets, theme, '삼합 (三合)',
        _toStringList(ph['samhap']), const Color(0xFFEC4899), Icons.auto_awesome);
    _addCategoryIfNotEmpty(positiveWidgets, theme, '육합 (六合)',
        _toStringList(ph['yukhap']), const Color(0xFFF472B6), Icons.handshake);
    _addCategoryIfNotEmpty(positiveWidgets, theme, '반합 (半合)',
        _toStringList(ph['banhap']), const Color(0xFFA855F7), Icons.join_inner);
    // 방합: "일부" 제외, 세 글자 완전 방합만
    _addCategoryIfNotEmpty(positiveWidgets, theme, '방합 (方合)',
        _filterFullBanghap(_toStringList(ph['banghap'])),
        const Color(0xFF8B5CF6), Icons.explore);
    _addCategoryIfNotEmpty(positiveWidgets, theme, '천간합 (天干合)',
        _toStringList(ph['cheongan_hap']), const Color(0xFF6366F1), Icons.link);

    // 부정적 관계
    _addCategoryIfNotEmpty(negativeWidgets, theme, '충 (沖)',
        _toStringList(ph['chung']), const Color(0xFFEF4444), Icons.flash_on_rounded);
    _addCategoryIfNotEmpty(negativeWidgets, theme, '형 (刑)',
        _toStringList(ph['hyung']), const Color(0xFFF97316), Icons.gavel_rounded);
    _addCategoryIfNotEmpty(negativeWidgets, theme, '해 (害)',
        _toStringList(ph['hae']), const Color(0xFFEAB308), Icons.heart_broken_rounded);
    _addCategoryIfNotEmpty(negativeWidgets, theme, '파 (破)',
        _toStringList(ph['pa']), const Color(0xFF06B6D4), Icons.broken_image_rounded);
    _addCategoryIfNotEmpty(negativeWidgets, theme, '원진 (怨嗔)',
        _toStringList(ph['wonjin']), const Color(0xFF6366F1), Icons.do_not_disturb_rounded);

    // Fallback: sub-categories 없으면 hap/chung 필드 사용
    if (positiveWidgets.isEmpty) {
      // hap에서도 "일부" 방합 제외
      final hapFiltered = _toStringList(ph['hap'])
          .where((e) => !e.contains('일부'))
          .toList();
      _addCategoryIfNotEmpty(positiveWidgets, theme, '합 (合)',
          hapFiltered, const Color(0xFFEC4899), Icons.favorite_rounded);
    }

    if (positiveWidgets.isEmpty && negativeWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (positiveWidgets.isNotEmpty)
          _buildGroupCard(
            theme,
            title: '조화의 기운',
            subtitle: '합 (合)',
            icon: Icons.favorite_rounded,
            accentColor: const Color(0xFFEC4899),
            children: positiveWidgets,
          ),
        if (positiveWidgets.isNotEmpty && negativeWidgets.isNotEmpty)
          const SizedBox(height: 16),
        if (negativeWidgets.isNotEmpty)
          _buildGroupCard(
            theme,
            title: '긴장의 기운',
            subtitle: '충 · 형 · 해 · 파 · 원진',
            icon: Icons.flash_on_rounded,
            accentColor: const Color(0xFF3B82F6),
            children: negativeWidgets,
          ),
      ],
    );
  }

  /// 방합: "일부" 포함된 항목 제외 (세 글자 완전 방합만)
  List<String> _filterFullBanghap(List<String> entries) {
    return entries.where((e) => !e.contains('일부')).toList();
  }

  void _addCategoryIfNotEmpty(
    List<Widget> target,
    AppThemeExtension theme,
    String categoryTitle,
    List<String> entries,
    Color color,
    IconData icon,
  ) {
    if (entries.isEmpty) return;
    final deduped = _dedupEntries(entries);
    if (deduped.isEmpty) return;
    if (target.isNotEmpty) {
      target.add(const SizedBox(height: 12));
    }
    target.add(_buildCategoryCard(theme, categoryTitle, deduped, color, icon));
  }

  Widget _buildGroupCard(
    AppThemeExtension theme, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0.12),
                  accentColor.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    AppThemeExtension theme,
    String title,
    List<({String name, String? hanja, int count})> items,
    Color color,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category title
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Items
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final explanation = _getHapchungExplanation(item.name);
            final isLast = idx == items.length - 1;

            return Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              decoration: isLast
                  ? null
                  : BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: color.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: item.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textPrimary,
                                ),
                              ),
                              if (item.hanja != null)
                                TextSpan(
                                  text: ' (${item.hanja})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (item.count > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '×${item.count}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (explanation.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        explanation,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: theme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ===== Hapchung Helper Methods =====

  List<String> _toStringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  List<({String name, String? hanja, int count})> _dedupEntries(
      List<String> entries) {
    final Map<String, ({String? hanja, int count})> grouped = {};
    for (final entry in entries) {
      final name = _extractCoreName(entry);
      final hanja = _extractHanja(entry);
      if (grouped.containsKey(name)) {
        final prev = grouped[name]!;
        grouped[name] = (hanja: prev.hanja ?? hanja, count: prev.count + 1);
      } else {
        grouped[name] = (hanja: hanja, count: 1);
      }
    }
    return grouped.entries
        .map((e) => (name: e.key, hanja: e.value.hanja, count: e.value.count))
        .toList();
  }

  String _extractCoreName(String entry) {
    var text = entry;
    // Remove [type] prefix like [삼합], [반합]
    text = text.replaceAll(RegExp(r'^\[.+?\]\s*'), '');
    // Remove position info before ": "
    final colonIdx = text.indexOf(': ');
    if (colonIdx != -1) {
      text = text.substring(colonIdx + 2);
    }
    // Take text before first parenthesis
    final parenIdx = text.indexOf('(');
    if (parenIdx > 0) {
      text = text.substring(0, parenIdx);
    }
    return text.trim();
  }

  String? _extractHanja(String entry) {
    var text = entry;
    text = text.replaceAll(RegExp(r'^\[.+?\]\s*'), '');
    final colonIdx = text.indexOf(': ');
    if (colonIdx != -1) text = text.substring(colonIdx + 2);
    final match = RegExp(r'\(([^)]+)\)').firstMatch(text);
    return match?.group(1);
  }

  String _getHapchungExplanation(String name) {
    final key = name.replaceAll(' ', '');
    return _hapchungExplanations[key] ??
        _hapchungExplanations[name] ??
        '';
  }

  static const _hapchungExplanations = <String, String>{
    // === 충 (沖) ===
    '자오충': '물(水)과 불(火)의 정면 충돌. 감정과 이성의 갈등, 급격한 변화를 의미하나 새로운 전환점이 될 수 있음',
    '축미충': '토(土)끼리의 충돌. 저장과 축적에 대한 대립, 재물이나 부동산 관련 변동 가능',
    '인신충': '나무(木)와 쇠(金)의 충돌. 활동성과 결단력의 갈등, 역마(驛馬)의 기운으로 이동·변화가 많음',
    '묘유충': '나무(木)와 쇠(金)의 충돌. 감성과 이성의 대립, 인간관계와 직업에 변동 가능',
    '진술충': '토(土)끼리의 충돌. 고집과 신념의 대립, 변화와 개혁의 에너지. 두 사람 모두 자기 뜻이 강해 부딪힐 수 있음',
    '사해충': '불(火)과 물(水)의 충돌. 지혜와 행동의 갈등, 이동과 여행이 잦을 수 있음',
    // === 형 (刑) ===
    '인사신형': '무은지형(無恩之刑). 은혜를 모르는 형벌로, 서로 돕고도 원망하는 관계. 의리와 배신의 갈등이 생길 수 있음',
    '인사신 형': '무은지형(無恩之刑). 은혜를 모르는 형벌로, 서로 돕고도 원망하는 관계',
    '축술미형': '지세지형(恃勢之刑). 권력에 의지하는 형벌로, 교만하거나 독선적인 태도에서 갈등 발생',
    '자묘형': '무례지형(無禮之刑). 예의를 모르는 형벌로, 무례하거나 방종한 행동에서 문제 발생',
    '진진자형': '자형(自刑). 같은 글자끼리의 형벌로, 자기 자신에게 엄격하고 완벽주의 성향. 자기비판이 강할 수 있음',
    '오오자형': '자형(自刑). 열정이 과잉되어 충동적이거나 급한 성격으로 나타남',
    '유유자형': '자형(自刑). 외로움과 고독감, 지나친 집착으로 인한 갈등',
    '해해자형': '자형(自刑). 과도한 걱정과 불안, 우유부단으로 결정이 어려움',
    // 삼형살 (三刑殺) - 세 글자 조합
    '인사신삼형살': '삼형살(三刑殺). 인(寅)·사(巳)·신(申)이 모두 만나는 무은지형(無恩之刑). 은혜를 원수로 갚는 강한 형벌로, 큰 시련이 따르지만 극복하면 크게 성장',
    '축술미삼형살': '삼형살(三刑殺). 축(丑)·술(戌)·미(未)가 모두 만나는 지세지형(恃勢之刑). 권력과 고집으로 인한 충돌, 자존심 싸움이 심할 수 있음',
    '인사신 삼형살': '삼형살(三刑殺). 인(寅)·사(巳)·신(申) 무은지형. 은혜를 원수로 갚는 형벌, 큰 시련 속 성장의 기회',
    '축술미 삼형살': '삼형살(三刑殺). 축(丑)·술(戌)·미(未) 지세지형. 권력과 고집의 충돌',
    // === 삼합 (三合) ===
    '신자진합수': '수(水)국 삼합. 신(申)·자(子)·진(辰)이 모여 물의 기운을 강하게 형성. 지혜·소통·유연함이 크게 강화됨',
    '인오술합화': '화(火)국 삼합. 인(寅)·오(午)·술(戌)이 모여 불의 기운을 강하게 형성. 열정·추진력·리더십이 크게 강화됨',
    '사유축합금': '금(金)국 삼합. 사(巳)·유(酉)·축(丑)이 모여 쇠의 기운을 강하게 형성. 결단력·실행력·의지가 크게 강화됨',
    '해묘미합목': '목(木)국 삼합. 해(亥)·묘(卯)·미(未)가 모여 나무의 기운을 강하게 형성. 성장·인자함·창의력이 크게 강화됨',
    // === 반합 (半合) ===
    '신자진반합': '수(水)국 반합. 삼합(申子辰)의 두 글자가 만나 부분적인 합을 이룸. 지혜와 소통의 기운이 있으나 삼합보다 약함',
    '인오술반합': '화(火)국 반합. 삼합(寅午戌)의 두 글자가 만나 부분적인 합을 이룸. 열정의 기운이 있으나 완전하지 않음',
    '사유축반합': '금(金)국 반합. 삼합(巳酉丑)의 두 글자가 만나 부분적인 합을 이룸. 결단의 기운이 있으나 완전하지 않음',
    '해묘미반합': '목(木)국 반합. 삼합(亥卯未)의 두 글자가 만나 부분적인 합을 이룸. 성장의 기운이 있으나 완전하지 않음',
    // === 방합 (方合) - 세 글자 완전 방합만 ===
    '인묘진방합': '동방(東方) 목(木)의 방합. 인(寅)·묘(卯)·진(辰)이 모두 모여 봄의 에너지를 형성. 성장·발전·시작의 강한 기운',
    '사오미방합': '남방(南方) 화(火)의 방합. 사(巳)·오(午)·미(未)가 모두 모여 여름의 에너지를 형성. 열정·화려함·확장의 강한 기운',
    '신유술방합': '서방(西方) 금(金)의 방합. 신(申)·유(酉)·술(戌)이 모두 모여 가을의 에너지를 형성. 결실·수확·정리의 강한 기운',
    '해자축방합': '북방(北方) 수(水)의 방합. 해(亥)·자(子)·축(丑)이 모두 모여 겨울의 에너지를 형성. 축적·지혜·내면의 강한 기운',
    // === 천간합 (天干合 · 천간오합) ===
    '갑기합': '갑(甲)과 기(己)의 합. 토(土)로 변화하며, 서로 보완하는 안정적 관계. 리더와 참모의 궁합',
    '을경합': '을(乙)과 경(庚)의 합. 금(金)으로 변화하며, 부드러움과 강함이 조화. 인의(仁義)의 궁합',
    '병신합': '병(丙)과 신(辛)의 합. 수(水)로 변화하며, 열정과 섬세함이 만남. 위엄과 지혜의 궁합',
    '정임합': '정(丁)과 임(壬)의 합. 목(木)으로 변화하며, 따뜻함과 포용이 만남. 인자(仁慈)의 궁합',
    '무계합': '무(戊)와 계(癸)의 합. 화(火)로 변화하며, 중후함과 총명함이 만남. 무정지합(無情之合)이라고도 함',
    // === 육합 (六合) ===
    '자축합': '자(子)와 축(丑)의 합. 토(土)로 변화하며, 안정과 신뢰를 바탕으로 한 조화로운 관계',
    '인해합': '인(寅)과 해(亥)의 합. 목(木)으로 변화하며, 서로의 성장을 돕는 발전적 관계',
    '묘술합': '묘(卯)와 술(戌)의 합. 화(火)로 변화하며, 따뜻하고 열정적인 관계',
    '진유합': '진(辰)과 유(酉)의 합. 금(金)으로 변화하며, 실질적이고 결단력 있는 관계',
    '사신합': '사(巳)와 신(申)의 합. 수(水)로 변화하며, 지혜롭고 소통이 원활한 관계',
    '오미합': '오(午)와 미(未)의 합. 태양과 태음의 합으로, 음양이 조화를 이루는 이상적 관계',
    // === 해 (害) ===
    '자미해': '자(子)와 미(未)의 해. 가까운 사이에서 오는 배신이나 갈등. 서로의 기대가 어긋남',
    '축오해': '축(丑)과 오(午)의 해. 신뢰와 의리에 상처를 주는 관계',
    '인사해': '인(寅)과 사(巳)의 해. 인연이 어긋나기 쉬운 관계',
    '묘진해': '묘(卯)와 진(辰)의 해. 은혜를 원수로 갚는 형상',
    '신해해': '신(申)과 해(亥)의 해. 서로에 대한 의심이 깊어지는 관계',
    '유술해': '유(酉)와 술(戌)의 해. 가까울수록 상처받기 쉬운 관계',
    // === 파 (破) ===
    '자유파': '자(子)와 유(酉)의 파. 기존 질서가 해체되며 새로운 변화가 필요',
    '축진파': '축(丑)과 진(辰)의 파. 안정된 관계에 균열이 생김',
    '인해파': '인(寅)과 해(亥)의 파. 관계의 틈이 벌어질 수 있음',
    '묘오파': '묘(卯)와 오(午)의 파. 감정적 균열로 인한 갈등',
    '사신파': '사(巳)와 신(申)의 파. 계획이 차질을 빚을 수 있음',
    '미술파': '미(未)와 술(戌)의 파. 고집끼리 부딪혀 깨지는 관계',
    // === 원진 (怨嗔) ===
    '자미원진': '자(子)와 미(未)의 원진. 서로 꺼리고 불편한 인연, 가까이하기 어려움',
    '축오원진': '축(丑)과 오(午)의 원진. 마음이 맞지 않는 인연',
    '인유원진': '인(寅)과 유(酉)의 원진. 갈등이 잦고 이해하기 힘든 관계',
    '묘신원진': '묘(卯)와 신(申)의 원진. 서로 다른 가치관으로 충돌',
    '진해원진': '진(辰)과 해(亥)의 원진. 서로 피하게 되는 인연',
    '사술원진': '사(巳)와 술(戌)의 원진. 충돌이 잦고 화해가 어려운 관계',
  };

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

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFFEC4899);
    if (score >= 60) return const Color(0xFF3B82F6);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFF6B7280);
  }
}
