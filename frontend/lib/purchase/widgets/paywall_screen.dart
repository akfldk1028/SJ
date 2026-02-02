import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadButton;

import '../purchase_config.dart';
import '../providers/purchase_provider.dart';
import 'restore_button_widget.dart';

/// 구매 선택 화면 (Paywall)
///
/// 3개 상품 카드: 1일 이용권, 1주일 이용권, 월간 구독
/// shadcn_ui 기반 레이아웃
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  /// 상품 표시 순서 및 메타 정보
  static const _productMeta = {
    PurchaseConfig.productDayPass: _ProductMeta(
      icon: Icons.bolt,
      badge: null,
      highlight: false,
      periodLabel: '/1일',
      features: ['광고 제거', 'AI 무제한 대화', '24시간 이용'],
    ),
    PurchaseConfig.productWeekPass: _ProductMeta(
      icon: Icons.star,
      badge: '인기',
      highlight: true,
      periodLabel: '/1주',
      features: ['광고 제거', 'AI 무제한 대화', '7일 이용', '일일 패스 대비 할인'],
    ),
    PurchaseConfig.productMonthly: _ProductMeta(
      icon: Icons.diamond_outlined,
      badge: 'BEST',
      highlight: false,
      periodLabel: '/월',
      features: ['광고 제거', 'AI 무제한 대화', '자동 갱신', '가장 저렴한 일일 단가'],
    ),
  };

  /// 상품 정렬 순서
  static const _productOrder = [
    PurchaseConfig.productDayPass,
    PurchaseConfig.productWeekPass,
    PurchaseConfig.productMonthly,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offeringsAsync = ref.watch(offeringsProvider);
    final purchaseState = ref.watch(purchaseNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        title: const Text('프리미엄'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: offeringsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '상품 정보를 불러올 수 없습니다.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ShadButton.outline(
                onPressed: () => ref.invalidate(offeringsProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (offerings) {
          if (offerings == null || offerings.current == null) {
            return const Center(
              child: Text(
                '상품이 준비 중입니다.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final packages = offerings.current!.availablePackages;
          final isLoading = purchaseState is AsyncLoading;

          // 상품 정렬
          final sorted = List<Package>.from(packages)
            ..sort((a, b) {
              final ai = _productOrder.indexOf(a.storeProduct.identifier);
              final bi = _productOrder.indexOf(b.storeProduct.identifier);
              return (ai == -1 ? 999 : ai).compareTo(bi == -1 ? 999 : bi);
            });

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 헤더
                const Text(
                  '프리미엄 이용권',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  '광고 제거 + AI 무제한 대화',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // 상품 카드들
                ...sorted.map((pkg) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ProductCard(
                        package: pkg,
                        meta: _productMeta[pkg.storeProduct.identifier] ??
                            const _ProductMeta(
                              icon: Icons.shopping_bag,
                              badge: null,
                              highlight: false,
                              periodLabel: '',
                              features: [],
                            ),
                        isLoading: isLoading,
                        onPurchase: () => _handlePurchase(ref, pkg),
                      ),
                    )),

                const SizedBox(height: 16),

                // 구매 복원 버튼
                const RestoreButtonWidget(),

                const SizedBox(height: 24),

                // 안내 문구
                const Text(
                  '월간 구독은 자동 갱신되며, 설정에서 언제든 해지할 수 있습니다.\n'
                  '1일/1주일 이용권은 기간 만료 후 자동 종료됩니다.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handlePurchase(WidgetRef ref, Package package) async {
    await ref.read(purchaseNotifierProvider.notifier).purchasePackage(package);
  }
}

/// 상품 메타 정보
class _ProductMeta {
  final IconData icon;
  final String? badge;
  final bool highlight;
  final String periodLabel;
  final List<String> features;

  const _ProductMeta({
    required this.icon,
    required this.badge,
    required this.highlight,
    required this.periodLabel,
    required this.features,
  });
}

/// 상품 카드 위젯
class _ProductCard extends StatelessWidget {
  final Package package;
  final _ProductMeta meta;
  final bool isLoading;
  final VoidCallback onPurchase;

  const _ProductCard({
    required this.package,
    required this.meta,
    required this.isLoading,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;
    final accentColor = meta.highlight
        ? const Color(0xFFD4AF37)
        : const Color(0xFF8B7FFF);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: meta.highlight
                ? const Color(0xFF1A1A2E)
                : const Color(0xFF151520),
            border: Border.all(
              color: meta.highlight
                  ? const Color(0xFFD4AF37)
                  : Colors.white.withValues(alpha: 0.1),
              width: meta.highlight ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이콘 + 상품 제목
              Row(
                children: [
                  Icon(meta.icon, color: accentColor, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      product.title.replaceAll(RegExp(r'\s*\(.*\)'), ''),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 가격
              Row(
                children: [
                  Text(
                    product.priceString,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    meta.periodLabel,
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 기능 목록
              ...meta.features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check, color: accentColor, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          f,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 16),

              // 구매 버튼
              SizedBox(
                width: double.infinity,
                child: ShadButton(
                  onPressed: isLoading ? null : onPurchase,
                  backgroundColor: accentColor,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          package.packageType == PackageType.monthly
                              ? '구독하기'
                              : '구매하기',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),

        // 뱃지
        if (meta.badge != null)
          Positioned(
            top: 0,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                meta.badge!,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
