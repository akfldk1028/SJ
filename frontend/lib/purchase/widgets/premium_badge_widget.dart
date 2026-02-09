import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/purchase_provider.dart';

/// 프리미엄 뱃지 + 남은 시간 카운트다운
///
/// PRO 아이콘/텍스트 + 연한 회색으로 "5일 3시간" 형태 표시
/// 매분 자동 갱신, 만료 임박 시 경고색
class PremiumBadgeWidget extends ConsumerStatefulWidget {
  const PremiumBadgeWidget({super.key});

  @override
  ConsumerState<PremiumBadgeWidget> createState() => _PremiumBadgeWidgetState();
}

class _PremiumBadgeWidgetState extends ConsumerState<PremiumBadgeWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 매 60초마다 카운트다운 갱신
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(purchaseNotifierProvider);
    final notifier = ref.read(purchaseNotifierProvider.notifier);
    final isPremium = notifier.isPremium;

    if (!isPremium) return const SizedBox.shrink();

    final theme = context.appTheme;
    final primary = theme.primaryColor;
    final accent = theme.accentColor ?? primary;

    final gradStart = _brighten(primary);
    final gradEnd = _brighten(accent);

    final expiresAt = notifier.expiresAt;
    final remainingText = _formatRemaining(expiresAt);
    final isExpiringSoon = notifier.isExpiringSoon;

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
          if (remainingText != null) ...[
            const SizedBox(width: 5),
            Text(
              remainingText,
              style: TextStyle(
                color: isExpiringSoon
                    ? Colors.redAccent.withValues(alpha: 0.8)
                    : theme.textMuted.withValues(alpha: 0.7),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 남은 시간 포맷
  /// 7일 이상: "6일"
  /// 1일 이상: "2일 3시간"
  /// 1시간 이상: "5시간 23분"
  /// 1시간 미만: "45분"
  String? _formatRemaining(DateTime? expiresAt) {
    if (expiresAt == null) return null;

    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return '만료됨';

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;

    if (days >= 7) return '$days일';
    if (days >= 1) return '$days일 $hours시간';
    if (hours >= 1) return '$hours시간 $minutes분';
    return '$minutes분';
  }

  Color _brighten(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withSaturation((hsl.saturation + 0.3).clamp(0.0, 1.0))
        .withLightness((hsl.lightness + 0.15).clamp(0.4, 0.7))
        .toColor();
  }
}
