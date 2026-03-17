/// Vungle (Liftoff Monetize) 어댑터 — STUB
///
/// pub.dev의 `vungle` 패키지가 3년간 미업데이트(v0.6.12)로
/// 현재 Flutter 3.x와 호환 불가.
///
/// 활성화 방법:
/// 1. Android 네이티브에 Liftoff SDK 직접 통합 (MethodChannel)
/// 2. 또는 향후 공식 Flutter 플러그인 출시 시 교체
/// 3. AdService._adapters 리스트에서 주석 해제
library;

import 'package:flutter/foundation.dart';

import 'ad_network_adapter.dart';

class VungleAdapter implements AdNetworkAdapter {
  @override
  String get name => 'Vungle';

  @override
  Future<void> initialize() async {
    debugPrint('[VungleAdapter] Stub — not initialized (SDK 미통합)');
  }

  @override
  bool get isInterstitialLoaded => false;

  @override
  Future<bool> loadInterstitial() async => false;

  @override
  Future<bool> showInterstitial({void Function()? onDismissed}) async => false;

  @override
  bool get isRewardedLoaded => false;

  @override
  Future<bool> loadRewarded() async => false;

  @override
  Future<bool> showRewarded({
    required void Function(int amount, String type) onRewarded,
  }) async => false;

  @override
  void dispose() {}
}
