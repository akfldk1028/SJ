/// AdFit 배너 광고 위젯
/// PlatformView (AndroidView)를 사용한 배너 광고 렌더링
/// 320x100 사이즈 (Android only)
/// 로드 실패 시 재시도 (최대 2회) 후 onFailed 콜백
library;

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'adfit_config.dart';

/// AdFit 배너 광고 위젯
///
/// Android PlatformView로 카카오 AdFit 배너 광고 렌더링.
/// iOS에서는 빈 위젯 반환.
/// [onFailed] 재시도 모두 실패 시 호출 (AdMob fallback용)
class AdFitBannerAdWidget extends StatefulWidget {
  final VoidCallback? onFailed;

  const AdFitBannerAdWidget({super.key, this.onFailed});

  @override
  State<AdFitBannerAdWidget> createState() => _AdFitBannerAdWidgetState();
}

class _AdFitBannerAdWidgetState extends State<AdFitBannerAdWidget> {
  MethodChannel? _channel;
  int _retryCount = 0;
  static const _maxRetries = 2;

  /// PlatformView 재생성용 키 (retry 시 증가)
  int _viewKey = 0;

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    _channel = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) return const SizedBox.shrink();

    // 화면 너비에 맞춰 배너 크기 조절 (최대 320)
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerWidth = screenWidth.clamp(0.0, 320.0);

    return RepaintBoundary(
      child: SizedBox(
        width: bannerWidth,
        height: 100,
        child: AndroidView(
          key: ValueKey('adfit-banner-$_viewKey'),
          viewType: 'adfit-banner-ad',
          creationParams: {
            'adUnitId': AdFitUnitIds.banner,
          },
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
        ),
      ),
    );
  }

  void _onPlatformViewCreated(int viewId) {
    _channel?.setMethodCallHandler(null);
    _channel = MethodChannel('adfit-banner-ad/$viewId');
    _channel!.setMethodCallHandler(_handleCall);
  }

  Future<dynamic> _handleCall(MethodCall call) async {
    switch (call.method) {
      case 'onAdLoaded':
        debugPrint('[AdFitBanner] Ad loaded');
      case 'onAdLoadFailed':
        debugPrint('[AdFitBanner] Ad load failed (retry $_retryCount/$_maxRetries): ${call.arguments}');
        if (_retryCount < _maxRetries) {
          _retryCount++;
          // PlatformView 재생성으로 재시도
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _viewKey++);
          });
        } else {
          // 재시도 소진 → 부모에게 실패 알림 (AdMob fallback)
          debugPrint('[AdFitBanner] All retries exhausted, calling onFailed');
          widget.onFailed?.call();
        }
      case 'onAdClicked':
        debugPrint('[AdFitBanner] Ad clicked');
    }
  }
}
