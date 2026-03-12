/// AdFit 배너 광고 위젯
/// PlatformView (AndroidView)를 사용한 배너 광고 렌더링
/// 320x100 사이즈 (Android only)
library;

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'adfit_config.dart';

/// AdFit 배너 광고 위젯
///
/// Android PlatformView로 카카오 AdFit 배너 광고 렌더링.
/// iOS에서는 빈 위젯 반환.
class AdFitBannerAdWidget extends StatefulWidget {
  const AdFitBannerAdWidget({super.key});

  @override
  State<AdFitBannerAdWidget> createState() => _AdFitBannerAdWidgetState();
}

class _AdFitBannerAdWidgetState extends State<AdFitBannerAdWidget> {
  bool _loadFailed = false;
  MethodChannel? _channel;

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    _channel = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid || _loadFailed) return const SizedBox.shrink();

    // 화면 너비에 맞춰 배너 크기 조절 (최대 320)
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerWidth = screenWidth.clamp(0.0, 320.0);

    return RepaintBoundary(
      child: SizedBox(
        width: bannerWidth,
        height: 100,
        child: AndroidView(
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
    _channel = MethodChannel('adfit-banner-ad/$viewId');
    _channel!.setMethodCallHandler(_handleCall);
  }

  Future<dynamic> _handleCall(MethodCall call) async {
    switch (call.method) {
      case 'onAdLoaded':
        debugPrint('[AdFitBanner] Ad loaded');
      case 'onAdLoadFailed':
        debugPrint('[AdFitBanner] Ad load failed: ${call.arguments}');
        if (mounted) setState(() => _loadFailed = true);
      case 'onAdClicked':
        debugPrint('[AdFitBanner] Ad clicked');
    }
  }
}
