import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/daeun.dart';
import '../../domain/entities/saju_chart.dart';
import '../../domain/entities/saju_analysis.dart';
import '../../domain/services/hapchung_service.dart';
import '../../domain/services/jijanggan_service.dart';
import '../../domain/services/unsung_service.dart';
import '../../domain/services/twelve_sinsal_service.dart';
import '../../domain/services/gongmang_service.dart';
import '../providers/saju_chart_provider.dart';
import 'hapchung_tab.dart';
import 'unsung_display.dart';
import 'sinsal_display.dart';
import 'gongmang_display.dart';
import 'jijanggan_display.dart';
import 'sipsung_display.dart';
import 'pillar_display.dart';
import 'possteller_style_table.dart';
import 'fortune_display.dart';
import 'day_strength_display.dart';
import 'oheng_analysis_display.dart';
import 'gilseong_display.dart';
import '../../domain/entities/pillar.dart';
import '../../data/constants/sipsin_relations.dart';
import '../../domain/services/gilseong_service.dart';

/// 포스텔러 스타일 사주 상세 탭 컨테이너
/// 여러 분석 탭(궁성, 합충, 십성, 운성, 신살, 공망)을 제공
class SajuDetailTabs extends ConsumerStatefulWidget {
  final bool isFullPage;

  const SajuDetailTabs({super.key, this.isFullPage = false});

  @override
  ConsumerState<SajuDetailTabs> createState() => _SajuDetailTabsState();
}

