/// AdMob 어댑터
///
/// 기존 AdService의 AdMob 전면/보상형 로직을 AdNetworkAdapter로 래핑.
/// AdMob 미디에이션(Liftoff, Unity bidding) 포함.
/// 네트워크별 트래킹(onPaidEvent, impression, click)은 어댑터 내부에서 처리.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ad_config.dart';
import '../ad_tracking_service.dart';
import 'ad_network_adapter.dart';

class AdMobAdapter implements AdNetworkAdapter {
  @override
  String get name => 'AdMob';

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isInterstitialLoaded = false;
  bool _isRewardedLoaded = false;

  // 보류 중인 콜백 (show 시 설정, dismiss 시 호출)
  void Function()? _pendingInterstitialDismissed;

  // 보류 중인 screen (show 시 설정, 콜백에서 사용)
  String? _pendingInterstitialScreen;
  String? _pendingRewardedScreen;

  // 보상형 광고 dismiss 대기 Completer
  Completer<void>? _rewardedDismissCompleter;

  @override
  bool get isInterstitialLoaded => _isInterstitialLoaded;

  @override
  bool get isRewardedLoaded => _isRewardedLoaded;

  @override
  Future<void> initialize() async {
    try {
      final status = await MobileAds.instance.initialize();
      status.adapterStatuses.forEach((key, value) {
        debugPrint('[AdMobAdapter] Adapter $key: ${value.description}');
      });
      debugPrint('[AdMobAdapter] SDK initialized');
    } catch (e) {
      debugPrint('[AdMobAdapter] SDK init failed: $e');
    }
  }

  // ==================== Interstitial ====================

  @override
  Future<bool> loadInterstitial() async {
    await InterstitialAd.load(
      adUnitId: AdUnitId.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdMobAdapter] Interstitial loaded');
          _interstitialAd = ad;
          _isInterstitialLoaded = true;

          // 수익 추적
          ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            debugPrint(
                '[AdMobAdapter] Interstitial paid: $valueMicros micros ($currencyCode)');
            AdTrackingService.instance.trackAdRevenue(
              adType: AdType.interstitial,
              valueMicros: valueMicros,
              precision: precision.name,
              currencyCode: currencyCode,
            );
          };

          // 풀스크린 콘텐츠 콜백
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              debugPrint('[AdMobAdapter] Interstitial showed');
              AdTrackingService.instance.trackInterstitialShow(screen: _pendingInterstitialScreen);
            },
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('[AdMobAdapter] Interstitial dismissed');
              AdTrackingService.instance.trackInterstitialComplete(screen: _pendingInterstitialScreen);
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialLoaded = false;
              _pendingInterstitialDismissed?.call();
              _pendingInterstitialDismissed = null;
              _pendingInterstitialScreen = null;
              // 자동 재로드
              loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint(
                  '[AdMobAdapter] Interstitial failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialLoaded = false;
              _pendingInterstitialDismissed?.call(); // show 실패해도 콜백 호출
              _pendingInterstitialDismissed = null;
              _pendingInterstitialScreen = null;
              loadInterstitial();
            },
            onAdImpression: (ad) {
              debugPrint('[AdMobAdapter] Interstitial impression');
            },
            onAdClicked: (ad) {
              debugPrint('[AdMobAdapter] Interstitial clicked');
              AdTrackingService.instance.trackInterstitialClick();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint(
              '[AdMobAdapter] Interstitial failed: ${error.message}');
          debugPrint(
              '[AdMobAdapter] error code: ${error.code}, domain: ${error.domain}');
          debugPrint(
              '[AdMobAdapter] responseInfo: ${error.responseInfo}');
          _isInterstitialLoaded = false;
        },
      ),
    );
    return true;
  }

  @override
  Future<bool> showInterstitial({void Function()? onDismissed, String? screen}) async {
    if (!_isInterstitialLoaded || _interstitialAd == null) return false;

    _pendingInterstitialDismissed = onDismissed;
    _pendingInterstitialScreen = screen;
    await _interstitialAd!.show();
    return true;
  }

  // ==================== Rewarded ====================

  @override
  Future<bool> loadRewarded() async {
    await RewardedAd.load(
      adUnitId: AdUnitId.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdMobAdapter] Rewarded loaded');
          _rewardedAd = ad;
          _isRewardedLoaded = true;

          // 수익 추적
          ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            debugPrint(
                '[AdMobAdapter] Rewarded paid: $valueMicros micros ($currencyCode)');
            AdTrackingService.instance.trackAdRevenue(
              adType: AdType.rewarded,
              valueMicros: valueMicros,
              precision: precision.name,
              currencyCode: currencyCode,
            );
          };

          // 풀스크린 콘텐츠 콜백
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              debugPrint('[AdMobAdapter] Rewarded showed');
              AdTrackingService.instance.trackRewardedShow(screen: _pendingRewardedScreen);
            },
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('[AdMobAdapter] Rewarded dismissed');
              AdTrackingService.instance.trackRewardedComplete(screen: _pendingRewardedScreen);
              ad.dispose();
              _rewardedAd = null;
              _isRewardedLoaded = false;
              _pendingRewardedScreen = null;
              if (!(_rewardedDismissCompleter?.isCompleted ?? true)) {
                _rewardedDismissCompleter?.complete();
              }
              // 지연 후 재로드
              Future.delayed(
                const Duration(seconds: AdSettings.rewardedReloadDelay),
                () => loadRewarded(),
              );
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint(
                  '[AdMobAdapter] Rewarded failed to show: $error');
              ad.dispose();
              _rewardedAd = null;
              _isRewardedLoaded = false;
              _pendingRewardedScreen = null;
              if (!(_rewardedDismissCompleter?.isCompleted ?? true)) {
                _rewardedDismissCompleter?.complete();
              }
            },
            onAdImpression: (ad) {
              debugPrint('[AdMobAdapter] Rewarded impression');
            },
            onAdClicked: (ad) {
              debugPrint('[AdMobAdapter] Rewarded clicked');
              AdTrackingService.instance.trackRewardedClick();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMobAdapter] Rewarded failed: ${error.message}');
          debugPrint(
              '[AdMobAdapter] error code: ${error.code}, domain: ${error.domain}');
          debugPrint(
              '[AdMobAdapter] responseInfo: ${error.responseInfo}');
          _isRewardedLoaded = false;
        },
      ),
    );
    return true;
  }

  @override
  Future<bool> showRewarded({
    required void Function(int amount, String type) onRewarded,
    String? screen,
  }) async {
    if (!_isRewardedLoaded || _rewardedAd == null) return false;

    _pendingRewardedScreen = screen;
    _rewardedDismissCompleter = Completer<void>();

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint(
            '[AdMobAdapter] User earned: ${reward.amount} ${reward.type}');
        onRewarded(reward.amount.toInt(), reward.type);
      },
    );

    // 광고 dismiss/실패 후에야 리턴 → 호출자가 rewardGranted 정확히 판단
    await _rewardedDismissCompleter!.future;
    return true;
  }

  // ==================== Lifecycle ====================

  @override
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
    _isInterstitialLoaded = false;
    _isRewardedLoaded = false;
    _pendingInterstitialDismissed = null;
    _pendingInterstitialScreen = null;
    _pendingRewardedScreen = null;
  }
}
