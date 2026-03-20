import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadButton;

import '../../core/theme/app_theme.dart';
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
  /// accentColor 제거 → 테마 기반 통일 색상 사용
  /// .tr() 사용을 위해 static getter로 변경 (const 불가)
  static Map<String, _ProductMeta> get _productMeta => {
    PurchaseConfig.productDayPass: _ProductMeta(
      icon: Icons.bolt,
      badge: null,
      highlight: false,
      periodLabelKey: 'purchase.perDay',
      dailyPriceKey: null,
      featureKeys: [
        'purchase.featureNoAds',
        'purchase.featureAiUnlimitedChat',
        'purchase.feature24Hour',
      ],
    ),
    PurchaseConfig.productWeekPass: _ProductMeta(
      icon: Icons.star,
      badgeKey: 'purchase.badgePopular',
      highlight: true,
      periodLabelKey: 'purchase.perWeek',
      dailyPriceKey: 'purchase.dailyPriceWeek',
      featureKeys: [
        'purchase.featureNoAds',
        'purchase.featureAiUnlimitedChat',
        'purchase.feature7Day',
        'purchase.featureDayPassDiscount',
      ],
    ),
    PurchaseConfig.productMonthly: _ProductMeta(
      icon: Icons.diamond_outlined,
      badgeKey: 'purchase.badgeBest',
      highlight: false,
      periodLabelKey: 'purchase.perMonth',
      dailyPriceKey: 'purchase.dailyPriceMonth',
      featureKeys: [
        'purchase.featureNoAds',
        'purchase.featureAiUnlimitedChat',
        'purchase.feature30Day',
        'purchase.featureAutoRenewConvenient',
        'purchase.featureCheapestDailyDetail',
      ],
    ),
  };

  /// 상품 정렬 순서
  static const _productOrder = [
    PurchaseConfig.productDayPass,
    PurchaseConfig.productWeekPass,
    PurchaseConfig.productMonthly,
  ];

  /// 상품 identifier에서 메타 정보 찾기
  /// Google Play 구독은 "productId:basePlanId" 형태로 올 수 있음
  static _ProductMeta _findProductMeta(String identifier) {
    final meta = _productMeta;
    // 정확 매칭 우선
    if (meta.containsKey(identifier)) return meta[identifier]!;
    // prefix 매칭 (구독: sadam_monthly:sadam-monthly-default 등)
    for (final entry in meta.entries) {
      if (identifier.startsWith(entry.key)) return entry.value;
    }
    return _ProductMeta(
      icon: Icons.shopping_bag,
      badge: null,
      highlight: false,
      periodLabelKey: '',
      dailyPriceKey: null,
      featureKeys: [],
    );
  }

  /// 상품 정렬 인덱스 찾기 (prefix 매칭)
  static int _findProductIndex(String identifier) {
    for (int i = 0; i < _productOrder.length; i++) {
      if (identifier.startsWith(_productOrder[i])) return i;
    }
    return 999;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offeringsAsync = ref.watch(offeringsProvider);
    final purchaseState = ref.watch(purchaseNotifierProvider);
    final theme = context.appTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'purchase.title'.tr(),
          style: TextStyle(color: theme.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textPrimary),
      ),
      body: offeringsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'purchase.errorLoadProducts'.tr(),
                style: TextStyle(color: theme.textSecondary),
              ),
              const SizedBox(height: 16),
              ShadButton.outline(
                onPressed: () => ref.invalidate(offeringsProvider),
                child: Text(
                  'common.buttonRetry'.tr(),
                  style: TextStyle(color: theme.textPrimary),
                ),
              ),
            ],
          ),
        ),
        data: (offerings) {
          if (offerings == null || offerings.current == null) {
            return Center(
              child: Text(
                'purchase.productsLoading'.tr(),
                style: TextStyle(color: theme.textSecondary),
              ),
            );
          }

          final packages = offerings.current!.availablePackages;
          final isLoading = purchaseState is AsyncLoading;

          // 상품 정렬 (구독 상품은 identifier가 "productId:basePlanId" 형태일 수 있음)
          final sorted = List<Package>.from(packages)
            ..sort((a, b) {
              final ai = _findProductIndex(a.storeProduct.identifier);
              final bi = _findProductIndex(b.storeProduct.identifier);
              return ai.compareTo(bi);
            });

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 헤더 아이콘
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.accentColor ?? theme.primaryColor.withValues(alpha: 0.7),
                    ],
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.workspace_premium,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // 헤더
                Text(
                  'purchase.premiumPass'.tr(),
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'purchase.premiumSubtitle'.tr(),
                  style: TextStyle(color: theme.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // 구매 즉시 적용 Chip
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flash_on, color: theme.primaryColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'purchase.instantApply'.tr(),
                          style: TextStyle(
                            color: theme.textSecondary,
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
                        meta: _findProductMeta(pkg.storeProduct.identifier),
                        isLoading: isLoading,
                        onPurchase: () => _handlePurchase(context, ref, pkg),
                        theme: theme,
                      ),
                    )),

                const SizedBox(height: 16),

                // 구매 복원 버튼
                const RestoreButtonWidget(),

                const SizedBox(height: 24),

                // 안내 문구
                Text(
                  'purchase.termsAutoRenew'.tr(),
                  style: TextStyle(color: theme.textMuted, fontSize: 11),
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
            title: Text('purchase.purchaseFailed'.tr()),
            content: Text('${purchaseState.error}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('common.buttonConfirm'.tr()),
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
            title: Row(
              children: [
                const Icon(Icons.workspace_premium, color: Color(0xFFD4AF37)),
                const SizedBox(width: 8),
                Text('purchase.premiumApplied'.tr()),
              ],
            ),
            content: Text('purchase.premiumAppliedSubtitle'.tr()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  Navigator.of(context).pop(); // PaywallScreen 닫기
                },
                child: Text('common.buttonConfirm'.tr()),
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
            title: Text('purchase.purchaseProcessing'.tr()),
            content: Text('purchase.purchaseProcessingMessage'.tr()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text('common.buttonConfirm'.tr()),
              ),
            ],
          ),
        );
      }
    }
  }
}

