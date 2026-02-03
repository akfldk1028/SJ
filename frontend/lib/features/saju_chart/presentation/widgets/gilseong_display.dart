/// 길성(吉星) 표시 위젯
/// 포스텔러 스타일로 각 기둥별 특수 신살을 표시
///
/// Phase 16-C: 길성 행 UI 위젯
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/constants/twelve_sinsal.dart';
import '../../domain/services/gilseong_service.dart';

// ============================================================================
// 특수 신살 뱃지 위젯
// ============================================================================

/// 특수 신살 뱃지 (단일)
class SpecialSinsalBadge extends StatelessWidget {
  final SpecialSinsal sinsal;
  final SpecialSinsalBadgeSize size;
  final bool showFortuneType;

  const SpecialSinsalBadge({
    super.key,
    required this.sinsal,
    this.size = SpecialSinsalBadgeSize.small,
    this.showFortuneType = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getSinsalColor(sinsal);
    final fontSize = _getFontSize();
    final padding = _getPadding();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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
          if (showFortuneType) ...[
            const SizedBox(width: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                sinsal.fortuneType.korean,
                style: TextStyle(
                  color: color,
                  fontSize: fontSize * 0.7,
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
      SpecialSinsalBadgeSize.tiny => 11.0,
      SpecialSinsalBadgeSize.small => 12.0,
      SpecialSinsalBadgeSize.medium => 13.0,
      SpecialSinsalBadgeSize.large => 14.0,
    };
  }

  EdgeInsets _getPadding() {
    return switch (size) {
      SpecialSinsalBadgeSize.tiny => const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      SpecialSinsalBadgeSize.small => const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      SpecialSinsalBadgeSize.medium => const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      SpecialSinsalBadgeSize.large => const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    };
  }

  Color _getSinsalColor(SpecialSinsal sinsal) {
    return switch (sinsal.fortuneType) {
      SinsalFortuneType.good => AppColors.success,
      SinsalFortuneType.bad => AppColors.error,
      SinsalFortuneType.mixed => AppColors.accent,
    };
  }
}

/// 특수 신살 뱃지 크기
enum SpecialSinsalBadgeSize { tiny, small, medium, large }

// ============================================================================
// 길성 행 위젯 (포스텔러 스타일)
// ============================================================================

/// 길성 행 - 각 기둥별 특수 신살을 세로로 표시
/// 포스텔러 이미지처럼 시/일/월/년 순서로 표시
class GilseongRow extends StatelessWidget {
  final GilseongAnalysisResult result;
  final bool showHeader;

  const GilseongRow({
    super.key,
    required this.result,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    // 시/일/월/년 순서로 표시 (포스텔러 스타일)
    final pillars = [
      result.hourResult,
      result.dayResult,
      result.monthResult,
      result.yearResult,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (길성 라벨)
          if (showHeader)
            SizedBox(
              width: 40,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '길성',
                  style: TextStyle(
                    color: theme.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          // 각 기둥별 신살
          ...pillars.map((pillar) => Expanded(
                child: _buildPillarSinsals(pillar, theme),
              )),
        ],
      ),
    );
  }

  Widget _buildPillarSinsals(PillarGilseongResult? pillar, AppThemeExtension theme) {
    if (pillar == null || !pillar.hasSinsals) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: pillar.sinsals.map((sinsal) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: SpecialSinsalBadge(
            sinsal: sinsal,
            size: SpecialSinsalBadgeSize.tiny,
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================================
// 신살과 길성 통합 테이블 (포스텔러 스타일)
// ============================================================================

/// 신살과 길성 통합 테이블
/// 포스텔러 이미지처럼 상단에 신살 목록, 테이블에 천간/지지/길성 표시
class SinsalGilseongTable extends StatelessWidget {
  final GilseongAnalysisResult gilseongResult;
  final String yearGan;
  final String yearJi;
  final String monthGan;
  final String monthJi;
  final String dayGan;
  final String dayJi;
  final String? hourGan;
  final String? hourJi;

  const SinsalGilseongTable({
    super.key,
    required this.gilseongResult,
    required this.yearGan,
    required this.yearJi,
    required this.monthGan,
    required this.monthJi,
    required this.dayGan,
    required this.dayJi,
    this.hourGan,
    this.hourJi,
  });

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: "신살과 길성"
          _buildHeader(theme),
          // 전체 신살 목록 (가로 스크롤)
          _buildAllSinsalList(theme),
          Divider(height: 1, color: theme.border),
          // 테이블
          _buildTable(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.surfaceHover,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 18, color: theme.primaryColor),
          const SizedBox(width: 8),
          Text(
            '신살과 길성',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // 통계
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '길 ${gilseongResult.totalGoodCount}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '흉 ${gilseongResult.totalBadCount}',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllSinsalList(AppThemeExtension theme) {
    if (gilseongResult.allUniqueSinsals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          '특수 신살 없음',
          style: TextStyle(
            color: theme.textMuted,
            fontSize: 13,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: gilseongResult.allUniqueSinsals.map((sinsal) {
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: SpecialSinsalBadge(
              sinsal: sinsal,
              size: SpecialSinsalBadgeSize.small,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTable(AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(50),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
          3: FlexColumnWidth(),
          4: FlexColumnWidth(),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          // 헤더 행
          _buildTableHeader(theme),
          // 천간 행
          _buildGanRow(theme),
          // 천간 길성 행 (포스텔러 스타일)
          _buildGanGilseongRow(theme),
          // 지지 행
          _buildJiRow(theme),
          // 지지 길성 행 (포스텔러 스타일)
          _buildJiGilseongRow(theme),
        ],
      ),
    );
  }

  TableRow _buildTableHeader(AppThemeExtension theme) {
    return TableRow(
      children: [
        const SizedBox(height: 32),
        _buildHeaderCell('시주', theme),
        _buildHeaderCell('일주', theme),
        _buildHeaderCell('월주', theme),
        _buildHeaderCell('년주', theme),
      ],
    );
  }

  Widget _buildHeaderCell(String text, AppThemeExtension theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          text,
          style: TextStyle(
            color: theme.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  TableRow _buildGanRow(AppThemeExtension theme) {
    return TableRow(
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.5),
      ),
      children: [
        _buildRowLabel('천간', theme),
        _buildGanCell(hourGan, theme),
        _buildGanCell(dayGan, theme),
        _buildGanCell(monthGan, theme),
        _buildGanCell(yearGan, theme),
      ],
    );
  }

  Widget _buildRowLabel(String text, AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          color: theme.textMuted,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildGanCell(String? gan, AppThemeExtension theme) {
    if (gan == null) {
      return Center(
        child: Text('-', style: TextStyle(color: theme.textMuted)),
      );
    }
    return Center(
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: theme.surfaceHover,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            gan,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  TableRow _buildJiRow(AppThemeExtension theme) {
    return TableRow(
      children: [
        _buildRowLabel('지지', theme),
        _buildJiCell(hourJi, theme),
        _buildJiCell(dayJi, theme),
        _buildJiCell(monthJi, theme),
        _buildJiCell(yearJi, theme),
      ],
    );
  }

  Widget _buildJiCell(String? ji, AppThemeExtension theme) {
    if (ji == null) {
      return Center(
        child: Text('-', style: TextStyle(color: theme.textMuted)),
      );
    }
    return Center(
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: theme.surfaceHover,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            ji,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// 천간 길성 행 (포스텔러 스타일)
  TableRow _buildGanGilseongRow(AppThemeExtension theme) {
    final pillars = [
      gilseongResult.hourResult,
      gilseongResult.dayResult,
      gilseongResult.monthResult,
      gilseongResult.yearResult,
    ];

    return TableRow(
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.3),
      ),
      children: [
        _buildRowLabel('길성', theme),
        ...pillars.map((p) => _buildGanGilseongCell(p, theme)),
      ],
    );
  }

  /// 지지 길성 행 (포스텔러 스타일)
  TableRow _buildJiGilseongRow(AppThemeExtension theme) {
    final pillars = [
      gilseongResult.hourResult,
      gilseongResult.dayResult,
      gilseongResult.monthResult,
      gilseongResult.yearResult,
    ];

    return TableRow(
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.3),
      ),
      children: [
        _buildRowLabel('길성', theme),
        ...pillars.map((p) => _buildJiGilseongCell(p, theme)),
      ],
    );
  }

  /// 천간 길성 셀 (천간에서 작용하는 신살만 표시)
  Widget _buildGanGilseongCell(PillarGilseongResult? pillar, AppThemeExtension theme) {
    if (pillar == null || !pillar.hasGanSinsals) {
      return Center(
        child: Text(
          '×',
          style: TextStyle(
            color: theme.textMuted,
            fontSize: 13,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: pillar.ganSinsals.take(3).map((sinsal) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: SpecialSinsalBadge(
              sinsal: sinsal,
              size: SpecialSinsalBadgeSize.tiny,
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 지지 길성 셀 (지지에서 작용하는 신살만 표시)
  Widget _buildJiGilseongCell(PillarGilseongResult? pillar, AppThemeExtension theme) {
    if (pillar == null || !pillar.hasJiSinsals) {
      return Center(
        child: Text(
          '×',
          style: TextStyle(
            color: theme.textMuted,
            fontSize: 13,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: pillar.jiSinsals.take(4).map((sinsal) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: SpecialSinsalBadge(
              sinsal: sinsal,
              size: SpecialSinsalBadgeSize.tiny,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================================
// 신살 요약 카드
// ============================================================================

/// 신살 요약 카드 (컴팩트 버전)
class GilseongSummaryCard extends StatelessWidget {
  final GilseongAnalysisResult result;

  const GilseongSummaryCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(Icons.stars, size: 16, color: theme.primaryColor),
              const SizedBox(width: 6),
              Text(
                '특수 신살',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // 개수
              Text(
                '${result.allUniqueSinsals.length}개',
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 신살 목록
          if (result.allUniqueSinsals.isEmpty)
            Text(
              '특수 신살 없음',
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 13,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: result.allUniqueSinsals.map((sinsal) {
                return SpecialSinsalBadge(
                  sinsal: sinsal,
                  size: SpecialSinsalBadgeSize.small,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// Phase 24: 확장 신살 정보 위젯
// ============================================================================

/// 확장 신살 정보 카드
/// 효신살, 고신살, 과숙살, 천라지망, 원진살 등 추가 정보 표시
class ExtendedSinsalInfoCard extends StatelessWidget {
  final GilseongAnalysisResult result;
  final bool isMale;

  const ExtendedSinsalInfoCard({
    super.key,
    required this.result,
    this.isMale = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    // 표시할 특수 상태가 있는지 확인
    final hasSpecialInfo = result.hasHyosinsal ||
        (isMale && result.hasGosinsal) ||
        (!isMale && result.hasGwasuksal) ||
        result.hasCheollaJimang ||
        result.wonJinsalCount > 0;

    if (!hasSpecialInfo) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: theme.primaryColor),
              const SizedBox(width: 6),
              Text(
                '특수 상태',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 특수 상태 목록
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              // 효신살
              if (result.hasHyosinsal)
                _buildInfoChip(
                  '효신살',
                  '어머니 영향 강함',
                  AppColors.accent,
                ),
              // 고신살 (남자)
              if (isMale && result.hasGosinsal)
                _buildInfoChip(
                  '고신살',
                  '배우자운 주의',
                  AppColors.error,
                ),
              // 과숙살 (여자)
              if (!isMale && result.hasGwasuksal)
                _buildInfoChip(
                  '과숙살',
                  '배우자운 주의',
                  AppColors.error,
                ),
              // 천라지망
              if (result.hasCheollaJimang)
                _buildInfoChip(
                  '천라지망',
                  '진술충 - 답답함',
                  AppColors.error,
                ),
              // 원진살
              if (result.wonJinsalCount > 0)
                _buildInfoChip(
                  '원진살 ${result.wonJinsalCount}개',
                  '관계 갈등 주의',
                  AppColors.warning,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String tooltip, Color color) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
