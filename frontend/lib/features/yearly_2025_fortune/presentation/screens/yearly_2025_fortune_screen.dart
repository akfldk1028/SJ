import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/fortune_shimmer_loading.dart';
import '../../../../shared/widgets/fortune_category_chip_section.dart';
import '../providers/yearly_2025_fortune_provider.dart';

/// 2025년 운세 상세 화면 - 책처럼 읽기 쉬운 레이아웃
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
        error: (error, stack) => _buildError(context, theme, ref),
        data: (fortune) {
          if (fortune == null) {
            return _buildAnalyzing(theme);
          }
          return _buildContent(context, theme, fortune);
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, AppThemeExtension theme, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '2025년 운세를 불러오지 못했습니다',
            style: TextStyle(color: theme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => ref.read(yearly2025FortuneProvider.notifier).refresh(),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzing(AppThemeExtension theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '2025년 운세를 분석하고 있습니다...',
            style: TextStyle(color: theme.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppThemeExtension theme, Yearly2025FortuneData fortune) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        // 제목
        _buildTitle(theme, fortune),
        const SizedBox(height: 32),

        // v7.0: 나의 사주 소개
        if (fortune.mySajuIntro != null && fortune.mySajuIntro!.reading.isNotEmpty) ...[
          _buildMySajuIntroSection(theme, fortune.mySajuIntro!),
          const SizedBox(height: 32),
        ],

        // 연간 총운
        _buildSection(
          theme,
          title: '2025년 총운',
          children: [
            if (fortune.overview.keyword.isNotEmpty)
              _buildKeyword(theme, fortune.overview.keyword, fortune.overview.score),
            if (fortune.overview.opening.isNotEmpty)
              _buildParagraph(theme, fortune.overview.opening),
            if (fortune.overview.yearEnergy.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSubSection(theme, '올해의 기운', fortune.overview.yearEnergy),
            ],
            if (fortune.overview.hapchungEffect.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSubSection(theme, '합충 영향', fortune.overview.hapchungEffect),
            ],
            if (fortune.overview.conclusion.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSubSection(theme, '결론', fortune.overview.conclusion),
            ],
          ],
        ),
        const SizedBox(height: 32),

        // 성취
        if (fortune.achievements.reading.isNotEmpty || fortune.achievements.highlights.isNotEmpty) ...[
          _buildSection(
            theme,
            title: fortune.achievements.title.isNotEmpty ? fortune.achievements.title : '2025년의 빛나는 순간들',
            children: [
              if (fortune.achievements.reading.isNotEmpty)
                _buildParagraph(theme, fortune.achievements.reading),
              if (fortune.achievements.highlights.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...fortune.achievements.highlights.map((item) => _buildListItem(theme, item)),
              ],
            ],
          ),
          const SizedBox(height: 32),
        ],

        // 도전
        if (fortune.challenges.reading.isNotEmpty || fortune.challenges.growthPoints.isNotEmpty) ...[
          _buildSection(
            theme,
            title: fortune.challenges.title.isNotEmpty ? fortune.challenges.title : '2025년의 시련, 그리고 성장',
            children: [
              if (fortune.challenges.reading.isNotEmpty)
                _buildParagraph(theme, fortune.challenges.reading),
              if (fortune.challenges.growthPoints.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...fortune.challenges.growthPoints.map((item) => _buildListItem(theme, item)),
              ],
            ],
          ),
          const SizedBox(height: 32),
        ],

        // 카테고리별 운세 (광고 잠금)
        if (fortune.categories.isNotEmpty) ...[
          FortuneCategoryChipSection(
            fortuneType: 'yearly_2025',
            title: '2025년 분야별 운세',
            categories: fortune.categories.map((key, cat) => MapEntry(
              key,
              CategoryData(
                title: cat.title,
                score: cat.score,
                reading: cat.reading,
              ),
            )),
          ),
          const SizedBox(height: 32),
        ],

        // 교훈
        if (fortune.lessons.reading.isNotEmpty || fortune.lessons.keyLessons.isNotEmpty) ...[
          _buildSection(
            theme,
            title: fortune.lessons.title.isNotEmpty ? fortune.lessons.title : '2025년이 가르쳐준 것들',
            children: [
              if (fortune.lessons.reading.isNotEmpty)
                _buildParagraph(theme, fortune.lessons.reading),
              if (fortune.lessons.keyLessons.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...fortune.lessons.keyLessons.map((item) => _buildListItem(theme, item)),
              ],
            ],
          ),
          const SizedBox(height: 32),
        ],

        // 2026년으로
        if (fortune.to2026.reading.isNotEmpty || fortune.to2026.strengths.isNotEmpty) ...[
          _buildSection(
            theme,
            title: fortune.to2026.title.isNotEmpty ? fortune.to2026.title : '2026년으로 가져가세요',
            children: [
              if (fortune.to2026.reading.isNotEmpty)
                _buildParagraph(theme, fortune.to2026.reading),
              if (fortune.to2026.strengths.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '강점:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...fortune.to2026.strengths.map((item) => _buildListItem(theme, item)),
              ],
              if (fortune.to2026.watchOut.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '주의할 점:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...fortune.to2026.watchOut.map((item) => _buildListItem(theme, item)),
              ],
            ],
          ),
          const SizedBox(height: 32),
        ],

        // 마무리 메시지
        if (fortune.closingMessage.isNotEmpty) ...[
          _buildSection(
            theme,
            title: '2025년을 마무리하며',
            children: [
              _buildParagraph(theme, fortune.closingMessage),
            ],
          ),
          const SizedBox(height: 32),
        ],

        // AI 상담 버튼
        _buildConsultButton(context, theme),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTitle(AppThemeExtension theme, Yearly2025FortuneData fortune) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${fortune.year}년',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        if (fortune.yearGanji.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            fortune.yearGanji,
            style: TextStyle(
              fontSize: 16,
              color: theme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSection(AppThemeExtension theme, {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildSubSection(AppThemeExtension theme, String title, String content) {
    return Column(
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
        const SizedBox(height: 6),
        Text(
          content,
          style: TextStyle(
            fontSize: 15,
            color: theme.textSecondary,
            height: 1.8,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyword(AppThemeExtension theme, String keyword, int score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        '키워드: $keyword  |  총점: $score점',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: theme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildParagraph(AppThemeExtension theme, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        color: theme.textSecondary,
        height: 1.8,
      ),
    );
  }

  Widget _buildListItem(AppThemeExtension theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 15,
              color: theme.textSecondary,
              height: 1.6,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: theme.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultButton(BuildContext context, AppThemeExtension theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.go('/saju/chat?type=yearly2025Fortune'),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.textPrimary,
          foregroundColor: theme.backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'AI에게 2025년 상담받기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// v7.0: 나의 사주 소개 섹션 (카드 스타일)
  Widget _buildMySajuIntroSection(AppThemeExtension theme, MySajuIntroSection intro) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.textMuted.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: theme.textPrimary, size: 22),
              const SizedBox(width: 8),
              Text(
                intro.title.isNotEmpty ? intro.title : '나의 사주, 나는 누구인가요?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            intro.reading,
            style: TextStyle(
              fontSize: 15,
              color: theme.textSecondary,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}
