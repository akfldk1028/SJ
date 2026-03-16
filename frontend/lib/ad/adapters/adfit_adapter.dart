/// AdFit 어댑터
///
/// 기존 AdFitService(MethodChannel)를 AdNetworkAdapter로 래핑.
/// 전면 광고만 지원 (보상형 없음).
/// AdFitService 자체는 변경 없음.
library;

import '../ad_network_resolver.dart';
import '../adfit/adfit_service.dart';
import 'ad_network_adapter.dart';

class AdFitAdapter implements AdNetworkAdapter {
  bool _available = false;

  @override
  String get name => 'AdFit';

  @override
  Future<void> initialize() async {
    if (!AdNetworkResolver.isAdFitAvailable) return;
    _available = true;
    AdFitService.instance.initialize();
  }

  // ==================== Interstitial ====================

  @override
  bool get isInterstitialLoaded =>
      _available && AdFitService.instance.isInterstitialLoaded;

  @override
  Future<bool> loadInterstitial() async {
    if (!_available) return false;
    AdFitService.instance.loadInterstitial();
    return true;
  }

  @override
  Future<bool> showInterstitial({void Function()? onDismissed}) async {
    if (!_available || !isInterstitialLoaded) return false;
    return AdFitService.instance.showInterstitial(onDismissed: onDismissed);
  }

  // ==================== Rewarded (미지원) ====================

  @override
  bool get isRewardedLoaded => false;

  @override
  Future<bool> loadRewarded() async => false;

  @override
  Future<bool> showRewarded({
    required void Function(int amount, String type) onRewarded,
  }) async => false;

  // ==================== Lifecycle ====================

  @override
  void dispose() {
    if (_available) AdFitService.instance.dispose();
  }
}
