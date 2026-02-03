import 'package:flutter/foundation.dart';
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
      accentColor: Color(0xFFFF6B6B),
      dailyPrice: null,
      features: ['광고 제거', 'AI 무제한 대화', '24시간 이용'],
    ),
    PurchaseConfig.productWeekPass: _ProductMeta(
      icon: Icons.star,
      badge: '인기',
      highlight: true,
      periodLabel: '/1주',
      accentColor: Color(0xFFD4AF37),
      dailyPrice: '일 ₩700',
      features: ['광고 제거', 'AI 무제한 대화', '7일 이용', '일일 패스 대비 할인'],
    ),
    PurchaseConfig.productMonthly: _ProductMeta(
      icon: Icons.diamond_outlined,
      badge: 'BEST',
      highlight: false,
      periodLabel: '/월',
      accentColor: Color(0xFF7C4DFF),
      dailyPrice: '일 ₩297',
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
                // 헤더 아이콘
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFF7C4DFF)],
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.workspace_premium,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // 헤더
                const Text(
                  '프리미엄 이용권',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
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
                const SizedBox(height: 12),

                // 구매 즉시 적용 Chip
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flash_on, color: Color(0xFFD4AF37), size: 14),
                        SizedBox(width: 4),
                        Text(
                          '구매 즉시 적용',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                              accentColor: Color(0xFF8B7FFF),
                              dailyPrice: null,
                              features: [],
                            ),
                        isLoading: isLoading,
                        onPurchase: () => _handlePurchase(context, ref, pkg),
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

  Future<void> _handlePurchase(BuildContext context, WidgetRef ref, Package package) async {
    await ref.read(purchaseNotifierProvider.notifier).purchasePackage(package);
    if (!context.mounted) return;

    final purchaseState = ref.read(purchaseNotifierProvider);
    final notifier = ref.read(purchaseNotifierProvider.notifier);

    // 구매 상태 확인
    if (purchaseState.hasError) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('구매 실패'),
            content: Text('${purchaseState.error}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (notifier.isPremium) {
      // 구매 성공 + 프리미엄 반영됨 → 성공 다이얼로그 후 뒤로가기
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.workspace_premium, color: Color(0xFFD4AF37)),
                SizedBox(width: 8),
                Text('프리미엄 적용 완료'),
              ],
            ),
            content: const Text('광고 제거 + AI 무제한 대화가\n즉시 적용되었습니다!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  Navigator.of(context).pop(); // PaywallScreen 닫기
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } else {
      // 구매는 됐지만 프리미엄 미반영 → 콘솔 로그만 남기고 사용자에게는 간단 안내
      if (kDebugMode) {
        final info = purchaseState.valueOrNull;
        print('[PaywallScreen] 구매 완료 but isPremium=false');
        print('[PaywallScreen] entitlements: ${info?.entitlements.all.keys.toList()}');
        print('[PaywallScreen] purchases: ${info?.allPurchasedProductIdentifiers}');
        print('[PaywallScreen] activeSubscriptions: ${info?.activeSubscriptions}');
        print('[PaywallScreen] nonSubscriptionTx: ${info?.nonSubscriptionTransactions.length}');
      }
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('구매 처리 중'),
            content: const Text(
              '구매가 처리되고 있습니다.\n'
              '잠시 후 앱을 재시작하면 적용됩니다.\n\n'
              '문제가 지속되면 설정 > 구매 복원을 시도해주세요.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    }
  }
}

/// 상품 메타 정보
class _ProductMeta {
  final IconData icon;
  final String? badge;
  final bool highlight;
  final String periodLabel;
  final Color accentColor;
  final String? dailyPrice;
  final List<String> features;

  const _ProductMeta({
    required this.icon,
    required this.badge,
    required this.highlight,
    required this.periodLabel,
    required this.accentColor,
    this.dailyPrice,
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
    final color = meta.accentColor;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: meta.highlight
                ? const Color(0xFF1A1A2E)
                : const Color(0xFF151520),
            border: Border.all(
              color: meta.highlight
                  ? color
                  : Colors.white.withValues(alpha: 0.1),
              width: meta.highlight ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 accentColor 바
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.8),
                      color,
                      color.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(meta.highlight ? 24 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 아이콘 + 상품 제목
                    Row(
                      children: [
                        Icon(meta.icon, color: color, size: 28),
                        const SizedBox(width: 10),
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
                    const SizedBox(height: 12),

                    // 가격 (대형)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          product.priceString,
                          style: TextStyle(
                            color: color,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          meta.periodLabel,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                        if (meta.dailyPrice != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              meta.dailyPrice!,
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 기능 목록
                    ...meta.features.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.check, color: color, size: 14),
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

                    const SizedBox(height: 18),

                    // 구매 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ShadButton(
                        onPressed: isLoading ? null : onPurchase,
                        backgroundColor: color,
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                meta.badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
