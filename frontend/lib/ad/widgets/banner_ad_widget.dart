/// Banner Ad Widget
/// 배너 광고를 표시하는 위젯
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../purchase/providers/purchase_provider.dart';
import '../ad_config.dart';
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
  bool _loadAttempted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('[BannerAdWidget] didChangeDependencies called');
    _loadAd();
  }

  void _loadAd() {
    if (!adEnabled) return;

    // 프리미엄 유저는 광고 로드 자체를 스킵
    final isPremium = ref.read(purchaseNotifierProvider.notifier).isPremium;
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
    if (!adEnabled) return const SizedBox.shrink();

    // 프리미엄 유저는 배너 광고 숨김 + 로드된 광고 해제
    ref.watch(purchaseNotifierProvider); // 상태 변경 감지용
    final isPremium = ref.read(purchaseNotifierProvider.notifier).isPremium;
    if (isPremium) {
      // 이미 로드된 배너가 있으면 해제
      if (_bannerAd != null) {
        _bannerAd?.dispose();
        _bannerAd = null;
        _isLoaded = false;
      }
      _loadAttempted = false; // 프리미엄 해제 시 재로드 가능하도록 리셋
      return const SizedBox.shrink();
    }

    if (!_isLoaded || _bannerAd == null) {
      // 프리미엄 만료 후 광고 재로드
      if (!_loadAttempted && _bannerAd == null) {
        _loadAttempted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadAd();
        });
      }
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