class _SajuDetailTabsState extends ConsumerState<SajuDetailTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 탭 정의
  static const _tabs = [
    _TabItem(label: '만세력', icon: Icons.grid_view_rounded),
    _TabItem(label: '오행', icon: Icons.donut_small),
    _TabItem(label: '신강', icon: Icons.fitness_center),
    _TabItem(label: '대운', icon: Icons.timeline),
    _TabItem(label: '합충', icon: Icons.sync_alt),
    _TabItem(label: '십성', icon: Icons.stars_rounded),
    _TabItem(label: '운성', icon: Icons.trending_up),
    _TabItem(label: '신살', icon: Icons.flash_on),
    _TabItem(label: '공망', icon: Icons.highlight_off),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sajuAnalysisAsync = ref.watch(currentSajuAnalysisProvider);
    final isFullPage = widget.isFullPage;

    return Container(
      constraints: isFullPage ? null : const BoxConstraints(maxHeight: 700),
      decoration: isFullPage
          ? null
          : BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
      child: Column(
        mainAxisSize: isFullPage ? MainAxisSize.max : MainAxisSize.min,
        children: [
          // Handle bar (팝업 모드에서만 표시)
          if (!isFullPage)
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          // Header (팝업 모드에서만 표시)
          if (!isFullPage)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '사주 풀이 자세히 보기',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.accent,
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              tabs: _tabs
                  .map((tab) => Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tab.icon, size: 16),
                            const SizedBox(width: 6),
                            Text(tab.label),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          // Tab Content
          Expanded(
            child: sajuAnalysisAsync.when(
              data: (analysis) {
                if (analysis == null) {
                  return const Center(
                    child: Text(
                      '분석 정보를 불러올 수 없습니다.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                final chart = analysis.chart;
                return TabBarView(
                  controller: _tabController,
                  children: [
                    // 1. 만세력 탭
                    _ManseryeokTab(chart: chart, oheng: analysis.ohengDistribution),
                    // 2. 오행/십성 분석 탭
                    OhengAnalysisDisplay(analysis: analysis),
                    // 3. 신강/신약 + 용신 탭
                    DayStrengthDisplay(analysis: analysis),
                    // 4. 대운/세운/월운 탭
                    FortuneDisplay(analysis: analysis),
                    // 5. 합충 탭
                    HapchungTab(chart: chart),
                    // 6. 십성 탭
                    _SipSungTab(chart: chart),
                    // 7. 운성 탭
                    _UnsungTab(chart: chart),
                    // 8. 신살 탭 (성별 정보 전달)
                    _SinsalTab(
                      chart: chart,
                      isMale: analysis.daeun?.gender == Gender.male,
                    ),
                    // 9. 공망 탭
                    _GongmangTab(chart: chart),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '오류가 발생했습니다:\n$err',
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 탭 아이템 정의
class _TabItem {
  final String label;
  final IconData icon;

  const _TabItem({required this.label, required this.icon});
}

/// 만세력 탭 (포스텔러 스타일 테이블 포함)
class _ManseryeokTab extends StatelessWidget {
  final SajuChart chart;
  final OhengDistribution oheng;

  const _ManseryeokTab({
    required this.chart,
    required this.oheng,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 포스텔러 스타일 통합 테이블
          _buildSectionTitle(context, '사주 팔자 분석표'),
          const SizedBox(height: 12),
          PosstellerStyleTable(chart: chart),
          const SizedBox(height: 24),

          // 기존 4주 카드 표시
          _buildSectionTitle(context, '사주팔자 (Four Pillars)'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 반응형 사이즈 조정
                final availableWidth = constraints.maxWidth;
                final pillarSize = availableWidth > 400 ? 32.0 : availableWidth > 300 ? 26.0 : 22.0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                      child: PillarDisplay(
                        label: '시주',
                        pillar: chart.hourPillar ?? const Pillar(gan: '?', ji: '?'),
                        size: pillarSize,
                      ),
                    ),
                    Flexible(
                      child: PillarDisplay(
                        label: '일주 (나)',
                        pillar: chart.dayPillar,
                        size: pillarSize,
                      ),
                    ),
                    Flexible(
                      child: PillarDisplay(
                        label: '월주',
                        pillar: chart.monthPillar,
                        size: pillarSize,
                      ),
                    ),
                    Flexible(
                      child: PillarDisplay(
                        label: '년주',
                        pillar: chart.yearPillar,
                        size: pillarSize,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // 오행 분포
          _buildSectionTitle(context, '오행 분포'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildOhengBar(context, '목(木) Wood', oheng.mok, AppColors.wood),
                _buildOhengBar(context, '화(火) Fire', oheng.hwa, AppColors.fire),
                _buildOhengBar(context, '토(土) Earth', oheng.to, AppColors.earth),
                _buildOhengBar(context, '금(金) Metal', oheng.geum, AppColors.metal),
                _buildOhengBar(context, '수(水) Water', oheng.su, AppColors.water),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
    );
  }

  Widget _buildOhengBar(
      BuildContext context, String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                if (count > 0)
                  Container(
                    height: 12,
                    width: count * 40.0,
                    constraints: const BoxConstraints(maxWidth: 200),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$count개',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

/// 십성 탭
class _SipSungTab extends StatelessWidget {
  final SajuChart chart;

  const _SipSungTab({required this.chart});

  @override
  Widget build(BuildContext context) {
    final jijangganResult = JiJangGanService.analyzeFromChart(chart);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 십성이란? 설명 카드
          _buildExplanationCard(context),
          const SizedBox(height: 20),

          _buildSectionTitle(context, '천간 십성'),
          const SizedBox(height: 12),
          _buildCheonganSipSin(context),
          const SizedBox(height: 24),

          _buildSectionTitle(context, '지장간 십성'),
          const SizedBox(height: 12),
          JiJangGanRow(analysis: jijangganResult, compact: true),
          const SizedBox(height: 24),

          _buildSectionTitle(context, '십성 분포'),
          const SizedBox(height: 12),
          SipSungCategoryChart(
            distribution: jijangganResult.categoryDistribution,
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withOpacity(0.1),
            AppColors.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                '십성(十星)이란?',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '일간(日干, 나)을 기준으로 다른 간지와의 관계를 나타낸 것입니다. '
            '오행의 상생상극 관계와 음양 조화에 따라 10가지 관계가 정해집니다.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '• 비겁(比劫): 나와 같은 오행 - 형제, 경쟁자, 자아\n'
            '• 식상(食傷): 내가 생하는 오행 - 표현력, 재능, 자녀\n'
            '• 재성(財星): 내가 극하는 오행 - 재물, 아버지(남), 아내(남)\n'
            '• 관성(官星): 나를 극하는 오행 - 직장, 명예, 남편(여)\n'
            '• 인성(印星): 나를 생하는 오행 - 학문, 문서, 어머니',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
    );
  }

  Widget _buildCheonganSipSin(BuildContext context) {
    final dayGan = chart.dayPillar.gan;

    // 각 천간의 십성 계산
    final sipsinList = <SipSin?>[
      chart.hourPillar != null
          ? calculateSipSin(dayGan, chart.hourPillar!.gan)
          : null,
      calculateSipSin(dayGan, chart.dayPillar.gan), // 일간 = 비견
      calculateSipSin(dayGan, chart.monthPillar.gan),
      calculateSipSin(dayGan, chart.yearPillar.gan),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 60,
            child: Text(
              '천간',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ),
          ...sipsinList.map((sipsin) => Expanded(
                child: Center(
                  child: sipsin != null
                      ? SipSungDisplay(
                          sipsin: sipsin,
                          size: SipSungSize.medium,
                        )
                      : const Text(
                          '-',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                ),
              )),
        ],
      ),
    );
  }
}

/// 운성 탭
class _UnsungTab extends StatelessWidget {
  final SajuChart chart;

  const _UnsungTab({required this.chart});

  @override
  Widget build(BuildContext context) {
    final result = UnsungService.analyzeFromChart(chart);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 요약
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics_outlined,
                    color: AppColors.accent, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.summary,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 12운성 테이블
          _buildSectionTitle(context, '각 궁성별 12운성'),
          const SizedBox(height: 12),
          UnsungTable(result: result),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
    );
  }
}

/// 신살 탭
class _SinsalTab extends StatelessWidget {
  final SajuChart chart;
  final bool isMale;

  const _SinsalTab({
    required this.chart,
    this.isMale = true,
  });

  @override
  Widget build(BuildContext context) {
    // 12신살 분석 (년지 기준 - 포스텔러 호환, Phase 39)
    final twelveSinsalResult = TwelveSinsalService.analyzeFromChart(chart);
    final gilseongResult = GilseongService.analyzeFromChart(chart);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 신살과 길성 통합 테이블 (포스텔러 스타일)
          SinsalGilseongTable(
            gilseongResult: gilseongResult,
            yearGan: chart.yearPillar.gan,
            yearJi: chart.yearPillar.ji,
            monthGan: chart.monthPillar.gan,
            monthJi: chart.monthPillar.ji,
            dayGan: chart.dayPillar.gan,
            dayJi: chart.dayPillar.ji,
            hourGan: chart.hourPillar?.gan,
            hourJi: chart.hourPillar?.ji,
          ),
          const SizedBox(height: 16),

          // Phase 24: 확장 신살 정보 (효신살, 고신살/과숙살, 천라지망, 원진살)
          ExtendedSinsalInfoCard(
            result: gilseongResult,
            isMale: isMale,
          ),
          const SizedBox(height: 24),

          // 12신살 요약
          _buildSectionTitle(context, '12신살 요약'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '주요 12신살',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  twelveSinsalResult.summary,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 12신살 상세 테이블
          _buildSectionTitle(context, '각 궁성별 12신살'),
          const SizedBox(height: 12),
          SinsalTable(result: twelveSinsalResult),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
    );
  }
}

/// 공망 탭
class _GongmangTab extends StatelessWidget {
  final SajuChart chart;

  const _GongmangTab({required this.chart});

  @override
  Widget build(BuildContext context) {
    final result = GongmangService.analyzeFromChart(chart);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 공망 지지 표시
          _buildSectionTitle(context, '공망 지지'),
          const SizedBox(height: 12),
          GongmangJijiDisplay(gongmangJijis: result.gongmangJijis),
          const SizedBox(height: 24),

          // 요약
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: result.hasGongmang
                  ? AppColors.warning.withOpacity(0.1)
                  : AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: result.hasGongmang
                    ? AppColors.warning.withOpacity(0.3)
                    : AppColors.success.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  result.hasGongmang
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: result.hasGongmang ? AppColors.warning : AppColors.success,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.summary,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 상세 결과
          _buildSectionTitle(context, '각 궁성별 공망 분석'),
          const SizedBox(height: 12),
          GongmangTable(result: result),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
    );
  }
}
