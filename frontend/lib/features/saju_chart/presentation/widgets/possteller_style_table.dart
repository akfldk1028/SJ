import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/constants/cheongan_jiji.dart';
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
    // 분석 데이터 계산
    final jijangganResult = JiJangGanService.analyzeFromChart(chart);
    final unsungResult = UnsungService.analyzeFromChart(chart);
    final sinsalResult = TwelveSinsalService.analyzeFromChart(chart);
    final dayGan = chart.dayPillar.gan;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더 행 (구분 | 시주 | 일주 | 월주 | 년주)
          _buildHeaderRow(context),
          _buildDivider(),
          // 천간 행
          _buildCheonganRow(context),
          _buildDivider(),
          // 지지 행
          _buildJijiRow(context),
          _buildDivider(),
          // 십성 행
          _buildSipsinRow(context, dayGan),
          _buildDivider(),
          // 지장간 행
          _buildJijangganRow(context, jijangganResult),
          _buildDivider(),
          // 12운성 행
          _buildUnsungRow(context, unsungResult),
          _buildDivider(),
          // 12신살 행
          _buildSinsalRow(context, sinsalResult),
        ],
      ),
    );
  }

  /// 헤더 행
  Widget _buildHeaderRow(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: compact ? 8 : 12,
        horizontal: compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceHover,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      ),
      child: Row(
        children: [
          _buildLabelCell(context, '구분', isHeader: true),
          _buildHeaderCell(context, '시주'),
          _buildHeaderCell(context, '일주'),
          _buildHeaderCell(context, '월주'),
          _buildHeaderCell(context, '년주'),
        ],
      ),
    );
  }

  /// 천간 행
  Widget _buildCheonganRow(BuildContext context) {
    final pillars = _getPillarsOrdered();

    return _buildDataRow(
      context,
      label: '천간',
      cells: pillars.map((pillar) {
        if (pillar == null) return _buildEmptyCell(context);
        final color = _getOhengColor(pillar.ganOheng);
        return _buildGanJiCell(
          context,
          hangul: pillar.gan,
          hanja: cheonganHanja[pillar.gan] ?? '',
          color: color,
        );
      }).toList(),
    );
  }

  /// 지지 행
  Widget _buildJijiRow(BuildContext context) {
    final pillars = _getPillarsOrdered();

    return _buildDataRow(
      context,
      label: '지지',
      cells: pillars.map((pillar) {
        if (pillar == null) return _buildEmptyCell(context);
        final color = _getOhengColor(pillar.jiOheng);
        return _buildGanJiCell(
          context,
          hangul: pillar.ji,
          hanja: jijiHanja[pillar.ji] ?? '',
          color: color,
        );
      }).toList(),
    );
  }

  /// 십성 행
  Widget _buildSipsinRow(BuildContext context, String dayGan) {
    final pillars = _getPillarsOrdered();

    return _buildDataRow(
      context,
      label: '십성',
      cells: pillars.asMap().entries.map((entry) {
        final index = entry.key;
        final pillar = entry.value;
        if (pillar == null) return _buildEmptyCell(context);

        // 일주는 '일원' 표시
        if (index == 1) {
          return _buildSipsinCell(context, '일원', null);
        }

        final sipsin = calculateSipSin(dayGan, pillar.gan);
        return _buildSipsinCell(context, sipsin.korean, sipsin);
      }).toList(),
    );
  }

  /// 지장간 행
  Widget _buildJijangganRow(BuildContext context, JiJangGanAnalysisResult result) {
    final results = [
      result.hourResult,
      result.dayResult,
      result.monthResult,
      result.yearResult,
    ];

    return _buildDataRow(
      context,
      label: '지장간',
      cells: results.map((r) {
        if (r == null) return _buildEmptyCell(context);
        // 지장간 한자들을 연결 (정기 → 중기 → 여기 순서로 표시, 일반적으로 여기/중기/정기 순)
        final jijangganStr = r.jijangganHanjaString;
        return _buildTextCell(context, jijangganStr, AppColors.textSecondary);
      }).toList(),
    );
  }

  /// 12운성 행
  Widget _buildUnsungRow(BuildContext context, UnsungAnalysisResult result) {
    final results = [
      result.hourUnsung,
      result.dayUnsung,
      result.monthUnsung,
      result.yearUnsung,
    ];

    return _buildDataRow(
      context,
      label: '12운성',
      cells: results.map((r) {
        if (r == null) return _buildEmptyCell(context);
        final color = _getUnsungColor(r.unsung);
        return _buildBadgeCell(context, r.unsung.korean, color);
      }).toList(),
    );
  }

  /// 12신살 행
  Widget _buildSinsalRow(BuildContext context, TwelveSinsalAnalysisResult result) {
    final results = [
      result.hourResult,
      result.dayResult,
      result.monthResult,
      result.yearResult,
    ];

    return _buildDataRow(
      context,
      label: '12신살',
      cells: results.map((r) {
        if (r == null) return _buildEmptyCell(context);
        final color = _getSinsalColor(r.sinsal);
        return _buildBadgeCell(context, r.sinsal.korean, color);
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

  /// 라벨 셀 (구분 열)
  Widget _buildLabelCell(BuildContext context, String text, {bool isHeader = false}) {
    return SizedBox(
      width: compact ? 50 : 60,
      child: Text(
        text,
        style: TextStyle(
          color: isHeader ? AppColors.textMuted : AppColors.textSecondary,
          fontSize: compact ? 11 : 12,
          fontWeight: isHeader ? FontWeight.w500 : FontWeight.w600,
        ),
      ),
    );
  }

  /// 헤더 셀
  Widget _buildHeaderCell(BuildContext context, String text) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 천간/지지 셀 (한글 + 한자)
  Widget _buildGanJiCell(
    BuildContext context, {
    required String hangul,
    required String hanja,
    required Color color,
  }) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 한자 (큰 글씨)
            if (showHanja && hanja.isNotEmpty)
              Text(
                hanja,
                style: TextStyle(
                  color: color,
                  fontSize: compact ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            // 한글 (작은 글씨)
            Text(
              showHanja ? hangul : '$hangul($hanja)',
              style: TextStyle(
                color: color.withOpacity(showHanja ? 0.8 : 1.0),
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 십성 셀
  Widget _buildSipsinCell(BuildContext context, String text, SipSin? sipsin) {
    final color = sipsin != null ? _getSipsinColor(sipsin) : AppColors.textSecondary;

    return Expanded(
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
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
            ),
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
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// 뱃지 셀 (12운성, 12신살용)
  Widget _buildBadgeCell(BuildContext context, String text, Color color) {
    return Expanded(
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
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
            ),
          ),
        ),
      ),
    );
  }

  /// 빈 셀
  Widget _buildEmptyCell(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          '-',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: compact ? 10 : 12,
          ),
        ),
      ),
    );
  }

  /// 구분선
  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.border,
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
