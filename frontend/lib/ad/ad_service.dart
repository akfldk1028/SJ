/// AdMob Service
/// 광고 초기화, 로딩, 표시를 담당하는 서비스
library;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'ad_tracking_service.dart';
import 'feature_unlock_service.dart';

/// 광고 서비스 싱글톤
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _isInitialized = false;
  DateTime? _lastInterstitialTime;

  // 광고 인스턴스
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // 광고 로드 상태
  bool _isBannerLoaded = false;
  bool _isInterstitialLoaded = false;
  bool _isRewardedLoaded = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isBannerLoaded => _isBannerLoaded;
  bool get isInterstitialLoaded => _isInterstitialLoaded;
  bool get isRewardedLoaded => _isRewardedLoaded;
  BannerAd? get bannerAd => _bannerAd;

  /// SDK 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final status = await MobileAds.instance.initialize();
      _isInitialized = true;

      // 어댑터 상태 로깅
      status.adapterStatuses.forEach((key, value) {
        debugPrint('[AdService] Adapter $key: ${value.description}');
      });

      debugPrint('[AdService] SDK initialized successfully');
    } catch (e) {
      debugPrint('[AdService] SDK initialization failed: $e');
    }
  }

  // ==================== Banner Ad ====================

  /// 배너 광고 로드
  Future<void> loadBannerAd({
    required double width,
    void Function(BannerAd)? onLoaded,
    void Function(LoadAdError)? onFailed,
  }) async {
    // 기존 배너 정리
    await _bannerAd?.dispose();
    _isBannerLoaded = false;

    // Adaptive 크기 가져오기
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
          debugPrint('[AdService] Banner ad loaded');
          _isBannerLoaded = true;
          onLoaded?.call(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdService] Banner ad failed: ${error.message}');
          ad.dispose();
          _bannerAd = null;
          _isBannerLoaded = false;
          onFailed?.call(error);
        },
        onAdOpened: (ad) {
          debugPrint('[AdService] Banner ad opened');
        },
        onAdClosed: (ad) {
          debugPrint('[AdService] Banner ad closed');
        },
        onAdImpression: (ad) {
          debugPrint('[AdService] Banner ad impression');
          AdTrackingService.instance.trackBannerImpression();
        },
        onAdClicked: (ad) {
          debugPrint('[AdService] Banner ad clicked');
          AdTrackingService.instance.trackBannerClick();
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

  /// 전면 광고 로드
  Future<void> loadInterstitialAd({
    void Function()? onLoaded,
    void Function(LoadAdError)? onFailed,
  }) async {
    await InterstitialAd.load(
      adUnitId: AdUnitId.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdService] Interstitial ad loaded');
          _interstitialAd = ad;
          _isInterstitialLoaded = true;

          // 전면 광고 콜백 설정
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              debugPrint('[AdService] Interstitial showed');
              AdTrackingService.instance.trackInterstitialShow();
            },
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('[AdService] Interstitial dismissed');
              AdTrackingService.instance.trackInterstitialComplete();
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialLoaded = false;
              // 자동 재로드
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('[AdService] Interstitial failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialLoaded = false;
              // 표시 실패 시에도 재로드 → 다음 기회에 사용 가능
              loadInterstitialAd();
            },
            onAdImpression: (ad) {
              debugPrint('[AdService] Interstitial impression');
            },
            onAdClicked: (ad) {
              debugPrint('[AdService] Interstitial clicked');
              AdTrackingService.instance.trackInterstitialClick();
            },
          );

          onLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] Interstitial failed to load: ${error.message}');
          _isInterstitialLoaded = false;
          onFailed?.call(error);
        },
      ),
    );
  }

  /// 전면 광고 표시
  Future<bool> showInterstitialAd() async {
    // 최소 간격 체크
    if (_lastInterstitialTime != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialTime!);
      if (elapsed.inSeconds < AdSettings.interstitialMinInterval) {
        debugPrint(
            '[AdService] Interstitial skipped: interval ${elapsed.inSeconds}s < ${AdSettings.interstitialMinInterval}s');
        return false;
      }
    }

    if (!_isInterstitialLoaded || _interstitialAd == null) {
      debugPrint('[AdService] Interstitial not ready');
      return false;
    }

    _lastInterstitialTime = DateTime.now();
    await _interstitialAd!.show();
    return true;
  }

  // ==================== Rewarded Ad ====================

  /// 보상형 광고 로드
  Future<void> loadRewardedAd({
    void Function()? onLoaded,
    void Function(LoadAdError)? onFailed,
  }) async {
    await RewardedAd.load(
      adUnitId: AdUnitId.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdService] Rewarded ad loaded');
          _rewardedAd = ad;
          _isRewardedLoaded = true;

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              debugPrint('[AdService] Rewarded showed');
              AdTrackingService.instance.trackRewardedShow();
            },
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('[AdService] Rewarded dismissed');
              AdTrackingService.instance.trackRewardedComplete();
              ad.dispose();
              _rewardedAd = null;
              _isRewardedLoaded = false;
              // 지연 후 재로드
              Future.delayed(
                const Duration(seconds: AdSettings.rewardedReloadDelay),
                () => loadRewardedAd(),
              );
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('[AdService] Rewarded failed to show: $error');
              ad.dispose();
              _rewardedAd = null;
              _isRewardedLoaded = false;
            },
            onAdImpression: (ad) {
              debugPrint('[AdService] Rewarded impression');
            },
            onAdClicked: (ad) {
              debugPrint('[AdService] Rewarded clicked');
              AdTrackingService.instance.trackRewardedClick();
            },
          );

          onLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] Rewarded failed to load: ${error.message}');
          _isRewardedLoaded = false;
          onFailed?.call(error);
        },
      ),
    );
  }

  /// 보상형 광고 표시 (기본)
  /// [onRewarded] 보상 지급 콜백 (보상 금액, 보상 타입)
  Future<bool> showRewardedAd({
    required void Function(int amount, String type) onRewarded,
  }) async {
    return showRewardedAdWithUnlock(onRewarded: onRewarded);
  }

  /// 보상형 광고 표시 + 기능 해금 추적
  ///
  /// [onRewarded] 보상 지급 콜백
  /// [featureType] 해금할 기능 유형 (null이면 해금 없이 광고만)
  /// [featureKey] 해금할 기능 키 (career, love 등)
  /// [targetYear] 대상 연도
  /// [targetMonth] 대상 월 (연간은 0)
  /// [profileId] 현재 활성 프로필 ID
  Future<bool> showRewardedAdWithUnlock({
    required void Function(int amount, String type) onRewarded,
    FeatureType? featureType,
    String? featureKey,
    int? targetYear,
    int? targetMonth,
    String? profileId,
  }) async {
    if (!_isRewardedLoaded || _rewardedAd == null) {
      debugPrint('[AdService] Rewarded not ready');
      return false;
    }

    // screen 문자열 생성 (추적용)
    String? screen;
    if (featureType != null && featureKey != null && targetYear != null) {
      screen = '${featureType.toDbString()}_${featureKey}_$targetYear';
      if (targetMonth != null && targetMonth > 0) {
        screen += '_${targetMonth.toString().padLeft(2, '0')}';
      }
    }

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) async {
        debugPrint(
            '[AdService] User earned reward: ${reward.amount} ${reward.type}');

        // 1. 광고 이벤트 추적 (ad_events 테이블)
        // featureType이 있으면 잠금해제 목적, 없으면 일반
        final adEventId = await AdTrackingService.instance.trackRewarded(
          rewardAmount: reward.amount.toInt(),
          rewardType: reward.type,
          screen: screen,
          profileId: profileId,
          purpose: featureType != null
              ? AdPurpose.featureUnlock
              : AdPurpose.general,
        );

        // 2. 기능 해금 (feature_unlocks 테이블)
        if (featureType != null &&
            featureKey != null &&
            targetYear != null) {
          await FeatureUnlockService.instance.unlockByRewardedAd(
            featureType: featureType,
            featureKey: featureKey,
            targetYear: targetYear,
            targetMonth: targetMonth ?? 0,
            rewardAmount: reward.amount.toInt(),
            rewardType: reward.type,
            adEventId: adEventId,
            profileId: profileId,
          );
        }

        // 3. 콜백 호출
        onRewarded(reward.amount.toInt(), reward.type);
      },
    );
    return true;
  }

  // ==================== Cleanup ====================

  /// 모든 광고 해제
  void disposeAll() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();

    _bannerAd = null;
    _interstitialAd = null;
    _rewardedAd = null;

    _isBannerLoaded = false;
    _isInterstitialLoaded = false;
    _isRewardedLoaded = false;
  }
}
