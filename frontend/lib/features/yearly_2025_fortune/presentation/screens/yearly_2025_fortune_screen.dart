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
import '../providers/yearly_2025_fortune_provider.dart';

/// 2025년 운세 상세 화면 - 개선된 UI/UX (회고 스타일)
class Yearly2025FortuneScreen extends ConsumerWidget {
  const Yearly2025FortuneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final fortuneAsync = ref.watch(yearly2025FortuneProvider);

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
          '2025년 운세',
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
            onPressed: () => ref.read(yearly2025FortuneProvider.notifier).refresh(),
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
    debugPrint('[Yearly2025FortuneScreen] error: $error');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.textMuted),
            const SizedBox(height: 16),
            Text(
              '2025년 운세를 불러오지 못했습니다',
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
              onPressed: () => ref.read(yearly2025FortuneProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('다시 시도'),
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
            '🔮 AI가 2025년 운세를 분석하고 있어요',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '잠시만 기다려주세요...',
            style: TextStyle(color: theme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppThemeExtension theme, Yearly2025FortuneData fortune) {
    // 반응형 패딩 적용
    final horizontalPadding = context.horizontalPadding;
    final isSmall = context.isSmallMobile;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isSmall ? 12 : 16),
      children: [
        // 히어로 헤더 (회고 스타일)
        FortuneTitleHeader(
          title: '${fortune.year}년 회고',
          subtitle: fortune.yearGanji,
          keyword: fortune.overview.keyword.isNotEmpty ? fortune.overview.keyword : null,
          score: fortune.overview.score > 0 ? fortune.overview.score : null,
          style: HeaderStyle.hero,
        ),
        const SizedBox(height: 24),

        // 년도 특징 카드 (청뱀의 해 등)
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
                : '나의 사주, 나는 누구인가요?',
            icon: Icons.person_outline,
            content: fortune.mySajuIntro!.reading,
            style: CardStyle.gradient,
          ),
          const SizedBox(height: 24),
        ],

        // 2025년 총운
        FortuneSectionCard(
          title: '2025년 총운',
          icon: Icons.auto_awesome,
          style: CardStyle.elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (fortune.overview.opening.isNotEmpty)
                Text(
                  fortune.overview.opening,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textSecondary,
                    height: 1.8,
                  ),
                ),
              if (fortune.overview.yearEnergy.isNotEmpty) ...[
                const SizedBox(height: 16),
                FortuneHighlightBox(
                  label: '올해의 기운',
                  content: fortune.overview.yearEnergy,
                  type: HighlightType.info,
                  icon: Icons.bolt,
                ),
              ],
              if (fortune.overview.hapchungEffect.isNotEmpty) ...[
                const SizedBox(height: 12),
                FortuneHighlightBox(
                  label: '합충 영향',
                  content: fortune.overview.hapchungEffect,
                  type: HighlightType.warning,
                ),
              ],
              if (fortune.overview.conclusion.isNotEmpty) ...[
                const SizedBox(height: 16),
                FortuneHighlightBox(
                  label: '결론',
                  content: fortune.overview.conclusion,
                  type: HighlightType.primary,
                  icon: Icons.check_circle_outline,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 빛나는 순간들 (성취)
        if (fortune.achievements.reading.isNotEmpty || fortune.achievements.highlights.isNotEmpty) ...[
          FortuneSectionCard(
            title: fortune.achievements.title.isNotEmpty
                ? fortune.achievements.title
                : '2025년의 빛나는 순간들',
            icon: Icons.star,
            style: CardStyle.outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fortune.achievements.reading.isNotEmpty)
                  Text(
                    fortune.achievements.reading,
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.textSecondary,
                      height: 1.8,
                    ),
                  ),
                if (fortune.achievements.highlights.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildHighlightsList(theme, fortune.achievements.highlights, HighlightType.success),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // 시련과 성장 (도전)
        if (fortune.challenges.reading.isNotEmpty || fortune.challenges.growthPoints.isNotEmpty) ...[
          FortuneSectionCard(
            title: fortune.challenges.title.isNotEmpty
                ? fortune.challenges.title
                : '2025년의 시련, 그리고 성장',
            icon: Icons.trending_up,
            style: CardStyle.outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fortune.challenges.reading.isNotEmpty)
                  Text(
                    fortune.challenges.reading,
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.textSecondary,
                      height: 1.8,
                    ),
                  ),
                if (fortune.challenges.growthPoints.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildHighlightsList(theme, fortune.challenges.growthPoints, HighlightType.warning),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // 분야별 운세 섹션
        if (fortune.categories.isNotEmpty) ...[
          const FortuneSectionTitle(
            title: '2025년 분야별 운세',
            subtitle: '탭하여 상세 운세를 확인하세요',
            icon: Icons.grid_view,
          ),
          const SizedBox(height: 12),
          FortuneCategoryChipSection(
            fortuneType: 'yearly_2025',
            title: '',
            categories: fortune.categories.map((key, cat) => MapEntry(
              key,
              CategoryData(
                title: cat.title,
                score: cat.score,
                reading: cat.reading,
              ),
            )),
          ),
          const SizedBox(height: 24),
        ],

        // 교훈
        if (fortune.lessons.reading.isNotEmpty || fortune.lessons.keyLessons.isNotEmpty) ...[
          FortuneSectionCard(
            title: fortune.lessons.title.isNotEmpty
                ? fortune.lessons.title
                : '2025년이 가르쳐준 것들',
            icon: Icons.lightbulb_outline,
            style: CardStyle.gradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fortune.lessons.reading.isNotEmpty)
                  Text(
                    fortune.lessons.reading,
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.textSecondary,
                      height: 1.8,
                    ),
                  ),
                if (fortune.lessons.keyLessons.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildLessonChips(theme, fortune.lessons.keyLessons),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // 2026년으로 가져가세요
        if (fortune.to2026.reading.isNotEmpty || fortune.to2026.strengths.isNotEmpty) ...[
          FortuneSectionCard(
            title: fortune.to2026.title.isNotEmpty
                ? fortune.to2026.title
                : '2026년으로 가져가세요',
            icon: Icons.arrow_forward,
            style: CardStyle.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fortune.to2026.reading.isNotEmpty)
                  Text(
                    fortune.to2026.reading,
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.textSecondary,
                      height: 1.8,
                    ),
                  ),
                if (fortune.to2026.strengths.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildStrengthsAndCautions(
                    theme,
                    '강점',
                    fortune.to2026.strengths,
                    Icons.add_circle_outline,
                    Colors.green,
                  ),
                ],
                if (fortune.to2026.watchOut.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildStrengthsAndCautions(
                    theme,
                    '주의할 점',
                    fortune.to2026.watchOut,
                    Icons.warning_amber,
                    Colors.orange,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // 마무리 메시지
        if (fortune.closingMessage.isNotEmpty) ...[
          FortuneSectionCard(
            title: '2025년을 마무리하며',
            icon: Icons.favorite_border,
            style: CardStyle.gradient,
            content: fortune.closingMessage,
          ),
          const SizedBox(height: 24),
        ],

        // AI 상담 버튼
        _buildConsultButton(context, theme),
        const SizedBox(height: 40),
      ],
    );
  }

  /// 하이라이트 리스트 (성취, 도전)
  Widget _buildHighlightsList(AppThemeExtension theme, List<String> items, HighlightType type) {
    final color = type == HighlightType.success ? Colors.green : Colors.orange;
    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  /// 교훈 칩
  Widget _buildLessonChips(AppThemeExtension theme, List<String> lessons) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: lessons.map((lesson) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_objects, size: 14, color: theme.primaryColor),
            const SizedBox(width: 6),
            Text(
              lesson,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.textPrimary,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  /// 강점 & 주의사항
  Widget _buildStrengthsAndCautions(
    AppThemeExtension theme,
    String label,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: theme.textSecondary)),
                Expanded(
                  child: Text(
                    item,
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
        onPressed: () => context.go('/saju/chat?type=yearly2025Fortune'),
        icon: const Icon(Icons.chat_bubble_outline, size: 20),
        label: const Text(
          'AI에게 2025년 상담받기',
          style: TextStyle(
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
}
