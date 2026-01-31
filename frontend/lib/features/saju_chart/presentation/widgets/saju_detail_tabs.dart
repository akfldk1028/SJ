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

  const SajuDetailTabs({super.key, this.isFullPage = false});

  @override
  ConsumerState<SajuDetailTabs> createState() => _SajuDetailTabsState();
}

class _SajuDetailTabsState extends ConsumerState<SajuDetailTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 탭 정의 (각 탭에 대한 간략 설명 포함)
  static const _tabs = [
    _TabItem(
      label: '만세력',
      icon: Icons.grid_view_rounded,
      description: '사주팔자의 기본 구조인 년주·월주·일주·시주 4개의 기둥과 오행 분포를 한눈에 볼 수 있는 기본 차트입니다.',
    ),
    _TabItem(
      label: '오행',
      icon: Icons.donut_small,
      description: '목(木)·화(火)·토(土)·금(金)·수(水) 다섯 가지 기운의 분포와 균형을 분석합니다. 오행의 과다/부족이 성격과 운세에 영향을 줍니다.',
    ),
    _TabItem(
      label: '신강',
      icon: Icons.fitness_center,
      description: '일간(나)의 기운이 강한지 약한지를 판단합니다. 신강하면 독립적이고, 신약하면 주변의 도움이 필요한 타입입니다. 용신(필요한 오행)도 함께 분석합니다.',
    ),
    _TabItem(
      label: '대운',
      icon: Icons.timeline,
      description: '10년 단위로 변하는 운의 흐름을 보여줍니다. 대운·세운·월운을 통해 인생의 큰 흐름과 시기별 운세를 파악할 수 있습니다.',
    ),
    _TabItem(
      label: '합충',
      icon: Icons.sync_alt,
      description: '천간과 지지 사이의 합(合)·충(沖)·형(刑)·파(破)·해(害) 관계를 분석합니다. 사주 내 기운의 조화와 갈등을 파악합니다.',
    ),
    _TabItem(
      label: '십성',
      icon: Icons.stars_rounded,
      description: '일간을 기준으로 다른 간지와의 관계를 10가지(비겁·식상·재성·관성·인성)로 나타냅니다. 성격, 재물운, 직업운 등을 파악하는 핵심 분석입니다.',
    ),
    _TabItem(
      label: '운성',
      icon: Icons.trending_up,
      description: '12운성은 일간의 기운이 각 지지에서 어떤 상태인지를 나타냅니다. 장생·건록·제왕 등 12단계로 인생의 에너지 흐름을 봅니다.',
    ),
    _TabItem(
      label: '신살',
      icon: Icons.flash_on,
      description: '사주에 나타나는 특별한 기운(신살)을 분석합니다. 역마살·도화살·화개살 등 길한 영향과 흉한 영향을 파악합니다.',
    ),
    _TabItem(
      label: '공망',
      icon: Icons.highlight_off,
      description: '일주를 기준으로 비어있는(空亡) 지지를 찾습니다. 해당 영역의 기운이 약해질 수 있지만, 흉한 것이 공망이면 오히려 흉함이 줄어듭니다.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // rebuild to update help bar
      }
    });
  }

  /// 현재 탭의 설명 팝업 표시
  void _showTabHelp(BuildContext context) {
    final tab = _tabs[_tabController.index];
    if (tab.description.isEmpty) return;
    final theme = context.appTheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(tab.icon, color: theme.primaryColor, size: 24),
            const SizedBox(width: 10),
            Text(
              '${tab.label}이란?',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          tab.description,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 15,
            height: 1.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('확인', style: TextStyle(color: theme.primaryColor, fontSize: 15)),
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
    final sajuAnalysisAsync = ref.watch(currentSajuAnalysisProvider);
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
                    '사주 풀이 자세히 보기',
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
              tabs: _tabs
                  .map((tab) => Tab(
                        height: 48,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tab.icon, size: 18),
                            const SizedBox(width: 6),
                            Text(tab.label),
                          ],
                        ),
                      ))
                  .toList(),
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
                      '${_tabs[_tabController.index].label} - 터치하여 자세한 설명 보기',
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
                      '분석 정보를 불러올 수 없습니다.',
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
                    '오류가 발생했습니다:\n$err',
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

