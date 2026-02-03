import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/purchase_provider.dart';

/// 프리미엄 뱃지
///
/// 사용자의 구매 상태에 따라 뱃지 표시
/// 테마의 primaryColor + accentColor 기반 그라데이션
/// - 프리미엄: 밝은 그라데이션 PRO 뱃지
/// - 무료: 표시 안 함
class PremiumBadgeWidget extends ConsumerWidget {
  const PremiumBadgeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(purchaseNotifierProvider); // 상태 변경 감지용
    final isPremium = ref.read(purchaseNotifierProvider.notifier).isPremium;

    if (!isPremium) return const SizedBox.shrink();

    final theme = context.appTheme;
    final primary = theme.primaryColor;
    final accent = theme.accentColor ?? primary;

    // 밝은 핑크톤 그라데이션 (테마 색상 기반)
    final gradStart = _brighten(primary);
    final gradEnd = _brighten(accent);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradStart.withValues(alpha: 0.2),
            gradEnd.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: gradStart.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [gradStart, gradEnd],
            ).createShader(bounds),
            child: const Icon(
              Icons.workspace_premium,
              size: 13,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 3),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [gradStart, gradEnd],
            ).createShader(bounds),
            child: const Text(
              'PRO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 색상을 밝고 생동감 있는 핑크/로즈 톤으로 변환
  Color _brighten(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withSaturation((hsl.saturation + 0.3).clamp(0.0, 1.0))
        .withLightness((hsl.lightness + 0.15).clamp(0.4, 0.7))
        .toColor();
  }
}
