/// 광고 네트워크 선택 로직
/// 지역 + 플랫폼 기반으로 primary/fallback 네트워크 결정
library;

import 'dart:io' show Platform;

import 'ad_config.dart';

/// 광고 네트워크
enum AdNetwork { admob, adfit }

/// 광고 네트워크 해석기
///
/// - 모든 지역: AdMob primary → AdFit fallback (Android only)
/// - iOS: AdMob only
class AdNetworkResolver {
  AdNetworkResolver._();

  /// Primary 광고 네트워크 (항상 AdMob)
  static AdNetwork get primary => AdNetwork.admob;

  /// Fallback 네트워크 (AdMob 실패 시 AdFit)
  static AdNetwork? get fallback {
    if (isAdFitAvailable) return AdNetwork.adfit;
    return null;
  }

  /// AdFit 사용 가능 여부 (Android + AdFit 킬스위치 ON)
  static bool get isAdFitAvailable =>
      adFitEnabled && Platform.isAndroid;
}
