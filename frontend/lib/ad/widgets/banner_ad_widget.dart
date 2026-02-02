/// Banner Ad Widget
/// 배너 광고를 표시하는 위젯
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../purchase/providers/purchase_provider.dart';
import '../../purchase/purchase_config.dart';
import '../ad_service.dart';

/// 배너 광고 위젯
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('[BannerAdWidget] didChangeDependencies called');
    _loadAd();
  }

  void _loadAd() {
    // 프리미엄 유저는 광고 로드 자체를 스킵
    final purchaseState = ref.read(purchaseNotifierProvider);
    final isPremium = purchaseState.valueOrNull?.entitlements
            .all[PurchaseConfig.entitlementPremium]?.isActive ==
        true;
    if (isPremium) return;

    final width = MediaQuery.of(context).size.width;
    debugPrint('[BannerAdWidget] Loading banner ad with width: $width');

    AdService.instance.loadBannerAd(
      width: width,
      onLoaded: (ad) {
        if (mounted) {
          setState(() {
            _bannerAd = ad;
            _isLoaded = true;
          });
        }
      },
      onFailed: (error) {
        debugPrint('[BannerAdWidget] Failed to load: ${error.message}');
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 프리미엄 유저는 배너 광고 숨김
    final purchaseState = ref.watch(purchaseNotifierProvider);
    final isPremium = purchaseState.valueOrNull?.entitlements
            .all[PurchaseConfig.entitlementPremium]?.isActive ==
        true;
    if (isPremium) return const SizedBox.shrink();

    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}

/// 하단 고정 배너 광고 위젯
class BottomBannerAdWidget extends StatelessWidget {
  const BottomBannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomCenter,
      child: BannerAdWidget(),
    );
  }
}
