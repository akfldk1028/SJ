import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/constants/twelve_unsung.dart';
import '../../domain/services/unsung_service.dart';

/// 12운성 단일 표시 위젯
class UnsungBadge extends StatelessWidget {
  final TwelveUnsung unsung;
  final UnsungBadgeSize size;
  final bool showStrength;

  const UnsungBadge({
    super.key,
    required this.unsung,
    this.size = UnsungBadgeSize.medium,
    this.showStrength = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getUnsungColor(unsung);
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
            unsung.korean,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (showStrength) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${unsung.strength}',
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
      UnsungBadgeSize.small => 12.0,
      UnsungBadgeSize.medium => 13.0,
      UnsungBadgeSize.large => 14.0,
    };
  }

  EdgeInsets _getPadding() {
    return switch (size) {
      UnsungBadgeSize.small => const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      UnsungBadgeSize.medium => const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      UnsungBadgeSize.large => const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    };
  }

  /// 12운성별 색상 (길흉 기반)
  Color _getUnsungColor(TwelveUnsung unsung) {
    // 강한 운성 (8 이상)
    if (unsung.strength >= 8) {
      return AppColors.success; // 녹색
    }
    // 중간 운성 (5-7)
    if (unsung.strength >= 5) {
      return AppColors.accent; // 파란색
    }
    // 약한 운성 (3-4)
    if (unsung.strength >= 3) {
      return AppColors.warning; // 주황색
    }
    // 매우 약한 운성 (0-2)
    return AppColors.error; // 빨간색
  }
}

/// 12운성 뱃지 크기
enum UnsungBadgeSize { small, medium, large }

/// 12운성 테이블 위젯
/// 4주의 12운성을 테이블 형태로 표시
class UnsungTable extends StatelessWidget {
  final UnsungAnalysisResult result;

  const UnsungTable({super.key, required this.result});

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
                      fontSize: 13,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '12운성',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '강도',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // 데이터 행
          _buildRow(context, theme, result.yearUnsung, isLast: false),
          _buildDivider(theme),
          _buildRow(context, theme, result.monthUnsung, isLast: false),
          _buildDivider(theme),
          _buildRow(context, theme, result.dayUnsung, isLast: result.hourUnsung == null),
          if (result.hourUnsung != null) ...[
            _buildDivider(theme),
            _buildRow(context, theme, result.hourUnsung!, isLast: true),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, AppThemeExtension theme, UnsungResult item, {required bool isLast}) {
    final color = _getUnsungColor(item.unsung);

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
          // 12운성
          Expanded(
            flex: 3,
            child: Center(
              child: UnsungBadge(
                unsung: item.unsung,
                size: UnsungBadgeSize.medium,
              ),
            ),
          ),
          // 강도 바
          Expanded(
            flex: 2,
            child: _buildStrengthBar(theme, item.unsung.strength, color),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthBar(AppThemeExtension theme, int strength, Color color) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength / 10,
              backgroundColor: theme.surfaceHover,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$strength',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(AppThemeExtension theme) {
    return Divider(
      height: 1,
      color: theme.border,
    );
  }

  Color _getUnsungColor(TwelveUnsung unsung) {
    if (unsung.strength >= 8) return AppColors.success;
    if (unsung.strength >= 5) return AppColors.accent;
    if (unsung.strength >= 3) return AppColors.warning;
    return AppColors.error;
  }
}

/// 12운성 행 (한 줄 표시)
class UnsungRow extends StatelessWidget {
  final UnsungAnalysisResult result;

  const UnsungRow({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final items = [
      result.hourUnsung,
      result.dayUnsung,
      result.monthUnsung,
      result.yearUnsung,
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
              '12운성',
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          ...items.map((item) => Expanded(
                child: Center(
                  child: item != null
                      ? UnsungBadge(
                          unsung: item.unsung,
                          size: UnsungBadgeSize.small,
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

/// 12운성 상세 카드
class UnsungDetailCard extends StatelessWidget {
  final UnsungResult result;

  const UnsungDetailCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final color = _getUnsungColor(result.unsung);
    final interpretation = UnsungService.getDetailedInterpretation(result.unsung);

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
                    fontSize: 13,
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
              UnsungBadge(
                unsung: result.unsung,
                size: UnsungBadgeSize.large,
                showStrength: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 한자
          Center(
            child: Text(
              result.unsung.hanja,
              style: TextStyle(
                color: color,
                fontSize: 48,
                fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }

  Color _getUnsungColor(TwelveUnsung unsung) {
    if (unsung.strength >= 8) return AppColors.success;
    if (unsung.strength >= 5) return AppColors.accent;
    if (unsung.strength >= 3) return AppColors.warning;
    return AppColors.error;
  }
}
