import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
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
  final String? profileId;

  const SajuDetailTabs({super.key, this.isFullPage = false, this.profileId});

  @override
  ConsumerState<SajuDetailTabs> createState() => _SajuDetailTabsState();
}

class _SajuDetailTabsState extends ConsumerState<SajuDetailTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 탭 정의 (각 탭에 대한 간략 설명 포함)
  static const _tabIcons = [
    Icons.grid_view_rounded,
    Icons.donut_small,
    Icons.fitness_center,
    Icons.timeline,
    Icons.sync_alt,
    Icons.stars_rounded,
    Icons.trending_up,
    Icons.flash_on,
    Icons.highlight_off,
  ];

  static const _tabLabelKeys = [
    'saju_chart.tabManseryeok',
    'saju_chart.tabOheng',
    'saju_chart.tabSingang',
    'saju_chart.tabDaeun',
    'saju_chart.tabHapchung',
    'saju_chart.tabSipsung',
    'saju_chart.tabUnsung',
    'saju_chart.tabSinsal',
    'saju_chart.tabGongmang',
  ];

  static const _tabDescKeys = [
    'saju_chart.tabManseryeokLongDesc',
    'saju_chart.tabOhengLongDesc',
    'saju_chart.tabSingangLongDesc',
    'saju_chart.tabDaeunLongDesc',
    'saju_chart.tabHapchungLongDesc',
    'saju_chart.tabSipsungLongDesc',
    'saju_chart.tabUnsungLongDesc',
    'saju_chart.tabSinsalLongDesc',
    'saju_chart.tabGongmangLongDesc',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabIcons.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // rebuild to update help bar
      }
    });
  }

  /// 현재 탭의 설명 팝업 표시
  void _showTabHelp(BuildContext context) {
    final index = _tabController.index;
    final label = _tabLabelKeys[index].tr();
    final description = _tabDescKeys[index].tr();
    if (description.isEmpty) return;
    final theme = context.appTheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(_tabIcons[index], color: theme.primaryColor, size: 24),
            const SizedBox(width: 10),
            Text(
              'saju_chart.whatIs'.tr(namedArgs: {'title': label}),
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          description,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 15,
            height: 1.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('saju_chart.confirm'.tr(), style: TextStyle(color: theme.primaryColor, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final sajuAnalysisAsync = widget.profileId != null
        ? ref.watch(sajuAnalysisForProfileProvider(widget.profileId!))
        : ref.watch(currentSajuAnalysisProvider);
    final isFullPage = widget.isFullPage;

    return Container(
      constraints: isFullPage ? null : const BoxConstraints(maxHeight: 700),
      decoration: isFullPage
          ? null
          : BoxDecoration(
              color: theme.surface,
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
                color: theme.textMuted,
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
                    'saju_chart.sajuDetailView'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: theme.textSecondary),
                  ),
                ],
              ),
            ),
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.border, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: theme.primaryColor,
              unselectedLabelColor: theme.textMuted,
              indicatorColor: theme.primaryColor,
              indicatorWeight: 2.5,
              labelPadding: const EdgeInsets.symmetric(horizontal: 14),
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              tabs: List.generate(_tabIcons.length, (i) => Tab(
                        height: 48,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_tabIcons[i], size: 18),
                            const SizedBox(width: 6),
                            Text(_tabLabelKeys[i].tr()),
                          ],
                        ),
                      )),
            ),
          ),
          // 탭 도움말 바 (물음표 아이콘 탭 시 설명 팝업)
          GestureDetector(
            onTap: () => _showTabHelp(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.06),
                border: Border(
                  bottom: BorderSide(color: theme.border, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    size: 20,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'saju_chart.tabTouchHint'.tr(namedArgs: {'label': _tabLabelKeys[_tabController.index].tr()}),
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: theme.primaryColor.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
          // Tab Content
          Expanded(
            child: sajuAnalysisAsync.when(
              data: (analysis) {
                if (analysis == null) {
                  return Center(
                    child: Text(
                      'saju_chart.cannotLoadAnalysis'.tr(),
                      style: TextStyle(color: theme.textSecondary),
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
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: theme.primaryColor),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'saju_chart.errorOccurredWithMsg'.tr(namedArgs: {'msg': '$err'}),
                    style: TextStyle(color: theme.fireColor ?? AppColors.error),
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

// _TabItem class removed - tab data now uses i18n key arrays

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
    final theme = context.appTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 포스텔러 스타일 통합 테이블
          _buildSectionTitle(context, 'saju_chart.sajuPaljaAnalysisTable'.tr(), theme),
          const SizedBox(height: 12),
          PosstellerStyleTable(chart: chart),
          const SizedBox(height: 24),

          // 기존 4주 카드 표시
          _buildSectionTitle(context, 'saju_chart.sajuPaljaFourPillars'.tr(), theme),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
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
                        label: 'saju_chart.hourPillar'.tr(),
                        pillar: chart.hourPillar ?? const Pillar(gan: '?', ji: '?'),
                        size: pillarSize,
                      ),
                    ),
                    Flexible(
                      child: PillarDisplay(
                        label: 'saju_chart.dayPillarMe'.tr(),
                        pillar: chart.dayPillar,
                        size: pillarSize,
                      ),
                    ),
                    Flexible(
                      child: PillarDisplay(
                        label: 'saju_chart.monthPillar'.tr(),
                        pillar: chart.monthPillar,
                        size: pillarSize,
                      ),
                    ),
                    Flexible(
                      child: PillarDisplay(
                        label: 'saju_chart.yearPillar'.tr(),
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
          _buildSectionTitle(context, 'saju_chart.ohengDistribution'.tr(), theme),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: Column(
              children: [
                _buildOhengBar(context, 'saju_chart.ohengWoodBar'.tr(), oheng.mok, theme.woodColor ?? AppColors.wood, theme),
                _buildOhengBar(context, 'saju_chart.ohengFireBar'.tr(), oheng.hwa, theme.fireColor ?? AppColors.fire, theme),
                _buildOhengBar(context, 'saju_chart.ohengEarthBar'.tr(), oheng.to, theme.earthColor ?? AppColors.earth, theme),
                _buildOhengBar(context, 'saju_chart.ohengMetalBar'.tr(), oheng.geum, theme.metalColor ?? AppColors.metal, theme),
                _buildOhengBar(context, 'saju_chart.ohengWaterBar'.tr(), oheng.su, theme.waterColor ?? AppColors.water, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, AppThemeExtension theme) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textSecondary,
            fontSize: 16,
          ),
    );
  }

  Widget _buildOhengBar(
      BuildContext context, String label, int count, Color color, AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: theme.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                if (count > 0)
                  Container(
                    height: 16,
                    width: count * 44.0,
                    constraints: const BoxConstraints(maxWidth: 220),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'saju_chart.countUnit'.tr(namedArgs: {'count': '$count'}),
            style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
    final theme = context.appTheme;
    final jijangganResult = JiJangGanService.analyzeFromChart(chart);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 십성이란? 설명 카드
          _buildExplanationCard(context, theme),
          const SizedBox(height: 20),

          _buildSectionTitle(context, 'saju_chart.cheonganSipsung'.tr(), theme),
          const SizedBox(height: 12),
          _buildCheonganSipSin(context, theme),
          const SizedBox(height: 24),

          _buildSectionTitle(context, 'saju_chart.jijangganSipsung'.tr(), theme),
          const SizedBox(height: 12),
          JiJangGanRow(analysis: jijangganResult, compact: true),
          const SizedBox(height: 24),

          _buildSectionTitle(context, 'saju_chart.sipsungDistribution'.tr(), theme),
          const SizedBox(height: 12),
          SipSungCategoryChart(
            distribution: jijangganResult.categoryDistribution,
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(BuildContext context, AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor.withOpacity(0.1),
            theme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded, color: theme.primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'saju_chart.sipsungDetailTitle'.tr(),
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'saju_chart.sipsungDetailBody'.tr(),
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${'saju_chart.sipsungBigeopDesc'.tr()}\n'
            '${'saju_chart.sipsungSiksangDesc'.tr()}\n'
            '${'saju_chart.sipsungJaeseongDesc'.tr()}\n'
            '${'saju_chart.sipsungGwanseongDesc'.tr()}\n'
            '${'saju_chart.sipsungInseongDesc'.tr()}',
            style: TextStyle(
              color: theme.textMuted,
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, AppThemeExtension theme) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textSecondary,
            fontSize: 16,
          ),
    );
  }

  Widget _buildCheonganSipSin(BuildContext context, AppThemeExtension theme) {
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
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              'saju_chart.heavenlyStem'.tr(),
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 13,
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
                      : Text(
                          '-',
                          style: TextStyle(
                            color: theme.textMuted,
                            fontSize: 13,
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

  // 12운성별 색상
  static const _unsungColors = {
    '장생': Color(0xFF4CAF50),  // 녹색 - 탄생
    '목욕': Color(0xFF2196F3),  // 파랑 - 성장
    '관대': Color(0xFF9C27B0),  // 보라 - 성인
    '건록': Color(0xFFFF9800),  // 주황 - 전성
    '제왕': Color(0xFFE91E63),  // 분홍 - 정점
    '쇠': Color(0xFF795548),    // 갈색 - 쇠퇴 시작
    '병': Color(0xFF607D8B),    // 청회색 - 쇠약
    '사': Color(0xFF9E9E9E),    // 회색 - 죽음
    '묘': Color(0xFF455A64),    // 진한 회색 - 무덤
    '절': Color(0xFF37474F),    // 더 진한 회색 - 완전 소멸
    '태': Color(0xFF00BCD4),    // 시안 - 잉태
    '양': Color(0xFF8BC34A),    // 연녹색 - 양육
  };

  // 12운성별 아이콘
  static const _unsungIcons = {
    '장생': Icons.child_care_rounded,       // 탄생
    '목욕': Icons.bathtub_rounded,          // 목욕
    '관대': Icons.school_rounded,           // 성인
    '건록': Icons.work_rounded,             // 일하는 시기
    '제왕': Icons.emoji_events_rounded,     // 정점/왕관
    '쇠': Icons.trending_down_rounded,      // 쇠퇴
    '병': Icons.local_hospital_rounded,     // 병
    '사': Icons.brightness_3_rounded,       // 달/죽음
    '묘': Icons.landscape_rounded,          // 무덤
    '절': Icons.radio_button_unchecked,     // 절
    '태': Icons.pregnant_woman_rounded,     // 잉태
    '양': Icons.child_friendly_rounded,     // 양육
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final result = UnsungService.analyzeFromChart(chart);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 운성이란? 설명 카드
          _buildExplanationCard(context, theme),
          const SizedBox(height: 16),

          // 궁성이란? 설명 카드
          _buildGungseongExplanationCard(context, theme),
          const SizedBox(height: 16),

          // 요약 카드 (개선된 디자인)
          _buildSummaryCard(context, result, theme),
          const SizedBox(height: 20),

          // 12운성 상세 카드 리스트
          _buildSectionHeader(context, 'saju_chart.gungseongUnsung'.tr(), 'saju_chart.gungseongUnsungSubtitle'.tr(), theme.primaryColor, Icons.analytics_rounded, theme),
          const SizedBox(height: 12),
          _buildUnsungDetailCards(context, result, theme),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(BuildContext context, AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor.withOpacity(0.1),
            theme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'saju_chart.unsungDetailTitle'.tr(),
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'saju_chart.unsungDetailBody'.tr(),
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCycleItem('장생', 'saju_chart.unsungCycleBirth'.tr(), theme),
                  _buildCycleArrow(theme),
                  _buildCycleItem('목욕', 'saju_chart.unsungCycleGrowth'.tr(), theme),
                  _buildCycleArrow(theme),
                  _buildCycleItem('관대', 'saju_chart.unsungCycleAdult'.tr(), theme),
                  _buildCycleArrow(theme),
                  _buildCycleItem('건록', 'saju_chart.unsungCyclePrime'.tr(), theme),
                  _buildCycleArrow(theme),
                  _buildCycleItem('제왕', 'saju_chart.unsungCyclePeak'.tr(), theme),
                  _buildCycleArrow(theme),
                  _buildCycleItem('쇠', 'saju_chart.unsungCycleDecline'.tr(), theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleItem(String name, String desc, AppThemeExtension theme) {
    final color = _unsungColors[name] ?? theme.textSecondary;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            name,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          desc,
          style: TextStyle(
            color: theme.textMuted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildCycleArrow(AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.arrow_forward_ios_rounded, size: 10, color: theme.textMuted),
    );
  }

  Widget _buildGungseongExplanationCard(BuildContext context, AppThemeExtension theme) {
    const tealColor = Color(0xFF009688);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tealColor.withOpacity(0.1),
            tealColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tealColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree_rounded, color: tealColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'saju_chart.gungseongDetailTitle'.tr(),
                style: TextStyle(
                  color: tealColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'saju_chart.gungseongDetailBody'.tr(),
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildGungseongRow('saju_chart.gungseong_year'.tr(), 'saju_chart.gungseong_yearPalace'.tr(), 'saju_chart.gungseong_yearMeaning'.tr(), theme),
                const SizedBox(height: 8),
                _buildGungseongRow('saju_chart.gungseong_month'.tr(), 'saju_chart.gungseong_monthPalace'.tr(), 'saju_chart.gungseong_monthMeaning'.tr(), theme),
                const SizedBox(height: 8),
                _buildGungseongRow('saju_chart.gungseong_day'.tr(), 'saju_chart.gungseong_dayPalace'.tr(), 'saju_chart.gungseong_dayMeaning'.tr(), theme),
                const SizedBox(height: 8),
                _buildGungseongRow('saju_chart.gungseong_hour'.tr(), 'saju_chart.gungseong_hourPalace'.tr(), 'saju_chart.gungseong_hourMeaning'.tr(), theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGungseongRow(String pillar, String palace, String meaning, AppThemeExtension theme) {
    const tealColor = Color(0xFF009688);
    return Row(
      children: [
        Container(
          width: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: tealColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            pillar,
            style: TextStyle(
              color: tealColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 50,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: theme.surfaceHover,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            palace,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            meaning,
            style: TextStyle(
              color: theme.textMuted,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle, Color color, IconData icon, AppThemeExtension theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, UnsungAnalysisResult result, AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: theme.primaryColor, size: 20),
              const SizedBox(width: 10),
              Text(
                'saju_chart.unsungSummaryTitle'.tr(),
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.format_quote_rounded, color: theme.primaryColor.withOpacity(0.5), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.summary,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsungDetailCards(BuildContext context, UnsungAnalysisResult result, AppThemeExtension theme) {
    final items = [
      result.yearUnsung,
      result.monthUnsung,
      result.dayUnsung,
      result.hourUnsung,
    ].whereType<UnsungResult>().toList();

    return Column(
      children: items.map((item) => _buildUnsungItemCard(context, item, theme)).toList(),
    );
  }

  Widget _buildUnsungItemCard(BuildContext context, UnsungResult item, AppThemeExtension theme) {
    final unsungName = item.unsung.korean;
    final color = _unsungColors[unsungName] ?? theme.textSecondary;
    final icon = _unsungIcons[unsungName] ?? Icons.circle;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 상단
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                // 궁성
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.pillarName,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 일간 → 지지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${item.dayGan}→${item.jiji}',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                // 운성 뱃지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        unsungName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 하단: 설명
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.surfaceHover,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.unsung.hanja,
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.unsung.meaning,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: color.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          UnsungService.getDetailedInterpretation(item.unsung),
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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

  // 신살별 색상 정의
  static const _sinsalColors = {
    '역마살': Color(0xFF2196F3),   // 파랑 - 이동/변화
    '도화살': Color(0xFFE91E63),   // 분홍 - 매력/인기
    '화개살': Color(0xFF9C27B0),   // 보라 - 예술/종교
    '장성살': Color(0xFF4CAF50),   // 녹색 - 성공/권위
    '겁살': Color(0xFFFF5722),     // 주황 - 위험/손재
    '재살': Color(0xFFF44336),     // 빨강 - 재앙
    '천살': Color(0xFF607D8B),     // 청회 - 하늘의 액
    '지살': Color(0xFF795548),     // 갈색 - 땅의 액
    '연살': Color(0xFFFFEB3B),     // 노랑 - 해의 액
    '월살': Color(0xFF00BCD4),     // 시안 - 달의 액
    '망신살': Color(0xFF9E9E9E),   // 회색 - 망신
    '반안살': Color(0xFF8BC34A),   // 연녹색 - 안정
  };

  // 신살별 아이콘 정의
  static const _sinsalIcons = {
    '역마살': Icons.flight_takeoff_rounded,
    '도화살': Icons.favorite_rounded,
    '화개살': Icons.palette_rounded,
    '장성살': Icons.military_tech_rounded,
    '겁살': Icons.warning_amber_rounded,
    '재살': Icons.dangerous_rounded,
    '천살': Icons.cloud_rounded,
    '지살': Icons.landscape_rounded,
    '연살': Icons.wb_sunny_rounded,
    '월살': Icons.nightlight_rounded,
    '망신살': Icons.sentiment_dissatisfied_rounded,
    '반안살': Icons.anchor_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    // 12신살 분석 (년지 기준 - 포스텔러 호환, Phase 39)
    final twelveSinsalResult = TwelveSinsalService.analyzeFromChart(chart);
    final gilseongResult = GilseongService.analyzeFromChart(chart);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 신살이란? 설명 카드
          _buildExplanationCard(context, theme),
          const SizedBox(height: 16),

          // 12신살 요약 카드 (개선된 디자인)
          _buildSinsalSummaryCard(context, twelveSinsalResult, theme),
          const SizedBox(height: 20),

          // 주요 신살 하이라이트
          if (twelveSinsalResult.yeokmaResult != null ||
              twelveSinsalResult.dohwaResult != null ||
              twelveSinsalResult.hwagaeResult != null ||
              twelveSinsalResult.jangsungResult != null) ...[
            _buildSectionHeader(context, 'saju_chart.mainSinsal'.tr(), 'saju_chart.mainSinsalSubtitle'.tr(), theme.primaryColor, Icons.star_rounded, theme),
            const SizedBox(height: 12),
            _buildKeySinsalCards(context, twelveSinsalResult, theme),
            const SizedBox(height: 20),
          ],

          // 12신살 상세 카드 리스트
          _buildSectionHeader(context, 'saju_chart.twelveSinsalDetail'.tr(), 'saju_chart.twelveSinsalDetailSubtitle'.tr(), theme.textSecondary, Icons.grid_view_rounded, theme),
          const SizedBox(height: 12),
          _buildSinsalDetailCards(context, twelveSinsalResult, theme),
          const SizedBox(height: 20),

          // 신살과 길성 통합 테이블 (포스텔러 스타일)
          _buildSectionHeader(context, 'saju_chart.sinsalGilseongTable'.tr(), 'saju_chart.sinsalGilseongTableSubtitle'.tr(), theme.textSecondary, Icons.table_chart_rounded, theme),
          const SizedBox(height: 12),
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
        ],
      ),
    );
  }

  Widget _buildExplanationCard(BuildContext context, AppThemeExtension theme) {
    const purpleColor = Color(0xFF9C27B0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            purpleColor.withOpacity(0.1),
            purpleColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: purpleColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded, color: purpleColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'saju_chart.sinsalDetailTitle'.tr(),
                style: TextStyle(
                  color: purpleColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'saju_chart.sinsalDetailBody'.tr(),
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildLegendItem('saju_chart.gilsin'.tr(), AppColors.success, theme),
                const SizedBox(width: 16),
                _buildLegendItem('saju_chart.hyungsin'.tr(), AppColors.error, theme),
                const SizedBox(width: 16),
                _buildLegendItem('saju_chart.mixed'.tr(), theme.primaryColor, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, AppThemeExtension theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle, Color color, IconData icon, AppThemeExtension theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSinsalSummaryCard(BuildContext context, TwelveSinsalAnalysisResult result, AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 길흉 통계
          Row(
            children: [
              Expanded(
                child: _buildStatBox('saju_chart.fortuneGil'.tr(), result.goodSinsalCount, AppColors.success),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBox('saju_chart.fortuneHyung'.tr(), result.badSinsalCount, AppColors.error),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBox('saju_chart.mixed'.tr(), result.mixedSinsalCount, theme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 요약 텍스트
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: theme.primaryColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.summary,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeySinsalCards(BuildContext context, TwelveSinsalAnalysisResult result, AppThemeExtension theme) {
    final keyItems = <Widget>[];

    if (result.jangsungResult != null) {
      keyItems.add(_buildKeySinsalCard(
        context,
        sinsal: result.jangsungResult!.sinsal,
        pillarName: result.jangsungResult!.pillarName,
        description: '권위와 성공을 상징하며, 출세와 명예를 얻을 수 있는 좋은 기운입니다.',
        theme: theme,
      ));
    }
    if (result.yeokmaResult != null) {
      keyItems.add(_buildKeySinsalCard(
        context,
        sinsal: result.yeokmaResult!.sinsal,
        pillarName: result.yeokmaResult!.pillarName,
        description: '이동과 변화의 기운으로, 활동적이고 여행이나 이사가 많을 수 있습니다.',
        theme: theme,
      ));
    }
    if (result.dohwaResult != null) {
      keyItems.add(_buildKeySinsalCard(
        context,
        sinsal: result.dohwaResult!.sinsal,
        pillarName: result.dohwaResult!.pillarName,
        description: '매력과 인기의 기운으로, 이성운과 대인관계에 영향을 줍니다.',
        theme: theme,
      ));
    }
    if (result.hwagaeResult != null) {
      keyItems.add(_buildKeySinsalCard(
        context,
        sinsal: result.hwagaeResult!.sinsal,
        pillarName: result.hwagaeResult!.pillarName,
        description: '예술성과 영적 감수성을 나타내며, 종교나 예술 분야에 재능이 있습니다.',
        theme: theme,
      ));
    }

    return Column(children: keyItems);
  }

  Widget _buildKeySinsalCard(
    BuildContext context, {
    required dynamic sinsal,
    required String pillarName,
    required String description,
    required AppThemeExtension theme,
  }) {
    final sinsalName = sinsal.korean;
    final color = _sinsalColors[sinsalName] ?? theme.primaryColor;
    final icon = _sinsalIcons[sinsalName] ?? Icons.star_rounded;
    final fortuneType = sinsal.fortuneType;
    final fortuneColor = fortuneType == '길' ? AppColors.success :
                         fortuneType == '흉' ? AppColors.error : theme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          // 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      sinsalName,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: fortuneColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        fortuneType,
                        style: TextStyle(
                          color: fortuneColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.surfaceHover,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        pillarName,
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 13,
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

  Widget _buildSinsalDetailCards(BuildContext context, TwelveSinsalAnalysisResult result, AppThemeExtension theme) {
    final items = [
      result.yearResult,
      result.monthResult,
      result.dayResult,
      result.hourResult,
    ].whereType<TwelveSinsalResult>().toList();

    return Column(
      children: items.map((item) => _buildSinsalItemCard(context, item, theme)).toList(),
    );
  }

  Widget _buildSinsalItemCard(BuildContext context, TwelveSinsalResult item, AppThemeExtension theme) {
    final sinsalName = item.sinsal.korean;
    final color = _sinsalColors[sinsalName] ?? theme.textSecondary;
    final icon = _sinsalIcons[sinsalName] ?? Icons.circle;
    final fortuneType = item.sinsal.fortuneType;
    final fortuneColor = fortuneType == '길' ? AppColors.success :
                         fortuneType == '흉' ? AppColors.error : theme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          // 상단
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                // 궁성
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.pillarName,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 지지
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(
                      item.jiji,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // 신살 뱃지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        sinsalName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 길흉 뱃지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: fortuneColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: fortuneColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    fortuneType == '길' ? 'saju_chart.fortuneGil'.tr() : fortuneType == '흉' ? 'saju_chart.fortuneHyung'.tr() : 'saju_chart.mixed'.tr(),
                    style: TextStyle(
                      color: fortuneColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 하단: 설명
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.sinsal.meaning,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  TwelveSinsalService.getDetailedInterpretation(item.sinsal),
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final theme = context.appTheme;
    final result = GongmangService.analyzeFromChart(chart);
    final hasGongmang = result.hasGongmang;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 공망이란? 설명 카드
          _buildExplanationCard(context, theme),
          const SizedBox(height: 16),

          // 공망 지지 표시 (개선된 디자인)
          _buildGongmangJijiCard(context, result, theme),
          const SizedBox(height: 16),

          // 요약 카드 (개선된 디자인)
          _buildSummaryCard(context, result, theme),
          const SizedBox(height: 20),

          // 각 궁성별 공망 상세 카드
          _buildSectionHeader(context, 'saju_chart.gungseongGongmangAnalysis'.tr(), 'saju_chart.gungseongGongmangSubtitle'.tr(), theme.textSecondary, Icons.grid_view_rounded, theme),
          const SizedBox(height: 12),
          _buildGongmangDetailCards(context, result, theme),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(BuildContext context, AppThemeExtension theme) {
    const grayBlue = Color(0xFF607D8B);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            grayBlue.withOpacity(0.1),
            grayBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: grayBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded, color: grayBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'saju_chart.gongmangDetailTitle'.tr(),
                style: TextStyle(
                  color: grayBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'saju_chart.gongmangDetailBody'.tr(),
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'saju_chart.gongmangTipBody'.tr(),
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle, Color color, IconData icon, AppThemeExtension theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGongmangJijiCard(BuildContext context, GongmangAnalysisResult result, AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 순(旬) 정보
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded, color: theme.primaryColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'saju_chart.gongmangDayPillarLabel'.tr(namedArgs: {'dayGapja': result.dayGapja}),
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.surfaceHover,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'saju_chart.gongmangSunBelong'.tr(namedArgs: {'sunName': result.sunInfo.sunName}),
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 공망 지지 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'saju_chart.gongmangJijiLabel'.tr(),
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 20),
              _buildGongmangJijiBox(result.sunInfo.gongmang1),
              const SizedBox(width: 12),
              _buildGongmangJijiBox(result.sunInfo.gongmang2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGongmangJijiBox(String jiji) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.error.withOpacity(0.15),
            AppColors.error.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          jiji,
          style: TextStyle(
            color: AppColors.error,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, GongmangAnalysisResult result, AppThemeExtension theme) {
    final hasGongmang = result.hasGongmang;
    final color = hasGongmang ? AppColors.warning : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // 통계
          Row(
            children: [
              Expanded(
                child: _buildStatBox('saju_chart.gongmangGung'.tr(), result.gongmangCount, AppColors.error),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBox('saju_chart.normalGung'.tr(), result.allResults.length - result.gongmangCount, AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 요약 메시지
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  hasGongmang ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.summary,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 공망 궁성 목록
          if (hasGongmang) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.allResults
                  .where((r) => r.isGongmang)
                  .map((r) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.blur_circular_rounded, size: 14, color: AppColors.error),
                            const SizedBox(width: 4),
                            Text(
                              '${r.pillarName} (${r.jiji})',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGongmangDetailCards(BuildContext context, GongmangAnalysisResult result, AppThemeExtension theme) {
    return Column(
      children: result.allResults.map((item) => _buildGongmangItemCard(context, item, theme)).toList(),
    );
  }

  Widget _buildGongmangItemCard(BuildContext context, GongmangResult item, AppThemeExtension theme) {
    final isGongmang = item.isGongmang;
    final color = isGongmang ? AppColors.error : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isGongmang ? color.withOpacity(0.3) : theme.border),
        boxShadow: isGongmang
            ? [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // 상단
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGongmang ? color.withOpacity(0.08) : theme.surfaceHover,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                // 궁성
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.pillarName,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 지지
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isGongmang ? color.withOpacity(0.15) : theme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isGongmang ? color.withOpacity(0.5) : theme.border,
                      width: isGongmang ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      item.jiji,
                      style: TextStyle(
                        color: isGongmang ? color : theme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // 상태 뱃지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGongmang ? Icons.blur_circular_rounded : Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isGongmang ? 'saju_chart.gongmang'.tr() : 'saju_chart.normal'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 하단: 해석
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isGongmang) ...[
                  Text(
                    item.interpretation,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, size: 16, color: color.withOpacity(0.7)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            GongmangService.getDetailedInterpretation(item),
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else
                  Row(
                    children: [
                      Icon(Icons.check_rounded, color: AppColors.success, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'saju_chart.normalEnergyDesc'.tr(),
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
