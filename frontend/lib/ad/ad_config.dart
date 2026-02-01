/// AdMob Configuration
/// 광고 상수 및 설정값 정의
library;

import 'dart:io';

/// 광고 모드 (테스트/프로덕션)
enum AdMode {
  test,
  production,
}

/// 현재 광고 모드 설정
const AdMode currentAdMode = AdMode.test;

/// 테스트 광고 Unit ID (Google 공식 테스트 ID)
/// 개발 중에는 반드시 이 ID를 사용해야 계정 정지 방지
abstract class TestAdUnitIds {
  // Banner
  static const String bannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String bannerIos = 'ca-app-pub-3940256099942544/2934735716';

  // Interstitial (전면 광고)
  static const String interstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String interstitialIos =
      'ca-app-pub-3940256099942544/4411468910';

  // Rewarded (보상형 광고)
  static const String rewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String rewardedIos = 'ca-app-pub-3940256099942544/1712485313';

  // Rewarded Interstitial (보상형 전면 광고)
  static const String rewardedInterstitialAndroid =
      'ca-app-pub-3940256099942544/5354046379';
  static const String rewardedInterstitialIos =
      'ca-app-pub-3940256099942544/6978759866';

  // Native (네이티브 광고)
  static const String nativeAndroid = 'ca-app-pub-3940256099942544/2247696110';
  static const String nativeIos = 'ca-app-pub-3940256099942544/3986624511';

  // App Open (앱 오픈 광고)
  static const String appOpenAndroid =
      'ca-app-pub-3940256099942544/9257395921';
  static const String appOpenIos = 'ca-app-pub-3940256099942544/5575463023';
}

/// 프로덕션 광고 Unit ID
/// TODO: AdMob 콘솔에서 생성한 실제 광고 ID로 교체
abstract class ProductionAdUnitIds {
  // App ID (AndroidManifest.xml, Info.plist에 설정)
  static const String appIdAndroid = 'ca-app-pub-7140787344231420~3931921704';
  static const String appIdIos = 'YOUR_IOS_APP_ID';

  // Banner
  static const String bannerAndroid = 'ca-app-pub-7140787344231420/8692228132';
  static const String bannerIos = 'YOUR_BANNER_IOS_ID';

  // Interstitial
  static const String interstitialAndroid = 'ca-app-pub-7140787344231420/2126819784';
  static const String interstitialIos = 'YOUR_INTERSTITIAL_IOS_ID';

  // Rewarded
  static const String rewardedAndroid = 'ca-app-pub-7140787344231420/8500656445';
  static const String rewardedIos = 'YOUR_REWARDED_IOS_ID';

  // Native
  static const String nativeAndroid = 'ca-app-pub-7140787344231420/4565280863';
  static const String nativeIos = 'YOUR_NATIVE_IOS_ID';
}

/// 현재 모드에 맞는 Ad Unit ID 반환
class AdUnitId {
  static String get banner {
    if (currentAdMode == AdMode.test) {
      return Platform.isAndroid
          ? TestAdUnitIds.bannerAndroid
          : TestAdUnitIds.bannerIos;
    }
    return Platform.isAndroid
        ? ProductionAdUnitIds.bannerAndroid
        : ProductionAdUnitIds.bannerIos;
  }

  static String get interstitial {
    if (currentAdMode == AdMode.test) {
      return Platform.isAndroid
          ? TestAdUnitIds.interstitialAndroid
          : TestAdUnitIds.interstitialIos;
    }
    return Platform.isAndroid
        ? ProductionAdUnitIds.interstitialAndroid
        : ProductionAdUnitIds.interstitialIos;
  }

  static String get rewarded {
    if (currentAdMode == AdMode.test) {
      return Platform.isAndroid
          ? TestAdUnitIds.rewardedAndroid
          : TestAdUnitIds.rewardedIos;
    }
    return Platform.isAndroid
        ? ProductionAdUnitIds.rewardedAndroid
        : ProductionAdUnitIds.rewardedIos;
  }

  static String get rewardedInterstitial {
    return Platform.isAndroid
        ? TestAdUnitIds.rewardedInterstitialAndroid
        : TestAdUnitIds.rewardedInterstitialIos;
  }

  static String get native {
    if (currentAdMode == AdMode.test) {
      return Platform.isAndroid
          ? TestAdUnitIds.nativeAndroid
          : TestAdUnitIds.nativeIos;
    }
    return Platform.isAndroid
        ? ProductionAdUnitIds.nativeAndroid
        : ProductionAdUnitIds.nativeIos;
  }

  static String get appOpen {
    return Platform.isAndroid
        ? TestAdUnitIds.appOpenAndroid
        : TestAdUnitIds.appOpenIos;
  }
}

/// 광고 설정값
abstract class AdSettings {
  /// 전면 광고 사이 최소 간격 (초)
  static const int interstitialMinInterval = 30;

  /// 보상형 광고 재로드 대기 시간 (초)
  static const int rewardedReloadDelay = 3;

  /// 배너 광고 자동 새로고침 간격 (초)
  static const int bannerRefreshInterval = 60;

  /// 광고 로드 타임아웃 (초)
  static const int loadTimeout = 30;
}
