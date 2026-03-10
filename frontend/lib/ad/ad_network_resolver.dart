/// 광고 네트워크 선택 로직
/// 지역 + 플랫폼 기반으로 primary/fallback 네트워크 결정
library;

import 'dart:io' show Platform;

import 'ad_config.dart';
import 'region_detector.dart';

/// 광고 네트워크
enum AdNetwork { admob, adfit }

/// 광고 네트워크 해석기
///
/// - 한국 Android: AdFit primary → AdMob fallback
/// - 해외 / iOS: AdMob only
class AdNetworkResolver {
  AdNetworkResolver._();

  /// Primary 광고 네트워크
  static AdNetwork get primary {
    if (!adFitEnabled) return AdNetwork.admob;
    if (Platform.isAndroid && RegionDetector.isKorea) return AdNetwork.adfit;
    return AdNetwork.admob;
  }

  /// Fallback 네트워크 (primary 실패 시)
  static AdNetwork? get fallback {
    if (primary == AdNetwork.adfit) return AdNetwork.admob;
    return null;
  }

  /// 현재 AdFit 사용 가능 여부
  static bool get isAdFitAvailable =>
      adFitEnabled && Platform.isAndroid && RegionDetector.isKorea;
}
