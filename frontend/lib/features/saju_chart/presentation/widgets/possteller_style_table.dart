import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/constants/cheongan_jiji.dart';
import '../../data/constants/cheongan_jiji_i18n.dart';
import '../../data/constants/jijanggan_table.dart';
import '../../data/constants/sipsin_relations.dart';
import '../../data/constants/twelve_unsung.dart';
import '../../data/constants/twelve_sinsal.dart';
import '../../domain/entities/saju_chart.dart';
import '../../domain/entities/pillar.dart';
import '../../domain/services/jijanggan_service.dart';
import '../../domain/services/unsung_service.dart';
import '../../domain/services/twelve_sinsal_service.dart';

/// 포스텔러 스타일 사주 테이블 위젯
///
/// 표시 형식:
/// | 구분   | 시주     | 일주     | 월주     | 년주     |
/// |--------|----------|----------|----------|----------|
/// | 천간   | 정(丁)   | 병(丙)   | 을(乙)   | 갑(甲)   |
/// | 지지   | 묘(卯)   | 축(丑)   | 해(亥)   | 인(寅)   |
/// | 십성   | 식신     | 일원     | 겁재     | 비견     |
/// | 지장간 | 을       | 신계기   | 무갑임   | 무기병   |
/// | 12운성 | 건록     | 관대     | 목욕     | 장생     |
/// | 12신살 | 도화     | 화개     | 역마     | 겁살     |
class PosstellerStyleTable extends StatelessWidget {
  final SajuChart chart;
  final bool showHanja;
  final bool compact;

