import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/constants/cheongan_jiji.dart';
import '../../domain/entities/pillar.dart';

/// 사주의 기둥 하나(천간+지지)를 표시하는 위젯
/// 한글과 한자를 함께 표시
class PillarDisplay extends StatelessWidget {
  final Pillar pillar;
  final String label;
  final bool showLabel;
  final double size;
  final bool showHanja; // 한자 표시 여부

  const PillarDisplay({
    super.key,
    required this.pillar,
    required this.label,
    this.showLabel = true,
    this.size = 24.0,
    this.showHanja = true,
  });

  @override
  Widget build(BuildContext context) {
    final ganHanja = cheonganHanja[pillar.gan] ?? '';
    final jiHanja = jijiHanja[pillar.ji] ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // 천간 (한자 + 한글)
              _buildCharWithHanja(
                context,
                hangul: pillar.gan,
                hanja: ganHanja,
                oheng: pillar.ganOheng,
              ),
              const SizedBox(height: 6),
              // 구분선
              Container(
                width: 28,
                height: 1,
                color: AppColors.borderSubtle,
              ),
              const SizedBox(height: 6),
              // 지지 (한자 + 한글)
              _buildCharWithHanja(
                context,
                hangul: pillar.ji,
                hanja: jiHanja,
                oheng: pillar.jiOheng,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 한자와 한글을 함께 표시하는 위젯
  Widget _buildCharWithHanja(
    BuildContext context, {
    required String hangul,
    required String hanja,
    required String oheng,
  }) {
    final color = _getOhengColor(oheng);

    if (!showHanja || hanja.isEmpty) {
      // 한자 표시 안 함 - 한글만 표시
      return Text(
        hangul,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: size,
            ),
      );
    }

    // 한자 크기는 size를 기준으로, 한글은 그 절반 정도로
    final hanjaSize = size > 24 ? size : 28.0;
    final hangulSize = hanjaSize * 0.45;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 한자 (큰 글씨, 오행별 색상)
        Text(
          hanja,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: hanjaSize,
          ),
        ),
        const SizedBox(height: 2),
        // 한글 (작은 글씨)
        Text(
          hangul,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
                fontSize: hangulSize,
              ),
        ),
      ],
    );
  }

  Color _getOhengColor(String oheng) {
    switch (oheng) {
      case '목':
        return AppColors.wood;
      case '화':
        return AppColors.fire;
      case '토':
        return AppColors.earth;
      case '금':
        return AppColors.metal;
      case '수':
        return AppColors.water;
      default:
        return AppColors.textPrimary;
    }
  }
}
