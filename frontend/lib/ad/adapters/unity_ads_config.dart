/// Unity Ads 설정
///
/// Unity Dashboard: https://dashboard.unity3d.com
/// Game IDs 및 Placement IDs
library;

import 'dart:io' show Platform;

abstract class UnityAdsConfig {
  // Game IDs
  static const String gameIdAndroid = '6064429';
  static const String gameIdIos = '6064428';

  // Placement IDs - Android
  static const String interstitialAndroid = 'Interstitial_Android';
  static const String rewardedAndroid = 'Rewarded_Android';

  // Placement IDs - iOS
  static const String interstitialIos = 'Interstitial_iOS';
  static const String rewardedIos = 'Rewarded_iOS';

  // Platform-aware getters
  static String get gameId =>
      Platform.isAndroid ? gameIdAndroid : gameIdIos;

  static String get interstitial =>
      Platform.isAndroid ? interstitialAndroid : interstitialIos;

  static String get rewarded =>
      Platform.isAndroid ? rewardedAndroid : rewardedIos;
}
