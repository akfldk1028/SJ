/// Inline Ad Widget for Chat
/// 채팅 메시지 목록 내 인라인 광고 위젯
library;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ad_config.dart';
import '../ad_tracking_service.dart';

/// 채팅 내 인라인 배너 광고
///
/// ListView 내에서 메시지 사이에 삽입되는 광고
/// Inline Adaptive Banner 사용 (Google 권장)
class InlineAdWidget extends StatefulWidget {
  /// 위젯 인덱스 (광고 재사용 방지용 고유 키)
  final int index;

  const InlineAdWidget({
    super.key,
    required this.index,
  });

  @override
  State<InlineAdWidget> createState() => _InlineAdWidgetState();
}

class _InlineAdWidgetState extends State<InlineAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null) {
      _loadAd();
    }
  }

  void _loadAd() {
    final width = MediaQuery.of(context).size.width.truncate();

    _bannerAd = BannerAd(
      adUnitId: AdUnitId.banner,
      size: AdSize.getInlineAdaptiveBannerAdSize(width, 60),
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[InlineAdWidget] Failed to load: ${error.message}');
          ad.dispose();
        },
        onAdImpression: (ad) {
          debugPrint('[InlineAdWidget] Impression');
          AdTrackingService.instance.trackBannerImpression();
        },
        onAdClicked: (ad) {
          debugPrint('[InlineAdWidget] Clicked');
          AdTrackingService.instance.trackBannerClick();
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          debugPrint('[InlineAdWidget] Paid: $valueMicros micros ($currencyCode)');
          AdTrackingService.instance.trackAdRevenue(
            adType: AdType.banner,
            valueMicros: valueMicros,
            precision: precision.name,
            currencyCode: currencyCode,
          );
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      // 로딩 중 placeholder (높이 유지)
      return const SizedBox(height: 60);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 광고 라벨 (Google 정책 준수)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Text(
              '광고',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 10,
                  ),
            ),
          ),
          // 광고 컨텐츠
          SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ],
      ),
    );
  }
}

/// 인라인 광고 삽입 유틸리티
class InlineAdHelper {
  /// 메시지 목록에서 광고가 삽입될 위치 계산
  ///
  /// [messageCount]: 실제 메시지 개수
  /// [interval]: 광고 삽입 간격 (N개 메시지마다 1개 광고)
  /// Returns: (총 아이템 수, 광고 인덱스 목록)
  static (int totalCount, Set<int> adIndices) calculateAdPositions({
    required int messageCount,
    required int interval,
  }) {
    if (messageCount < interval) {
      // 메시지가 interval보다 적으면 광고 없음
      return (messageCount, {});
    }

    final Set<int> adIndices = {};
    int adCount = 0;

    // interval번째 메시지 뒤에 광고 삽입
    for (int i = interval; i <= messageCount; i += interval) {
      // 광고 위치 = 메시지 인덱스 + 이미 삽입된 광고 수
      final adIndex = i + adCount;
      adIndices.add(adIndex);
      adCount++;
    }

    return (messageCount + adCount, adIndices);
  }

  /// ListView 인덱스가 광고인지 확인
  static bool isAdIndex(int index, Set<int> adIndices) {
    return adIndices.contains(index);
  }

  /// ListView 인덱스를 실제 메시지 인덱스로 변환
  static int toMessageIndex(int index, Set<int> adIndices) {
    int adsBefore = 0;
    for (final adIndex in adIndices) {
      if (adIndex < index) {
        adsBefore++;
      }
    }
    return index - adsBefore;
  }
}
