import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/fortune_shimmer_loading.dart';
import '../../../../shared/widgets/fortune_category_chip_section.dart';
import '../providers/lifetime_fortune_provider.dart';

/// 평생운세 상세 화면 - 책처럼 읽기 쉬운 레이아웃
class LifetimeFortuneScreen extends ConsumerWidget {
  const LifetimeFortuneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final fortuneAsync = ref.watch(lifetimeFortuneProvider);

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
          '평생운세',
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
            onPressed: () => ref.read(lifetimeFortuneProvider.notifier).refresh(),
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
            '평생운세를 불러오지 못했습니다',
            style: TextStyle(color: theme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => ref.read(lifetimeFortuneProvider.notifier).refresh(),
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
            '평생운세를 분석하고 있습니다...',
            style: TextStyle(color: theme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'GPT-5.2 분석은 1-2분 정도 소요됩니다',
            style: TextStyle(color: theme.textSecondary.withValues(alpha: 0.7), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppThemeExtension theme, LifetimeFortuneData fortune) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        // 제목
        _buildTitle(theme),
        const SizedBox(height: 32),

        // v7.0: 나의 사주 소개
        if (fortune.mySajuIntro != null && fortune.mySajuIntro!.reading.isNotEmpty) ...[
          _buildMySajuIntroSection(theme, fortune.mySajuIntro!),
          const SizedBox(height: 32),
        ],

        // 요약
        if (fortune.summary.isNotEmpty) ...[
          _buildSection(
            theme,
            title: '나의 사주 요약',
            children: [
              _buildParagraph(theme, fortune.summary),
            ],
          ),
          const SizedBox(height: 32),
        ],

        // 성격 분석
        if (_hasPersonality(fortune.personality)) ...[
          _buildSection(
            theme,
            title: '타고난 성격',
            children: [
              if (fortune.personality.description.isNotEmpty)
                _buildParagraph(theme, fortune.personality.description),
              if (fortune.personality.coreTraits.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '핵심 특성:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...fortune.personality.coreTraits.map((t) => _buildListItem(theme, t)),
              ],
              if (fortune.personality.strengths.isNotEmpty) ...[
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
                ...fortune.personality.strengths.map((s) => _buildListItem(theme, s)),
              ],
              if (fortune.personality.weaknesses.isNotEmpty) ...[
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
                ...fortune.personality.weaknesses.map((w) => _buildListItem(theme, w)),
              ],
            ],
          ),
          const SizedBox(height: 32),
        ],

        // 분야별 운세 (칩 형태로 표시, 광고 보고 펼치기)
        if (fortune.categories.isNotEmpty) ...[
          FortuneCategoryChipSection(
            fortuneType: 'lifetime',
            title: '평생 분야별 운세',
            categories: fortune.categories.map((key, cat) => MapEntry(
              key,
              CategoryData(
                title: cat.title,
                score: cat.score,
                reading: cat.reading,
              ),
            )),
          ),
          const SizedBox(height: 8),
        ],

        // 인생 주기
        if (_hasLifeCycles(fortune.lifeCycles)) ...[
          _buildSection(
            theme,
            title: '인생 주기별 전망',
            children: [
              if (fortune.lifeCycles.youth.isNotEmpty) ...[
                _buildSubSection(theme, '청년기 (20-35세)', fortune.lifeCycles.youth),
                const SizedBox(height: 12),
              ],
              if (fortune.lifeCycles.middleAge.isNotEmpty) ...[
                _buildSubSection(theme, '중년기 (35-55세)', fortune.lifeCycles.middleAge),
                const SizedBox(height: 12),
              ],
              if (fortune.lifeCycles.laterYears.isNotEmpty)
                _buildSubSection(theme, '후년기 (55세 이후)', fortune.lifeCycles.laterYears),
              if (fortune.lifeCycles.keyYears.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  '중요 전환점:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...fortune.lifeCycles.keyYears.map((y) => _buildListItem(theme, y)),
              ],
            ],
          ),
          const SizedBox(height: 32),
        ],

        // 행운 정보
        if (_hasLucky(fortune.luckyElements)) ...[
          _buildSection(
            theme,
            title: '행운 정보',
            children: [
              if (fortune.luckyElements.colors.isNotEmpty)
                _buildLuckyItem(theme, '행운의 색상', fortune.luckyElements.colors.join(', ')),
              if (fortune.luckyElements.numbers.isNotEmpty)
                _buildLuckyItem(theme, '행운의 숫자', fortune.luckyElements.numbers.join(', ')),
              if (fortune.luckyElements.directions.isNotEmpty)
                _buildLuckyItem(theme, '좋은 방향', fortune.luckyElements.directions.join(', ')),
              if (fortune.luckyElements.seasons.isNotEmpty)
                _buildLuckyItem(theme, '유리한 계절', fortune.luckyElements.seasons),
              if (fortune.luckyElements.partnerElements.isNotEmpty)
                _buildLuckyItem(theme, '궁합이 좋은 띠', fortune.luckyElements.partnerElements.join(', ')),
            ],
          ),
          const SizedBox(height: 32),
        ],

        // 종합 조언
        if (fortune.overallAdvice.isNotEmpty) ...[
          _buildSection(
            theme,
            title: '종합 인생 조언',
            children: [
              _buildParagraph(theme, fortune.overallAdvice),
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

  Widget _buildTitle(AppThemeExtension theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '평생운세',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '타고난 사주로 본 나의 운명',
          style: TextStyle(
            fontSize: 16,
            color: theme.textSecondary,
          ),
        ),
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

  Widget _buildLuckyItem(AppThemeExtension theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 15,
          color: theme.textSecondary,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildConsultButton(BuildContext context, AppThemeExtension theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.go('/saju/chat?type=lifetimeFortune'),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.textPrimary,
          foregroundColor: theme.backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'AI에게 평생운세 상담받기',
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

  bool _hasPersonality(PersonalitySection personality) {
    return personality.description.isNotEmpty ||
        personality.coreTraits.isNotEmpty ||
        personality.strengths.isNotEmpty;
  }

  bool _hasLifeCycles(LifeCyclesSection lifeCycles) {
    return lifeCycles.youth.isNotEmpty ||
        lifeCycles.middleAge.isNotEmpty ||
        lifeCycles.laterYears.isNotEmpty;
  }

  bool _hasLucky(LuckyElementsSection lucky) {
    return lucky.colors.isNotEmpty ||
        lucky.numbers.isNotEmpty ||
        lucky.directions.isNotEmpty ||
        lucky.seasons.isNotEmpty;
  }
}
