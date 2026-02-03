/// Card Style Native Ad Widget
/// 메뉴 화면의 운세 카드와 동일한 스타일의 네이티브 광고
library;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

/// 카드 스타일 Native 광고 (Lazy Loading 적용)
///
/// - loadDelay: 광고 로드 지연 시간 (밀리초)
/// - 화면에 보일 때만 로드하여 프레임 드롭 방지
class CardNativeAdWidget extends ConsumerStatefulWidget {
  /// 광고 로드 지연 시간 (밀리초)
  /// 여러 광고가 동시에 로드되는 것을 방지
  final int loadDelayMs;

  const CardNativeAdWidget({
    super.key,
    this.loadDelayMs = 0,
  });

  @override
  ConsumerState<CardNativeAdWidget> createState() => _CardNativeAdWidgetState();
}

class _CardNativeAdWidgetState extends ConsumerState<CardNativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _loadStarted = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    if (!_isMobile) return;

    // 프레임 완료 후 지연 로드 (UI 블로킹 방지)
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (widget.loadDelayMs > 0) {
        Future.delayed(Duration(milliseconds: widget.loadDelayMs), _loadAd);
      } else {
        _loadAd();
      }
    });
  }

  void _loadAd() {
    if (!_isMobile || _loadStarted || !mounted) return;

    // 프리미엄 유저는 광고 로드 자체를 스킵
    final purchaseState = ref.read(purchaseNotifierProvider);
    final isPremium = purchaseState.valueOrNull?.entitlements
            .all[PurchaseConfig.entitlementPremium]?.isActive ==
        true;
    if (isPremium) return;

    _loadStarted = true;
    _nativeAd = NativeAd(
      adUnitId: AdUnitId.native,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('[CardNativeAd] Ad loaded');
          if (mounted) {
            setState(() => _isLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[CardNativeAd] Failed: ${error.message}');
          ad.dispose();
          _nativeAd = null;
          if (mounted) {
            setState(() => _loadFailed = true);
          }
        },
        onAdImpression: (ad) {
          debugPrint('[CardNativeAd] Impression');
          AdTrackingService.instance.trackNativeImpression();
        },
        onAdClicked: (ad) {
          debugPrint('[CardNativeAd] Clicked → bonus ${AdStrategy.intervalClickRewardTokens} tokens');
          AdTrackingService.instance.trackNativeClick(
            rewardTokens: AdStrategy.intervalClickRewardTokens,
          );
          TokenRewardService.grantNativeAdTokens(AdStrategy.intervalClickRewardTokens);
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          debugPrint('[CardNativeAd] Paid: $valueMicros micros ($currencyCode, $precision)');
          AdTrackingService.instance.trackAdRevenue(
            adType: AdType.native,
            valueMicros: valueMicros,
            precision: precision.name,
            currencyCode: currencyCode,
          );
        },
      ),
      // Medium 템플릿 - 카드에 적합
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.transparent,
        cornerRadius: 20,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF6750A4),
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black87,
          style: NativeTemplateFontStyle.bold,
          size: 15,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black54,
          style: NativeTemplateFontStyle.normal,
          size: 13,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black45,
          style: NativeTemplateFontStyle.normal,
          size: 12,
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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 로딩 중이거나 실패 시 placeholder 표시
    if (!_isLoaded || _nativeAd == null) {
      return _buildPlaceholder(context, isDark);
    }

    // ⚡ RepaintBoundary로 광고 영역 분리 (스크롤 시 불필요한 리페인트 방지)
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 120,
            maxHeight: 300,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D3A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color.fromRGBO(0, 0, 0, 0.3)
                    : const Color.fromRGBO(0, 0, 0, 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Native 광고
              AdWidget(ad: _nativeAd!),
              // 광고 라벨 (우측 상단)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 10,
                        color: isDark ? Colors.white60 : Colors.black45,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '광고',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white60 : Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, bool isDark) {
    // 로드 실패 → 공간 차지 안 함 (원래 동작)
    if (_loadFailed) {
      return const SizedBox.shrink();
    }

    // 로딩 중 → skeleton으로 자리 확보 (갑자기 튀어나옴 방지)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2D2D3A).withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
