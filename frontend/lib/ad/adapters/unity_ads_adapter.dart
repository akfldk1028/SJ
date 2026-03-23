/// Unity Ads 직접 어댑터
///
/// AdMob 미디에이션 없이 Unity Ads SDK 직접 호출.
/// AdMob 제한 시에도 독립적으로 광고 제공.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import '../ad_tracking_service.dart';
import 'ad_network_adapter.dart';
import 'unity_ads_config.dart';

class UnityAdsAdapter implements AdNetworkAdapter {
  bool _initialized = false;
  bool _isInterstitialLoaded = false;
  bool _isRewardedLoaded = false;

  @override
  String get name => 'UnityAds';

  @override
  bool get isInterstitialLoaded => _isInterstitialLoaded;

  @override
  bool get isRewardedLoaded => _isRewardedLoaded;

  @override
  Future<void> initialize() async {
    final completer = Completer<void>();

    UnityAds.init(
      gameId: UnityAdsConfig.gameId,
      testMode: kDebugMode,
      onComplete: () {
        _initialized = true;
        debugPrint('[UnityAds] Initialized (gameId: ${UnityAdsConfig.gameId})');
        completer.complete();
      },
      onFailed: (error, message) {
        debugPrint('[UnityAds] Init failed: $error — $message');
        completer.complete(); // 실패해도 블로킹하지 않음
      },
    );

    await completer.future;
  }

  // ==================== Interstitial ====================

  @override
  Future<bool> loadInterstitial() async {
    if (!_initialized) return false;

    UnityAds.load(
      placementId: UnityAdsConfig.interstitial,
      onComplete: (placementId) {
        _isInterstitialLoaded = true;
        debugPrint('[UnityAds] Interstitial loaded ($placementId)');
      },
      onFailed: (placementId, error, message) {
        _isInterstitialLoaded = false;
        debugPrint(
            '[UnityAds] Interstitial load failed: $error — $message');
      },
    );
    return true;
  }

  @override
  Future<bool> showInterstitial({void Function()? onDismissed, String? screen}) async {
    if (!_isInterstitialLoaded) return false;
    _isInterstitialLoaded = false;

    UnityAds.showVideoAd(
      placementId: UnityAdsConfig.interstitial,
      onStart: (placementId) {
        debugPrint('[UnityAds] Interstitial started');
        AdTrackingService.instance.trackInterstitialShow(screen: screen);
      },
      onClick: (placementId) {
        debugPrint('[UnityAds] Interstitial clicked');
        AdTrackingService.instance.trackInterstitialClick(screen: screen);
      },
      onComplete: (placementId) {
        debugPrint('[UnityAds] Interstitial completed');
        AdTrackingService.instance.trackInterstitialComplete(screen: screen);
        onDismissed?.call();
        loadInterstitial(); // 자동 재로드
      },
      onSkipped: (placementId) {
        debugPrint('[UnityAds] Interstitial skipped');
        AdTrackingService.instance.trackInterstitialComplete(screen: screen);
        onDismissed?.call();
        loadInterstitial();
      },
      onFailed: (placementId, error, message) {
        debugPrint('[UnityAds] Interstitial show failed: $error — $message');
        onDismissed?.call(); // show 실패해도 콜백 호출 (토큰 지급 누락 방지)
        loadInterstitial();
      },
    );
    return true;
  }

  // ==================== Rewarded ====================

  @override
  Future<bool> loadRewarded() async {
    if (!_initialized) return false;

    UnityAds.load(
      placementId: UnityAdsConfig.rewarded,
      onComplete: (placementId) {
        _isRewardedLoaded = true;
        debugPrint('[UnityAds] Rewarded loaded ($placementId)');
      },
      onFailed: (placementId, error, message) {
        _isRewardedLoaded = false;
        debugPrint('[UnityAds] Rewarded load failed: $error — $message');
      },
    );
    return true;
  }

  @override
  Future<bool> showRewarded({
    required void Function(int amount, String type) onRewarded,
    String? screen,
  }) async {
    if (!_isRewardedLoaded) return false;
    _isRewardedLoaded = false;

    // Completer: 광고 종료(완료/스킵/실패) 후에야 리턴
    // → 호출자가 rewardGranted 플래그를 정확히 판단 가능
    final completer = Completer<void>();

    UnityAds.showVideoAd(
      placementId: UnityAdsConfig.rewarded,
      onStart: (placementId) {
        debugPrint('[UnityAds] Rewarded started');
        AdTrackingService.instance.trackRewardedShow(screen: screen);
      },
      onClick: (placementId) {
        debugPrint('[UnityAds] Rewarded clicked');
        AdTrackingService.instance.trackRewardedClick(screen: screen);
      },
      onComplete: (placementId) {
        debugPrint('[UnityAds] Rewarded completed — granting reward');
        AdTrackingService.instance.trackRewardedComplete(screen: screen);
        onRewarded(1, 'unity_reward');
        loadRewarded();
        if (!completer.isCompleted) completer.complete();
      },
      onSkipped: (placementId) {
        debugPrint('[UnityAds] Rewarded skipped — no reward');
        loadRewarded();
        if (!completer.isCompleted) completer.complete();
      },
      onFailed: (placementId, error, message) {
        debugPrint('[UnityAds] Rewarded show failed: $error — $message');
        loadRewarded();
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future;
    return true;
  }

  // ==================== Lifecycle ====================

  @override
  void dispose() {
    _isInterstitialLoaded = false;
    _isRewardedLoaded = false;
  }
}
