/// AdMob Configuration
/// 광고 상수 및 설정값 정의
library;

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// 광고 모드 (테스트/프로덕션)
enum AdMode {
  test,
  production,
}

/// 에뮬레이터 감지 + 광고 모드 결정
/// 에뮬레이터 → 무조건 test, 실기기 → production
class AdModeResolver {
  AdModeResolver._();
  static AdMode _resolved = AdMode.production;
  static bool _initialized = false;
  static bool _isEmulator = false;

  static AdMode get current => _resolved;
  static bool get isEmulator => _isEmulator;

  /// 앱 시작 시 1회 호출 (main.dart 또는 AdService.initialize에서)
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 에뮬레이터 감지 (Debug/Release 공통)
    try {
      if (Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        _isEmulator = !info.isPhysicalDevice;
      } else if (Platform.isIOS) {
        final info = await DeviceInfoPlugin().iosInfo;
        _isEmulator = !info.isPhysicalDevice;
      }
    } catch (e) {
      debugPrint('[AdModeResolver] Device info check failed: $e');
    }

    // 에뮬레이터 → test, 실기기 → production (Debug 빌드에서도)
    _resolved = _isEmulator ? AdMode.test : AdMode.production;
    debugPrint('[AdModeResolver] isEmulator=$_isEmulator, kDebugMode=$kDebugMode → ${_resolved.name}');
  }
}

/// 광고 킬스위치
/// false = 모든 광고 비활성화 (SDK 초기화, 로드, 표시 전부 스킵)
/// true = 정상 동작
/// AdMob 제한 해제 또는 대체 네트워크 승인 시 true로 변경
const bool adEnabled = true;

/// AdFit 킬스위치
/// false = AdFit 비활성화 (AdMob only)
/// true = 한국 Android에서 AdFit 우선 사용
const bool adFitEnabled = true;

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
  static const String appIdIos = 'ca-app-pub-7140787344231420~6791926286';

  // Banner
  static const String bannerAndroid = 'ca-app-pub-7140787344231420/8692228132';
  static const String bannerIos = 'ca-app-pub-7140787344231420/8787534233';

  // Interstitial
  static const String interstitialAndroid = 'ca-app-pub-7140787344231420/2126819784';
  static const String interstitialIos = 'ca-app-pub-7140787344231420/8169554734';

  // Rewarded
  static const String rewardedAndroid = 'ca-app-pub-7140787344231420/8500656445';
  static const String rewardedIos = 'ca-app-pub-7140787344231420/9186288783';

  // Native
  static const String nativeAndroid = 'ca-app-pub-7140787344231420/4565280863';
  static const String nativeIos = 'ca-app-pub-7140787344231420/1303795883';
}

/// 현재 모드에 맞는 Ad Unit ID 반환
/// 에뮬레이터/디버그 → 테스트 ID, 실기기 릴리스 → 프로덕션 ID
class AdUnitId {
  static bool get _useTest => AdModeResolver.current == AdMode.test;

  static String get banner {
    if (_useTest) {
      return Platform.isAndroid
          ? TestAdUnitIds.bannerAndroid
          : TestAdUnitIds.bannerIos;
    }
    final id = Platform.isAndroid
        ? ProductionAdUnitIds.bannerAndroid
        : ProductionAdUnitIds.bannerIos;
    assert(!id.startsWith('YOUR_'), 'iOS Ad Unit ID가 설정되지 않았습니다: $id');
    return id;
  }

  static String get interstitial {
    if (_useTest) {
      return Platform.isAndroid
          ? TestAdUnitIds.interstitialAndroid
          : TestAdUnitIds.interstitialIos;
    }
    final id = Platform.isAndroid
        ? ProductionAdUnitIds.interstitialAndroid
        : ProductionAdUnitIds.interstitialIos;
    assert(!id.startsWith('YOUR_'), 'iOS Ad Unit ID가 설정되지 않았습니다: $id');
    return id;
  }

  static String get rewarded {
    if (_useTest) {
      return Platform.isAndroid
          ? TestAdUnitIds.rewardedAndroid
          : TestAdUnitIds.rewardedIos;
    }
    final id = Platform.isAndroid
        ? ProductionAdUnitIds.rewardedAndroid
        : ProductionAdUnitIds.rewardedIos;
    assert(!id.startsWith('YOUR_'), 'iOS Ad Unit ID가 설정되지 않았습니다: $id');
    return id;
  }

  static String get rewardedInterstitial {
    return Platform.isAndroid
        ? TestAdUnitIds.rewardedInterstitialAndroid
        : TestAdUnitIds.rewardedInterstitialIos;
  }

  static String get native {
    if (_useTest) {
      return Platform.isAndroid
          ? TestAdUnitIds.nativeAndroid
          : TestAdUnitIds.nativeIos;
    }
    final id = Platform.isAndroid
        ? ProductionAdUnitIds.nativeAndroid
        : ProductionAdUnitIds.nativeIos;
    assert(!id.startsWith('YOUR_'), 'iOS Ad Unit ID가 설정되지 않았습니다: $id');
    return id;
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
