import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../../data/models/compatibility_analysis_model.dart';
import '../../data/hapchung_explanations.dart';
import '../../data/compatibility_interpreter.dart';
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

  static const _primaryColor = Color(0xFFD4637B);
  static const _secondaryColor = Color(0xFFE08E9D);

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
          'compatibility.detail_title'.tr(),
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
                    Text('compatibility.menu_reanalyze'.tr(), style: TextStyle(color: theme.textPrimary)),
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
                    Text('compatibility.menu_delete'.tr(), style: const TextStyle(color: Colors.red)),
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
          title: Text('compatibility.delete_title'.tr(), style: TextStyle(color: theme.textPrimary)),
          content: Text(
            'compatibility.delete_confirm_short'.tr(),
            style: TextStyle(color: theme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('common.buttonCancel'.tr(), style: TextStyle(color: theme.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('common.delete'.tr(), style: const TextStyle(color: Colors.red)),
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
            SnackBar(content: Text('compatibility.deleted_snackbar'.tr())),
          );
        }
      }
    } else if (action == 'reanalyze') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('compatibility.reanalyze_started'.tr())),
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
            SnackBar(content: Text('compatibility.reanalyze_complete'.tr())),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('compatibility.reanalyze_failed'.tr(namedArgs: {'error': result.error ?? ''}))),
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
              'compatibility.error_occurred'.tr(),
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
            'compatibility.not_found'.tr(),
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

        // 일주 분석 섹션 (개인화된 해석)
        _buildDayPillarSection(theme, analysis),

        // 요약
        if (analysis.summary != null) ...[
          _buildSummaryCard(theme, analysis.summary!),
          const SizedBox(height: 16),
        ],

        // 합충형해파 분석
        _buildHapchungSection(theme, analysis),
        const SizedBox(height: 16),

        // 강점
        if (analysis.strengths != null && analysis.strengths!.isNotEmpty) ...[
          _buildListSection(
            theme,
            title: 'compatibility.strengths_title'.tr(),
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
            title: 'compatibility.cautions_title'.tr(),
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

  /// 일주 분석 섹션 (개인화된 해석)
  Widget _buildDayPillarSection(
    AppThemeExtension theme,
    CompatibilityAnalysisModel analysis,
  ) {
    // 일주 정보가 없으면 표시하지 않음
    if (analysis.ownerDayGan == null && analysis.targetDayGan == null) {
      return const SizedBox.shrink();
    }

    final interpreter = CompatibilityInterpreter(
      myDayGan: analysis.ownerDayGan,
      myDayJi: analysis.ownerDayJi,
      targetDayGan: analysis.targetDayGan,
      targetDayJi: analysis.targetDayJi,
      pairHapchung: analysis.pairHapchung,
    );

    final interpretation = interpreter.generateInterpretation();
    if (!interpretation.hasContent) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF9B7ED6).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF9B7ED6).withValues(alpha: 0.2),
                          const Color(0xFFB794F6).withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Color(0xFF9B7ED6),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'compatibility.day_pillar_title'.tr(),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'compatibility.day_pillar_subtitle'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF9B7ED6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 내 일간 소개
              if (interpretation.myDayGanIntro.isNotEmpty) ...[
                _buildInterpretationItem(
                  theme,
                  icon: Icons.person_rounded,
                  iconColor: const Color(0xFFD4637B),
                  title: 'compatibility.my_day_gan'.tr(),
                  content: interpretation.myDayGanIntro,
                ),
                const SizedBox(height: 14),
              ],

              // 상대 일간 소개
              if (interpretation.targetDayGanIntro.isNotEmpty) ...[
                _buildInterpretationItem(
                  theme,
                  icon: Icons.person_outline_rounded,
                  iconColor: const Color(0xFF6B7F99),
                  title: 'compatibility.target_day_gan'.tr(),
                  content: interpretation.targetDayGanIntro,
                ),
                const SizedBox(height: 14),
              ],

              // 천간합 분석 (있을 경우)
              if (interpretation.ganHapAnalysis != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFD4637B).withValues(alpha: 0.1),
                        const Color(0xFFE08E9D).withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD4637B).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            color: Color(0xFFD4637B),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'compatibility.cheongan_hap_title'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFD4637B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        interpretation.ganHapAnalysis!,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 오행 분석
              if (interpretation.ohengAnalysis != null) ...[
                _buildInterpretationItem(
                  theme,
                  icon: Icons.spa_rounded,
                  iconColor: const Color(0xFF4CAF50),
                  title: 'compatibility.oheng_relation'.tr(),
                  content: interpretation.ohengAnalysis!,
                ),
                const SizedBox(height: 14),
              ],

              // 조언
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B7ED6).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xFF9B7ED6),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        interpretation.advice,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInterpretationItem(
    AppThemeExtension theme, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
        ),
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
            '${analysis.scoreGrade} ${'compatibility.score_suffix'.tr()}',
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
          // 合/沖 요약 - 한자 포함
          if (analysis.positiveCount > 0 || analysis.negativeCount > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (analysis.positiveCount > 0)
                  _buildCountBadge(
                    icon: Icons.brightness_5_rounded,
                    count: analysis.positiveCount,
                    label: '\u5408',
                    color: const Color(0xFFD4637B),
                  ),
                if (analysis.positiveCount > 0 && analysis.negativeCount > 0)
                  const SizedBox(width: 16),
                if (analysis.negativeCount > 0)
                  _buildCountBadge(
                    icon: Icons.contrast_rounded,
                    count: analysis.negativeCount,
                    label: '\u6C96',
                    color: const Color(0xFF6B7F99),
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
            '$label ${'compatibility.count_suffix'.tr(namedArgs: {'count': count.toString()})}',
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
                'compatibility.summary_title'.tr(),
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

  // ===== 합충형해파 분석 (Modern Redesign) =====

  Widget _buildHapchungSection(
      AppThemeExtension theme, CompatibilityAnalysisModel analysis) {
    final ph = analysis.pairHapchung;
    if (ph == null) return const SizedBox.shrink();

    final positiveWidgets = <Widget>[];
    final negativeWidgets = <Widget>[];

    // 긍정적 관계 (합) - 합력 순: 방합 > 삼합 > 육합 > 천간합 > 반합
    // 통일된 accent color 사용 (모던/미니멀)
    const hapColor = Color(0xFFD4637B); // 따뜻한 로즈
    _addCategoryIfNotEmpty(positiveWidgets, theme, '\u65B9\u5408 \uBC29\uD569',
        _filterFullBanghap(_toStringList(ph['banghap'])),
        hapColor, Icons.panorama_fish_eye);
    _addCategoryIfNotEmpty(positiveWidgets, theme, '\u4E09\u5408 \uC0BC\uD569',
        _toStringList(ph['samhap']), hapColor, Icons.change_history_rounded);
    _addCategoryIfNotEmpty(positiveWidgets, theme, '\u516D\u5408 \uC721\uD569',
        _toStringList(ph['yukhap']), hapColor, Icons.link_rounded);
    _addCategoryIfNotEmpty(positiveWidgets, theme, '\u5929\u5E72\u5408 \uCC9C\uAC04\uD569',
        _toStringList(ph['cheongan_hap']), hapColor, Icons.sync_alt_rounded);
    _addCategoryIfNotEmpty(positiveWidgets, theme, '\u534A\u5408 \uBC18\uD569',
        _toStringList(ph['banhap']), hapColor, Icons.pie_chart_outline_rounded);

    // 부정적 관계 - 통일된 색상
    const chungColor = Color(0xFF6B7F99); // 차분한 슬레이트
    _addCategoryIfNotEmpty(negativeWidgets, theme, '\u5929\u5E72\u6C96 \uCC9C\uAC04\uCDA9',
        _toStringList(ph['cheongan_chung']), chungColor, Icons.compare_arrows_rounded);
    _addCategoryIfNotEmpty(negativeWidgets, theme, '\u5730\u652F\u6C96 \uC9C0\uC9C0\uCDA9',
        _toStringList(ph['chung']), chungColor, Icons.swap_horiz_rounded);
    _addCategoryIfNotEmpty(negativeWidgets, theme, '\u5211 \uD615',
        _toStringList(ph['hyung']), chungColor, Icons.gavel_rounded);
    _addCategoryIfNotEmpty(negativeWidgets, theme, '\u5BB3 \uD574',
        _toStringList(ph['hae']), chungColor, Icons.remove_circle_outline_rounded);
    _addCategoryIfNotEmpty(negativeWidgets, theme, '\u7834 \uD30C',
        _toStringList(ph['pa']), chungColor, Icons.radio_button_unchecked);
    _addCategoryIfNotEmpty(negativeWidgets, theme, '\u6028\u55D4 \uC6D0\uC9C4',
        _toStringList(ph['wonjin']), chungColor, Icons.block_rounded);

    // Fallback: sub-categories 없으면 hap/chung 필드 사용
    if (positiveWidgets.isEmpty) {
      // hap에서도 "일부" 방합 제외
      final hapFiltered = _toStringList(ph['hap'])
          .where((e) => !e.contains('\uC77C\uBD80'))
          .toList();
      _addCategoryIfNotEmpty(positiveWidgets, theme, 'compatibility.hap_fallback'.tr(),
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
            title: 'compatibility.hap_harmony_title'.tr(),
            subtitle: 'compatibility.hap_harmony_subtitle'.tr(),
            icon: Icons.brightness_5_rounded,
            accentColor: const Color(0xFFD4637B),
            children: positiveWidgets,
          ),
        if (positiveWidgets.isNotEmpty && negativeWidgets.isNotEmpty)
          const SizedBox(height: 16),
        if (negativeWidgets.isNotEmpty)
          _buildGroupCard(
            theme,
            title: 'compatibility.chung_tension_title'.tr(),
            subtitle: 'compatibility.chung_tension_subtitle'.tr(),
            icon: Icons.contrast_rounded,
            accentColor: const Color(0xFF6B7F99),
            children: negativeWidgets,
          ),
      ],
    );
  }

  /// 방합: "일부" 포함된 항목 제외 (세 글자 완전 방합만)
  List<String> _filterFullBanghap(List<String> entries) {
    return entries.where((e) => !e.contains('\uC77C\uBD80')).toList();
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
                            '\u00D7${item.count}',
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
    return hapchungExplanations[key] ??
        hapchungExplanations[name] ??
        '';
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
              Text(
                'compatibility.advice_title'.tr(),
                style: const TextStyle(
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
    if (score >= 80) return const Color(0xFFD4637B); // 로즈
    if (score >= 60) return const Color(0xFF6B7F99); // 슬레이트
    if (score >= 40) return const Color(0xFF9CA3AF); // 그레이
    return const Color(0xFF6B7280); // 다크 그레이
  }
}
