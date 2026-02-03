import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/purchase_provider.dart';

/// 프리미엄 뱃지
///
/// 사용자의 구매 상태에 따라 뱃지 표시
/// - 프리미엄: 그라데이션 PRO 뱃지 + 아이콘
/// - 무료: 표시 안 함
class PremiumBadgeWidget extends ConsumerWidget {
  const PremiumBadgeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(purchaseNotifierProvider); // 상태 변경 감지용
    final isPremium = ref.read(purchaseNotifierProvider.notifier).isPremium;

    if (isPremium) {
      return const BadgeLabel(
        label: 'PRO',
        icon: Icons.workspace_premium,
        gradientColors: [Color(0xFF7C4DFF), Color(0xFFD4AF37)],
      );
    }

    return const SizedBox.shrink();
  }
}

class BadgeLabel extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final List<Color>? gradientColors;

  const BadgeLabel({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? const Color(0xFF8B7FFF);
    final hasGradient = gradientColors != null && gradientColors!.length >= 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: hasGradient
            ? LinearGradient(
                colors: gradientColors!.map((c) => c.withValues(alpha: 0.25)).toList(),
              )
            : null,
        color: hasGradient ? null : baseColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasGradient
              ? gradientColors!.first.withValues(alpha: 0.5)
              : baseColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: hasGradient ? gradientColors!.first : baseColor,
            ),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: hasGradient ? gradientColors!.first : baseColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
