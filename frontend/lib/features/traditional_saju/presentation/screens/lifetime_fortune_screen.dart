import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/fortune_shimmer_loading.dart';
import '../../../../shared/widgets/fortune_category_chip_section.dart';
import '../../../../shared/widgets/fortune_section_card.dart';
import '../../../../shared/widgets/fortune_title_header.dart';
import '../../../../ad/ad_service.dart';
import '../../../../animation/saju_loading_animation.dart';
import '../providers/lifetime_fortune_provider.dart';

/// 평생운세 상세 화면 - 책처럼 읽기 쉬운 레이아웃
class LifetimeFortuneScreen extends ConsumerStatefulWidget {
  const LifetimeFortuneScreen({super.key});

  @override
  ConsumerState<LifetimeFortuneScreen> createState() => _LifetimeFortuneScreenState();
}

class _LifetimeFortuneScreenState extends ConsumerState<LifetimeFortuneScreen> {
  /// [Static] 세션 기반 잠금해제 상태 - 앱 종료 전까지 유지!
  /// 페이지 이동해도 유지됨
  static final Set<String> _unlockedCycles = {};
  bool _isLoadingAd = false;

  @override
  Widget build(BuildContext context) {
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
        error: (error, stack) => _buildError(context, theme),
        data: (fortune) {
          if (fortune == null) {
            // Progressive Disclosure: Phase 폴링 시작
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(lifetimeFortuneProgressProvider.notifier).startPolling();
            });
            return _buildAnalyzing(theme);
          }
          // 완료 시 폴링 중지
          ref.read(lifetimeFortuneProgressProvider.notifier).stopPolling();
          return _buildContent(context, theme, fortune);
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, AppThemeExtension theme) {
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
    // Progressive Disclosure: Phase 진행 상황 표시
    final progress = ref.watch(lifetimeFortuneProgressProvider);

    // 사주팔자 8글자 데이터 (애니메이션용)
    final sajuPaljaAsync = ref.watch(sajuPaljaProvider);

    // 부분 결과가 있으면 UI에 먼저 표시
    if (progress != null && progress.partialFortuneData != null) {
      return _buildPartialContent(context, theme, progress);
    }

    // 사주팔자 8글자 애니메이션 로딩 UI
    return sajuPaljaAsync.when(
      loading: () => const FortuneShimmerLoading(),
      error: (_, __) => _buildFallbackLoading(theme, progress),
      data: (sajuPalja) {
        final currentPhase = progress?.currentPhase ?? 0;
        final totalPhases = progress?.totalPhases ?? 4;
        final statusMessage = progress?.currentAnalysisDetail ?? '당신의 사주정보를 파악하고 있습니다...';

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.backgroundColor,
                theme.backgroundColor.withValues(alpha: 0.95),
                const Color(0xFF1a1a2e),
              ],
            ),
          ),
          child: SajuLoadingAnimation(
            yearGan: sajuPalja?.yearGan,
            yearJi: sajuPalja?.yearJi,
            monthGan: sajuPalja?.monthGan,
            monthJi: sajuPalja?.monthJi,
            dayGan: sajuPalja?.dayGan,
            dayJi: sajuPalja?.dayJi,
            hourGan: sajuPalja?.hourGan,
            hourJi: sajuPalja?.hourJi,
            currentPhase: currentPhase,
            totalPhases: totalPhases,
            statusMessage: statusMessage,
          ),
        );
      },
    );
  }

  /// 폴백 로딩 UI (사주팔자 데이터 없을 때)
  Widget _buildFallbackLoading(AppThemeExtension theme, PhaseProgressData? progress) {
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
          if (progress != null && progress.currentPhase > 0) ...[
            Text(
              'Phase ${progress.currentPhase}/${progress.totalPhases}',
              style: TextStyle(color: theme.textSecondary.withValues(alpha: 0.7), fontSize: 14),
            ),
          ] else ...[
            Text(
              '사주정보를 파악하고 있습니다...',
              style: TextStyle(color: theme.textSecondary.withValues(alpha: 0.7), fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  /// Phase 진행률 UI (부분 결과 없을 때)
  Widget _buildProgressUI(AppThemeExtension theme, PhaseProgressData progress) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 진행률 원형 표시
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: progress.progress,
                    strokeWidth: 8,
                    backgroundColor: theme.textMuted.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(theme.textPrimary),
                  ),
                ),
                Text(
                  '${(progress.progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Phase 설명
            Text(
              'Phase ${progress.currentPhase}/${progress.totalPhases}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              progress.currentAnalysisDetail,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // 완료된 섹션 표시
            if (progress.completedSections.isNotEmpty) ...[
              Text(
                '완료: ${progress.completedSections.join(', ')}',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 부분 결과 표시 (Phase 완료 시 즉시 표시)
  Widget _buildPartialContent(BuildContext context, AppThemeExtension theme, PhaseProgressData progress) {
    final fortune = progress.partialFortuneData!;
    final isComplete = progress.currentPhase >= progress.totalPhases;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        // 진행 상황 배너 (완료되지 않은 경우)
        if (!isComplete) ...[
          _buildProgressBanner(theme, progress),
          const SizedBox(height: 24),
        ],

        // ========== 1단계: 소개 (나는 누구?) ==========
        _buildTitle(theme),
        const SizedBox(height: 32),

        // 나의 사주 소개
        if (fortune.mySajuIntro != null && fortune.mySajuIntro!.reading.isNotEmpty) ...[
          _buildMySajuIntroSection(theme, fortune.mySajuIntro!),
          const SizedBox(height: 32),
        ],

        // 사주팔자 8글자 설명
        if (fortune.mySajuCharacters != null && fortune.mySajuCharacters!.hasContent) ...[
          _buildMySajuCharactersSection(theme, fortune.mySajuCharacters!),
          const SizedBox(height: 32),
        ],

        // ========== 2단계: 분석 기초 (내 사주의 구조) ==========
        // 십성 분석
        if (fortune.sipsungAnalysis != null && fortune.sipsungAnalysis!.hasContent) ...[
          _buildSipsungSection(theme, fortune.sipsungAnalysis!),
          const SizedBox(height: 32),
        ],

        // 합충 분석
        if (fortune.hapchungAnalysis != null && fortune.hapchungAnalysis!.hasContent) ...[
          _buildHapchungSection(theme, fortune.hapchungAnalysis!),
          const SizedBox(height: 32),
        ],

        // v8.1: 신살/길성 분석
        if (fortune.sinsalGilseong != null && fortune.sinsalGilseong!.hasContent) ...[
          _buildSinsalGilseongSection(theme, fortune.sinsalGilseong!),
          const SizedBox(height: 32),
        ],

        // ========== 3단계: 해석 (분석 결과 요약) ==========
        // 나의 사주 요약
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

        // 타고난 성격
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

        // ========== 4단계: 분야별 운세 ==========
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

        // ========== 5단계: 시간축 ==========
        // v8.1: 전성기 섹션
        if (fortune.peakYears != null && fortune.peakYears!.hasContent) ...[
          _buildPeakYearsSection(theme, fortune.peakYears!),
          const SizedBox(height: 32),
        ],

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
                _buildLifeCycleCard(
                  theme,
                  cycleKey: 'middleAge',
                  title: '중년기',
                  ageRange: '35-55세',
                  content: fortune.lifeCycles.middleAge,
                ),
                const SizedBox(height: 12),
              ],
              if (fortune.lifeCycles.laterYears.isNotEmpty)
                _buildLifeCycleCard(
                  theme,
                  cycleKey: 'laterYears',
                  title: '후년기',
                  ageRange: '55세 이후',
                  content: fortune.lifeCycles.laterYears,
                ),
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

        // v8.1: 대운 상세 섹션
        if (fortune.daeunDetail != null && fortune.daeunDetail!.hasContent) ...[
          _buildDaeunDetailSection(theme, fortune.daeunDetail!),
          const SizedBox(height: 32),
        ],

        // ========== 6단계: 보너스 정보 ==========
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

        // AI 시대 해석
        if (fortune.modernInterpretation != null && fortune.modernInterpretation!.hasContent) ...[
          _buildModernInterpretationSection(theme, fortune.modernInterpretation!),
          const SizedBox(height: 32),
        ],

        // ========== 7단계: 마무리 ==========
        // 종합 인생 조언
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

        // 아직 분석 중인 경우 안내
        if (!isComplete) ...[
          _buildAnalyzingMoreBanner(theme, progress),
          const SizedBox(height: 32),
        ],

        // AI 상담 버튼
        _buildConsultButton(context, theme),
        const SizedBox(height: 40),
      ],
    );
  }

  /// 진행 상황 배너 (상단) - 개선된 UI
  Widget _buildProgressBanner(AppThemeExtension theme, PhaseProgressData progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.cardColor,
            theme.cardColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.textPrimary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.textPrimary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: progress.progress,
                  strokeWidth: 4,
                  backgroundColor: theme.textMuted.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.textPrimary),
                ),
              ),
              Text(
                '${(progress.progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: theme.textPrimary),
                    const SizedBox(width: 6),
                    Text(
                      '분석 진행 중',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  progress.currentAnalysisDetail,
                  style: TextStyle(
                    fontSize: 13,
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

  /// 추가 분석 중 안내 배너 (하단)
  Widget _buildAnalyzingMoreBanner(AppThemeExtension theme, PhaseProgressData progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.textMuted.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(theme.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${progress.currentAnalysisDetail}\n완료되면 자동으로 표시됩니다.',
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppThemeExtension theme, LifetimeFortuneData fortune) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        // ========== 1단계: 소개 (나는 누구?) ==========
        _buildTitle(theme),
        const SizedBox(height: 32),

        // 나의 사주 소개
        if (fortune.mySajuIntro != null && fortune.mySajuIntro!.reading.isNotEmpty) ...[
          _buildMySajuIntroSection(theme, fortune.mySajuIntro!),
          const SizedBox(height: 32),
        ],

        // 사주팔자 8글자 설명
        if (fortune.mySajuCharacters != null && fortune.mySajuCharacters!.hasContent) ...[
          _buildMySajuCharactersSection(theme, fortune.mySajuCharacters!),
          const SizedBox(height: 32),
        ],

        // ========== 2단계: 분석 기초 (내 사주의 구조) ==========
        // 십성 분석
        if (fortune.sipsungAnalysis != null && fortune.sipsungAnalysis!.hasContent) ...[
          _buildSipsungSection(theme, fortune.sipsungAnalysis!),
          const SizedBox(height: 32),
        ],

        // 합충 분석
        if (fortune.hapchungAnalysis != null && fortune.hapchungAnalysis!.hasContent) ...[
          _buildHapchungSection(theme, fortune.hapchungAnalysis!),
          const SizedBox(height: 32),
        ],

        // v8.1: 신살/길성 분석
        if (fortune.sinsalGilseong != null && fortune.sinsalGilseong!.hasContent) ...[
          _buildSinsalGilseongSection(theme, fortune.sinsalGilseong!),
          const SizedBox(height: 32),
        ],

        // ========== 3단계: 해석 (분석 결과 요약) ==========
        // 나의 사주 요약
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

        // 타고난 성격
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

        // ========== 4단계: 분야별 운세 (구체적인 삶의 영역) ==========
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

        // ========== 5단계: 시간축 (언제?) ==========
        // v8.1: 전성기 섹션 (시간축 최상단에 배치)
        if (fortune.peakYears != null && fortune.peakYears!.hasContent) ...[
          _buildPeakYearsSection(theme, fortune.peakYears!),
          const SizedBox(height: 32),
        ],

        if (_hasLifeCycles(fortune.lifeCycles)) ...[
          _buildSection(
            theme,
            title: '인생 주기별 전망',
            children: [
              // 청년기 (항상 열림)
              if (fortune.lifeCycles.youth.isNotEmpty) ...[
                _buildSubSection(theme, '청년기 (20-35세)', fortune.lifeCycles.youth),
                const SizedBox(height: 12),
              ],
              // 중년기 (광고 필요)
              if (fortune.lifeCycles.middleAge.isNotEmpty) ...[
                _buildLifeCycleCard(
                  theme,
                  cycleKey: 'middleAge',
                  title: '중년기',
                  ageRange: '35-55세',
                  content: fortune.lifeCycles.middleAge,
                ),
                const SizedBox(height: 12),
              ],
              // 후년기 (광고 필요)
              if (fortune.lifeCycles.laterYears.isNotEmpty)
                _buildLifeCycleCard(
                  theme,
                  cycleKey: 'laterYears',
                  title: '후년기',
                  ageRange: '55세 이후',
                  content: fortune.lifeCycles.laterYears,
                ),
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

        // v8.1: 대운 상세 섹션 (인생 주기 후에 배치)
        if (fortune.daeunDetail != null && fortune.daeunDetail!.hasContent) ...[
          _buildDaeunDetailSection(theme, fortune.daeunDetail!),
          const SizedBox(height: 32),
        ],

        // ========== 6단계: 보너스 정보 ==========
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

        // AI 시대 해석
        if (fortune.modernInterpretation != null && fortune.modernInterpretation!.hasContent) ...[
          _buildModernInterpretationSection(theme, fortune.modernInterpretation!),
          const SizedBox(height: 32),
        ],

        // ========== 7단계: 마무리 ==========
        // 종합 인생 조언
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
    return const FortuneTitleHeader(
      title: '평생운세',
      subtitle: '타고난 사주로 본 나의 운명',
      style: HeaderStyle.centered,
    );
  }

  Widget _buildSection(AppThemeExtension theme, {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FortuneSectionTitle(title: title),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: theme.textPrimary.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
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
    // 라벨별 아이콘
    IconData icon;
    switch (label) {
      case '행운의 색상':
        icon = Icons.palette_outlined;
        break;
      case '행운의 숫자':
        icon = Icons.tag;
        break;
      case '좋은 방향':
        icon = Icons.explore_outlined;
        break;
      case '유리한 계절':
        icon = Icons.wb_sunny_outlined;
        break;
      case '궁합이 좋은 띠':
        icon = Icons.favorite_outline;
        break;
      default:
        icon = Icons.star_outline;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.textPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: theme.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textSecondary,
                    height: 1.4,
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
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.textPrimary,
            theme.textPrimary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.textPrimary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => context.go('/saju/chat?type=lifetimeFortune'),
        icon: const Icon(Icons.auto_awesome, size: 20),
        label: const Text(
          'AI에게 평생운세 상담받기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.backgroundColor,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  /// v7.0: 나의 사주 소개 섹션 (카드 스타일)
  Widget _buildMySajuIntroSection(AppThemeExtension theme, MySajuIntroSection intro) {
    return FortuneSectionCard(
      title: intro.title.isNotEmpty ? intro.title : '나의 사주, 나는 누구인가요?',
      icon: Icons.person_outline,
      content: intro.reading,
      style: CardStyle.elevated,
    );
  }

  /// v8.0: 사주팔자 8글자 설명 섹션
  Widget _buildMySajuCharactersSection(AppThemeExtension theme, MySajuCharactersSection chars) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.textPrimary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Row(
            children: [
              Icon(Icons.grid_view_rounded, color: theme.textPrimary, size: 22),
              const SizedBox(width: 10),
              Text(
                '나의 사주팔자 8글자',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            chars.description,
            style: TextStyle(
              fontSize: 14,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // 8글자 그리드 (4열 2행)
          _buildSajuGrid(theme, chars),

          const SizedBox(height: 20),

          // 종합 해석
          if (chars.overallReading.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.textPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                chars.overallReading,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: theme.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 사주 8글자 그리드
  Widget _buildSajuGrid(AppThemeExtension theme, MySajuCharactersSection chars) {
    final columns = [
      ('연주', chars.yearGan, chars.yearJi),
      ('월주', chars.monthGan, chars.monthJi),
      ('일주', chars.dayGan, chars.dayJi),
      ('시주', chars.hourGan, chars.hourJi),
    ];

    return Row(
      children: columns.map((column) {
        final (label, gan, ji) = column;
        return Expanded(
          child: Column(
            children: [
              // 기둥 라벨
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              // 천간
              _buildCharacterCard(theme, gan, isGan: true, isDay: label == '일주'),
              const SizedBox(height: 6),
              // 지지
              _buildCharacterCard(theme, ji, isGan: false, isDay: label == '일주'),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 개별 글자 카드
  Widget _buildCharacterCard(AppThemeExtension theme, SajuCharacterInfo info, {required bool isGan, required bool isDay}) {
    // 오행별 색상
    final ohengColor = _getOhengColor(info.oheng);

    return GestureDetector(
      onTap: () => _showCharacterDetail(theme, info, isGan: isGan, isDay: isDay),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: ohengColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDay ? ohengColor : ohengColor.withValues(alpha: 0.3),
            width: isDay ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              info.character,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ohengColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              info.reading,
              style: TextStyle(
                fontSize: 12,
                color: theme.textSecondary,
              ),
            ),
            if (info.animal != null && info.animal!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                info.animal!,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 오행별 색상
  Color _getOhengColor(String oheng) {
    switch (oheng) {
      case '목':
        return const Color(0xFF00C853);  // 초록
      case '화':
        return const Color(0xFFFF5252);  // 빨강
      case '토':
        return const Color(0xFFFFB300);  // 노랑
      case '금':
        return const Color(0xFFFFFFFF);  // 흰색/금색
      case '수':
        return const Color(0xFF2196F3);  // 파랑
      default:
        return const Color(0xFF9E9E9E);  // 회색
    }
  }

  /// 글자 상세 다이얼로그
  void _showCharacterDetail(AppThemeExtension theme, SajuCharacterInfo info, {required bool isGan, required bool isDay}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final ohengColor = _getOhengColor(info.oheng);
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ohengColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      info.character,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: ohengColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${info.reading} (${info.character})',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildTag(theme, info.oheng, ohengColor),
                            const SizedBox(width: 8),
                            _buildTag(theme, info.yinYang, theme.textSecondary),
                            if (isDay) ...[
                              const SizedBox(width: 8),
                              _buildTag(theme, '일간 (나)', theme.textPrimary),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 설명
              Text(
                info.meaning,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  color: theme.textPrimary,
                ),
              ),

              // 추가 정보
              if (info.animal != null && info.animal!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildInfoRow(theme, '띠', info.animal!),
              ],
              if (info.season != null && info.season!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(theme, '계절', info.season!),
              ],

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTag(AppThemeExtension theme, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoRow(AppThemeExtension theme, String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: theme.textPrimary,
          ),
        ),
      ],
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

  /// 인생 주기 카드 (잠금/해제 상태에 따른 UI) - 개선된 UI
  Widget _buildLifeCycleCard(
    AppThemeExtension theme, {
    required String cycleKey,
    required String title,
    required String ageRange,
    required String content,
  }) {
    final isUnlocked = _unlockedCycles.contains(cycleKey);

    // 주기별 아이콘
    final IconData cycleIcon = cycleKey == 'middleAge'
        ? Icons.trending_up
        : Icons.spa;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnlocked
              ? theme.textPrimary.withValues(alpha: 0.2)
              : theme.textMuted.withValues(alpha: 0.15),
        ),
        boxShadow: isUnlocked ? [
          BoxShadow(
            color: theme.textPrimary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? theme.textPrimary.withValues(alpha: 0.1)
                      : theme.textMuted.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isUnlocked ? cycleIcon : Icons.lock_outline,
                  size: 18,
                  color: isUnlocked ? theme.textPrimary : theme.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    Text(
                      ageRange,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isUnlocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.textMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '잠김',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // 내용 또는 잠금 UI
          if (isUnlocked)
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                color: theme.textSecondary,
                height: 1.8,
              ),
            )
          else
            _buildLockedContent(theme, cycleKey, title),
        ],
      ),
    );
  }

  /// 잠금 상태 UI - 개선된 UI
  Widget _buildLockedContent(AppThemeExtension theme, String cycleKey, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.textMuted.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.movie_outlined, size: 20, color: theme.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '광고를 시청하면 $title 운세를 확인할 수 있습니다.',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.textPrimary.withValues(alpha: 0.9),
                    theme.textPrimary.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton.icon(
                onPressed: _isLoadingAd ? null : () => _showRewardedAdAndUnlock(cycleKey, title),
                icon: _isLoadingAd
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.backgroundColor,
                        ),
                      )
                    : Icon(Icons.play_circle_filled, size: 20, color: theme.backgroundColor),
                label: Text(
                  _isLoadingAd ? '광고 로딩 중...' : '광고 보고 $title 확인',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.backgroundColor,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 광고 보고 잠금 해제 (기존 FortuneCategoryChipSection 패턴 참고)
  Future<void> _showRewardedAdAndUnlock(String cycleKey, String title) async {
    if (_isLoadingAd) return;

    setState(() => _isLoadingAd = true);

    // 웹에서는 광고 스킵하고 바로 해제 (테스트용)
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _unlockedCycles.add(cycleKey);
          _isLoadingAd = false;
        });
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title 운세가 해제되었습니다! (웹 테스트)'),
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (_) {}
      }
      return;
    }

    // 광고가 로드되어 있는지 확인
    if (!AdService.instance.isRewardedLoaded) {
      await AdService.instance.loadRewardedAd(
        onLoaded: () async {
          final shown = await AdService.instance.showRewardedAd(
            onRewarded: (amount, type) async {
              if (mounted) {
                setState(() {
                  _unlockedCycles.add(cycleKey);
                  _isLoadingAd = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$title 운세가 해제되었습니다!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          );

          if (!shown && mounted) {
            setState(() => _isLoadingAd = false);
            _showAdNotReadyDialog(title);
          }
        },
        onFailed: (error) {
          if (mounted) {
            setState(() => _isLoadingAd = false);
            _showAdNotReadyDialog(title);
          }
        },
      );
    } else {
      final shown = await AdService.instance.showRewardedAd(
        onRewarded: (amount, type) async {
          if (mounted) {
            setState(() {
              _unlockedCycles.add(cycleKey);
              _isLoadingAd = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title 운세가 해제되었습니다!'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      );

      if (!shown && mounted) {
        setState(() => _isLoadingAd = false);
        _showAdNotReadyDialog(title);
      }
    }
  }

  void _showAdNotReadyDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('광고 준비 중'),
        content: Text('$title 운세를 보려면 광고를 시청해야 합니다.\n잠시 후 다시 시도해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // v7.3: 상세 분석 섹션 Builder 메서드들
  // ============================================================

  /// 원국 분석 섹션 (격국, 일간, 오행균형, 신강/신약)
  Widget _buildWonGukSection(AppThemeExtension theme, WonGukAnalysisSection wonGuk) {
    return _buildSection(
      theme,
      title: '원국 분석',
      children: [
        if (wonGuk.gyeokguk.isNotEmpty) ...[
          _buildSubSectionHeader(theme, '격국'),
          _buildParagraph(theme, wonGuk.gyeokguk),
          const SizedBox(height: 12),
        ],
        if (wonGuk.dayMaster.isNotEmpty) ...[
          _buildSubSectionHeader(theme, '일간'),
          _buildParagraph(theme, wonGuk.dayMaster),
          const SizedBox(height: 12),
        ],
        if (wonGuk.ohengBalance.isNotEmpty) ...[
          _buildSubSectionHeader(theme, '오행 균형'),
          _buildParagraph(theme, wonGuk.ohengBalance),
        ],
      ],
    );
  }

  /// 십성 분석 섹션 (강한 십성, 약한 십성, 상호작용)
  Widget _buildSipsungSection(AppThemeExtension theme, SipsungAnalysisSection sipsung) {
    return _buildSection(
      theme,
      title: '십성 분석',
      children: [
        if (sipsung.dominantSipsung.isNotEmpty) ...[
          _buildSubSectionHeader(theme, '강한 십성'),
          ...sipsung.dominantSipsung.map((s) => _buildListItem(theme, s)),
          const SizedBox(height: 12),
        ],
        if (sipsung.weakSipsung.isNotEmpty) ...[
          _buildSubSectionHeader(theme, '약한 십성'),
          ...sipsung.weakSipsung.map((s) => _buildListItem(theme, s)),
          const SizedBox(height: 12),
        ],
        if (sipsung.keyInteractions.isNotEmpty) ...[
          _buildSubSectionHeader(theme, '핵심 상호작용'),
          _buildParagraph(theme, sipsung.keyInteractions),
          const SizedBox(height: 12),
        ],
        if (sipsung.lifeImplications.isNotEmpty) ...[
          _buildSubSectionHeader(theme, '삶에 대한 영향'),
          _buildParagraph(theme, sipsung.lifeImplications),
        ],
      ],
    );
  }

  /// 합충 분석 섹션 (합, 충, 종합 영향)
  Widget _buildHapchungSection(AppThemeExtension theme, HapchungAnalysisSection hapchung) {
    return _buildSection(
      theme,
      title: '합충 분석',
      children: [
        if (hapchung.majorHaps.isNotEmpty) ...[
          _buildSubSectionHeader(theme, '주요 합(合)'),
          ...hapchung.majorHaps.map((h) => _buildListItem(theme, h)),
          const SizedBox(height: 12),
        ],
        if (hapchung.majorChungs.isNotEmpty) ...[
          _buildSubSectionHeader(theme, '주요 충(沖)'),
          ...hapchung.majorChungs.map((c) => _buildListItem(theme, c)),
          const SizedBox(height: 12),
        ],
        if (hapchung.overallImpact.isNotEmpty) ...[
          _buildSubSectionHeader(theme, '종합 영향'),
          _buildParagraph(theme, hapchung.overallImpact),
          const SizedBox(height: 12),
        ],
        if (hapchung.otherInteractions.isNotEmpty) ...[
          _buildSubSectionHeader(theme, '기타 상호작용'),
          _buildParagraph(theme, hapchung.otherInteractions),
        ],
      ],
    );
  }

  /// 현대적 해석 섹션 (AI 시대 직업, 재물, 관계)
  Widget _buildModernInterpretationSection(AppThemeExtension theme, ModernInterpretationSection modern) {
    return _buildSection(
      theme,
      title: 'AI 시대의 사주 해석',
      children: [
        // 커리어 (AI 시대)
        if (modern.careerInAiEra != null) ...[
          _buildSubSectionHeader(theme, '💼 디지털 시대 직업운'),
          if (modern.careerInAiEra!.traditionalPath.isNotEmpty)
            _buildParagraph(theme, modern.careerInAiEra!.traditionalPath),
          if (modern.careerInAiEra!.digitalStrengths.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildHighlightBox(theme, '디지털 강점', modern.careerInAiEra!.digitalStrengths),
          ],
          if (modern.careerInAiEra!.modernOpportunities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('현대적 기회:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimary)),
            const SizedBox(height: 4),
            ...modern.careerInAiEra!.modernOpportunities.map((o) => _buildListItem(theme, o)),
          ],
          const SizedBox(height: 16),
        ],

        // 재물 (AI 시대)
        if (modern.wealthInAiEra != null) ...[
          _buildSubSectionHeader(theme, '💰 디지털 자산 운용'),
          if (modern.wealthInAiEra!.traditionalView.isNotEmpty)
            _buildParagraph(theme, modern.wealthInAiEra!.traditionalView),
          if (modern.wealthInAiEra!.riskFactors.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildHighlightBox(theme, '주의할 리스크', modern.wealthInAiEra!.riskFactors, isWarning: true),
          ],
          if (modern.wealthInAiEra!.modernOpportunities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('현대적 기회:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimary)),
            const SizedBox(height: 4),
            ...modern.wealthInAiEra!.modernOpportunities.map((o) => _buildListItem(theme, o)),
          ],
          const SizedBox(height: 16),
        ],

        // 관계 (AI 시대)
        if (modern.relationshipsInAiEra != null) ...[
          _buildSubSectionHeader(theme, '🤝 디지털 시대 인간관계'),
          if (modern.relationshipsInAiEra!.traditionalView.isNotEmpty)
            _buildParagraph(theme, modern.relationshipsInAiEra!.traditionalView),
          if (modern.relationshipsInAiEra!.modernNetworking.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildHighlightBox(theme, '네트워킹 스타일', modern.relationshipsInAiEra!.modernNetworking),
          ],
          if (modern.relationshipsInAiEra!.collaborationStyle.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildHighlightBox(theme, '협업 스타일', modern.relationshipsInAiEra!.collaborationStyle),
          ],
        ],
      ],
    );
  }

  /// 서브섹션 헤더 (작은 제목)
  Widget _buildSubSectionHeader(AppThemeExtension theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: theme.textPrimary,
        ),
      ),
    );
  }

  /// 하이라이트 박스 (강조 정보) - 공통 위젯 사용
  Widget _buildHighlightBox(AppThemeExtension theme, String label, String content, {bool isWarning = false}) {
    return FortuneHighlightBox(
      label: label,
      content: content,
      type: isWarning ? HighlightType.warning : HighlightType.info,
    );
  }

  // ============================================================
  // v8.1: 누락된 섹션 Builder 메서드들
  // ============================================================

  /// 신살/길성 분석 섹션
  Widget _buildSinsalGilseongSection(AppThemeExtension theme, SinsalGilseongSection sinsal) {
    return _buildSection(
      theme,
      title: '신살/길성 분석',
      children: [
        if (sinsal.majorGilseong.isNotEmpty) ...[
          _buildSubSectionHeader(theme, '✨ 길성 (좋은 별)'),
          ...sinsal.majorGilseong.map((g) => _buildListItem(theme, g)),
          const SizedBox(height: 12),
        ],
        if (sinsal.majorSinsal.isNotEmpty) ...[
          _buildSubSectionHeader(theme, '⚡ 신살 (주의할 별)'),
          ...sinsal.majorSinsal.map((s) => _buildListItem(theme, s)),
          const SizedBox(height: 12),
        ],
        if (sinsal.practicalImplications.isNotEmpty) ...[
          _buildSubSectionHeader(theme, '실생활 영향'),
          _buildParagraph(theme, sinsal.practicalImplications),
          const SizedBox(height: 12),
        ],
        if (sinsal.reading.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.textPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              sinsal.reading,
              style: TextStyle(
                fontSize: 15,
                height: 1.7,
                color: theme.textPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 전성기 섹션
  Widget _buildPeakYearsSection(AppThemeExtension theme, PeakYearsSection peakYears) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD700).withValues(alpha: 0.15),
            const Color(0xFFFF8C00).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
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
                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star, color: Color(0xFFFFD700), size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '나의 전성기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.textPrimary,
                    ),
                  ),
                  if (peakYears.period.isNotEmpty)
                    Text(
                      peakYears.period,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 왜 이 시기가 전성기인가?
          if (peakYears.why.isNotEmpty) ...[
            _buildSubSectionHeader(theme, '왜 이 시기인가요?'),
            _buildParagraph(theme, peakYears.why),
            const SizedBox(height: 14),
          ],

          // 무엇을 해야 하는가?
          if (peakYears.whatToDo.isNotEmpty) ...[
            _buildSubSectionHeader(theme, '이 시기에 해야 할 것'),
            _buildParagraph(theme, peakYears.whatToDo),
            const SizedBox(height: 14),
          ],

          // 무엇을 준비해야 하는가?
          if (peakYears.whatToPrepare.isNotEmpty) ...[
            _buildSubSectionHeader(theme, '미리 준비할 것'),
            _buildParagraph(theme, peakYears.whatToPrepare),
            const SizedBox(height: 14),
          ],

          // 주의사항
          if (peakYears.cautions.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      peakYears.cautions,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: theme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 대운 상세 섹션
  Widget _buildDaeunDetailSection(AppThemeExtension theme, DaeunDetailSection daeun) {
    return _buildSection(
      theme,
      title: '대운(大運) 상세 분석',
      children: [
        // 대운 소개
        if (daeun.intro.isNotEmpty) ...[
          _buildParagraph(theme, daeun.intro),
          const SizedBox(height: 20),
        ],

        // 최고/최악 대운 요약
        if (daeun.bestDaeunPeriod.isNotEmpty || daeun.worstDaeunPeriod.isNotEmpty) ...[
          Row(
            children: [
              if (daeun.bestDaeunPeriod.isNotEmpty)
                Expanded(
                  child: _buildDaeunHighlight(
                    theme,
                    title: '최고의 대운',
                    period: daeun.bestDaeunPeriod,
                    reason: daeun.bestDaeunWhy,
                    isPositive: true,
                  ),
                ),
              if (daeun.bestDaeunPeriod.isNotEmpty && daeun.worstDaeunPeriod.isNotEmpty)
                const SizedBox(width: 12),
              if (daeun.worstDaeunPeriod.isNotEmpty)
                Expanded(
                  child: _buildDaeunHighlight(
                    theme,
                    title: '주의할 대운',
                    period: daeun.worstDaeunPeriod,
                    reason: daeun.worstDaeunWhy,
                    isPositive: false,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // 대운 사이클 목록
        if (daeun.cycles.isNotEmpty) ...[
          _buildSubSectionHeader(theme, '대운 흐름'),
          const SizedBox(height: 8),
          ...daeun.cycles.map((cycle) => _buildDaeunCycleCard(theme, cycle)),
        ],
      ],
    );
  }

  /// 대운 하이라이트 카드 (최고/최악)
  Widget _buildDaeunHighlight(
    AppThemeExtension theme, {
    required String title,
    required String period,
    required String reason,
    required bool isPositive,
  }) {
    final color = isPositive ? Colors.green : Colors.orange;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            period,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
            ),
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              reason,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: theme.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  /// 대운 사이클 개별 카드
  Widget _buildDaeunCycleCard(AppThemeExtension theme, DaeunCycleItem cycle) {
    // 운세 수준에 따른 색상
    Color levelColor;
    switch (cycle.fortuneLevel) {
      case '상':
        levelColor = Colors.green;
        break;
      case '중상':
        levelColor = Colors.teal;
        break;
      case '중':
        levelColor = Colors.blue;
        break;
      case '중하':
        levelColor = Colors.orange;
        break;
      case '하':
        levelColor = Colors.red;
        break;
      default:
        levelColor = theme.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: levelColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  cycle.pillar,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: levelColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cycle.mainTheme,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    Text(
                      cycle.ageRange,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  cycle.fortuneLevel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: levelColor,
                  ),
                ),
              ),
            ],
          ),

          // 해석
          if (cycle.reading.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              cycle.reading,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: theme.textSecondary,
              ),
            ),
          ],

          // 기회 & 도전
          if (cycle.opportunities.isNotEmpty || cycle.challenges.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cycle.opportunities.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '기회',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...cycle.opportunities.take(2).map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '• $o',
                            style: TextStyle(fontSize: 12, color: theme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                      ],
                    ),
                  ),
                if (cycle.opportunities.isNotEmpty && cycle.challenges.isNotEmpty)
                  const SizedBox(width: 12),
                if (cycle.challenges.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '도전',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...cycle.challenges.take(2).map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '• $c',
                            style: TextStyle(fontSize: 12, color: theme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
