/// 카카오 AdFit MethodChannel Bridge
/// Android 네이티브 AdFit SDK를 Flutter에서 제어
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'adfit_config.dart';

/// AdFit 서비스 (MethodChannel 기반)
class AdFitService {
  AdFitService._();
  static final AdFitService instance = AdFitService._();

  static const _channel = MethodChannel('com.clickaround.sadam/adfit');

  bool _isInterstitialLoaded = false;
  bool _isInitialized = false;

  bool get isInterstitialLoaded => _isInterstitialLoaded;

  /// 초기화 (MethodChannel 이벤트 리스너 설정)
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    _channel.setMethodCallHandler(_handleNativeCall);
    debugPrint('[AdFitService] Initialized');
  }

  // ==================== Interstitial ====================

  /// 전면 광고 로드
  Future<void> loadInterstitial() async {
    try {
      await _channel.invokeMethod('loadInterstitial', {
        'adUnitId': AdFitUnitIds.interstitial,
      });
    } on PlatformException catch (e) {
      debugPrint('[AdFitService] loadInterstitial error: ${e.message}');
      _isInterstitialLoaded = false;
    }
  }

  /// 전면 광고 표시
  ///
  /// [onDismissed] 광고 닫힌 후 콜백 (토큰 충전 등)
  Future<bool> showInterstitial({void Function()? onDismissed}) async {
    if (!_isInterstitialLoaded) {
      debugPrint('[AdFitService] Interstitial not loaded');
      return false;
    }

    _onInterstitialDismissed = onDismissed;

    try {
      final result = await _channel.invokeMethod<bool>('showInterstitial');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AdFitService] showInterstitial error: ${e.message}');
      _isInterstitialLoaded = false;
      return false;
    }
  }

  /// 전면 광고 로드 대기
  Future<bool> waitForInterstitialLoad({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_isInterstitialLoaded) return true;

    loadInterstitial();

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_isInterstitialLoaded) return true;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return _isInterstitialLoaded;
  }

  // ==================== Native Ad ====================

  // Native 광고는 PlatformView (AndroidView)로 직접 렌더링
  // → AdFitNativeAdWidget에서 처리

  // ==================== Callbacks ====================

  void Function()? _onInterstitialDismissed;

  /// 네이티브 → Flutter 콜백 처리
  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onInterstitialLoaded':
        debugPrint('[AdFitService] Interstitial loaded');
        _isInterstitialLoaded = true;
      case 'onInterstitialLoadFailed':
        debugPrint('[AdFitService] Interstitial load failed: ${call.arguments}');
        _isInterstitialLoaded = false;
      case 'onInterstitialDismissed':
        debugPrint('[AdFitService] Interstitial dismissed');
        _isInterstitialLoaded = false;
        _onInterstitialDismissed?.call();
        _onInterstitialDismissed = null;
        // 자동 재로드
        loadInterstitial();
      case 'onInterstitialClicked':
        debugPrint('[AdFitService] Interstitial clicked');
    }
  }

  /// 정리
  void dispose() {
    _onInterstitialDismissed = null;
  }
}
