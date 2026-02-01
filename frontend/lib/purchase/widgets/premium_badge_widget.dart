import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../purchase_config.dart';
import '../providers/purchase_provider.dart';

/// 프리미엄/광고제거 뱃지
///
/// 사용자의 구매 상태에 따라 적절한 뱃지 표시
/// - AI 프리미엄: 보라색 뱃지
/// - 광고 제거: 금색 뱃지
/// - 무료: 표시 안 함
class PremiumBadgeWidget extends ConsumerWidget {
  const PremiumBadgeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseState = ref.watch(purchaseNotifierProvider);

    return purchaseState.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (info) {
        final isAiPremium = info.entitlements.all[PurchaseConfig.entitlementAiPremium]?.isActive == true;
        final isAdFree = info.entitlements.all[PurchaseConfig.entitlementAdFree]?.isActive == true;

        if (isAiPremium) {
          return const BadgeLabel(label: 'PRO', color: Color(0xFF8B7FFF));
        }

        if (isAdFree) {
          return const BadgeLabel(label: 'AD FREE', color: Color(0xFFD4AF37));
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class BadgeLabel extends StatelessWidget {
  final String label;
  final Color color;

  const BadgeLabel({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
