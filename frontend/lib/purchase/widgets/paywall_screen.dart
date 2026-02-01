import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadButton;

import '../providers/purchase_provider.dart';
import 'restore_button_widget.dart';

/// 구매 선택 화면 (Paywall)
///
/// 3개 상품 카드: 광고 제거, AI 프리미엄, 콤보
/// shadcn_ui 기반 레이아웃
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

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

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 헤더
                const Text(
                  '더 나은 사주 상담을 위해',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  '광고 제거, AI 무제한 대화를 경험하세요',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // 상품 카드들
                ...packages.map((pkg) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ProductCard(
                        package: pkg,
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
                  '구독은 자동 갱신되며, 설정에서 언제든 해지할 수 있습니다.\n'
                  '광고 제거는 일회성 구매로 영구 적용됩니다.',
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

/// 상품 카드 위젯
class _ProductCard extends StatelessWidget {
  final Package package;
  final bool isLoading;
  final VoidCallback onPurchase;

  const _ProductCard({
    required this.package,
    required this.isLoading,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;
    final isCombo = product.identifier.contains('combo');
    final isSubscription = package.packageType != PackageType.lifetime;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isCombo ? const Color(0xFF1A1A2E) : const Color(0xFF151520),
            border: Border.all(
              color: isCombo
                  ? const Color(0xFFD4AF37)
                  : Colors.white.withValues(alpha: 0.1),
              width: isCombo ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상품 제목
              Text(
                product.title.replaceAll(RegExp(r'\s*\(.*\)'), ''),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // 가격
              Row(
                children: [
                  Text(
                    product.priceString,
                    style: TextStyle(
                      color: isCombo
                          ? const Color(0xFFD4AF37)
                          : const Color(0xFF8B7FFF),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isSubscription)
                    const Text(
                      '/월',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  if (!isSubscription)
                    const Text(
                      ' (일회성)',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // 설명
              Text(
                product.description,
                style:
                    const TextStyle(color: Colors.white60, fontSize: 13),
              ),

              if (isCombo) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '별도 구매 대비 할인',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // 구매 버튼
              SizedBox(
                width: double.infinity,
                child: ShadButton(
                  onPressed: isLoading ? null : onPurchase,
                  backgroundColor: isCombo
                      ? const Color(0xFFD4AF37)
                      : const Color(0xFF8B7FFF),
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
                          isSubscription ? '구독하기' : '구매하기',
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

        // BEST 뱃지 (콤보 상품)
        if (isCombo)
          Positioned(
            top: 0,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFD4AF37),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: const Text(
                'BEST',
                style: TextStyle(
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
