import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/constants/gongmang_table.dart';
import '../../domain/services/gongmang_service.dart';

/// 공망 지지 표시 위젯
/// 일주 기준 공망인 2개의 지지를 표시
class GongmangJijiDisplay extends StatelessWidget {
  final List<String> gongmangJijis;

  const GongmangJijiDisplay({
    super.key,
    required this.gongmangJijis,
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
      child: Row(
        children: [
          Icon(
            Icons.blur_circular,
            size: 20,
            color: theme.textMuted,
          ),
          const SizedBox(width: 12),
          Text(
            '공망 지지',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          ...gongmangJijis.map((jiji) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(
                      jiji,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

/// 공망 상태 뱃지
class GongmangBadge extends StatelessWidget {
  final bool isGongmang;
  final GongmangBadgeSize size;

  const GongmangBadge({
    super.key,
    required this.isGongmang,
    this.size = GongmangBadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final color = isGongmang ? AppColors.error : AppColors.success;
    final text = isGongmang ? '공망' : '정상';
    final fontSize = _getFontSize();
    final padding = _getPadding();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  double _getFontSize() {
    return switch (size) {
      GongmangBadgeSize.small => 10.0,
      GongmangBadgeSize.medium => 12.0,
      GongmangBadgeSize.large => 14.0,
    };
  }

  EdgeInsets _getPadding() {
    return switch (size) {
      GongmangBadgeSize.small => const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      GongmangBadgeSize.medium => const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      GongmangBadgeSize.large => const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    };
  }
}

/// 공망 뱃지 크기
enum GongmangBadgeSize { small, medium, large }

/// 공망 테이블 위젯
/// 각 궁성의 공망 여부를 테이블로 표시
class GongmangTable extends StatelessWidget {
  final GongmangAnalysisResult result;

  const GongmangTable({super.key, required this.result});

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
                  flex: 2,
                  child: Text(
                    '상태',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    '해석',
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
          _buildRow(context, theme, result.monthResult, isLast: result.hourResult == null),
          if (result.hourResult != null) ...[
            _buildDivider(theme),
            _buildRow(context, theme, result.hourResult!, isLast: true),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, AppThemeExtension theme, GongmangResult item, {required bool isLast}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: item.isGongmang ? AppColors.error.withOpacity(0.05) : null,
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
                  color: item.isGongmang
                      ? AppColors.error.withOpacity(0.15)
                      : theme.surfaceHover,
                  borderRadius: BorderRadius.circular(6),
                  border: item.isGongmang
                      ? Border.all(color: AppColors.error.withOpacity(0.3))
                      : null,
                ),
                child: Center(
                  child: Text(
                    item.jiji,
                    style: TextStyle(
                      color: item.isGongmang
                          ? AppColors.error
                          : theme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 상태
          Expanded(
            flex: 2,
            child: Center(
              child: GongmangBadge(
                isGongmang: item.isGongmang,
                size: GongmangBadgeSize.small,
              ),
            ),
          ),
          // 해석
          Expanded(
            flex: 4,
            child: Text(
              item.isGongmang ? item.interpretation : '-',
              style: TextStyle(
                color: item.isGongmang
                    ? AppColors.error
                    : theme.textMuted,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(AppThemeExtension theme) {
    return Divider(
      height: 1,
      color: theme.border,
    );
  }
}

/// 공망 행 (한 줄 표시)
class GongmangRow extends StatelessWidget {
  final GongmangAnalysisResult result;

  const GongmangRow({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final items = [
      result.hourResult,
      null, // 일지는 공망 대상이 아님
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
              '공망',
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 10,
              ),
            ),
          ),
          ...items.map((item) => Expanded(
                child: Center(
                  child: item != null
                      ? GongmangBadge(
                          isGongmang: item.isGongmang,
                          size: GongmangBadgeSize.small,
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

/// 공망 상세 카드
class GongmangDetailCard extends StatelessWidget {
  final GongmangResult result;

  const GongmangDetailCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final color = result.isGongmang ? AppColors.error : AppColors.success;
    final interpretation = GongmangService.getDetailedInterpretation(result);

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
              GongmangBadge(
                isGongmang: result.isGongmang,
                size: GongmangBadgeSize.large,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 공망 아이콘
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.3), width: 2),
              ),
              child: Center(
                child: Icon(
                  result.isGongmang ? Icons.blur_circular : Icons.check_circle,
                  size: 40,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 상태 텍스트
          Center(
            child: Text(
              result.isGongmang ? '空亡(공망)' : '正常(정상)',
              style: TextStyle(
                color: color,
                fontSize: 16,
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
}

/// 공망 요약 카드
class GongmangSummaryCard extends StatelessWidget {
  final GongmangAnalysisResult result;

  const GongmangSummaryCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final hasGongmang = result.hasGongmang;
    final mainColor = hasGongmang ? AppColors.error : AppColors.success;

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
              Icon(
                Icons.blur_circular,
                size: 18,
                color: mainColor,
              ),
              const SizedBox(width: 8),
              Text(
                '공망 요약',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.surfaceHover,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '일주: ${result.dayGapja}',
                  style: TextStyle(
                    color: theme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 순 정보
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '소속 순(旬)',
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.sunInfo.sunName,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '공망 지지',
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildGongmangJiji(result.sunInfo.gongmang1),
                        const SizedBox(width: 4),
                        _buildGongmangJiji(result.sunInfo.gongmang2),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 공망 통계
          Row(
            children: [
              _buildStatItem(
                '공망 궁',
                '${result.gongmangCount}개',
                hasGongmang ? AppColors.error : AppColors.success,
              ),
              const SizedBox(width: 12),
              _buildStatItem(
                '정상 궁',
                '${result.allResults.length - result.gongmangCount}개',
                AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 요약 메시지
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: mainColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  hasGongmang ? Icons.info_outline : Icons.check_circle_outline,
                  size: 18,
                  color: mainColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.summary,
                    style: TextStyle(
                      color: mainColor,
                      fontSize: 12,
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
            _buildGongmangPillars(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildGongmangJiji(String jiji) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          jiji,
          style: const TextStyle(
            color: AppColors.error,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
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
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
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

  Widget _buildGongmangPillars(AppThemeExtension theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '공망 궁성',
          style: TextStyle(
            color: theme.textMuted,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: result.allResults
              .where((r) => r.isGongmang)
              .map((r) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.blur_circular,
                          size: 14,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${r.pillarName}(${r.jiji})',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

/// 공망 유형 배지
class GongmangTypeBadge extends StatelessWidget {
  final GongmangType type;

  const GongmangTypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            type.korean,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${type.hanja})',
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(GongmangType type) {
    return switch (type) {
      GongmangType.jinGong => AppColors.error,
      GongmangType.banGong => AppColors.warning,
      GongmangType.haeGongChung => AppColors.success,
      GongmangType.haeGongHap => AppColors.success,
      GongmangType.haeGongHyung => AppColors.info,
      GongmangType.talGong => AppColors.success,
    };
  }
}
