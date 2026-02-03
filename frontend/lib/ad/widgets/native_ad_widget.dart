/// Native Ad Widget for Chat
/// 채팅 버블 스타일의 네이티브 광고 위젯
library;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../purchase/providers/purchase_provider.dart';
import '../../purchase/purchase_config.dart';
import '../ad_config.dart';
import '../ad_strategy.dart';
import '../ad_tracking_service.dart';
import '../token_reward_service.dart';

/// 모바일 플랫폼 체크
bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// 채팅 버블 스타일 Native 광고
///
/// AI 메시지처럼 보이는 자연스러운 광고 형태
/// eCPM: $3~15 (Inline Banner보다 높음)
class NativeAdWidget extends ConsumerStatefulWidget {
  /// 위젯 인덱스 (고유 키용)
  final int index;

  const NativeAdWidget({
    super.key,
    required this.index,
  });

  @override
  ConsumerState<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends ConsumerState<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (_isMobile) {
      _loadAd();
    }
  }

  void _loadAd() {
    if (!_isMobile) return;

    // 프리미엄 유저는 광고 로드 자체를 스킵
    final purchaseState = ref.read(purchaseNotifierProvider);
    final isPremium = purchaseState.valueOrNull?.entitlements
            .all[PurchaseConfig.entitlementPremium]?.isActive ==
        true;
    if (isPremium) return;

    _nativeAd = NativeAd(
      adUnitId: AdUnitId.native,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('[NativeAdWidget] Ad loaded');
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[NativeAdWidget] Failed to load: ${error.message}');
          ad.dispose();
          _nativeAd = null;
        },
        onAdOpened: (ad) {
          debugPrint('[NativeAdWidget] Ad opened');
        },
        onAdClosed: (ad) {
          debugPrint('[NativeAdWidget] Ad closed');
        },
        onAdImpression: (ad) {
          debugPrint('[NativeAdWidget] Ad impression');
          AdTrackingService.instance.trackNativeImpression();
        },
        onAdClicked: (ad) {
          debugPrint('[NativeAdWidget] Ad clicked → bonus ${AdStrategy.intervalClickRewardTokens} tokens');
          AdTrackingService.instance.trackNativeClick(
            rewardTokens: AdStrategy.intervalClickRewardTokens,
          );
          TokenRewardService.grantNativeAdTokens(AdStrategy.intervalClickRewardTokens);
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          debugPrint('[NativeAdWidget] Paid: $valueMicros micros ($currencyCode, $precision)');
          AdTrackingService.instance.trackAdRevenue(
            adType: AdType.native,
            valueMicros: valueMicros,
            precision: precision.name,
            currencyCode: currencyCode,
          );
        },
      ),
      // Medium 템플릿 스타일 (채팅에 적합)
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.transparent,
        cornerRadius: 16,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF6750A4), // Primary color
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black87,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black54,
          style: NativeTemplateFontStyle.normal,
          size: 12,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black45,
          style: NativeTemplateFontStyle.normal,
          size: 11,
        ),
      ),
    );

    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 프리미엄 유저는 네이티브 광고 숨김
    final purchaseState = ref.watch(purchaseNotifierProvider);
    final isPremium = purchaseState.valueOrNull?.entitlements
            .all[PurchaseConfig.entitlementPremium]?.isActive ==
        true;
    if (isPremium) return const SizedBox.shrink();

    if (!_isLoaded || _nativeAd == null) {
      // 로딩 중 placeholder
      return _buildPlaceholder(context);
    }

    return _buildAdBubble(context);
  }

  /// 로딩 중 placeholder (채팅 버블 스타일)
  Widget _buildPlaceholder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI 아바타 placeholder
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 18,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(width: 8),
          // 버블 placeholder
          Expanded(
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 채팅 버블 스타일 광고
  Widget _buildAdBubble(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI 아바타 (광고 아이콘)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.campaign_outlined,
              size: 18,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          // 광고 버블
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 광고 라벨
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '광고',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.outline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Native 광고 컨테이너
                Container(
                  constraints: const BoxConstraints(
                    minHeight: 120,
                    maxHeight: 280,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AdWidget(ad: _nativeAd!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 컴팩트 Native 광고 (Small 템플릿)
///
/// 더 작은 공간에 표시되는 네이티브 광고
class CompactNativeAdWidget extends ConsumerStatefulWidget {
  final int index;

  const CompactNativeAdWidget({
    super.key,
    required this.index,
  });

  @override
  ConsumerState<CompactNativeAdWidget> createState() => _CompactNativeAdWidgetState();
}

class _CompactNativeAdWidgetState extends ConsumerState<CompactNativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (_isMobile) {
      _loadAd();
    }
  }

  void _loadAd() {
    if (!_isMobile) return;

    // 프리미엄 유저는 광고 로드 자체를 스킵
    final purchaseState = ref.read(purchaseNotifierProvider);
    final isPremium = purchaseState.valueOrNull?.entitlements
            .all[PurchaseConfig.entitlementPremium]?.isActive ==
        true;
    if (isPremium) return;

    _nativeAd = NativeAd(
      adUnitId: AdUnitId.native,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() => _isLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[CompactNativeAdWidget] Failed: ${error.message}');
          ad.dispose();
        },
        onAdImpression: (ad) {
          debugPrint('[CompactNativeAdWidget] Ad impression');
          AdTrackingService.instance.trackNativeImpression();
        },
        onAdClicked: (ad) {
          debugPrint('[CompactNativeAdWidget] Ad clicked → bonus ${AdStrategy.intervalClickRewardTokens} tokens');
          AdTrackingService.instance.trackNativeClick(
            rewardTokens: AdStrategy.intervalClickRewardTokens,
          );
          TokenRewardService.grantNativeAdTokens(AdStrategy.intervalClickRewardTokens);
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          debugPrint('[CompactNativeAd] Paid: $valueMicros micros ($currencyCode, $precision)');
          AdTrackingService.instance.trackAdRevenue(
            adType: AdType.native,
            valueMicros: valueMicros,
            precision: precision.name,
            currencyCode: currencyCode,
          );
        },
      ),
      // Small 템플릿 (컴팩트)
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.transparent,
        cornerRadius: 12,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF6750A4),
          style: NativeTemplateFontStyle.bold,
          size: 12,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black87,
          style: NativeTemplateFontStyle.bold,
          size: 12,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black54,
          style: NativeTemplateFontStyle.normal,
          size: 11,
        ),
      ),
    );

    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 프리미엄 유저는 컴팩트 네이티브 광고 숨김
    final purchaseState = ref.watch(purchaseNotifierProvider);
    final isPremium = purchaseState.valueOrNull?.entitlements
            .all[PurchaseConfig.entitlementPremium]?.isActive ==
        true;
    if (isPremium) return const SizedBox.shrink();

    if (!_isLoaded || _nativeAd == null) {
      return const SizedBox(height: 80);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          AdWidget(ad: _nativeAd!),
          // 광고 라벨
          Positioned(
            top: 4,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Text(
                '광고',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
