import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/text_formatter.dart';
import '../../../../shared/widgets/fortune_shimmer_loading.dart';
import '../../../../shared/widgets/fortune_category_chip_section.dart';
import '../../../../shared/widgets/fortune_section_card.dart';
import '../../../../shared/widgets/fortune_title_header.dart';
import '../../../../ad/ad_service.dart';
import '../../../../animation/saju_loading_animation.dart';
import '../../../../purchase/providers/purchase_provider.dart';
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
          'lifetime_fortune.title'.tr(),
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
            'lifetime_fortune.errorLoad'.tr(),
            style: TextStyle(color: theme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => ref.read(lifetimeFortuneProvider.notifier).refresh(),
            child: Text('lifetime_fortune.retry'.tr()),
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
        final statusMessage = progress?.currentAnalysisDetail ?? 'lifetime_fortune.analyzingStatus'.tr();

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
            'lifetime_fortune.analyzingFallback'.tr(),
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
              'lifetime_fortune.analyzingFallbackSub'.tr(),
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
                'lifetime_fortune.completed'.tr(namedArgs: {'sections': progress.completedSections.join(', ')}),
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
        if (fortune.mySajuIntro != null && fortune.mySajuIntro!.hasContent) ...[
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
            title: 'lifetime_fortune.mySajuSummary'.tr(),
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
            title: 'lifetime_fortune.personality'.tr(),
            children: [
              if (fortune.personality.description.isNotEmpty)
                _buildParagraph(theme, fortune.personality.description),
              if (fortune.personality.coreTraits.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'lifetime_fortune.coreTraits'.tr(),
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
                  'lifetime_fortune.strengths'.tr(),
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
                  'lifetime_fortune.weaknesses'.tr(),
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
        // v9.4: 카테고리별 상세 필드 전체 전달 (DB 필드 100% 매핑)
        if (fortune.categories.isNotEmpty) ...[
          FortuneCategoryChipSection(
            fortuneType: 'lifetime',
            title: 'lifetime_fortune.categoryFortune'.tr(),
            categories: fortune.categories.map((key, cat) => MapEntry(
              key,
              CategoryData(
                title: cat.title,
                score: cat.score,
                reading: cat.reading,
                advice: cat.advice,
                cautions: cat.cautions.isNotEmpty ? cat.cautions : null,
                strengths: cat.strengths.isNotEmpty ? cat.strengths : null,
                weaknesses: cat.weaknesses.isNotEmpty ? cat.weaknesses : null,
                timing: cat.timing,
                suitableFields: cat.suitableFields.isNotEmpty ? cat.suitableFields : null,
                unsuitableFields: cat.unsuitableFields.isNotEmpty ? cat.unsuitableFields : null,
                // v9.4: 카테고리별 상세 필드
                workStyle: cat.workStyle,
                leadershipPotential: cat.leadershipPotential,
                datingPattern: cat.datingPattern,
                attractionStyle: cat.attractionStyle,
                idealPartnerTraits: cat.idealPartnerTraits.isNotEmpty ? cat.idealPartnerTraits : null,
                overallTendency: cat.overallTendency,
                earningStyle: cat.earningStyle,
                spendingTendency: cat.spendingTendency,
                investmentAptitude: cat.investmentAptitude,
                entrepreneurshipAptitude: cat.entrepreneurshipAptitude,
                businessPartnerTraits: cat.businessPartnerTraits,
                spousePalaceAnalysis: cat.spousePalaceAnalysis,
                spouseCharacteristics: cat.spouseCharacteristics,
                marriedLifeTendency: cat.marriedLifeTendency,
                mentalHealth: cat.mentalHealth,
                lifestyleAdvice: cat.lifestyleAdvice.isNotEmpty ? cat.lifestyleAdvice : null,
              ),
            )),
          ),
          const SizedBox(height: 8),
        ],

        // ========== 5단계: 시간축 ==========
        // v8.1: 전성기 섹션 (광고 잠금)
        if (fortune.peakYears != null && fortune.peakYears!.hasContent) ...[
          _buildPeakYearsCard(theme, fortune.peakYears!),
          const SizedBox(height: 32),
        ],

        if (_hasLifeCycles(fortune.lifeCycles)) ...[
          _buildSection(
            theme,
            title: 'lifetime_fortune.lifeCycleOutlook'.tr(),
            children: [
              if (fortune.lifeCycles.youth.isNotEmpty) ...[
                _buildSubSection(theme, 'lifetime_fortune.youthPeriod'.tr(), fortune.lifeCycles.youth),
                if (fortune.lifeCycles.youthDetail.hasContent) ...[
                  const SizedBox(height: 12),
                  _buildLifeCycleDetailSection(theme, fortune.lifeCycles.youthDetail),
                ],
                const SizedBox(height: 12),
              ],
              if (fortune.lifeCycles.middleAge.isNotEmpty) ...[
                _buildLifeCycleCard(
                  theme,
                  cycleKey: 'middleAge',
                  title: 'lifetime_fortune.middleAgePeriod'.tr(),
                  ageRange: 'lifetime_fortune.middleAgeRange'.tr(),
                  content: fortune.lifeCycles.middleAge,
                  detail: fortune.lifeCycles.middleAgeDetail,
                ),
                const SizedBox(height: 12),
              ],
              if (fortune.lifeCycles.laterYears.isNotEmpty)
                _buildLifeCycleCard(
                  theme,
                  cycleKey: 'laterYears',
                  title: 'lifetime_fortune.laterYearsPeriod'.tr(),
                  ageRange: 'lifetime_fortune.laterYearsRange'.tr(),
                  content: fortune.lifeCycles.laterYears,
                  detail: fortune.lifeCycles.laterYearsDetail,
                ),
              if (fortune.lifeCycles.keyYears.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'lifetime_fortune.keyTurningPoints'.tr(),
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
            title: 'lifetime_fortune.luckyInfo'.tr(),
            children: [
              if (fortune.luckyElements.colors.isNotEmpty)
                _buildLuckyItem(theme, 'color', 'lifetime_fortune.luckyColor'.tr(), fortune.luckyElements.colors.join(', ')),
              if (fortune.luckyElements.numbers.isNotEmpty)
                _buildLuckyItem(theme, 'number', 'lifetime_fortune.luckyNumber'.tr(), fortune.luckyElements.numbers.join(', ')),
              if (fortune.luckyElements.directions.isNotEmpty)
                _buildLuckyItem(theme, 'direction', 'lifetime_fortune.luckyDirection'.tr(), fortune.luckyElements.directions.join(', ')),
              if (fortune.luckyElements.seasons.isNotEmpty)
                _buildLuckyItem(theme, 'season', 'lifetime_fortune.luckySeason'.tr(), fortune.luckyElements.seasons),
              if (fortune.luckyElements.partnerElements.isNotEmpty)
                _buildLuckyItem(theme, 'partner', 'lifetime_fortune.luckyPartner'.tr(), fortune.luckyElements.partnerElements.join(', ')),
            ],
          ),
          const SizedBox(height: 32),
        ],

        // AI 시대 해석 (광고 잠금)
        if (fortune.modernInterpretation != null && fortune.modernInterpretation!.hasContent) ...[
          _buildModernInterpretationCard(theme, fortune.modernInterpretation!),
          const SizedBox(height: 32),
        ],

        // ========== 7단계: 마무리 ==========
        // 종합 인생 조언
        if (fortune.overallAdvice.isNotEmpty) ...[
          _buildSection(
            theme,
            title: 'lifetime_fortune.overallLifeAdvice'.tr(),
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
                      'lifetime_fortune.analyzingInProgress'.tr(),
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
              '${progress.currentAnalysisDetail}\n${'lifetime_fortune.autoShowOnComplete'.tr()}',
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
        if (fortune.mySajuIntro != null && fortune.mySajuIntro!.hasContent) ...[
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
            title: 'lifetime_fortune.mySajuSummary'.tr(),
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
            title: 'lifetime_fortune.personality'.tr(),
            children: [
              if (fortune.personality.description.isNotEmpty)
                _buildParagraph(theme, fortune.personality.description),
              if (fortune.personality.coreTraits.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'lifetime_fortune.coreTraits'.tr(),
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
                  'lifetime_fortune.strengths'.tr(),
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
                  'lifetime_fortune.weaknesses'.tr(),
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
        // v9.4: 카테고리별 상세 필드 전체 전달 (DB 필드 100% 매핑)
        if (fortune.categories.isNotEmpty) ...[
          FortuneCategoryChipSection(
            fortuneType: 'lifetime',
            title: 'lifetime_fortune.categoryFortune'.tr(),
            categories: fortune.categories.map((key, cat) => MapEntry(
              key,
              CategoryData(
                title: cat.title,
                score: cat.score,
                reading: cat.reading,
                advice: cat.advice,
                cautions: cat.cautions.isNotEmpty ? cat.cautions : null,
                strengths: cat.strengths.isNotEmpty ? cat.strengths : null,
                weaknesses: cat.weaknesses.isNotEmpty ? cat.weaknesses : null,
                timing: cat.timing,
                suitableFields: cat.suitableFields.isNotEmpty ? cat.suitableFields : null,
                unsuitableFields: cat.unsuitableFields.isNotEmpty ? cat.unsuitableFields : null,
                // v9.4: 카테고리별 상세 필드
                workStyle: cat.workStyle,
                leadershipPotential: cat.leadershipPotential,
                datingPattern: cat.datingPattern,
                attractionStyle: cat.attractionStyle,
                idealPartnerTraits: cat.idealPartnerTraits.isNotEmpty ? cat.idealPartnerTraits : null,
                overallTendency: cat.overallTendency,
                earningStyle: cat.earningStyle,
                spendingTendency: cat.spendingTendency,
                investmentAptitude: cat.investmentAptitude,
                entrepreneurshipAptitude: cat.entrepreneurshipAptitude,
                businessPartnerTraits: cat.businessPartnerTraits,
                spousePalaceAnalysis: cat.spousePalaceAnalysis,
                spouseCharacteristics: cat.spouseCharacteristics,
                marriedLifeTendency: cat.marriedLifeTendency,
                mentalHealth: cat.mentalHealth,
                lifestyleAdvice: cat.lifestyleAdvice.isNotEmpty ? cat.lifestyleAdvice : null,
              ),
            )),
          ),
          const SizedBox(height: 8),
        ],

        // ========== 5단계: 시간축 (언제?) ==========
        // v8.1: 전성기 섹션 (시간축 최상단에 배치, 광고 잠금)
        if (fortune.peakYears != null && fortune.peakYears!.hasContent) ...[
          _buildPeakYearsCard(theme, fortune.peakYears!),
          const SizedBox(height: 32),
        ],

        if (_hasLifeCycles(fortune.lifeCycles)) ...[
          _buildSection(
            theme,
            title: 'lifetime_fortune.lifeCycleOutlook'.tr(),
            children: [
              // 청년기 (항상 열림)
              if (fortune.lifeCycles.youth.isNotEmpty) ...[
                _buildSubSection(theme, 'lifetime_fortune.youthPeriod'.tr(), fortune.lifeCycles.youth),
                if (fortune.lifeCycles.youthDetail.hasContent) ...[
                  const SizedBox(height: 12),
                  _buildLifeCycleDetailSection(theme, fortune.lifeCycles.youthDetail),
                ],
                const SizedBox(height: 12),
              ],
              // 중년기 (광고 필요)
              if (fortune.lifeCycles.middleAge.isNotEmpty) ...[
                _buildLifeCycleCard(
                  theme,
                  cycleKey: 'middleAge',
                  title: 'lifetime_fortune.middleAgePeriod'.tr(),
                  ageRange: 'lifetime_fortune.middleAgeRange'.tr(),
                  content: fortune.lifeCycles.middleAge,
                  detail: fortune.lifeCycles.middleAgeDetail,
                ),
                const SizedBox(height: 12),
              ],
              // 후년기 (광고 필요)
              if (fortune.lifeCycles.laterYears.isNotEmpty)
                _buildLifeCycleCard(
                  theme,
                  cycleKey: 'laterYears',
                  title: 'lifetime_fortune.laterYearsPeriod'.tr(),
                  ageRange: 'lifetime_fortune.laterYearsRange'.tr(),
                  content: fortune.lifeCycles.laterYears,
                  detail: fortune.lifeCycles.laterYearsDetail,
                ),
              if (fortune.lifeCycles.keyYears.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'lifetime_fortune.keyTurningPoints'.tr(),
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
            title: 'lifetime_fortune.luckyInfo'.tr(),
            children: [
              if (fortune.luckyElements.colors.isNotEmpty)
                _buildLuckyItem(theme, 'color', 'lifetime_fortune.luckyColor'.tr(), fortune.luckyElements.colors.join(', ')),
              if (fortune.luckyElements.numbers.isNotEmpty)
                _buildLuckyItem(theme, 'number', 'lifetime_fortune.luckyNumber'.tr(), fortune.luckyElements.numbers.join(', ')),
              if (fortune.luckyElements.directions.isNotEmpty)
                _buildLuckyItem(theme, 'direction', 'lifetime_fortune.luckyDirection'.tr(), fortune.luckyElements.directions.join(', ')),
              if (fortune.luckyElements.seasons.isNotEmpty)
                _buildLuckyItem(theme, 'season', 'lifetime_fortune.luckySeason'.tr(), fortune.luckyElements.seasons),
              if (fortune.luckyElements.partnerElements.isNotEmpty)
                _buildLuckyItem(theme, 'partner', 'lifetime_fortune.luckyPartner'.tr(), fortune.luckyElements.partnerElements.join(', ')),
            ],
          ),
          const SizedBox(height: 32),
        ],

        // AI 시대 해석 (광고 잠금)
        if (fortune.modernInterpretation != null && fortune.modernInterpretation!.hasContent) ...[
          _buildModernInterpretationCard(theme, fortune.modernInterpretation!),
          const SizedBox(height: 32),
        ],

        // ========== 7단계: 마무리 ==========
        // 종합 인생 조언
        if (fortune.overallAdvice.isNotEmpty) ...[
          _buildSection(
            theme,
            title: 'lifetime_fortune.overallLifeAdvice'.tr(),
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
    return FortuneTitleHeader(
      title: 'lifetime_fortune.title'.tr(),
      subtitle: 'lifetime_fortune.subtitle'.tr(),
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
      FortuneTextFormatter.formatParagraph(text),
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

  Widget _buildLuckyItem(AppThemeExtension theme, String iconKey, String label, String value) {
    // 아이콘 키별 아이콘
    IconData icon;
    switch (iconKey) {
      case 'color':
        icon = Icons.palette_outlined;
        break;
      case 'number':
        icon = Icons.tag;
        break;
      case 'direction':
        icon = Icons.explore_outlined;
        break;
      case 'season':
        icon = Icons.wb_sunny_outlined;
        break;
      case 'partner':
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
        label: Text(
          'lifetime_fortune.consultButton'.tr(),
          style: const TextStyle(
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
  /// v9.0: ilju (일주설명) 필드 추가
  Widget _buildMySajuIntroSection(AppThemeExtension theme, MySajuIntroSection intro) {
    // ilju와 reading을 조합하여 표시
    final contentBuffer = StringBuffer();

    // 일주 설명 (있으면 먼저 표시)
    if (intro.ilju.isNotEmpty) {
      contentBuffer.writeln('📍 ${intro.ilju}');
      contentBuffer.writeln('');
    }

    // 일반 reading
    if (intro.reading.isNotEmpty) {
      contentBuffer.write(intro.reading);
    }

    return FortuneSectionCard(
      title: intro.title.isNotEmpty ? intro.title : 'lifetime_fortune.mySajuIntroDefault'.tr(),
      icon: Icons.person_outline,
      content: contentBuffer.toString().trim(),
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
                'lifetime_fortune.mySajuCharacters'.tr(),
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
  /// 전통 순서: 시주 → 일주 → 월주 → 연주 (오른쪽에서 왼쪽으로 읽음)
  Widget _buildSajuGrid(AppThemeExtension theme, MySajuCharactersSection chars) {
    final columns = [
      ('lifetime_fortune.pillarHour'.tr(), chars.hourGan, chars.hourJi),
      ('lifetime_fortune.pillarDay'.tr(), chars.dayGan, chars.dayJi),
      ('lifetime_fortune.pillarMonth'.tr(), chars.monthGan, chars.monthJi),
      ('lifetime_fortune.pillarYear'.tr(), chars.yearGan, chars.yearJi),
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
              _buildCharacterCard(theme, gan, isGan: true, isDay: label == 'lifetime_fortune.pillarDay'.tr()),
              const SizedBox(height: 6),
              // 지지
              _buildCharacterCard(theme, ji, isGan: false, isDay: label == 'lifetime_fortune.pillarDay'.tr()),
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
        return const Color(0xFF708090);  // 슬레이트 그레이 (은색 계열)
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
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _buildTag(theme, info.oheng, ohengColor),
                            _buildTag(theme, info.yinYang, theme.textSecondary),
                            if (isDay)
                              _buildTag(theme, 'lifetime_fortune.dayMasterTag'.tr(), theme.textPrimary),
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
                _buildInfoRow(theme, 'lifetime_fortune.zodiacAnimal'.tr(), info.animal!),
              ],
              if (info.season != null && info.season!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(theme, 'lifetime_fortune.season'.tr(), info.season!),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: theme.textPrimary,
            ),
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
    LifeCycleDetail? detail,
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
                    'lifetime_fortune.locked'.tr(),
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
          if (isUnlocked) ...[
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                color: theme.textSecondary,
                height: 1.8,
              ),
            ),
            if (detail != null && detail.hasContent) ...[
              const SizedBox(height: 16),
              _buildLifeCycleDetailSection(theme, detail),
            ],
          ] else
            _buildLockedContent(theme, cycleKey, title),
        ],
      ),
    );
  }

  /// 인생 주기 상세 카테고리 섹션 (v9.6)
  Widget _buildLifeCycleDetailSection(AppThemeExtension theme, LifeCycleDetail detail) {
    final categories = <MapEntry<String, String>>[];
    if (detail.career.isNotEmpty) categories.add(MapEntry('💼 ${'lifetime_fortune.categoryCareer'.tr()}', detail.career));
    if (detail.wealth.isNotEmpty) categories.add(MapEntry('💰 ${'lifetime_fortune.categoryWealth'.tr()}', detail.wealth));
    if (detail.love.isNotEmpty) categories.add(MapEntry('💕 ${'lifetime_fortune.categoryRelationship'.tr()}', detail.love));
    if (detail.health.isNotEmpty) categories.add(MapEntry('🏥 ${'lifetime_fortune.categoryHealth'.tr()}', detail.health));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 카테고리별 상세
        ...categories.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.value,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textSecondary,
                  height: 1.7,
                ),
              ),
            ],
          ),
        )),
        // 핵심 조언
        if (detail.tip.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.textPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💡 ', style: TextStyle(fontSize: 14, color: theme.textPrimary)),
                Expanded(
                  child: Text(
                    detail.tip,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.textPrimary,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        // 시기 정보
        if (detail.bestPeriod.isNotEmpty || detail.cautionPeriod.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              if (detail.bestPeriod.isNotEmpty)
                Expanded(
                  child: _buildPeriodChip(theme, 'lifetime_fortune.bestPeriod'.tr(), detail.bestPeriod, true),
                ),
              if (detail.bestPeriod.isNotEmpty && detail.cautionPeriod.isNotEmpty)
                const SizedBox(width: 8),
              if (detail.cautionPeriod.isNotEmpty)
                Expanded(
                  child: _buildPeriodChip(theme, 'lifetime_fortune.cautionPeriod'.tr(), detail.cautionPeriod, false),
                ),
            ],
          ),
        ],
      ],
    );
  }

  /// 시기 칩 위젯
  Widget _buildPeriodChip(AppThemeExtension theme, String label, String period, bool isPositive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isPositive
            ? Colors.green.withValues(alpha: 0.08)
            : Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPositive
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isPositive ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            period,
            style: TextStyle(
              fontSize: 13,
              color: theme.textSecondary,
            ),
          ),
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
                    'lifetime_fortune.adWatchToUnlock'.tr(namedArgs: {'title': title}),
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
                  _isLoadingAd ? 'lifetime_fortune.adLoading'.tr() : 'lifetime_fortune.adWatchAndCheck'.tr(namedArgs: {'title': title}),
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

    // 프리미엄 유저는 광고 없이 바로 해제
    final isPremium = ref.read(purchaseNotifierProvider.notifier).isPremium;
    if (isPremium) {
      setState(() {
        _unlockedCycles.add(cycleKey);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('lifetime_fortune.adUnlocked'.tr(namedArgs: {'title': title})),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

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
              content: Text('lifetime_fortune.adUnlockedWeb'.tr(namedArgs: {'title': title})),
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
                    content: Text('lifetime_fortune.adUnlocked'.tr(namedArgs: {'title': title})),
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
                content: Text('lifetime_fortune.adUnlocked'.tr(namedArgs: {'title': title})),
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
        title: Text('lifetime_fortune.adNotReadyTitle'.tr()),
        content: Text('lifetime_fortune.adNotReadyContent'.tr(namedArgs: {'title': title})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('lifetime_fortune.confirm'.tr()),
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
      title: 'lifetime_fortune.wonGukAnalysis'.tr(),
      children: [
        if (wonGuk.gyeokguk.isNotEmpty) ...[
          _buildSubSectionHeader(theme, 'lifetime_fortune.gyeokguk'.tr()),
          _buildParagraph(theme, wonGuk.gyeokguk),
          const SizedBox(height: 12),
        ],
        if (wonGuk.dayMaster.isNotEmpty) ...[
          _buildSubSectionHeader(theme, 'lifetime_fortune.dayMaster'.tr()),
          _buildParagraph(theme, wonGuk.dayMaster),
          const SizedBox(height: 12),
        ],
        if (wonGuk.ohengBalance.isNotEmpty) ...[
          _buildSubSectionHeader(theme, 'lifetime_fortune.ohengBalance'.tr()),
          _buildParagraph(theme, wonGuk.ohengBalance),
          const SizedBox(height: 12),
        ],
        // v8.2: singangSingak 필드 - 사용자 요청으로 주석 처리
        // if (wonGuk.singangSingak.isNotEmpty) ...[
        //   _buildSubSectionHeader(theme, '신강/신약'),
        //   _buildParagraph(theme, wonGuk.singangSingak),
        // ],
      ],
    );
  }

  /// 십성 분석 섹션 (강한 십성, 약한 십성, 상호작용)
  Widget _buildSipsungSection(AppThemeExtension theme, SipsungAnalysisSection sipsung) {
    return _buildSection(
      theme,
      title: 'lifetime_fortune.sipsungAnalysis'.tr(),
      children: [
        if (sipsung.dominantSipsung.isNotEmpty) ...[
          _buildSubSectionHeader(theme, 'lifetime_fortune.dominantSipsung'.tr()),
          ...sipsung.dominantSipsung.map((s) => _buildListItem(theme, s)),
          const SizedBox(height: 12),
        ],
        if (sipsung.weakSipsung.isNotEmpty) ...[
          _buildSubSectionHeader(theme, 'lifetime_fortune.weakSipsung'.tr()),
          ...sipsung.weakSipsung.map((s) => _buildListItem(theme, s)),
          const SizedBox(height: 12),
        ],
        if (sipsung.keyInteractions.isNotEmpty) ...[
          _buildSubSectionHeader(theme, 'lifetime_fortune.keyInteractions'.tr()),
          _buildParagraph(theme, sipsung.keyInteractions),
          const SizedBox(height: 12),
        ],
        if (sipsung.lifeImplications.isNotEmpty) ...[
          _buildSubSectionHeader(theme, 'lifetime_fortune.lifeImplications'.tr()),
          _buildParagraph(theme, sipsung.lifeImplications),
        ],
      ],
    );
  }

  /// 합충 분석 섹션 (합, 충, 종합 영향)
  Widget _buildHapchungSection(AppThemeExtension theme, HapchungAnalysisSection hapchung) {
    return _buildSection(
      theme,
      title: 'lifetime_fortune.hapchungAnalysis'.tr(),
      children: [
        if (hapchung.majorHaps.isNotEmpty) ...[
          _buildSubSectionHeader(theme, 'lifetime_fortune.majorHaps'.tr()),
          ...hapchung.majorHaps.map((h) => _buildListItem(theme, h)),
          const SizedBox(height: 12),
        ],
        if (hapchung.majorChungs.isNotEmpty) ...[
          _buildSubSectionHeader(theme, 'lifetime_fortune.majorChungs'.tr()),
          ...hapchung.majorChungs.map((c) => _buildListItem(theme, c)),
          const SizedBox(height: 12),
        ],
        if (hapchung.overallImpact.isNotEmpty) ...[
          _buildSubSectionHeader(theme, 'lifetime_fortune.overallImpact'.tr()),
          _buildParagraph(theme, hapchung.overallImpact),
          const SizedBox(height: 12),
        ],
        // v9.3: 기타 상호작용 섹션 숨김 처리
        // if (hapchung.otherInteractions.isNotEmpty) ...[
        //   _buildSubSectionHeader(theme, '기타 상호작용'),
        //   _buildParagraph(theme, hapchung.otherInteractions),
        // ],
      ],
    );
  }

  /// AI 시대 해석 카드 (광고 잠금)
  Widget _buildModernInterpretationCard(AppThemeExtension theme, ModernInterpretationSection modern) {
    final isUnlocked = _unlockedCycles.contains('modernInterpretation');

    // 잠금 해제 상태면 전체 내용 표시
    if (isUnlocked) {
      return _buildModernInterpretationSection(theme, modern);
    }

    // 잠금 상태: 미리보기 + 광고 버튼
    return _buildSection(
      theme,
      title: 'lifetime_fortune.aiEraInterpretation'.tr(),
      children: [
        // 미리보기 텍스트
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.textSecondary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.smart_toy_outlined, size: 24, color: Colors.purple),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'lifetime_fortune.digitalEraSaju'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'lifetime_fortune.lockedWithEmoji'.tr(),
                      style: TextStyle(fontSize: 12, color: Colors.purple),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'lifetime_fortune.digitalEraPreview'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              // 광고 버튼
              Row(
                children: [
                  Icon(Icons.movie_outlined, size: 20, color: theme.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'lifetime_fortune.adWatchForAiEra'.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoadingAd
                      ? null
                      : () => _showRewardedAdAndUnlock('modernInterpretation', 'lifetime_fortune.aiEraLabel'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: _isLoadingAd
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.play_circle_filled, size: 20),
                  label: Text(
                    _isLoadingAd ? 'lifetime_fortune.adLoading'.tr() : 'lifetime_fortune.adWatchAndCheckAiEra'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 현대적 해석 섹션 (AI 시대 직업, 재물, 관계)
  Widget _buildModernInterpretationSection(AppThemeExtension theme, ModernInterpretationSection modern) {
    return _buildSection(
      theme,
      title: 'lifetime_fortune.aiEraInterpretation'.tr(),
      children: [
        // 커리어 (AI 시대)
        if (modern.careerInAiEra != null) ...[
          _buildSubSectionHeader(theme, 'lifetime_fortune.digitalCareer'.tr()),
          if (modern.careerInAiEra!.traditionalPath.isNotEmpty)
            _buildParagraph(theme, modern.careerInAiEra!.traditionalPath),
          if (modern.careerInAiEra!.digitalStrengths.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildHighlightBox(theme, 'lifetime_fortune.digitalStrengths'.tr(), modern.careerInAiEra!.digitalStrengths),
          ],
          if (modern.careerInAiEra!.modernOpportunities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('lifetime_fortune.modernOpportunities'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimary)),
            const SizedBox(height: 4),
            ...modern.careerInAiEra!.modernOpportunities.map((o) => _buildListItem(theme, o)),
          ],
          const SizedBox(height: 16),
        ],

        // 재물 (AI 시대)
        if (modern.wealthInAiEra != null) ...[
          _buildSubSectionHeader(theme, 'lifetime_fortune.digitalWealth'.tr()),
          if (modern.wealthInAiEra!.traditionalView.isNotEmpty)
            _buildParagraph(theme, modern.wealthInAiEra!.traditionalView),
          if (modern.wealthInAiEra!.riskFactors.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildHighlightBox(theme, 'lifetime_fortune.riskFactors'.tr(), modern.wealthInAiEra!.riskFactors, isWarning: true),
          ],
          if (modern.wealthInAiEra!.modernOpportunities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('lifetime_fortune.modernOpportunities'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimary)),
            const SizedBox(height: 4),
            ...modern.wealthInAiEra!.modernOpportunities.map((o) => _buildListItem(theme, o)),
          ],
          const SizedBox(height: 16),
        ],

        // 관계 (AI 시대)
        if (modern.relationshipsInAiEra != null) ...[
          _buildSubSectionHeader(theme, 'lifetime_fortune.digitalRelationships'.tr()),
          if (modern.relationshipsInAiEra!.traditionalView.isNotEmpty)
            _buildParagraph(theme, modern.relationshipsInAiEra!.traditionalView),
          if (modern.relationshipsInAiEra!.modernNetworking.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildHighlightBox(theme, 'lifetime_fortune.networkingStyle'.tr(), modern.relationshipsInAiEra!.modernNetworking),
          ],
          if (modern.relationshipsInAiEra!.collaborationStyle.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildHighlightBox(theme, 'lifetime_fortune.collaborationStyle'.tr(), modern.relationshipsInAiEra!.collaborationStyle),
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
      title: 'lifetime_fortune.sinsalGilseong'.tr(),
      children: [
        if (sinsal.majorGilseong.isNotEmpty) ...[
          _buildSubSectionHeader(theme, 'lifetime_fortune.gilseongLabel'.tr()),
          ...sinsal.majorGilseong.map((g) => _buildListItem(theme, g)),
          const SizedBox(height: 12),
        ],
        if (sinsal.majorSinsal.isNotEmpty) ...[
          _buildSubSectionHeader(theme, 'lifetime_fortune.sinsalLabel'.tr()),
          ...sinsal.majorSinsal.map((s) => _buildListItem(theme, s)),
          const SizedBox(height: 12),
        ],
        if (sinsal.practicalImplications.isNotEmpty) ...[
          _buildSubSectionHeader(theme, 'lifetime_fortune.practicalImplications'.tr()),
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

  /// 전성기 카드 (광고 잠금)
  Widget _buildPeakYearsCard(AppThemeExtension theme, PeakYearsSection peakYears) {
    final isUnlocked = _unlockedCycles.contains('peakYears');

    // 잠금 해제 상태면 전체 내용 표시
    if (isUnlocked) {
      return _buildPeakYearsSection(theme, peakYears);
    }

    // 잠금 상태: 미리보기 + 광고 버튼
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD700).withValues(alpha: 0.1),
            const Color(0xFFFF8C00).withValues(alpha: 0.05),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'lifetime_fortune.peakYears'.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                      ),
                    ),
                    if (peakYears.period.isNotEmpty)
                      Text(
                        peakYears.period,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'lifetime_fortune.lockedWithEmoji'.tr(),
                  style: const TextStyle(fontSize: 12, color: Color(0xFFFF8C00)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 미리보기 텍스트
          Text(
            'lifetime_fortune.peakYearsPreview'.tr(),
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          // 안내 + 광고 버튼
          Row(
            children: [
              Icon(Icons.movie_outlined, size: 20, color: theme.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'lifetime_fortune.adWatchForPeakYears'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoadingAd
                  ? null
                  : () => _showRewardedAdAndUnlock('peakYears', 'lifetime_fortune.peakYears'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _isLoadingAd
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_circle_filled, size: 20),
              label: Text(
                _isLoadingAd ? 'lifetime_fortune.adLoading'.tr() : 'lifetime_fortune.adWatchAndCheckPeakYears'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 전성기 섹션 (잠금 해제 후 표시)
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
                    'lifetime_fortune.peakYears'.tr(),
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
            _buildSubSectionHeader(theme, 'lifetime_fortune.whyThisPeriod'.tr()),
            _buildParagraph(theme, peakYears.why),
            const SizedBox(height: 14),
          ],

          // 무엇을 해야 하는가?
          if (peakYears.whatToDo.isNotEmpty) ...[
            _buildSubSectionHeader(theme, 'lifetime_fortune.whatToDoInPeriod'.tr()),
            _buildParagraph(theme, peakYears.whatToDo),
            const SizedBox(height: 14),
          ],

          // 무엇을 준비해야 하는가?
          if (peakYears.whatToPrepare.isNotEmpty) ...[
            _buildSubSectionHeader(theme, 'lifetime_fortune.whatToPrepare'.tr()),
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
      title: 'lifetime_fortune.daeunDetailAnalysis'.tr(),
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
                    title: 'lifetime_fortune.bestDaeun'.tr(),
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
                    title: 'lifetime_fortune.cautionDaeun'.tr(),
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
          _buildSubSectionHeader(theme, 'lifetime_fortune.daeunFlow'.tr()),
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
                constraints: const BoxConstraints(maxWidth: 120),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      cycle.ageRange,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                          'lifetime_fortune.opportunities'.tr(),
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
                          'lifetime_fortune.challenges'.tr(),
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