  const PosstellerStyleTable({
    super.key,
    required this.chart,
    this.showHanja = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    // 분석 데이터 계산
    final jijangganResult = JiJangGanService.analyzeFromChart(chart);
    final unsungResult = UnsungService.analyzeFromChart(chart);
    // 12신살 분석 (년지 기준 - 포스텔러 호환, Phase 39)
    final sinsalResult = TwelveSinsalService.analyzeFromChart(chart);
    final dayGan = chart.dayPillar.gan;

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeaderRow(context),
          _buildDivider(),
          _buildCheonganRow(context),
          _buildDivider(),
          _buildCheonganSipsinRow(context, dayGan),
          _buildDivider(),
          _buildJijiRow(context),
          _buildDivider(),
          _buildJijiSipsinRow(context, dayGan),
          _buildDivider(),
          _buildJijangganRow(context, jijangganResult),
          _buildDivider(),
          _buildUnsungRow(context, unsungResult),
          _buildDivider(),
          _buildSinsalRow(context, sinsalResult),
        ],
      ),
    );
  }

  /// 헤더 행
  Widget _buildHeaderRow(BuildContext context) {
    final theme = context.appTheme;
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: compact ? 8 : 12,
        horizontal: compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: theme.surfaceHover,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      ),
      child: Row(
        children: [
          _buildLabelCell(context, 'saju_chart.category'.tr(), isHeader: true),
          _buildHeaderCell(context, 'saju_chart.hourPillar'.tr()),
          _buildHeaderCell(context, 'saju_chart.dayPillar'.tr()),
          _buildHeaderCell(context, 'saju_chart.monthPillar'.tr()),
          _buildHeaderCell(context, 'saju_chart.yearPillar'.tr()),
        ],
      ),
    );
  }

  /// 천간 행
  Widget _buildCheonganRow(BuildContext context) {
    final pillars = _getPillarsOrdered();
    final locale = context.locale.languageCode;

    return _buildDataRow(
      context,
      label: 'saju_chart.heavenlyStem'.tr(),
      cells: pillars.map((pillar) {
        if (pillar == null) return _buildEmptyCell(context);
        final color = _getOhengColor(pillar.ganOheng);
        return _buildGanJiCell(
          context,
          korean: pillar.gan,
          localeName: SajuI18n.cheongan(pillar.gan, locale),
          hanja: cheonganHanja[pillar.gan] ?? '',
          color: color,
        );
      }).toList(),
    );
  }

  /// 지지 행
  Widget _buildJijiRow(BuildContext context) {
    final pillars = _getPillarsOrdered();
    final locale = context.locale.languageCode;

    return _buildDataRow(
      context,
      label: 'saju_chart.earthlyBranch'.tr(),
      cells: pillars.map((pillar) {
        if (pillar == null) return _buildEmptyCell(context);
        final color = _getOhengColor(pillar.jiOheng);
        return _buildGanJiCell(
          context,
          korean: pillar.ji,
          localeName: SajuI18n.jiji(pillar.ji, locale),
          hanja: jijiHanja[pillar.ji] ?? '',
          color: color,
        );
      }).toList(),
    );
  }

  /// 천간 십성 행 (포스텔러 스타일)
  Widget _buildCheonganSipsinRow(BuildContext context, String dayGan) {
    final pillars = _getPillarsOrdered();
    final locale = context.locale.languageCode;

    return _buildDataRow(
      context,
      label: 'saju_chart.sipsung'.tr(),
      cells: pillars.asMap().entries.map((entry) {
        final index = entry.key;
        final pillar = entry.value;
        if (pillar == null) return _buildEmptyCell(context);

        // 일주는 '비견' 표시 (일간 자신)
        if (index == 1) {
          return _buildSipsinCell(context, 'saju_chart.bigyeon'.tr(), SipSin.bigyeon);
        }

        final sipsin = calculateSipSin(dayGan, pillar.gan);
        return _buildSipsinCell(context, SajuI18n.sipsin(sipsin.korean, locale), sipsin);
      }).toList(),
    );
  }

  /// 지지 십성 행 (포스텔러 스타일 - 정기 기준)
  Widget _buildJijiSipsinRow(BuildContext context, String dayGan) {
    final pillars = _getPillarsOrdered();
    final locale = context.locale.languageCode;

    return _buildDataRow(
      context,
      label: 'saju_chart.sipsung'.tr(),
      cells: pillars.map((pillar) {
        if (pillar == null) return _buildEmptyCell(context);

        // 지지의 정기(正氣) 천간을 가져와서 십성 계산
        final jeongGi = getJeongGi(pillar.ji);
        if (jeongGi == null) return _buildEmptyCell(context);

        final sipsin = calculateSipSin(dayGan, jeongGi);
        return _buildSipsinCell(context, SajuI18n.sipsin(sipsin.korean, locale), sipsin);
      }).toList(),
    );
  }

  /// 지장간 행
  Widget _buildJijangganRow(BuildContext context, JiJangGanAnalysisResult result) {
    final locale = context.locale.languageCode;
    final results = [
      result.hourResult,
      result.dayResult,
      result.monthResult,
      result.yearResult,
    ];

    return _buildDataRow(
      context,
      label: 'saju_chart.jijanggan'.tr(),
      cells: results.map((r) {
        if (r == null) return _buildEmptyCell(context);
        // 지장간 locale별 표시
        final sorted = [...r.jijangganList]..sort((a, b) =>
            a.type.strengthRank.compareTo(b.type.strengthRank));
        final jijangganStr = sorted.map((j) => SajuI18n.cheongan(j.gan, locale)).join();
        final theme = context.appTheme;
        return _buildTextCell(context, jijangganStr, theme.textSecondary);
      }).toList(),
    );
  }

  /// 12운성 행
  Widget _buildUnsungRow(BuildContext context, UnsungAnalysisResult result) {
    final locale = context.locale.languageCode;
    final results = [
      result.hourUnsung,
      result.dayUnsung,
      result.monthUnsung,
      result.yearUnsung,
    ];

    return _buildDataRow(
      context,
      label: 'saju_chart.twelveUnsung'.tr(),
      cells: results.map((r) {
        if (r == null) return _buildEmptyCell(context);
        final color = _getUnsungColor(r.unsung);
        return _buildBadgeCell(context, SajuI18n.unsung(r.unsung.korean, locale), color);
      }).toList(),
    );
  }

  /// 12신살 행
  Widget _buildSinsalRow(BuildContext context, TwelveSinsalAnalysisResult result) {
    final locale = context.locale.languageCode;
    final results = [
      result.hourResult,
      result.dayResult,
      result.monthResult,
      result.yearResult,
    ];

    return _buildDataRow(
      context,
      label: 'saju_chart.twelveSinsal'.tr(),
      cells: results.map((r) {
        if (r == null) return _buildEmptyCell(context);
        final color = _getSinsalColor(r.sinsal);
        return _buildBadgeCell(context, SajuI18n.sinsal(r.sinsal.korean, locale), color);
      }).toList(),
      isLast: true,
    );
  }

  /// 기둥 목록 [시주, 일주, 월주, 년주] 순서로 반환
  List<Pillar?> _getPillarsOrdered() {
    return [
      chart.hourPillar,
      chart.dayPillar,
      chart.monthPillar,
      chart.yearPillar,
    ];
  }

  /// 데이터 행 빌더
  Widget _buildDataRow(
    BuildContext context, {
    required String label,
    required List<Widget> cells,
    bool isLast = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: compact ? 8 : 12,
        horizontal: compact ? 8 : 12,
      ),
      decoration: isLast
          ? const BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
            )
          : null,
      child: Row(
        children: [
          _buildLabelCell(context, label),
          ...cells,
        ],
      ),
    );
  }

  /// 라벨 셀 (구분 열) — locale에 따라 너비 조정
  Widget _buildLabelCell(BuildContext context, String text, {bool isHeader = false}) {
    final theme = context.appTheme;
    final locale = context.locale.languageCode;
    final isCjk = locale == 'ko' || locale == 'ja' || locale == 'zh';
    final labelWidth = compact
        ? (isCjk ? 50.0 : 80.0)
        : (isCjk ? 60.0 : 90.0);

    return SizedBox(
      width: labelWidth,
      child: Text(
        text,
        style: TextStyle(
          color: isHeader ? theme.textMuted : theme.textSecondary,
          fontSize: compact ? 11 : 12,
          fontWeight: isHeader ? FontWeight.w500 : FontWeight.w600,
        ),
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 헤더 셀 — 2줄 허용, 글씨 크기 통일
  Widget _buildHeaderCell(BuildContext context, String text) {
    final theme = context.appTheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          text,
          style: TextStyle(
            color: theme.textMuted,
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// 천간/지지 셀
  /// CJK(한/중/일): 한자 큰 글씨 + locale명 작은 글씨
  /// 나머지: 한글 큰 글씨 + locale명 작은 글씨
  Widget _buildGanJiCell(
    BuildContext context, {
    required String korean,     // 원본 한글 (갑, 을, 자, 축...)
    required String localeName, // locale별 이름 (Gap, Gye...)
    required String hanja,      // 한자 (甲, 乙...)
    required Color color,
  }) {
    final locale = context.locale.languageCode;
    final isCjk = locale == 'ko' || locale == 'ja' || locale == 'zh';
    final bigChar = isCjk ? hanja : korean;
    final smallChar = isCjk ? korean : localeName;
    final showSmall = bigChar != smallChar;

    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              bigChar.isNotEmpty ? bigChar : korean,
              style: TextStyle(
                color: color,
                fontSize: compact ? 18 : 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showSmall)
              Text(
                smallChar,
                style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 십성 셀 — 글씨 크기 통일, 2줄 허용
  Widget _buildSipsinCell(BuildContext context, String text, SipSin? sipsin) {
    final theme = context.appTheme;
    final color = sipsin != null ? _getSipsinColor(sipsin) : theme.textSecondary;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 3 : 4,
            vertical: compact ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  /// 텍스트 셀
  Widget _buildTextCell(BuildContext context, String text, Color color) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// 뱃지 셀 (12운성, 12신살용) — 글씨 크기 통일, 2줄 허용
  Widget _buildBadgeCell(BuildContext context, String text, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 3 : 4,
            vertical: compact ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  /// 빈 셀
  Widget _buildEmptyCell(BuildContext context) {
    final theme = context.appTheme;
    return Expanded(
      child: Center(
        child: Text(
          '-',
          style: TextStyle(
            color: theme.textMuted,
            fontSize: compact ? 12 : 13,
          ),
        ),
      ),
    );
  }

  /// 구분선
  Widget _buildDivider() {
    return Builder(
      builder: (context) {
        final theme = context.appTheme;
        return Divider(
          height: 1,
          thickness: 1,
          color: theme.border,
        );
      },
    );
  }

  /// 오행별 색상
  Color _getOhengColor(String oheng) {
    return switch (oheng) {
      '목' => AppColors.wood,
      '화' => AppColors.fire,
      '토' => AppColors.earth,
      '금' => AppColors.metal,
      '수' => AppColors.water,
      _ => AppColors.textPrimary,
    };
  }

  /// 십성별 색상
  Color _getSipsinColor(SipSin sipsin) {
    final category = sipsinToCategory[sipsin];
    return switch (category) {
      SipSinCategory.bigeop => AppColors.water,
      SipSinCategory.siksang => AppColors.wood,
      SipSinCategory.jaeseong => AppColors.earth,
      SipSinCategory.gwanseong => AppColors.fire,
      SipSinCategory.inseong => AppColors.metal,
      _ => AppColors.textSecondary,
    };
  }

  /// 12운성별 색상
  Color _getUnsungColor(TwelveUnsung unsung) {
    if (unsung.strength >= 8) return AppColors.success;
    if (unsung.strength >= 5) return AppColors.accent;
    if (unsung.strength >= 3) return AppColors.warning;
    return AppColors.error;
  }

  /// 12신살별 색상
  Color _getSinsalColor(TwelveSinsal sinsal) {
    return switch (sinsal.fortuneType) {
      '길' => AppColors.success,
      '길흉혼합' => AppColors.accent,
      '흉' => AppColors.error,
      _ => AppColors.textSecondary,
    };
  }
}

/// 포스텔러 스타일 미니 테이블 (컴팩트 버전)
/// 만세력 탭에서 기본 정보를 한눈에 보여주는 용도
class PosstellerMiniTable extends StatelessWidget {
  final SajuChart chart;

  const PosstellerMiniTable({super.key, required this.chart});

  @override
  Widget build(BuildContext context) {
    return PosstellerStyleTable(
      chart: chart,
      showHanja: true,
      compact: true,
    );
  }
}

/// 포스텔러 스타일 상세 테이블 (전체 정보)
class PosstellerDetailTable extends StatelessWidget {
  final SajuChart chart;
  final bool showHanja;

  const PosstellerDetailTable({
    super.key,
    required this.chart,
    this.showHanja = true,
  });

  @override
  Widget build(BuildContext context) {
    return PosstellerStyleTable(
      chart: chart,
      showHanja: showHanja,
      compact: false,
    );
  }
}