/// 탭 아이템 정의
class _TabItem {
  final String label;
  final IconData icon;
  final String description;

  const _TabItem({
    required this.label,
    required this.icon,
    this.description = '',
  });
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
    final theme = context.appTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 포스텔러 스타일 통합 테이블
          _buildSectionTitle(context, '사주 팔자 분석표', theme),
          const SizedBox(height: 12),
          PosstellerStyleTable(chart: chart),
          const SizedBox(height: 24),

          // 기존 4주 카드 표시
          _buildSectionTitle(context, '사주팔자 (Four Pillars)', theme),
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
          _buildSectionTitle(context, '오행 분포', theme),
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
                _buildOhengBar(context, '목(木) Wood', oheng.mok, theme.woodColor ?? AppColors.wood, theme),
                _buildOhengBar(context, '화(火) Fire', oheng.hwa, theme.fireColor ?? AppColors.fire, theme),
                _buildOhengBar(context, '토(土) Earth', oheng.to, theme.earthColor ?? AppColors.earth, theme),
                _buildOhengBar(context, '금(金) Metal', oheng.geum, theme.metalColor ?? AppColors.metal, theme),
                _buildOhengBar(context, '수(水) Water', oheng.su, theme.waterColor ?? AppColors.water, theme),
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
            '$count개',
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

          _buildSectionTitle(context, '천간 십성', theme),
          const SizedBox(height: 12),
          _buildCheonganSipSin(context, theme),
          const SizedBox(height: 24),

          _buildSectionTitle(context, '지장간 십성', theme),
          const SizedBox(height: 12),
          JiJangGanRow(analysis: jijangganResult, compact: true),
          const SizedBox(height: 24),

