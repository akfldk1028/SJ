import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/constants/twelve_sinsal.dart';
import '../../domain/services/twelve_sinsal_service.dart';

/// 12신살 단일 뱃지 위젯
class SinsalBadge extends StatelessWidget {
  final TwelveSinsal sinsal;
  final SinsalBadgeSize size;
  final bool showMeaning;

  const SinsalBadge({
    super.key,
    required this.sinsal,
    this.size = SinsalBadgeSize.medium,
    this.showMeaning = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final color = _getSinsalColor(sinsal, theme);
    final fontSize = _getFontSize();
    final padding = _getPadding();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sinsal.korean,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (showMeaning) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getFortuneLabel(sinsal.fortuneType),
                style: TextStyle(
                  color: color,
                  fontSize: fontSize * 0.75,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _getFontSize() {
    return switch (size) {
      SinsalBadgeSize.small => 10.0,
      SinsalBadgeSize.medium => 12.0,
      SinsalBadgeSize.large => 14.0,
    };
  }

  EdgeInsets _getPadding() {
    return switch (size) {
      SinsalBadgeSize.small => const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      SinsalBadgeSize.medium => const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      SinsalBadgeSize.large => const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    };
  }

  String _getFortuneLabel(String fortuneType) {
    return switch (fortuneType) {
      '길' => '길',
      '흉' => '흉',
      '길흉혼합' => '혼합',
      _ => '',
    };
  }

  /// 신살별 색상 (길흉 기반)
  Color _getSinsalColor(TwelveSinsal sinsal, AppThemeExtension theme) {
    return switch (sinsal.fortuneType) {
      '길' => AppColors.success, // 녹색
      '길흉혼합' => AppColors.accent, // 파란색
      '흉' => AppColors.error, // 빨간색
      _ => theme.textSecondary,
    };
  }
}

/// 신살 뱃지 크기
enum SinsalBadgeSize { small, medium, large }

/// 12신살 테이블 위젯
/// 4주의 12신살을 테이블 형태로 표시
class SinsalTable extends StatelessWidget {
  final TwelveSinsalAnalysisResult result;

  const SinsalTable({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.surfaceHover,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '궁성',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '지지',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '12신살',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '길흉',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // 데이터 행
          _buildRow(context, theme, result.yearResult, isLast: false),
          _buildDivider(theme),
          _buildRow(context, theme, result.monthResult, isLast: false),
          _buildDivider(theme),
          _buildRow(context, theme, result.dayResult, isLast: result.hourResult == null),
          if (result.hourResult != null) ...[
            _buildDivider(theme),
            _buildRow(context, theme, result.hourResult!, isLast: true),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, AppThemeExtension theme, TwelveSinsalResult item, {required bool isLast}) {
    final color = _getSinsalColor(item.sinsal, theme);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(11))
            : null,
      ),
      child: Row(
        children: [
          // 궁성
          Expanded(
            flex: 2,
            child: Text(
              item.pillarName,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // 지지
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.surfaceHover,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    item.jiji,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 12신살
          Expanded(
            flex: 3,
            child: Center(
              child: SinsalBadge(
                sinsal: item.sinsal,
                size: SinsalBadgeSize.medium,
              ),
            ),
          ),
          // 길흉 라벨
          Expanded(
            flex: 2,
            child: Center(
              child: _buildFortuneLabel(item.sinsal.fortuneType, color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFortuneLabel(String fortuneType, Color color) {
    final label = switch (fortuneType) {
      '길' => '길(吉)',
      '흉' => '흉(凶)',
      '길흉혼합' => '혼합',
      _ => '-',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDivider(AppThemeExtension theme) {
    return Divider(
      height: 1,
      color: theme.border,
    );
  }

  Color _getSinsalColor(TwelveSinsal sinsal, AppThemeExtension theme) {
    return switch (sinsal.fortuneType) {
      '길' => AppColors.success,
      '길흉혼합' => AppColors.accent,
      '흉' => AppColors.error,
      _ => theme.textSecondary,
    };
  }
}

/// 12신살 행 (한 줄 표시)
class SinsalRow extends StatelessWidget {
  final TwelveSinsalAnalysisResult result;

  const SinsalRow({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final items = [
      result.hourResult,
      result.dayResult,
      result.monthResult,
      result.yearResult,
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
            width: 50,
            child: Text(
              '12신살',
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 10,
              ),
            ),
          ),
          ...items.map((item) => Expanded(
                child: Center(
                  child: item != null
                      ? SinsalBadge(
                          sinsal: item.sinsal,
                          size: SinsalBadgeSize.small,
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

/// 12신살 상세 카드
class SinsalDetailCard extends StatelessWidget {
  final TwelveSinsalResult result;

  const SinsalDetailCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final color = _getSinsalColor(result.sinsal, theme);
    final interpretation = TwelveSinsalService.getDetailedInterpretation(result.sinsal);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  result.pillarName,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${result.jiji}(地支)',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              SinsalBadge(
                sinsal: result.sinsal,
                size: SinsalBadgeSize.large,
                showMeaning: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 한자
          Center(
            child: Text(
              result.sinsal.hanja,
              style: TextStyle(
                color: color,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 의미
          Center(
            child: Text(
              result.sinsal.meaning,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 해석
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              interpretation,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
          // 특수 신살 표시
          if (result.hasSpecialSinsal) ...[
            const SizedBox(height: 12),
            _buildSpecialSinsals(),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecialSinsals() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star, size: 16, color: AppColors.warning),
              SizedBox(width: 4),
              Text(
                '특수 신살',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: result.specialSinsals.map((special) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${special.korean} (${special.hanja})',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getSinsalColor(TwelveSinsal sinsal, AppThemeExtension theme) {
    return switch (sinsal.fortuneType) {
      '길' => AppColors.success,
      '길흉혼합' => AppColors.accent,
      '흉' => AppColors.error,
      _ => theme.textSecondary,
    };
  }
}

/// 주요 신살 요약 카드
class SinsalSummaryCard extends StatelessWidget {
  final TwelveSinsalAnalysisResult result;

  const SinsalSummaryCard({super.key, required this.result});

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
        children: [
          // 헤더
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                '신살 요약',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '기준: ${result.baseType}(${result.baseJi})',
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 길흉 통계
          Row(
            children: [
              _buildStatItem('길', result.goodSinsalCount, AppColors.success),
              const SizedBox(width: 12),
              _buildStatItem('흉', result.badSinsalCount, AppColors.error),
              const SizedBox(width: 12),
              _buildStatItem('혼합', result.mixedSinsalCount, AppColors.accent),
            ],
          ),
          const SizedBox(height: 16),
          // 주요 신살
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '주요 신살',
                  style: TextStyle(
                    color: theme.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.summary,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // 주요 신살 배지
          if (result.yeokmaResult != null ||
              result.dohwaResult != null ||
              result.hwagaeResult != null ||
              result.jangsungResult != null) ...[
            const SizedBox(height: 12),
            _buildKeysSinsalBadges(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeysSinsalBadges() {
    final keySinsals = <Widget>[];

    if (result.jangsungResult != null) {
      keySinsals.add(_buildKeySinsalBadge(
        '장성살',
        result.jangsungResult!.pillarName,
        AppColors.success,
        Icons.military_tech,
      ));
    }
    if (result.yeokmaResult != null) {
      keySinsals.add(_buildKeySinsalBadge(
        '역마살',
        result.yeokmaResult!.pillarName,
        AppColors.accent,
        Icons.flight,
      ));
    }
    if (result.dohwaResult != null) {
      keySinsals.add(_buildKeySinsalBadge(
        '도화살',
        result.dohwaResult!.pillarName,
        AppColors.error,
        Icons.favorite,
      ));
    }
    if (result.hwagaeResult != null) {
      keySinsals.add(_buildKeySinsalBadge(
        '화개살',
        result.hwagaeResult!.pillarName,
        AppColors.accent,
        Icons.palette,
      ));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: keySinsals,
    );
  }

  Widget _buildKeySinsalBadge(
    String name,
    String pillar,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$name($pillar)',
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
}
