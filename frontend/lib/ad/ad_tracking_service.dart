/// Ad Tracking Service
/// 광고 이벤트 추적 및 Supabase 저장을 담당하는 서비스
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/supabase_service.dart';
import '../AI/fortune/common/korea_date_utils.dart';

/// 광고 유형
enum AdType {
  banner,
  interstitial,
  rewarded,
  native,
}

/// 광고 이벤트 유형
enum AdEventType {
  impression, // 배너/네이티브 노출
  show, // 전면/보상형 표시 시작
  complete, // 전면/보상형 완료 (닫힘)
  click, // 클릭
  rewarded, // 보상 지급
}

/// 광고 추적 서비스
///
/// 광고 이벤트를 Supabase에 기록하고 일별 집계를 업데이트
class AdTrackingService {
  AdTrackingService._();
  static final AdTrackingService instance = AdTrackingService._();

  SupabaseClient? get _client => SupabaseService.client;
  String? get _userId => SupabaseService.currentUserId;

  // 디바이스 정보 캐시
  Map<String, dynamic>? _deviceInfoCache;

  /// 디바이스 정보 수집 (한 번만 실행)
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    if (_deviceInfoCache != null) return _deviceInfoCache!;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _deviceInfoCache = {
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'os_version': Platform.operatingSystemVersion,
        'app_version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
      };
    } catch (e) {
      _deviceInfoCache = {
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'error': 'Failed to get device info',
      };
    }
    return _deviceInfoCache!;
  }

  // ==================== 이벤트 추적 ====================

  /// 배너 광고 노출 추적
  Future<void> trackBannerImpression({String? screen}) async {
    await _trackEvent(
      adType: AdType.banner,
      eventType: AdEventType.impression,
      screen: screen,
    );
    await _incrementDailyCounter('banner_impressions');
  }

  /// 배너 광고 클릭 추적
  Future<void> trackBannerClick({String? screen}) async {
    await _trackEvent(
      adType: AdType.banner,
      eventType: AdEventType.click,
      screen: screen,
    );
    await _incrementDailyCounter('banner_clicks');
  }

  /// 전면 광고 표시 시작 추적
  Future<void> trackInterstitialShow({String? screen}) async {
    await _trackEvent(
      adType: AdType.interstitial,
      eventType: AdEventType.show,
      screen: screen,
    );
    await _incrementDailyCounter('interstitial_shows');
  }

  /// 전면 광고 완료 추적
  Future<void> trackInterstitialComplete({String? screen}) async {
    await _trackEvent(
      adType: AdType.interstitial,
      eventType: AdEventType.complete,
      screen: screen,
    );
    await _incrementDailyCounter('interstitial_completes');
  }

  /// 전면 광고 클릭 추적
  Future<void> trackInterstitialClick({String? screen}) async {
    await _trackEvent(
      adType: AdType.interstitial,
      eventType: AdEventType.click,
      screen: screen,
    );
    await _incrementDailyCounter('interstitial_clicks');
  }

  /// 보상형 광고 표시 시작 추적
  Future<void> trackRewardedShow({String? screen}) async {
    await _trackEvent(
      adType: AdType.rewarded,
      eventType: AdEventType.show,
      screen: screen,
    );
    await _incrementDailyCounter('rewarded_shows');
  }

  /// 보상형 광고 완료 추적
  Future<void> trackRewardedComplete({String? screen}) async {
    await _trackEvent(
      adType: AdType.rewarded,
      eventType: AdEventType.complete,
      screen: screen,
    );
    await _incrementDailyCounter('rewarded_completes');
  }

  /// 보상형 광고 클릭 추적
  Future<void> trackRewardedClick({String? screen}) async {
    await _trackEvent(
      adType: AdType.rewarded,
      eventType: AdEventType.click,
      screen: screen,
    );
    await _incrementDailyCounter('rewarded_clicks');
  }

  /// 보상 지급 추적
  ///
  /// [rewardAmount] AdMob 보상 금액
  /// [rewardType] AdMob 보상 타입
  /// [screen] 화면명 (예: category_yearly_career_2026)
  /// [profileId] 현재 활성 프로필 ID
  ///
  /// 반환: ad_event ID (feature_unlocks 연결용), 실패 시 null
  Future<String?> trackRewarded({
    required int rewardAmount,
    required String rewardType,
    String? screen,
    String? profileId,
  }) async {
    final adEventId = await _trackEventWithReturn(
      adType: AdType.rewarded,
      eventType: AdEventType.rewarded,
      rewardAmount: rewardAmount,
      rewardType: rewardType,
      screen: screen,
      profileId: profileId,
    );
    await _incrementDailyCounter('rewarded_tokens_earned', increment: rewardAmount);
    return adEventId;
  }

  /// 네이티브 광고 노출 추적
  Future<void> trackNativeImpression({String? screen, String? sessionId}) async {
    await _trackEvent(
      adType: AdType.native,
      eventType: AdEventType.impression,
      screen: screen,
      sessionId: sessionId,
    );
    await _incrementDailyCounter('native_impressions');
  }

  /// 네이티브 광고 클릭 추적
  Future<void> trackNativeClick({String? screen, String? sessionId}) async {
    await _trackEvent(
      adType: AdType.native,
      eventType: AdEventType.click,
      screen: screen,
      sessionId: sessionId,
    );
    await _incrementDailyCounter('native_clicks');
  }

  // ==================== 내부 메서드 ====================

  /// 광고 이벤트를 ad_events 테이블에 기록
  Future<void> _trackEvent({
    required AdType adType,
    required AdEventType eventType,
    int? rewardAmount,
    String? rewardType,
    String? screen,
    String? sessionId,
    String? profileId,
  }) async {
    await _trackEventWithReturn(
      adType: adType,
      eventType: eventType,
      rewardAmount: rewardAmount,
      rewardType: rewardType,
      screen: screen,
      sessionId: sessionId,
      profileId: profileId,
    );
  }

  /// 광고 이벤트를 ad_events 테이블에 기록하고 ID 반환
  Future<String?> _trackEventWithReturn({
    required AdType adType,
    required AdEventType eventType,
    int? rewardAmount,
    String? rewardType,
    String? screen,
    String? sessionId,
    String? profileId,
  }) async {
    if (_client == null || _userId == null) {
      debugPrint('[AdTracking] Supabase not connected, skipping event tracking');
      return null;
    }

    try {
      final deviceInfo = await _getDeviceInfo();

      final response = await _client!.from('ad_events').insert({
        'user_id': _userId,
        'ad_type': adType.name,
        'event_type': eventType.name,
        'reward_amount': rewardAmount,
        'reward_type': rewardType,
        'screen': screen,
        'session_id': sessionId,
        'profile_id': profileId,
        'device_info': deviceInfo,
      }).select('id').single();

      final adEventId = response['id'] as String?;
      debugPrint('[AdTracking] Event tracked: ${adType.name} - ${eventType.name} (id: $adEventId)');
      return adEventId;
    } catch (e) {
      debugPrint('[AdTracking] Failed to track event: $e');
      return null;
    }
  }

  /// user_daily_token_usage 테이블의 일별 카운터 증가
  Future<void> _incrementDailyCounter(String column, {int increment = 1}) async {
    if (_client == null || _userId == null) {
      debugPrint('[AdTracking] Supabase not connected, skipping counter update');
      return;
    }

    final today = KoreaDateUtils.currentDateKey;

    try {
      // upsert로 오늘 레코드가 없으면 생성, 있으면 업데이트
      await _client!.rpc('increment_ad_counter', params: {
        'p_user_id': _userId,
        'p_usage_date': today,
        'p_column_name': column,
        'p_increment': increment,
      });

      debugPrint('[AdTracking] Counter incremented: $column += $increment');
    } catch (e) {
      // RPC 함수가 없으면 fallback으로 직접 업데이트
      debugPrint('[AdTracking] RPC failed, trying direct update: $e');
      await _incrementDailyCounterDirect(column, today, increment);
    }
  }

  /// 직접 업데이트 fallback (RPC 없을 때)
  Future<void> _incrementDailyCounterDirect(
    String column,
    String today,
    int increment,
  ) async {
    try {
      // 1. 기존 레코드 조회
      final existing = await _client!
          .from('user_daily_token_usage')
          .select('id, $column')
          .eq('user_id', _userId!)
          .eq('usage_date', today)
          .maybeSingle();

      if (existing != null) {
        // 2a. 기존 레코드 업데이트
        final currentValue = (existing[column] as int?) ?? 0;
        await _client!
            .from('user_daily_token_usage')
            .update({column: currentValue + increment})
            .eq('id', existing['id']);
      } else {
        // 2b. 새 레코드 생성
        await _client!.from('user_daily_token_usage').insert({
          'user_id': _userId,
          'usage_date': today,
          column: increment,
        });
      }

      debugPrint('[AdTracking] Counter updated directly: $column += $increment');
    } catch (e) {
      debugPrint('[AdTracking] Direct update failed: $e');
    }
  }
}
