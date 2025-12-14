import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/constants/sipsin_relations.dart';

/// 십성(十星) 표시 위젯
/// 일간 기준 천간/지지의 십성을 표시
class SipSungDisplay extends StatelessWidget {
  /// 십성
  final SipSin sipsin;

  /// 크기 (small, medium, large)
  final SipSungSize size;

  /// 배경 표시 여부
  final bool showBackground;

  /// 한자 표시 여부
  final bool showHanja;

  const SipSungDisplay({
    super.key,
    required this.sipsin,
    this.size = SipSungSize.medium,
    this.showBackground = true,
    this.showHanja = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getSipSinColor(sipsin);
    final fontSize = _getFontSize();
    final padding = _getPadding();

    if (!showBackground) {
      return Text(
        showHanja ? sipsin.hanja : sipsin.korean,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        showHanja ? sipsin.hanja : sipsin.korean,
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
      SipSungSize.small => 10.0,
      SipSungSize.medium => 12.0,
      SipSungSize.large => 14.0,
    };
  }

  EdgeInsets _getPadding() {
    return switch (size) {
      SipSungSize.small => const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      SipSungSize.medium => const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      SipSungSize.large => const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    };
  }

  /// 십성별 색상 (카테고리 기반)
  Color _getSipSinColor(SipSin sipsin) {
    final category = sipsinToCategory[sipsin];
    return switch (category) {
      SipSinCategory.bigeop => AppColors.water,    // 비겁: 파랑
      SipSinCategory.siksang => AppColors.wood,    // 식상: 초록
      SipSinCategory.jaeseong => AppColors.earth,  // 재성: 노랑
      SipSinCategory.gwanseong => AppColors.fire,  // 관성: 빨강
      SipSinCategory.inseong => AppColors.metal,   // 인성: 회색
      _ => AppColors.textSecondary,
    };
  }
}

/// 십성 크기 옵션
enum SipSungSize { small, medium, large }

/// 십성 행 (천간 또는 지지 한 줄)
/// 4주 모두의 십성을 한 줄로 표시
class SipSungRow extends StatelessWidget {
  /// 십성 목록 [시주, 일주, 월주, 년주] 순서
  final List<SipSin?> sipsins;

  /// 라벨 (예: "천간 십성", "지지 십성")
  final String? label;

  const SipSungRow({
    super.key,
    required this.sipsins,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (label != null) ...[
          SizedBox(
            width: 60,
            child: Text(
              label!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
            ),
          ),
        ],
        ...sipsins.map((sipsin) => Expanded(
              child: Center(
                child: sipsin != null
                    ? SipSungDisplay(
                        sipsin: sipsin,
                        size: SipSungSize.small,
                      )
                    : Text(
                        '-',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
              ),
            )),
      ],
    );
  }
}

/// 십성 분포 차트 (막대 그래프)
class SipSungDistributionChart extends StatelessWidget {
  /// 십성별 개수 맵
  final Map<SipSin, int> distribution;

  /// 최대 높이
  final double maxHeight;

  const SipSungDistributionChart({
    super.key,
    required this.distribution,
    this.maxHeight = 100,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = distribution.values.fold<int>(0, (a, b) => a > b ? a : b);
    if (maxCount == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 막대 그래프
        SizedBox(
          height: maxHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: SipSin.values.map((sipsin) {
              final count = distribution[sipsin] ?? 0;
              final height = count > 0 ? (count / maxCount) * maxHeight : 0.0;
              final color = _getSipSinColor(sipsin);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (count > 0)
                        Text(
                          '$count',
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: height,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.7),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        // 라벨
        Row(
          children: SipSin.values.map((sipsin) {
            return Expanded(
              child: Center(
                child: Text(
                  sipsin.korean.substring(0, 1), // 첫 글자만
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 9,
                      ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getSipSinColor(SipSin sipsin) {
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

/// 십성 카테고리별 분포 (비겁/식상/재성/관성/인성)
class SipSungCategoryChart extends StatelessWidget {
  /// 카테고리별 개수 맵
  final Map<SipSinCategory, int> distribution;

  const SipSungCategoryChart({
    super.key,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    final total = distribution.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      children: SipSinCategory.values.map((category) {
        final count = distribution[category] ?? 0;
        final ratio = count / total;
        final color = _getCategoryColor(category);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: Text(
                  category.korean,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 16,
                      width: ratio * 200, // 최대 너비
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 30,
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(SipSinCategory category) {
    return switch (category) {
      SipSinCategory.bigeop => AppColors.water,
      SipSinCategory.siksang => AppColors.wood,
      SipSinCategory.jaeseong => AppColors.earth,
      SipSinCategory.gwanseong => AppColors.fire,
      SipSinCategory.inseong => AppColors.metal,
    };
  }
}