/// 상품 메타 정보
/// accentColor 제거 → 테마 기반 통일 색상 사용
/// .tr() 사용을 위해 i18n 키를 저장하고, 표시 시점에 tr() 호출
class _ProductMeta {
  final IconData icon;
  /// badge 텍스트: null이면 뱃지 없음, 아니면 .tr() 키
  final String? badge;
  /// badge i18n 키 (별도 저장, badge는 null 기반 분기용)
  final String? badgeKey;
  final bool highlight;
  final String periodLabelKey;
  final String? dailyPriceKey;
  final List<String> featureKeys;

  _ProductMeta({
    required this.icon,
    this.badge,
    this.badgeKey,
    required this.highlight,
    required this.periodLabelKey,
    this.dailyPriceKey,
    required this.featureKeys,
  });

  String get periodLabel => periodLabelKey.isEmpty ? '' : periodLabelKey.tr();
  String? get dailyPrice => dailyPriceKey?.tr();
  List<String> get features => featureKeys.map((k) => k.tr()).toList();
  String? get badgeText => badgeKey?.tr();
  bool get hasBadge => badgeKey != null || badge != null;
}

/// 상품 카드 위젯
/// 테마 기반 통일 색상 사용
class _ProductCard extends StatelessWidget {
  final Package package;
  final _ProductMeta meta;
  final bool isLoading;
  final VoidCallback onPurchase;
  final AppThemeExtension theme;

  const _ProductCard({
    required this.package,
    required this.meta,
    required this.isLoading,
    required this.onPurchase,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;
    final primaryColor = theme.primaryColor;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border.all(
              color: meta.highlight
                  ? primaryColor
                  : theme.border,
              width: meta.highlight ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 gradient 바
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.6),
                      primaryColor,
                      primaryColor.withValues(alpha: 0.6),
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
                        Icon(meta.icon, color: primaryColor, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            product.title.replaceAll(RegExp(r'\s*\(.*\)'), ''),
                            style: TextStyle(
                              color: theme.textPrimary,
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
                            color: primaryColor,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          meta.periodLabel,
                          style: TextStyle(
                            color: theme.textMuted,
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
                              color: primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              meta.dailyPrice!,
                              style: TextStyle(
                                color: primaryColor,
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
                              Icon(Icons.check, color: primaryColor, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                f,
                                style: TextStyle(
                                  color: theme.textSecondary,
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
                        backgroundColor: primaryColor,
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
                                    ? 'purchase.subscribe'.tr()
                                    : 'purchase.purchase'.tr(),
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
        if (meta.hasBadge)
          Positioned(
            top: 0,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                meta.badgeText ?? '',
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
