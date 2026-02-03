import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/constants/sipsin_relations.dart';
import '../../domain/entities/saju_analysis.dart';

/// 오행과 십성 분석 위젯 (포스텔러 스타일 도넛 차트)
class OhengAnalysisDisplay extends StatelessWidget {
  final SajuAnalysis analysis;

  const OhengAnalysisDisplay({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, '오행과 십성 분석', theme),
          const SizedBox(height: 16),

          // 도넛 차트 2개 (오행, 십성)
          Row(
            children: [
              Expanded(
                child: _buildOhengDonutChart(context, theme),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSipsinDonutChart(context, theme),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 오행 분포 테이블
          _buildSectionTitle(context, '오행', theme),
          const SizedBox(height: 12),
          _buildOhengTable(context, theme),
          const SizedBox(height: 24),

          // 십성 분포 테이블
          _buildSectionTitle(context, '십성', theme),
          const SizedBox(height: 12),
          _buildSipsinTable(context, theme),
          const SizedBox(height: 24),

          // 오행 상생상극 관계도
          _buildSectionTitle(context, '나의 오행: ${_getDayGanOheng().korean}', theme),
          const SizedBox(height: 12),
          _buildOhengRelationDiagram(context, theme),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, AppThemeExtension theme) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _showSectionHelp(context, title, theme),
          child: Icon(Icons.help_outline, size: 16, color: theme.textMuted),
        ),
      ],
    );
  }

  void _showSectionHelp(BuildContext context, String title, AppThemeExtension theme) {
    final descriptions = {
      '오행과 십성 분석': '오행(목·화·토·금·수)의 분포와 십성(비겁·식상·재성·관성·인성) 관계를 종합적으로 분석합니다.',
      '오행': '목(木)·화(火)·토(土)·금(金)·수(水) 다섯 가지 기운의 분포를 보여줍니다. 오행의 균형이 성격과 운세에 영향을 줍니다.',
      '십성': '일간을 기준으로 다른 간지와의 관계를 10가지(비겁·식상·재성·관성·인성)로 분류한 것입니다.',
    };
    // "나의 오행: ○" 형태의 타이틀도 처리
    final desc = descriptions[title] ?? (title.startsWith('나의 오행') ? '일간(나)의 오행 속성입니다. 내가 어떤 오행인지에 따라 성격, 적성, 궁합 등이 달라집니다.' : '');
    if (desc.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.help_outline_rounded, color: theme.primaryColor, size: 24),
            const SizedBox(width: 10),
            Expanded(child: Text(
              '$title이란?',
              style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            )),
          ],
        ),
        content: Text(desc, style: TextStyle(color: theme.textSecondary, fontSize: 15, height: 1.7)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('확인', style: TextStyle(color: theme.primaryColor, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  /// 오행 도넛 차트
  Widget _buildOhengDonutChart(BuildContext context, AppThemeExtension theme) {
    final oheng = analysis.ohengDistribution;
    final total = oheng.total;
    final strongest = oheng.strongest;

    final data = [
      _ChartData('목', oheng.mok, theme.woodColor ?? AppColors.wood),
      _ChartData('화', oheng.hwa, theme.fireColor ?? AppColors.fire),
      _ChartData('토', oheng.to, theme.earthColor ?? AppColors.earth),
      _ChartData('금', oheng.geum, theme.metalColor ?? AppColors.metal),
      _ChartData('수', oheng.su, theme.waterColor ?? AppColors.water),
    ];

    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(120, 120),
                  painter: _DonutChartPainter(data: data, total: total),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strongest.korean,
                      style: TextStyle(
                        color: _getOhengColor(strongest),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getOhengHanja(strongest),
                      style: TextStyle(
                        color: _getOhengColor(strongest),
                        fontSize: 16,
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

  /// 십성 도넛 차트
  Widget _buildSipsinDonutChart(BuildContext context, AppThemeExtension theme) {
    final sipsinDist = _calculateSipsinDistribution();
    final total = sipsinDist.values.fold(0, (a, b) => a + b);
    final strongest = sipsinDist.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    final data = sipsinDist.entries.where((e) => e.value > 0).map((e) {
      return _ChartData(e.key.korean, e.value, _getSipsinColor(e.key));
    }).toList();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(120, 120),
                  painter: _DonutChartPainter(data: data, total: total),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strongest.korean,
                      style: TextStyle(
                        color: _getSipsinColor(strongest),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      strongest.hanja,
                      style: TextStyle(
                        color: _getSipsinColor(strongest),
                        fontSize: 14,
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

  /// 오행 분포 테이블
  Widget _buildOhengTable(BuildContext context, AppThemeExtension theme) {
    final oheng = analysis.ohengDistribution;
    final total = oheng.total;

    final items = [
      _OhengItem('목(木)', oheng.mok, total, theme.woodColor ?? AppColors.wood),
      _OhengItem('화(火)', oheng.hwa, total, theme.fireColor ?? AppColors.fire),
      _OhengItem('토(土)', oheng.to, total, theme.earthColor ?? AppColors.earth),
      _OhengItem('금(金)', oheng.geum, total, theme.metalColor ?? AppColors.metal),
      _OhengItem('수(水)', oheng.su, total, theme.waterColor ?? AppColors.water),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: items.map((item) {
          final percentage = total > 0 ? (item.count / total * 100) : 0.0;
          final status = _getOhengStatus(percentage);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: item.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${percentage.toStringAsFixed(1)}% $status',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 십성 분포 테이블
  Widget _buildSipsinTable(BuildContext context, AppThemeExtension theme) {
    final sipsinDist = _calculateSipsinDistribution();
    final total = sipsinDist.values.fold(0, (a, b) => a + b);

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: SipSin.values.map((sipsin) {
          final count = sipsinDist[sipsin] ?? 0;
          final percentage = total > 0 ? (count / total * 100) : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    '${sipsin.korean}(${sipsin.hanja})',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    count > 0 ? '${percentage.toStringAsFixed(1)}%' : '-',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: count > 0 ? theme.textPrimary : theme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 오행 상생상극 관계도
  Widget _buildOhengRelationDiagram(BuildContext context, AppThemeExtension theme) {
    final oheng = analysis.ohengDistribution;
    final total = oheng.total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          // 범례
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('생(生)', AppColors.info),
              const SizedBox(width: 16),
              _buildLegend('극(剋)', AppColors.error),
            ],
          ),
          const SizedBox(height: 16),
          // 오각형 도표
          SizedBox(
            height: 280,
            child: CustomPaint(
              size: const Size(280, 280),
              painter: _OhengPentagonPainter(
                distribution: oheng,
                dayGanOheng: _getDayGanOheng(),
                surfaceColor: theme.surfaceElevated,
                textSecondaryColor: theme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.arrow_forward, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 13),
        ),
      ],
    );
  }

  /// 십성 분포 계산
  Map<SipSin, int> _calculateSipsinDistribution() {
    final dist = <SipSin, int>{};
    for (final sipsin in SipSin.values) {
      dist[sipsin] = 0;
    }

    final info = analysis.sipsinInfo;
    dist[info.yearGanSipsin] = (dist[info.yearGanSipsin] ?? 0) + 1;
    dist[info.monthGanSipsin] = (dist[info.monthGanSipsin] ?? 0) + 1;
    if (info.hourGanSipsin != null) {
      dist[info.hourGanSipsin!] = (dist[info.hourGanSipsin!] ?? 0) + 1;
    }
    dist[info.yearJiSipsin] = (dist[info.yearJiSipsin] ?? 0) + 1;
    dist[info.monthJiSipsin] = (dist[info.monthJiSipsin] ?? 0) + 1;
    dist[info.dayJiSipsin] = (dist[info.dayJiSipsin] ?? 0) + 1;
    if (info.hourJiSipsin != null) {
      dist[info.hourJiSipsin!] = (dist[info.hourJiSipsin!] ?? 0) + 1;
    }
    // 일간 비견 추가
    dist[SipSin.bigyeon] = (dist[SipSin.bigyeon] ?? 0) + 1;

    return dist;
  }

  Oheng _getDayGanOheng() {
    return cheonganToOheng[analysis.chart.dayPillar.gan] ?? Oheng.mok;
  }

  String _getOhengStatus(double percentage) {
    if (percentage >= 30) return '과다';
    if (percentage >= 20) return '발달';
    if (percentage >= 10) return '적정';
    return '부족';
  }

  Color _getOhengColor(Oheng oheng) {
    return switch (oheng) {
      Oheng.mok => AppColors.wood,
      Oheng.hwa => AppColors.fire,
      Oheng.to => AppColors.earth,
      Oheng.geum => AppColors.metal,
      Oheng.su => AppColors.water,
    };
  }

  String _getOhengHanja(Oheng oheng) {
    return switch (oheng) {
      Oheng.mok => '木',
      Oheng.hwa => '火',
      Oheng.to => '土',
      Oheng.geum => '金',
      Oheng.su => '水',
    };
  }

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
}

class _ChartData {
  final String label;
  final int value;
  final Color color;

  _ChartData(this.label, this.value, this.color);
}

class _OhengItem {
  final String label;
  final int count;
  final int total;
  final Color color;

  _OhengItem(this.label, this.count, this.total, this.color);
}

/// 도넛 차트 페인터
class _DonutChartPainter extends CustomPainter {
  final List<_ChartData> data;
  final int total;

  _DonutChartPainter({required this.data, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = 20.0;

    double startAngle = -math.pi / 2;

    for (final item in data) {
      if (item.value == 0) continue;

      final sweepAngle = (item.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 오행 오각형 관계도 페인터
class _OhengPentagonPainter extends CustomPainter {
  final OhengDistribution distribution;
  final Oheng dayGanOheng;
  final Color surfaceColor;
  final Color textSecondaryColor;

  _OhengPentagonPainter({
    required this.distribution,
    required this.dayGanOheng,
    required this.surfaceColor,
    required this.textSecondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 40;

    // 오행 순서: 목, 화, 토, 금, 수 (상생 순환)
    final ohengList = [Oheng.mok, Oheng.hwa, Oheng.to, Oheng.geum, Oheng.su];
    final ohengCounts = [
      distribution.mok,
      distribution.hwa,
      distribution.to,
      distribution.geum,
      distribution.su,
    ];
    final total = distribution.total;

    // 오각형 꼭짓점 계산 (상단부터 시계방향)
    final points = <Offset>[];
    for (int i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / 5);
      points.add(Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      ));
    }

    // 상생 화살표 (외곽 - 파란색)
    final saenPaint = Paint()
      ..color = AppColors.info
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 5; i++) {
      final next = (i + 1) % 5;
      _drawArrow(canvas, points[i], points[next], saenPaint);
    }

    // 상극 화살표 (내부 별 - 빨간색)
    final geukPaint = Paint()
      ..color = AppColors.error
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 상극 순서: 목→토, 토→수, 수→화, 화→금, 금→목
    final geukPairs = [
      [0, 2], // 목→토
      [2, 4], // 토→수
      [4, 1], // 수→화
      [1, 3], // 화→금
      [3, 0], // 금→목
    ];

    for (final pair in geukPairs) {
      _drawArrow(canvas, points[pair[0]], points[pair[1]], geukPaint);
    }

    // 오행 원 그리기
    for (int i = 0; i < 5; i++) {
      final oheng = ohengList[i];
      final count = ohengCounts[i];
      final percentage = total > 0 ? (count / total * 100) : 0.0;

      // 원 배경
      final circlePaint = Paint()
        ..color = surfaceColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(points[i], 35, circlePaint);

      // 원 테두리
      final borderPaint = Paint()
        ..color = _getOhengColor(oheng).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(points[i], 35, borderPaint);

      // 텍스트
      final textPainter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${oheng.korean}(${_getSipsinCategory(oheng)})\n',
              style: TextStyle(
                color: _getOhengColor(oheng),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: textSecondaryColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          points[i].dx - textPainter.width / 2,
          points[i].dy - textPainter.height / 2,
        ),
      );
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    // 시작점과 끝점을 원 안쪽으로 조정
    final direction = (end - start).normalize();
    final adjustedStart = start + direction * 38;
    final adjustedEnd = end - direction * 38;

    canvas.drawLine(adjustedStart, adjustedEnd, paint);

    // 화살표 머리
    final arrowSize = 8.0;
    final angle = math.atan2(
      adjustedEnd.dy - adjustedStart.dy,
      adjustedEnd.dx - adjustedStart.dx,
    );

    final path = Path()
      ..moveTo(adjustedEnd.dx, adjustedEnd.dy)
      ..lineTo(
        adjustedEnd.dx - arrowSize * math.cos(angle - 0.5),
        adjustedEnd.dy - arrowSize * math.sin(angle - 0.5),
      )
      ..lineTo(
        adjustedEnd.dx - arrowSize * math.cos(angle + 0.5),
        adjustedEnd.dy - arrowSize * math.sin(angle + 0.5),
      )
      ..close();

    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  String _getSipsinCategory(Oheng oheng) {
    // 일간 기준 십성 카테고리
    final dayOheng = dayGanOheng;
    if (oheng == dayOheng) return '비겁';

    // 상생상극 관계로 카테고리 결정
    final saengSeq = [Oheng.mok, Oheng.hwa, Oheng.to, Oheng.geum, Oheng.su];
    final dayIdx = saengSeq.indexOf(dayOheng);
    final targetIdx = saengSeq.indexOf(oheng);

    final diff = (targetIdx - dayIdx + 5) % 5;
    return switch (diff) {
      0 => '비겁',
      1 => '식상',
      2 => '재성',
      3 => '관성',
      4 => '인성',
      _ => '',
    };
  }

  Color _getOhengColor(Oheng oheng) {
    return switch (oheng) {
      Oheng.mok => AppColors.wood,
      Oheng.hwa => AppColors.fire,
      Oheng.to => AppColors.earth,
      Oheng.geum => AppColors.metal,
      Oheng.su => AppColors.water,
    };
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension on Offset {
  Offset normalize() {
    final length = math.sqrt(dx * dx + dy * dy);
    return length > 0 ? Offset(dx / length, dy / length) : this;
  }
}
