import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/fortune_shimmer_loading.dart';
import '../../../../shared/widgets/fortune_category_chip_section.dart';
import '../providers/new_year_fortune_provider.dart';

/// 2026 신년운세 화면 - 책처럼 읽기 쉬운 레이아웃
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
          '2026 신년운세',
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
    debugPrint('[NewYearFortuneScreen] ❌ 에러: $error');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '신년운세를 불러오지 못했습니다',
            style: TextStyle(color: theme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              '$error',
              style: TextStyle(color: theme.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => ref.read(newYearFortuneProvider.notifier).refresh(),
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
            '2026년 신년운세를 분석하고 있습니다...',
            style: TextStyle(color: theme.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppThemeExtension theme, NewYearFortuneData fortune) {
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

        // 연도 정보
        if (_hasYearInfo(fortune.yearInfo)) ...[
          _buildSection(
            theme,
            title: '${fortune.year}년 ${fortune.yearInfo.alias}',
            children: [
              if (fortune.yearInfo.napeum.isNotEmpty)
                _buildSubSection(theme, '납음', '${fortune.yearInfo.napeum}\n${fortune.yearInfo.napeumExplain}'),
              if (fortune.yearInfo.twelveUnsung.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSubSection(theme, '12운성', '${fortune.yearInfo.twelveUnsung}\n${fortune.yearInfo.unsungExplain}'),
              ],
              if (fortune.yearInfo.mainSinsal.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSubSection(theme, '주요 신살', '${fortune.yearInfo.mainSinsal}\n${fortune.yearInfo.sinsalExplain}'),
              ],
            ],
          ),
          const SizedBox(height: 32),
        ],

        // 개인 분석
        if (_hasPersonalAnalysis(fortune.personalAnalysis)) ...[
          _buildSection(
            theme,
            title: '나와 2026년의 관계',
            children: [
              if (fortune.personalAnalysis.ilgan.isNotEmpty)
                _buildSubSection(theme, '일간 분석', '${fortune.personalAnalysis.ilgan}\n${fortune.personalAnalysis.ilganExplain}'),
              if (fortune.personalAnalysis.fireEffect.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSubSection(theme, '화(火) 기운의 영향', fortune.personalAnalysis.fireEffect),
              ],
              if (fortune.personalAnalysis.yongshinMatch.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSubSection(theme, '용신 조화', fortune.personalAnalysis.yongshinMatch),
              ],
              if (fortune.personalAnalysis.hapchungEffect.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSubSection(theme, '합충 영향', fortune.personalAnalysis.hapchungEffect),
              ],
              if (fortune.personalAnalysis.sinsalEffect.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSubSection(theme, '신살 영향', fortune.personalAnalysis.sinsalEffect),
              ],
            ],
          ),
          const SizedBox(height: 32),
        ],

        // 총운
        _buildSection(
          theme,
          title: '2026년 총운',
          children: [
            if (fortune.overview.keyword.isNotEmpty)
              _buildKeyword(theme, fortune.overview.keyword, fortune.overview.score),
            if (fortune.overview.summary.isNotEmpty)
              _buildParagraph(theme, fortune.overview.summary),
            if (fortune.overview.keyPoint.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSubSection(theme, '핵심 포인트', fortune.overview.keyPoint),
            ],
          ],
        ),
        const SizedBox(height: 32),

        // 카테고리별 운세 (광고 잠금)
        FortuneCategoryChipSection(
          fortuneType: 'yearly_2026',
          title: '2026년 분야별 운세',
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
        const SizedBox(height: 32),

        // 행운 정보
        if (_hasLucky(fortune.lucky)) ...[
          _buildSection(
            theme,
            title: '2026년 행운 정보',
            children: [
              if (fortune.lucky.colors.isNotEmpty)
                _buildLuckyItem(theme, '행운의 색상', fortune.lucky.colors.join(', ')),
              if (fortune.lucky.numbers.isNotEmpty)
                _buildLuckyItem(theme, '행운의 숫자', fortune.lucky.numbers.join(', ')),
              if (fortune.lucky.direction.isNotEmpty)
                _buildLuckyItem(theme, '좋은 방향', fortune.lucky.direction),
              if (fortune.lucky.items.isNotEmpty)
                _buildLuckyItem(theme, '행운 아이템', fortune.lucky.items.join(', ')),
            ],
          ),
          const SizedBox(height: 32),
        ],

        // 마무리 메시지
        if (fortune.closing.yearMessage.isNotEmpty || fortune.closing.finalAdvice.isNotEmpty) ...[
          _buildSection(
            theme,
            title: '2026년을 맞이하며',
            children: [
              if (fortune.closing.yearMessage.isNotEmpty)
                _buildParagraph(theme, fortune.closing.yearMessage),
              if (fortune.closing.finalAdvice.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSubSection(theme, '마지막 조언', fortune.closing.finalAdvice),
              ],
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

  Widget _buildTitle(AppThemeExtension theme, NewYearFortuneData fortune) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${fortune.year}년 신년운세',
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
        onPressed: () => context.go('/saju/chat?type=newYearFortune'),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.textPrimary,
          foregroundColor: theme.backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '신년운세 AI 상담받기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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

  /// AI 응답에 카테고리가 없을 때 기본 카테고리 제공
  /// 6개 카테고리 칩이 항상 표시되도록 함
  Map<String, CategoryData> _getDefaultCategories() {
    return {
      'career': const CategoryData(
        title: '직업운',
        score: 0,
        reading: '광고를 시청하면 2026년 직업운을 확인할 수 있습니다.',
      ),
      'wealth': const CategoryData(
        title: '재물운',
        score: 0,
        reading: '광고를 시청하면 2026년 재물운을 확인할 수 있습니다.',
      ),
      'love': const CategoryData(
        title: '애정운',
        score: 0,
        reading: '광고를 시청하면 2026년 애정운을 확인할 수 있습니다.',
      ),
      'health': const CategoryData(
        title: '건강운',
        score: 0,
        reading: '광고를 시청하면 2026년 건강운을 확인할 수 있습니다.',
      ),
      'study': const CategoryData(
        title: '학업운',
        score: 0,
        reading: '광고를 시청하면 2026년 학업운을 확인할 수 있습니다.',
      ),
      'business': const CategoryData(
        title: '사업운',
        score: 0,
        reading: '광고를 시청하면 2026년 사업운을 확인할 수 있습니다.',
      ),
    };
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
