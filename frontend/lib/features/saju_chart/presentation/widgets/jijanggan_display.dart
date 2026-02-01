import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/constants/jijanggan_table.dart';
import '../../domain/services/jijanggan_service.dart';
import 'sipsung_display.dart';

/// 지장간(地藏干) 표시 위젯
/// 지지 속에 숨어있는 천간(여기/중기/정기)을 표시
class JiJangGanDisplay extends StatelessWidget {
  /// 지장간 결과
  final JiJangGanResult result;

  /// 크기 옵션
  final JiJangGanSize size;

  /// 십성 표시 여부
  final bool showSipSin;

  const JiJangGanDisplay({
    super.key,
    required this.result,
    this.size = JiJangGanSize.medium,
    this.showSipSin = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final padding = _getPadding();
    final fontSize = _getFontSize();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 지지 표시
          Text(
            result.jiji,
            style: TextStyle(
              color: theme.textMuted,
              fontSize: fontSize * 0.8,
            ),
          ),
          const SizedBox(height: 4),
          // 지장간 목록 (여기 → 중기 → 정기 순)
          ...result.jijangganList
              .where((jjg) => jjg.type == JiJangGanType.yeoGi)
              .map((jjg) => _buildJiJangGanItem(context, theme, jjg, fontSize)),
          ...result.jijangganList
              .where((jjg) => jjg.type == JiJangGanType.jungGi)
              .map((jjg) => _buildJiJangGanItem(context, theme, jjg, fontSize)),
          ...result.jijangganList
              .where((jjg) => jjg.type == JiJangGanType.jeongGi)
              .map((jjg) => _buildJiJangGanItem(context, theme, jjg, fontSize)),
        ],
      ),
    );
  }

  Widget _buildJiJangGanItem(
    BuildContext context,
    AppThemeExtension theme,
    JiJangGanSipSin jjg,
    double fontSize,
  ) {
    final color = _getOhengColor(jjg.oheng, theme);
    final typeLabel = jjg.type.korean.substring(0, 1); // 여/중/정

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 기운 유형 라벨
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: theme.surfaceHover,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                typeLabel,
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // 천간 (한자)
          Text(
            jjg.ganHanja,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showSipSin) ...[
            const SizedBox(width: 4),
            SipSungDisplay(
              sipsin: jjg.sipsin,
              size: SipSungSize.small,
              showBackground: false,
            ),
          ],
        ],
      ),
    );
  }

  double _getFontSize() {
    return switch (size) {
      JiJangGanSize.small => 13.0,
      JiJangGanSize.medium => 16.0,
      JiJangGanSize.large => 20.0,
    };
  }

  EdgeInsets _getPadding() {
    return switch (size) {
      JiJangGanSize.small => const EdgeInsets.all(6),
      JiJangGanSize.medium => const EdgeInsets.all(10),
      JiJangGanSize.large => const EdgeInsets.all(14),
    };
  }

  Color _getOhengColor(String oheng, AppThemeExtension theme) {
    return switch (oheng) {
      '목' => AppColors.wood,
      '화' => AppColors.fire,
      '토' => AppColors.earth,
      '금' => AppColors.metal,
      '수' => AppColors.water,
      _ => theme.textSecondary,
    };
  }
}

/// 지장간 크기 옵션
enum JiJangGanSize { small, medium, large }

/// 지장간 행 (4주 한 줄)
/// 포스텔러 스타일로 4주의 지장간을 한 줄로 표시
class JiJangGanRow extends StatelessWidget {
  /// 지장간 분석 결과
  final JiJangGanAnalysisResult analysis;

  /// 간략 표시 여부 (한자만 표시)
  final bool compact;

  const JiJangGanRow({
    super.key,
    required this.analysis,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final results = [
      analysis.hourResult,
      analysis.dayResult,
      analysis.monthResult,
      analysis.yearResult,
    ];

    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            '지장간',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: theme.textMuted,
                  fontSize: 13,
                ),
          ),
        ),
        ...results.map((result) {
          if (result == null) {
            return Expanded(
              child: Center(
                child: Text(
                  '-',
                  style: TextStyle(
                    color: theme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }

          if (compact) {
            // 간략 표시: 한자만 가로로 나열
            return Expanded(
              child: Center(
                child: Text(
                  result.jijangganHanjaString,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }

          // 상세 표시
          return Expanded(
            child: JiJangGanDisplay(
              result: result,
              size: JiJangGanSize.small,
              showSipSin: false,
            ),
          );
        }),
      ],
    );
  }
}

/// 지장간 상세 카드
/// 특정 궁성의 지장간을 상세하게 표시
class JiJangGanDetailCard extends StatelessWidget {
  /// 지장간 결과
  final JiJangGanResult result;

  /// 일간 (십성 계산용)
  final String dayGan;

  const JiJangGanDetailCard({
    super.key,
    required this.result,
    required this.dayGan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  result.pillarName,
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${result.jiji}(地支) 지장간',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: theme.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 지장간 상세
          ...result.jijangganList.map((jjg) => _buildDetailItem(context, theme, jjg)),
        ],
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, AppThemeExtension theme, JiJangGanSipSin jjg) {
    final color = _getOhengColor(jjg.oheng, theme);
    final strengthPercent = (jjg.strength / 30 * 100).round(); // 30일 기준

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // 기운 유형
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.surfaceHover,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              jjg.type.korean,
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          // 천간 (한자 + 한글)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                jjg.ganHanja,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 한글 + 오행
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                jjg.gan,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      jjg.oheng,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${jjg.strength}일 ($strengthPercent%)',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // 십성
          SipSungDisplay(
            sipsin: jjg.sipsin,
            size: SipSungSize.medium,
          ),
        ],
      ),
    );
  }

  Color _getOhengColor(String oheng, AppThemeExtension theme) {
    return switch (oheng) {
      '목' => AppColors.wood,
      '화' => AppColors.fire,
      '토' => AppColors.earth,
      '금' => AppColors.metal,
      '수' => AppColors.water,
      _ => theme.textSecondary,
    };
  }
}
