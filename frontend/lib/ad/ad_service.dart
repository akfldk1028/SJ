/// 멀티 네트워크 광고 서비스 (어댑터 오케스트레이터)
///
/// AdNetworkAdapter 리스트를 우선순위 순으로 순회하며 fallback 처리.
/// 새 네트워크 추가 = 어댑터 1개 구현 + _adapters 등록. 끝.
///
/// Fallback 순서:
///   AdMob(+미디에이션) → UnityAds(직접)
/// AdFit은 배너/네이티브 전용 (전면/보상형에 포함하지 않음)
///
/// 배너/네이티브는 기존 방식 유지 (어댑터 대상 아님).
library;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/services/posthog_service.dart';
import 'ad_config.dart';
import 'ad_tracking_service.dart';
import 'adapters/ad_network_adapter.dart';
import 'adapters/admob_adapter.dart';
import 'adapters/unity_ads_adapter.dart';
import 'feature_unlock_service.dart';

/// 광고 서비스 싱글톤
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _isInitialized = false;
  DateTime? _lastInterstitialTime;

  // 어댑터 리스트 (우선순위 순)
  final List<AdNetworkAdapter> _adapters = [];

  // 배너 광고 (어댑터 미적용 — AdMob 전용)
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isBannerLoaded => _isBannerLoaded;
  BannerAd? get bannerAd => _bannerAd;

  /// 전면 광고 로드 여부 (어댑터 중 하나라도 로드됐으면 true)
  bool get isInterstitialLoaded =>
      _adapters.any((a) => a.isInterstitialLoaded);

  /// 보상형 광고 로드 여부 (어댑터 중 하나라도 로드됐으면 true)
  bool get isRewardedLoaded => _adapters.any((a) => a.isRewardedLoaded);

  /// SDK 초기화 + 어댑터 등록
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (!adEnabled) {
      debugPrint('[AdService] Ad kill switch OFF — skipping init');
      return;
    }

    // 에뮬레이터 감지 → 테스트 광고 자동 전환
    await AdModeResolver.init();

    // 어댑터 등록 (우선순위 순)
    // AdFit은 배너/네이티브 전용 — 전면/보상형 fallback에 포함하지 않음
    _adapters.addAll([
      AdMobAdapter(), // 1순위: AdMob (+Liftoff/Mintegral bidding 미디에이션)
      UnityAdsAdapter(), // 2순위: Unity Ads 직접 SDK (Bidding→직접 전환 완료 2026-03-15)
      // VungleAdapter(), // TODO: Liftoff SDK 네이티브 브릿지 구현 후 활성화
    ]);

    // 전체 SDK 병렬 초기화
    await Future.wait(_adapters.map((a) => a.initialize()));

    _isInitialized = true;
    debugPrint(
        '[AdService] Initialized with ${_adapters.length} adapters: '
        '${_adapters.map((a) => a.name).join(', ')}');
  }

  // ==================== Banner Ad (기존 유지) ====================

  /// 배너 광고 로드
  Future<void> loadBannerAd({
    required double width,
    void Function(BannerAd)? onLoaded,
    void Function(LoadAdError)? onFailed,
  }) async {
    if (!adEnabled) return;

    await _bannerAd?.dispose();
    _isBannerLoaded = false;

    final adSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width.truncate(),
    );

    if (adSize == null) {
      debugPrint('[AdService] Failed to get adaptive banner size');
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: AdUnitId.banner,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('[AdService] Banner loaded');
          _isBannerLoaded = true;
          onLoaded?.call(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdService] Banner failed: ${error.message}');
          ad.dispose();
          _bannerAd = null;
          _isBannerLoaded = false;
          onFailed?.call(error);
        },
        onAdOpened: (ad) {
          debugPrint('[AdService] Banner opened');
        },
        onAdClosed: (ad) {
          debugPrint('[AdService] Banner closed');
        },
        onAdImpression: (ad) {
          debugPrint('[AdService] Banner impression');
          AdTrackingService.instance.trackBannerImpression();
        },
        onAdClicked: (ad) {
          debugPrint('[AdService] Banner clicked');
          AdTrackingService.instance.trackBannerClick();
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          debugPrint(
              '[AdService] Banner paid: $valueMicros micros ($currencyCode)');
          AdTrackingService.instance.trackAdRevenue(
            adType: AdType.banner,
            valueMicros: valueMicros,
            precision: precision.name,
            currencyCode: currencyCode,
          );
        },
      ),
    );

    await _bannerAd!.load();
  }

  /// 배너 광고 해제
  void disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerLoaded = false;
  }

  // ==================== Interstitial Ad ====================

  /// 전면 광고 로드 (모든 어댑터 병렬)
  Future<void> loadInterstitialAd({
    void Function()? onLoaded,
    void Function(LoadAdError)? onFailed,
  }) async {
    if (!adEnabled) return;

    for (final adapter in _adapters) {
      adapter.loadInterstitial();
    }
  }

  /// 전면 광고 표시
  ///
  /// [onDismissed] 광고 닫힌 후 콜백 (토큰 충전 등)
  /// [bypassInterval] true면 최소 간격 무시 (토큰 소진 필수 광고)
  Future<bool> showInterstitialAd({
    void Function()? onDismissed,
    bool bypassInterval = false,
  }) async {
    if (!adEnabled) return false;

    // 최소 간격 체크
    if (!bypassInterval && _lastInterstitialTime != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialTime!);
      if (elapsed.inSeconds < AdSettings.interstitialMinInterval) {
        debugPrint(
            '[AdService] Interstitial skipped: interval ${elapsed.inSeconds}s < ${AdSettings.interstitialMinInterval}s');
        return false;
      }
    }

    // 우선순위 순으로 어댑터 시도
    for (final adapter in _adapters) {
      if (adapter.isInterstitialLoaded) {
        final shown =
            await adapter.showInterstitial(onDismissed: onDismissed);
        if (shown) {
          _lastInterstitialTime = DateTime.now();
          PosthogService.trackEvent('ad_watched', {
            'ad_type': 'interstitial',
            'network': adapter.name,
          });
          debugPrint('[AdService] ${adapter.name} interstitial shown');
          return true;
        }
      }
    }

    debugPrint('[AdService] Interstitial not ready (all adapters)');
    return false;
  }

  /// 전면 광고 로드 대기 (최대 timeout)
  ///
  /// 모든 어댑터에 로드 요청 후, 아무 어댑터라도 로드 완료되면 반환.
  Future<bool> waitForInterstitialLoad({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (isInterstitialLoaded) return true;

    // 모든 어댑터에 로드 요청
    loadInterstitialAd();

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (isInterstitialLoaded) {
        debugPrint(
            '[AdService] Interstitial ready: '
            '${_adapters.firstWhere((a) => a.isInterstitialLoaded).name}');
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return isInterstitialLoaded;
  }

  // ==================== Rewarded Ad ====================

  /// 보상형 광고 로드 (모든 어댑터 병렬)
  Future<void> loadRewardedAd({
    void Function()? onLoaded,
    void Function(LoadAdError)? onFailed,
  }) async {
    if (!adEnabled) {
      debugPrint('[AdService] Ad kill switch OFF — skipping rewarded load');
      return;
    }

    for (final adapter in _adapters) {
      adapter.loadRewarded();
    }
  }

  /// 보상형 광고 표시 (기본)
  ///
  /// [screen]: 광고가 표시된 화면 (ad_events.screen에 기록)
  /// [purpose]: 광고 목적 (ad_events.purpose에 기록, 기본: general)
  Future<bool> showRewardedAd({
    required void Function(int amount, String type) onRewarded,
    String? screen,
    AdPurpose purpose = AdPurpose.general,
  }) async {
    return showRewardedAdWithUnlock(
      onRewarded: onRewarded,
      overrideScreen: screen,
      overridePurpose: purpose,
    );
  }

  /// 보상형 광고 표시 + 기능 해금 추적
  Future<bool> showRewardedAdWithUnlock({
    required void Function(int amount, String type) onRewarded,
    FeatureType? featureType,
    String? featureKey,
    int? targetYear,
    int? targetMonth,
    String? profileId,
    String? overrideScreen,
    AdPurpose? overridePurpose,
  }) async {
    if (!adEnabled) return false;

    // screen 문자열 생성 (추적용)
    // overrideScreen이 있으면 우선 사용 (token_depleted 등 직접 지정)
    String? screen = overrideScreen;
    if (screen == null && featureType != null && featureKey != null && targetYear != null) {
      screen = '${featureType.toDbString()}_${featureKey}_$targetYear';
      if (targetMonth != null && targetMonth > 0) {
        screen += '_${targetMonth.toString().padLeft(2, '0')}';
      }
    }

    // purpose 결정: override > featureType 기반 > general
    final purpose = overridePurpose
        ?? (featureType != null ? AdPurpose.featureUnlock : AdPurpose.general);

    // 우선순위 순으로 어댑터 시도
    for (final adapter in _adapters) {
      if (adapter.isRewardedLoaded) {
        final shown = await adapter.showRewarded(
          screen: screen,
          onRewarded: (amount, type) async {
            debugPrint(
                '[AdService] Reward earned via ${adapter.name}: $amount $type');

            // 1. 광고 이벤트 추적
            final adEventId =
                await AdTrackingService.instance.trackRewarded(
              rewardAmount: amount,
              rewardType: type,
              screen: screen,
              profileId: profileId,
              purpose: purpose,
            );

            // 2. 기능 해금
            if (featureType != null &&
                featureKey != null &&
                targetYear != null) {
              await FeatureUnlockService.instance.unlockByRewardedAd(
                featureType: featureType,
                featureKey: featureKey,
                targetYear: targetYear,
                targetMonth: targetMonth ?? 0,
                rewardAmount: amount,
                rewardType: type,
                adEventId: adEventId,
                profileId: profileId,
              );
            }

            // 3. 유저 콜백
            onRewarded(amount, type);
          },
        );
        if (shown) {
          debugPrint('[AdService] ${adapter.name} rewarded shown');
          return true;
        }
      }
    }

    debugPrint('[AdService] Rewarded not ready (all adapters)');
    return false;
  }

  /// 보상형 광고 로드 대기 (최대 timeout)
  Future<bool> waitForRewardedLoad({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (isRewardedLoaded) return true;

    loadRewardedAd();

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (isRewardedLoaded) return true;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return isRewardedLoaded;
  }

  // ==================== Cleanup ====================

  /// 모든 광고 해제
  void disposeAll() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerLoaded = false;

    for (final adapter in _adapters) {
      adapter.dispose();
    }
  }
}