          _buildSectionTitle(context, '십성 분포', theme),
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
                '십성(十星)이란?',
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
            '일간(日干, 나)을 기준으로 다른 간지와의 관계를 나타낸 것입니다. '
            '오행의 상생상극 관계와 음양 조화에 따라 10가지 관계가 정해집니다.',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '• 비겁(比劫): 나와 같은 오행 - 형제, 경쟁자, 자아\n'
            '• 식상(食傷): 내가 생하는 오행 - 표현력, 재능, 자녀\n'
            '• 재성(財星): 내가 극하는 오행 - 재물, 아버지(남), 아내(남)\n'
            '• 관성(官星): 나를 극하는 오행 - 직장, 명예, 남편(여)\n'
            '• 인성(印星): 나를 생하는 오행 - 학문, 문서, 어머니',
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
              '천간',
              style: TextStyle(
                color: theme.textMuted,
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
                      : Text(
                          '-',
                          style: TextStyle(
                            color: theme.textMuted,
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
          _buildSectionHeader(context, '궁성별 12운성', '각 궁의 운성과 그 의미', theme.primaryColor, Icons.analytics_rounded, theme),
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
                '12운성(十二運星)이란?',
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
            '12운성은 일간(日干)의 기운이 각 지지(地支)에서 어떤 상태인지를 나타냅니다. '
            '마치 사람의 일생처럼 탄생(장생)부터 죽음(사)까지의 순환을 12단계로 표현합니다.',
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
                  _buildCycleItem('장생', '탄생', theme),
                  _buildCycleArrow(theme),
                  _buildCycleItem('목욕', '성장', theme),
                  _buildCycleArrow(theme),
                  _buildCycleItem('관대', '성인', theme),
                  _buildCycleArrow(theme),
                  _buildCycleItem('건록', '전성', theme),
                  _buildCycleArrow(theme),
                  _buildCycleItem('제왕', '정점', theme),
                  _buildCycleArrow(theme),
                  _buildCycleItem('쇠', '쇠퇴', theme),
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
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          desc,
          style: TextStyle(
            color: theme.textMuted,
            fontSize: 9,
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
                '궁성(宮星)이란?',
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
            '궁성은 사주팔자의 4개 기둥(년주, 월주, 일주, 시주)이 각각 나타내는 삶의 영역입니다. '
            '각 궁성의 운성을 통해 그 영역에서의 기운 상태를 파악할 수 있습니다.',
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
                _buildGungseongRow('년주(年柱)', '조상궁', '조상, 유년기, 사회적 배경', theme),
                const SizedBox(height: 8),
                _buildGungseongRow('월주(月柱)', '부모궁', '부모, 청년기, 성장환경', theme),
                const SizedBox(height: 8),
                _buildGungseongRow('일주(日柱)', '자신궁', '자신, 배우자, 중년기', theme),
                const SizedBox(height: 8),
                _buildGungseongRow('시주(時柱)', '자녀궁', '자녀, 노년기, 결과', theme),
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
              fontSize: 11,
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
              fontSize: 10,
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
              fontSize: 11,
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
                fontSize: 11,
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
                '12운성 요약',
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
                          fontSize: 11,
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
                            fontSize: 12,
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
            _buildSectionHeader(context, '주요 신살', '특히 주목해야 할 신살', theme.primaryColor, Icons.star_rounded, theme),
            const SizedBox(height: 12),
            _buildKeySinsalCards(context, twelveSinsalResult, theme),
            const SizedBox(height: 20),
          ],

          // 12신살 상세 카드 리스트
          _buildSectionHeader(context, '12신살 상세', '각 궁성별 신살 분석', theme.textSecondary, Icons.grid_view_rounded, theme),
          const SizedBox(height: 12),
          _buildSinsalDetailCards(context, twelveSinsalResult, theme),
          const SizedBox(height: 20),

          // 신살과 길성 통합 테이블 (포스텔러 스타일)
          _buildSectionHeader(context, '신살·길성 테이블', '전체 신살 현황', theme.textSecondary, Icons.table_chart_rounded, theme),
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
                '신살(神殺)이란?',
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
            '신살은 사주팔자에 나타나는 특별한 기운으로, 길한 영향(길신)과 흉한 영향(흉신)을 분석합니다. '
            '12신살은 년지를 기준으로 각 지지의 특성을 파악하는 대표적인 신살 체계입니다.',
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
                _buildLegendItem('길신(吉神)', AppColors.success, theme),
                const SizedBox(width: 16),
                _buildLegendItem('흉신(凶神)', AppColors.error, theme),
                const SizedBox(width: 16),
                _buildLegendItem('혼합', theme.primaryColor, theme),
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
            fontSize: 11,
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
                fontSize: 11,
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
                child: _buildStatBox('길(吉)', result.goodSinsalCount, AppColors.success),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBox('흉(凶)', result.badSinsalCount, AppColors.error),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBox('혼합', result.mixedSinsalCount, theme.primaryColor),
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
              fontSize: 12,
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
                          fontSize: 10,
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
                          fontSize: 11,
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
                    fontSize: 12,
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
                    fortuneType == '길' ? '길(吉)' : fortuneType == '흉' ? '흉(凶)' : '혼합',
                    style: TextStyle(
                      color: fortuneColor,
                      fontSize: 11,
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
                    fontSize: 12,
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
          _buildSectionHeader(context, '궁성별 공망 분석', '각 궁의 공망 여부와 해석', theme.textSecondary, Icons.grid_view_rounded, theme),
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
                '공망(空亡)이란?',
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
            '공망은 \'비어있다\'는 의미로, 일주를 기준으로 특정 지지가 빈 상태를 말합니다. '
            '공망에 해당하는 궁성은 그 영역의 기운이 약해지거나 허무하게 될 수 있습니다.',
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
                    '공망은 반드시 나쁜 것만은 아닙니다. 흉한 것이 공망이면 오히려 흉함이 줄어들기도 합니다.',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 11,
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
                fontSize: 11,
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
                      '일주: ${result.dayGapja}',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 12,
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
                  '${result.sunInfo.sunName} 소속',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 12,
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
                '공망 지지',
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
                child: _buildStatBox('공망 궁', result.gongmangCount, AppColors.error),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBox('정상 궁', result.allResults.length - result.gongmangCount, AppColors.success),
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
                                fontSize: 12,
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
              fontSize: 12,
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
                        isGongmang ? '공망' : '정상',
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
                              fontSize: 12,
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
                        '공망에 해당하지 않아 정상적인 기운을 발휘합니다.',
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
