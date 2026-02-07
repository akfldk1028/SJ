import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/illustrations/illustrations.dart';
import '../../../../shared/widgets/fortune_shimmer_loading.dart';
import '../../../../shared/widgets/fortune_category_chip_section.dart';
import '../../../../shared/widgets/fortune_title_header.dart';
import '../../../../shared/widgets/fortune_section_card.dart';
import '../../../../shared/widgets/fortune_year_info_card.dart';
import '../providers/new_year_fortune_provider.dart';

/// 2026 신년운세 화면 - 개선된 UI/UX
class NewYearFortuneScreen extends ConsumerWidget {
  const NewYearFortuneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final fortuneAsync = ref.watch(newYearFortuneProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'new_year_fortune.appBarTitle'.tr(),
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.textSecondary, size: 22),
            onPressed: () => ref.read(newYearFortuneProvider.notifier).refresh(),
          ),
        ],
      ),
      body: fortuneAsync.when(
        loading: () => const FortuneShimmerLoading(),
        error: (error, stack) => _buildError(context, theme, ref, error),
        data: (fortune) {
          if (fortune == null) {
            return _buildAnalyzing(theme);
          }
          return _buildContent(context, theme, fortune);
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, AppThemeExtension theme, WidgetRef ref, Object error) {
    debugPrint('[NewYearFortuneScreen] error: $error');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.textMuted),
            const SizedBox(height: 16),
            Text(
              'new_year_fortune.errorLoad'.tr(),
              style: TextStyle(color: theme.textSecondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: TextStyle(color: theme.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(newYearFortuneProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text('new_year_fortune.retry'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzing(AppThemeExtension theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 100,
            height: 100,
            child: AnimatedYinYangIllustration(
              size: 100,
              showGlow: true,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'new_year_fortune.analyzingTitle'.tr(),
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'new_year_fortune.pleaseWait'.tr(),
            style: TextStyle(color: theme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppThemeExtension theme, NewYearFortuneData fortune) {
    // 반응형 패딩 적용
    final horizontalPadding = context.horizontalPadding;
    final isSmall = context.isSmallMobile;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isSmall ? 12 : 16),
      children: [
        // 히어로 헤더 (타이틀 + 점수 + 키워드)
        FortuneTitleHeader(
          title: 'new_year_fortune.yearNewYearFortune'.tr(namedArgs: {'year': '${fortune.year}'}),
          subtitle: fortune.yearGanji,
          keyword: fortune.overview.keyword.isNotEmpty ? fortune.overview.keyword : null,
          score: fortune.overview.score > 0 ? fortune.overview.score : null,
          style: HeaderStyle.hero,
        ),
        const SizedBox(height: 24),

        // 년도 특징 카드 (붉은말의 해 등)
        FortuneYearInfoCard(
          year: fortune.year,
          ganji: fortune.yearGanji.replaceAll('년', ''),
        ),
        const SizedBox(height: 24),

        // 나의 사주 소개 (있으면)
        if (fortune.mySajuIntro != null && fortune.mySajuIntro!.reading.isNotEmpty) ...[
          FortuneSectionCard(
            title: fortune.mySajuIntro!.title.isNotEmpty
                ? fortune.mySajuIntro!.title
                : 'new_year_fortune.mySajuIntroDefault'.tr(),
            icon: Icons.person_outline,
            content: fortune.mySajuIntro!.reading,
            style: CardStyle.gradient,
          ),
          const SizedBox(height: 24),
        ],

        // 2026년 총운 (opening 사용)
        FortuneSectionCard(
          title: 'new_year_fortune.yearOverallFortune'.tr(namedArgs: {'year': '${fortune.year}'}),
          icon: Icons.auto_awesome,
          style: CardStyle.elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // opening (DB 구조)이 있으면 우선 사용, 없으면 summary 사용
              if (fortune.overview.opening.isNotEmpty)
                Text(
                  fortune.overview.opening,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textSecondary,
                    height: 1.8,
                  ),
                )
              else if (fortune.overview.summary.isNotEmpty)
                Text(
                  fortune.overview.summary,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textSecondary,
                    height: 1.8,
                  ),
                ),
              // 일간 분석
              if (fortune.overview.ilganAnalysis.isNotEmpty) ...[
                const SizedBox(height: 16),
                FortuneHighlightBox(
                  label: 'new_year_fortune.ilganAnalysis'.tr(),
                  content: fortune.overview.ilganAnalysis,
                  type: HighlightType.primary,
                  icon: Icons.person_outline,
                ),
              ],
              // 신살 분석
              if (fortune.overview.sinsalAnalysis.isNotEmpty) ...[
                const SizedBox(height: 16),
                FortuneHighlightBox(
                  label: 'new_year_fortune.sinsalAnalysis'.tr(),
                  content: fortune.overview.sinsalAnalysis,
                  type: HighlightType.info,
                  icon: Icons.star_outline,
                ),
              ],
              // 합충 분석
              if (fortune.overview.hapchungAnalysis.isNotEmpty) ...[
                const SizedBox(height: 16),
                FortuneHighlightBox(
                  label: 'new_year_fortune.hapchungAnalysis'.tr(),
                  content: fortune.overview.hapchungAnalysis,
                  type: HighlightType.info,
                  icon: Icons.sync_alt,
                ),
              ],
              // 용신 분석
              if (fortune.overview.yongshinAnalysis.isNotEmpty) ...[
                const SizedBox(height: 16),
                FortuneHighlightBox(
                  label: 'new_year_fortune.yongshinAnalysis'.tr(),
                  content: fortune.overview.yongshinAnalysis,
                  type: HighlightType.warning,
                  icon: Icons.water_drop_outlined,
                ),
              ],
              // 연도 에너지 결론
              if (fortune.overview.yearEnergyConclusion.isNotEmpty) ...[
                const SizedBox(height: 16),
                FortuneHighlightBox(
                  label: 'new_year_fortune.yearEnergyConclusion'.tr(namedArgs: {'year': '${fortune.year}'}),
                  content: fortune.overview.yearEnergyConclusion,
                  type: HighlightType.success,
                  icon: Icons.bolt,
                ),
              ],
              // 레거시 keyPoint
              if (fortune.overview.keyPoint.isNotEmpty) ...[
                const SizedBox(height: 16),
                FortuneHighlightBox(
                  label: 'new_year_fortune.keyPoint'.tr(),
                  content: fortune.overview.keyPoint,
                  type: HighlightType.primary,
                  icon: Icons.lightbulb_outline,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 연도 정보 (납음, 12운성, 신살)
        if (_hasYearInfo(fortune.yearInfo)) ...[
          FortuneSectionCard(
            title: 'new_year_fortune.yearAlias'.tr(namedArgs: {'year': '${fortune.year}', 'alias': fortune.yearInfo.alias}),
            icon: Icons.calendar_today,
            style: CardStyle.outlined,
            child: Column(
              children: [
                if (fortune.yearInfo.napeum.isNotEmpty)
                  _buildInfoTile(theme, 'new_year_fortune.napeum'.tr(), fortune.yearInfo.napeum, fortune.yearInfo.napeumExplain),
                if (fortune.yearInfo.twelveUnsung.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoTile(theme, 'new_year_fortune.twelveUnsung'.tr(), fortune.yearInfo.twelveUnsung, fortune.yearInfo.unsungExplain),
                ],
                if (fortune.yearInfo.mainSinsal.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoTile(theme, 'new_year_fortune.mainSinsal'.tr(), fortune.yearInfo.mainSinsal, fortune.yearInfo.sinsalExplain),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // 나와 2026년의 관계 (개인 분석)
        if (_hasPersonalAnalysis(fortune.personalAnalysis)) ...[
          FortuneSectionCard(
            title: 'new_year_fortune.personalRelation'.tr(namedArgs: {'year': '${fortune.year}'}),
            icon: Icons.connecting_airports,
            style: CardStyle.outlined,
            child: Column(
              children: [
                if (fortune.personalAnalysis.ilgan.isNotEmpty)
                  _buildInfoTile(theme, 'new_year_fortune.ilganAnalysis'.tr(), fortune.personalAnalysis.ilgan, fortune.personalAnalysis.ilganExplain),
                if (fortune.personalAnalysis.fireEffect.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FortuneHighlightBox(
                    label: 'new_year_fortune.fireEffect'.tr(),
                    content: fortune.personalAnalysis.fireEffect,
                    type: HighlightType.warning,
                    icon: Icons.local_fire_department,
                  ),
                ],
                if (fortune.personalAnalysis.yongshinMatch.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FortuneHighlightBox(
                    label: 'new_year_fortune.yongshinMatch'.tr(),
                    content: fortune.personalAnalysis.yongshinMatch,
                    type: HighlightType.info,
                  ),
                ],
                if (fortune.personalAnalysis.hapchungEffect.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FortuneHighlightBox(
                    label: 'new_year_fortune.hapchungEffectLabel'.tr(),
                    content: fortune.personalAnalysis.hapchungEffect,
                    type: HighlightType.info,
                  ),
                ],
                if (fortune.personalAnalysis.sinsalEffect.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FortuneHighlightBox(
                    label: 'new_year_fortune.sinsalEffect'.tr(),
                    content: fortune.personalAnalysis.sinsalEffect,
                    type: HighlightType.info,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // 분야별 운세 섹션 제목
        FortuneSectionTitle(
          title: 'new_year_fortune.categoryFortuneTitle'.tr(namedArgs: {'year': '${fortune.year}'}),
          subtitle: 'new_year_fortune.categoryFortuneSubtitle'.tr(),
          icon: Icons.grid_view,
        ),
        const SizedBox(height: 12),

        // 카테고리별 운세 (광고 잠금)
        FortuneCategoryChipSection(
          fortuneType: 'yearly_2026',
          title: '',
          categories: fortune.categories.isNotEmpty
              ? fortune.categories.map((key, cat) => MapEntry(
                  key,
                  CategoryData(
                    title: cat.title,
                    score: cat.score,
                    reading: cat.reading,
                    summary: cat.summary,
                    bestMonths: cat.bestMonths,
                    cautionMonths: cat.cautionMonths,
                    actionTip: cat.actionTip,
                    focusAreas: cat.focusAreas,
                  ),
                ))
              : _getDefaultCategories(),
        ),
        const SizedBox(height: 24),

        // 행운 정보
        if (_hasLucky(fortune.lucky)) ...[
          FortuneSectionCard(
            title: 'new_year_fortune.luckyInfo'.tr(namedArgs: {'year': '${fortune.year}'}),
            icon: Icons.star,
            style: CardStyle.gradient,
            child: Column(
              children: [
                _buildLuckyGrid(theme, fortune.lucky),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // 빛날 순간들 (achievements)
        if (fortune.achievements != null && fortune.achievements!.reading.isNotEmpty) ...[
          FortuneSectionCard(
            title: fortune.achievements!.title.isNotEmpty
                ? fortune.achievements!.title
                : 'new_year_fortune.achievementsDefault'.tr(namedArgs: {'year': '${fortune.year}'}),
            icon: Icons.emoji_events_outlined,
            style: CardStyle.gradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fortune.achievements!.reading,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textSecondary,
                    height: 1.8,
                  ),
                ),
                if (fortune.achievements!.highlights.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...fortune.achievements!.highlights.map((highlight) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.star, size: 16, color: theme.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            highlight,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // 도전과 성장 (challenges)
        if (fortune.challenges != null && fortune.challenges!.reading.isNotEmpty) ...[
          FortuneSectionCard(
            title: fortune.challenges!.title.isNotEmpty
                ? fortune.challenges!.title
                : 'new_year_fortune.challengesDefault'.tr(namedArgs: {'year': '${fortune.year}'}),
            icon: Icons.trending_up,
            style: CardStyle.outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fortune.challenges!.reading,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textSecondary,
                    height: 1.8,
                  ),
                ),
                if (fortune.challenges!.growthPoints.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...fortune.challenges!.growthPoints.map((point) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_outline, size: 16, color: const Color(0xFF2D8659)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            point,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // 교훈 (lessons)
        if (fortune.lessons != null && fortune.lessons!.reading.isNotEmpty) ...[
          FortuneSectionCard(
            title: fortune.lessons!.title.isNotEmpty
                ? fortune.lessons!.title
                : 'new_year_fortune.lessonsDefault'.tr(namedArgs: {'year': '${fortune.year}'}),
            icon: Icons.school_outlined,
            style: CardStyle.outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fortune.lessons!.reading,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textSecondary,
                    height: 1.8,
                  ),
                ),
                if (fortune.lessons!.keyLessons.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...fortune.lessons!.keyLessons.map((lesson) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, size: 16, color: const Color(0xFFB8860B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lesson,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // 2027년으로 이어가기 (to2027)
        if (fortune.to2027 != null && fortune.to2027!.reading.isNotEmpty) ...[
          FortuneSectionCard(
            title: fortune.to2027!.title.isNotEmpty
                ? fortune.to2027!.title
                : 'new_year_fortune.to2027Default'.tr(),
            icon: Icons.arrow_forward_outlined,
            style: CardStyle.gradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fortune.to2027!.reading,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textSecondary,
                    height: 1.8,
                  ),
                ),
                if (fortune.to2027!.strengths.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  FortuneHighlightBox(
                    label: 'new_year_fortune.strengths'.tr(),
                    content: fortune.to2027!.strengths.join('\n'),
                    type: HighlightType.success,
                    icon: Icons.thumb_up_outlined,
                  ),
                ],
                if (fortune.to2027!.watchOut.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FortuneHighlightBox(
                    label: 'new_year_fortune.watchOut'.tr(),
                    content: fortune.to2027!.watchOut.join('\n'),
                    type: HighlightType.warning,
                    icon: Icons.warning_amber_outlined,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // 마무리 메시지
        if (fortune.closing.yearMessage.isNotEmpty || fortune.closing.finalAdvice.isNotEmpty) ...[
          FortuneSectionCard(
            title: 'new_year_fortune.closingTitle'.tr(namedArgs: {'year': '${fortune.year}'}),
            icon: Icons.celebration,
            style: CardStyle.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fortune.closing.yearMessage.isNotEmpty)
                  Text(
                    fortune.closing.yearMessage,
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.textSecondary,
                      height: 1.8,
                    ),
                  ),
                if (fortune.closing.finalAdvice.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  FortuneHighlightBox(
                    label: 'new_year_fortune.finalAdvice'.tr(),
                    content: fortune.closing.finalAdvice,
                    type: HighlightType.success,
                    icon: Icons.tips_and_updates,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // AI 상담 버튼
        _buildConsultButton(context, theme),
        const SizedBox(height: 40),
      ],
    );
  }

  /// 정보 타일 (제목 + 값 + 설명)
  Widget _buildInfoTile(AppThemeExtension theme, String label, String value, String? explain) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.textMuted.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (explain != null && explain.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              explain,
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 행운 정보 그리드
  Widget _buildLuckyGrid(AppThemeExtension theme, LuckySection lucky) {
    final items = <Map<String, dynamic>>[];

    if (lucky.colors.isNotEmpty) {
      items.add({'icon': Icons.palette, 'label': 'new_year_fortune.luckyColors'.tr(), 'value': lucky.colors.join(', ')});
    }
    if (lucky.numbers.isNotEmpty) {
      items.add({'icon': Icons.pin, 'label': 'new_year_fortune.luckyNumbers'.tr(), 'value': lucky.numbers.join(', ')});
    }
    if (lucky.direction.isNotEmpty) {
      items.add({'icon': Icons.explore, 'label': 'new_year_fortune.goodDirection'.tr(), 'value': lucky.direction});
    }
    if (lucky.items.isNotEmpty) {
      items.add({'icon': Icons.card_giftcard, 'label': 'new_year_fortune.luckyItems'.tr(), 'value': lucky.items.join(', ')});
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) => _buildLuckyChip(
        theme,
        item['icon'] as IconData,
        item['label'] as String,
        item['value'] as String,
      )).toList(),
    );
  }

  Widget _buildLuckyChip(AppThemeExtension theme, IconData icon, String label, String value) {
    // 긴 텍스트인 경우 전체 너비 사용
    final isLongValue = value.length > 20;

    return Container(
      width: isLongValue ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.textMuted.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: isLongValue ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.primaryColor),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textMuted,
                  ),
                ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildConsultButton(BuildContext context, AppThemeExtension theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.accentColor ?? theme.primaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => context.go('/saju/chat?type=newYearFortune'),
        icon: const Icon(Icons.chat_bubble_outline, size: 20),
        label: Text(
          'new_year_fortune.consultAi'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  bool _hasYearInfo(YearInfoSection info) {
    return info.napeum.isNotEmpty ||
        info.twelveUnsung.isNotEmpty ||
        info.mainSinsal.isNotEmpty;
  }

  bool _hasPersonalAnalysis(PersonalAnalysisSection analysis) {
    return analysis.ilgan.isNotEmpty ||
        analysis.fireEffect.isNotEmpty ||
        analysis.yongshinMatch.isNotEmpty ||
        analysis.hapchungEffect.isNotEmpty ||
        analysis.sinsalEffect.isNotEmpty;
  }

  bool _hasLucky(LuckySection lucky) {
    return lucky.colors.isNotEmpty ||
        lucky.numbers.isNotEmpty ||
        lucky.direction.isNotEmpty ||
        lucky.items.isNotEmpty;
  }

  Map<String, CategoryData> _getDefaultCategories() {
    return {
      'career': CategoryData(
        title: 'new_year_fortune.defaultCareer'.tr(),
        score: 0,
        reading: 'new_year_fortune.watchAdToView'.tr(namedArgs: {'year': '2026', 'category': 'new_year_fortune.defaultCareer'.tr()}),
      ),
      'wealth': CategoryData(
        title: 'new_year_fortune.defaultWealth'.tr(),
        score: 0,
        reading: 'new_year_fortune.watchAdToView'.tr(namedArgs: {'year': '2026', 'category': 'new_year_fortune.defaultWealth'.tr()}),
      ),
      'love': CategoryData(
        title: 'new_year_fortune.defaultLove'.tr(),
        score: 0,
        reading: 'new_year_fortune.watchAdToView'.tr(namedArgs: {'year': '2026', 'category': 'new_year_fortune.defaultLove'.tr()}),
      ),
      'health': CategoryData(
        title: 'new_year_fortune.defaultHealth'.tr(),
        score: 0,
        reading: 'new_year_fortune.watchAdToView'.tr(namedArgs: {'year': '2026', 'category': 'new_year_fortune.defaultHealth'.tr()}),
      ),
      'study': CategoryData(
        title: 'new_year_fortune.defaultStudy'.tr(),
        score: 0,
        reading: 'new_year_fortune.watchAdToView'.tr(namedArgs: {'year': '2026', 'category': 'new_year_fortune.defaultStudy'.tr()}),
      ),
      'business': CategoryData(
        title: 'new_year_fortune.defaultBusiness'.tr(),
        score: 0,
        reading: 'new_year_fortune.watchAdToView'.tr(namedArgs: {'year': '2026', 'category': 'new_year_fortune.defaultBusiness'.tr()}),
      ),
    };
  }
}
