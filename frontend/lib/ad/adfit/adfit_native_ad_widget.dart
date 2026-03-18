/// AdFit 네이티브 광고 위젯
/// PlatformView (AndroidView)를 사용한 네이티브 광고 렌더링
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'adfit_config.dart';

/// AdFit 네이티브 광고 콜백
typedef AdFitNativeAdCallback = void Function();

/// AdFit 네이티브 광고 위젯
///
/// Android PlatformView로 카카오 AdFit 네이티브 광고 렌더링.
/// Hybrid Composition 사용.
class AdFitNativeAdWidget extends StatefulWidget {
  /// 광고 로드 성공 콜백
  final AdFitNativeAdCallback? onLoaded;

  /// 광고 로드 실패 콜백
  final AdFitNativeAdCallback? onLoadFailed;

  /// 광고 클릭 콜백 (토큰 보상용)
  final AdFitNativeAdCallback? onClicked;

  /// 광고 노출 콜백
  final AdFitNativeAdCallback? onImpression;

  const AdFitNativeAdWidget({
    super.key,
    this.onLoaded,
    this.onLoadFailed,
    this.onClicked,
    this.onImpression,
  });

  @override
  State<AdFitNativeAdWidget> createState() => _AdFitNativeAdWidgetState();
}

class _AdFitNativeAdWidgetState extends State<AdFitNativeAdWidget> {
  bool _isLoaded = false;
  bool _loadFailed = false;

  @override
  Widget build(BuildContext context) {
    if (_loadFailed) return const SizedBox.shrink();

    return RepaintBoundary(
      child: SizedBox(
        height: 250,
        child: AndroidView(
          viewType: 'adfit-native-ad',
          creationParams: {
            'adUnitId': AdFitUnitIds.native,
          },
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
        ),
      ),
    );
  }

  void _onPlatformViewCreated(int viewId) {
    final channel = MethodChannel('adfit-native-ad/$viewId');
    channel.setMethodCallHandler(_handleCall);
  }

  Future<dynamic> _handleCall(MethodCall call) async {
    switch (call.method) {
      case 'onAdLoaded':
        debugPrint('[AdFitNative] Ad loaded');
        if (mounted) setState(() => _isLoaded = true);
        widget.onLoaded?.call();
      case 'onAdLoadFailed':
        debugPrint('[AdFitNative] Ad load failed: ${call.arguments}');
        if (mounted) setState(() => _loadFailed = true);
        widget.onLoadFailed?.call();
      case 'onAdClicked':
        debugPrint('[AdFitNative] Ad clicked');
        widget.onClicked?.call();
      case 'onAdImpression':
        debugPrint('[AdFitNative] Ad impression');
        widget.onImpression?.call();
    }
  }
}
