/// AdMob + AdFit 이중 광고 서비스
/// 광고 초기화, 로딩, 표시를 담당하는 서비스
/// 전면/네이티브: AdMob primary → AdFit fallback (Android)
/// 배너: AdFit 고정 (Android) / AdMob (iOS)
library;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'ad_network_resolver.dart';
import 'ad_tracking_service.dart';
import 'adfit/adfit_service.dart';
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

  /// AdFit 전면 광고 로드 상태
  bool _isAdFitInterstitialLoaded = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isBannerLoaded => _isBannerLoaded;
  bool get isInterstitialLoaded => _isInterstitialLoaded || _isAdFitInterstitialLoaded;
  bool get isRewardedLoaded => _isRewardedLoaded;
  BannerAd? get bannerAd => _bannerAd;

  /// SDK 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (!adEnabled) {
      debugPrint('[AdService] Ad kill switch OFF — skipping SDK init');
      return;
    }

    // 에뮬레이터 감지 → 테스트 광고 자동 전환
    await AdModeResolver.init();

    try {
      final status = await MobileAds.instance.initialize();
      _isInitialized = true;

      // 어댑터 상태 로깅
      status.adapterStatuses.forEach((key, value) {
        debugPrint('[AdService] Adapter $key: ${value.description}');
      });

      debugPrint('[AdService] AdMob SDK initialized successfully');
    } catch (e) {
      debugPrint('[AdService] AdMob SDK initialization failed: $e');
    }

    // AdFit 초기화 (한국 Android만)
    if (AdNetworkResolver.isAdFitAvailable) {
      AdFitService.instance.initialize();
      debugPrint('[AdService] AdFit initialized (Korea Android)');
    }
  }

  // ==================== Banner Ad ====================

  /// 배너 광고 로드
  Future<void> loadBannerAd({
    required double width,
    void Function(BannerAd)? onLoaded,
    void Function(LoadAdError)? onFailed,
  }) async {
    if (!adEnabled) return;

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
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          debugPrint('[AdService] Banner paid: $valueMicros micros ($currencyCode)');
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

  /// 전면 광고 로드 (AdMob primary, AdFit도 병렬 로드하여 fallback 대비)
  Future<void> loadInterstitialAd({
    void Function()? onLoaded,
    void Function(LoadAdError)? onFailed,
  }) async {
    if (!adEnabled) return;

    // Android: AdFit도 병렬 로드 (AdMob 실패 시 fallback용)
    if (AdNetworkResolver.isAdFitAvailable) {
      AdFitService.instance.loadInterstitial();
    }

    await InterstitialAd.load(
      adUnitId: AdUnitId.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdService] Interstitial ad loaded');
          _interstitialAd = ad;
          _isInterstitialLoaded = true;

          // onPaidEvent 수익 추적
          _interstitialAd!.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            debugPrint('[AdService] Interstitial paid: $valueMicros micros ($currencyCode)');
            AdTrackingService.instance.trackAdRevenue(
              adType: AdType.interstitial,
              valueMicros: valueMicros,
              precision: precision.name,
              currencyCode: currencyCode,
            );
          };

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
  ///
  /// [onDismissed] 광고가 닫힌 후 호출되는 콜백 (토큰 충전 등 후처리용)
  /// [bypassInterval] true면 최소 간격 체크 무시 (토큰 소진 등 필수 광고용)
  /// 광고 show() 후 바로 return하면 광고가 아직 화면에 있는 상태라
  /// 후처리가 너무 일찍 실행되어 크래시 발생 → onDismissed 콜백으로 안전하게 처리
  Future<bool> showInterstitialAd({
    void Function()? onDismissed,
    bool bypassInterval = false,
  }) async {
    if (!adEnabled) return false;

    // 최소 간격 체크 (bypassInterval이면 무시 — 토큰 소진 필수 광고)
    if (!bypassInterval && _lastInterstitialTime != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialTime!);
      if (elapsed.inSeconds < AdSettings.interstitialMinInterval) {
        debugPrint(
            '[AdService] Interstitial skipped: interval ${elapsed.inSeconds}s < ${AdSettings.interstitialMinInterval}s');
        return false;
      }
    }

    // AdFit 상태 동기화 (stale 캐시 방지)
    if (AdNetworkResolver.isAdFitAvailable) {
      _isAdFitInterstitialLoaded = AdFitService.instance.isInterstitialLoaded;
    }

    // 1) AdMob 우선 시도
    if (_isInterstitialLoaded && _interstitialAd != null) {
      // onDismissed 콜백을 기존 fullScreenContentCallback에 연결
      if (onDismissed != null) {
        final originalCallback = _interstitialAd!.fullScreenContentCallback;
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdShowedFullScreenContent: originalCallback?.onAdShowedFullScreenContent,
          onAdDismissedFullScreenContent: (ad) {
            originalCallback?.onAdDismissedFullScreenContent?.call(ad);
            onDismissed();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            originalCallback?.onAdFailedToShowFullScreenContent?.call(ad, error);
          },
          onAdImpression: originalCallback?.onAdImpression,
          onAdClicked: originalCallback?.onAdClicked,
        );
      }

      _lastInterstitialTime = DateTime.now();
      await _interstitialAd!.show();
      debugPrint('[AdService] AdMob interstitial shown');
      return true;
    }

    // 2) AdMob 실패 → AdFit fallback (Android only)
    if (AdNetworkResolver.isAdFitAvailable && AdFitService.instance.isInterstitialLoaded) {
      final shown = await AdFitService.instance.showInterstitial(
        onDismissed: onDismissed,
      );
      if (shown) {
        _lastInterstitialTime = DateTime.now();
        _isAdFitInterstitialLoaded = false; // 소비됨 — 캐시 리셋
        debugPrint('[AdService] AdFit interstitial shown (AdMob fallback)');
        return true;
      }
      debugPrint('[AdService] AdFit interstitial also failed');
    }

    // 3) 둘 다 실패
    debugPrint('[AdService] Interstitial not ready (both networks)');
    return false;
  }

  /// Interstitial 광고 로드 대기 (최대 timeout)
  /// 이미 로드되어 있으면 즉시 true 반환
  /// AdFit 또는 AdMob 중 하나라도 로드되면 true
  /// 2초 경과 후에도 미로드 시 1회 재시도
  Future<bool> waitForInterstitialLoad({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (isInterstitialLoaded) return true;

    // 로드 시작
    loadInterstitialAd();

    // 폴링으로 대기 (100ms 간격)
    final checkAdFit = AdNetworkResolver.isAdFitAvailable;
    final startTime = DateTime.now();
    final deadline = startTime.add(timeout);
    bool retried = false;

    while (DateTime.now().isBefore(deadline)) {
      if (checkAdFit) {
        _isAdFitInterstitialLoaded = AdFitService.instance.isInterstitialLoaded;
      }
      if (isInterstitialLoaded) return true;
      await Future.delayed(const Duration(milliseconds: 100));

      // 3초 경과 후에도 로드 안 됐으면 1회 재시도
      if (!retried && DateTime.now().difference(startTime).inMilliseconds > 3000) {
        retried = true;
        debugPrint('[AdService] Interstitial not loaded after 2s, retrying...');
        loadInterstitialAd();
      }
    }

    if (checkAdFit) {
      _isAdFitInterstitialLoaded = AdFitService.instance.isInterstitialLoaded;
    }
    return isInterstitialLoaded;
  }

  // ==================== Rewarded Ad ====================

  /// 보상형 광고 로드
  Future<void> loadRewardedAd({
    void Function()? onLoaded,
    void Function(LoadAdError)? onFailed,
  }) async {
    if (!adEnabled) {
      debugPrint('[AdService] Ad kill switch OFF — skipping rewarded load');
      return;
    }

    await RewardedAd.load(
      adUnitId: AdUnitId.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdService] Rewarded ad loaded');
          _rewardedAd = ad;
          _isRewardedLoaded = true;

          // onPaidEvent 수익 추적
          _rewardedAd!.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            debugPrint('[AdService] Rewarded paid: $valueMicros micros ($currencyCode)');
            AdTrackingService.instance.trackAdRevenue(
              adType: AdType.rewarded,
              valueMicros: valueMicros,
              precision: precision.name,
              currencyCode: currencyCode,
            );
          };

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
    if (!adEnabled) return false;

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

  // ==================== Rewarded Ad Helpers ====================

  /// Rewarded 광고 로드 대기 (최대 timeout)
  /// 이미 로드되어 있으면 즉시 true 반환
  Future<bool> waitForRewardedLoad({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_isRewardedLoaded) return true;

    // 로드 중이 아니면 재로드 시작
    loadRewardedAd();

    // 폴링으로 대기 (100ms 간격)
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_isRewardedLoaded) return true;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return _isRewardedLoaded;
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
    _isAdFitInterstitialLoaded = false;

    if (AdNetworkResolver.isAdFitAvailable) {
      AdFitService.instance.dispose();
    }
  }
}
