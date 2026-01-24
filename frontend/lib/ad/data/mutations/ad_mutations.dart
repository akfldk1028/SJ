/// Ad Mutations
/// 광고 관련 Supabase 변경 쿼리 (INSERT/UPDATE)
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../../AI/fortune/common/korea_date_utils.dart';
import '../../ad_tracking_service.dart' show AdType, AdEventType;

/// 광고 이벤트 Mutation
class AdMutations {
  AdMutations._();

  static SupabaseClient? get _client => SupabaseService.client;
  static String? get _userId => SupabaseService.currentUserId;

  // 디바이스 정보 캐시
  static Map<String, dynamic>? _deviceInfoCache;

  /// 디바이스 정보 수집 (한 번만 실행)
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
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

  // ==================== 광고 이벤트 INSERT ====================

  /// 광고 이벤트 기록
  ///
  /// 반환: ad_event ID (feature_unlocks 연결용), 실패 시 null
  static Future<String?> insertAdEvent({
    required AdType adType,
    required AdEventType eventType,
    int? rewardAmount,
    String? rewardType,
    String? screen,
    String? sessionId,
    String? profileId,
  }) async {
    if (_client == null || _userId == null) {
      debugPrint('[AdMutations] Supabase not connected, skipping event');
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
      debugPrint('[AdMutations] Event inserted: ${adType.name} - ${eventType.name} (id: $adEventId)');
      return adEventId;
    } catch (e) {
      debugPrint('[AdMutations] Failed to insert event: $e');
      return null;
    }
  }

  // ==================== 일일 카운터 UPDATE ====================

  /// 일일 광고 카운터 증가
  static Future<void> incrementDailyCounter(
    String column, {
    int increment = 1,
  }) async {
    if (_client == null || _userId == null) {
      debugPrint('[AdMutations] Supabase not connected, skipping counter');
      return;
    }

    final today = KoreaDateUtils.currentDateKey;

    try {
      // RPC 함수 시도
      await _client!.rpc('increment_ad_counter', params: {
        'p_user_id': _userId,
        'p_usage_date': today,
        'p_column_name': column,
        'p_increment': increment,
      });

      debugPrint('[AdMutations] Counter incremented via RPC: $column += $increment');
    } catch (e) {
      // RPC 실패 시 직접 업데이트
      debugPrint('[AdMutations] RPC failed, trying direct update: $e');
      await _incrementDirect(column, today, increment);
    }
  }

  /// 직접 카운터 업데이트 (RPC fallback)
  static Future<void> _incrementDirect(
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

      debugPrint('[AdMutations] Counter updated directly: $column += $increment');
    } catch (e) {
      debugPrint('[AdMutations] Direct update failed: $e');
    }
  }

  // ==================== Feature Unlock INSERT ====================

  /// 기능 해금 기록
  static Future<String?> insertFeatureUnlock({
    required String featureType,
    required String featureKey,
    required int targetYear,
    int? targetMonth,
    required String unlockMethod,
    String? adEventId,
    int? rewardAmount,
    String? rewardType,
    DateTime? expiresAt,
  }) async {
    if (_client == null || _userId == null) {
      debugPrint('[AdMutations] Supabase not connected, skipping unlock');
      return null;
    }

    try {
      final response = await _client!.from('feature_unlocks').insert({
        'user_id': _userId,
        'feature_type': featureType,
        'feature_key': featureKey,
        'target_year': targetYear,
        'target_month': targetMonth ?? 0,
        'unlock_method': unlockMethod,
        'ad_event_id': adEventId,
        'reward_amount': rewardAmount,
        'reward_type': rewardType,
        'expires_at': expiresAt?.toUtc().toIso8601String(),
        'is_active': true,
      }).select('id').single();

      final unlockId = response['id'] as String?;
      debugPrint('[AdMutations] Feature unlocked: $featureType/$featureKey (id: $unlockId)');
      return unlockId;
    } catch (e) {
      debugPrint('[AdMutations] Failed to insert unlock: $e');
      return null;
    }
  }

  /// 기능 해금 비활성화
  static Future<void> deactivateFeatureUnlock(String unlockId) async {
    if (_client == null) return;

    try {
      await _client!
          .from('feature_unlocks')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', unlockId);

      debugPrint('[AdMutations] Feature unlock deactivated: $unlockId');
    } catch (e) {
      debugPrint('[AdMutations] Failed to deactivate unlock: $e');
    }
  }

  // ==================== 편의 메서드 (이벤트 + 카운터 동시) ====================

  /// 배너 광고 노출 기록
  static Future<void> trackBannerImpression({String? screen}) async {
    await insertAdEvent(
      adType: AdType.banner,
      eventType: AdEventType.impression,
      screen: screen,
    );
    await incrementDailyCounter('banner_impressions');
  }

  /// 배너 광고 클릭 기록
  static Future<void> trackBannerClick({String? screen}) async {
    await insertAdEvent(
      adType: AdType.banner,
      eventType: AdEventType.click,
      screen: screen,
    );
    await incrementDailyCounter('banner_clicks');
  }

  /// 전면 광고 표시 기록
  static Future<void> trackInterstitialShow({String? screen}) async {
    await insertAdEvent(
      adType: AdType.interstitial,
      eventType: AdEventType.show,
      screen: screen,
    );
    await incrementDailyCounter('interstitial_shows');
  }

  /// 전면 광고 완료 기록
  static Future<void> trackInterstitialComplete({String? screen}) async {
    await insertAdEvent(
      adType: AdType.interstitial,
      eventType: AdEventType.complete,
      screen: screen,
    );
    await incrementDailyCounter('interstitial_completes');
  }

  /// 전면 광고 클릭 기록
  static Future<void> trackInterstitialClick({String? screen}) async {
    await insertAdEvent(
      adType: AdType.interstitial,
      eventType: AdEventType.click,
      screen: screen,
    );
    await incrementDailyCounter('interstitial_clicks');
  }

  /// 보상형 광고 표시 기록
  static Future<void> trackRewardedShow({String? screen}) async {
    await insertAdEvent(
      adType: AdType.rewarded,
      eventType: AdEventType.show,
      screen: screen,
    );
    await incrementDailyCounter('rewarded_shows');
  }

  /// 보상형 광고 완료 기록
  static Future<void> trackRewardedComplete({String? screen}) async {
    await insertAdEvent(
      adType: AdType.rewarded,
      eventType: AdEventType.complete,
      screen: screen,
    );
    await incrementDailyCounter('rewarded_completes');
  }

  /// 보상형 광고 클릭 기록
  static Future<void> trackRewardedClick({String? screen}) async {
    await insertAdEvent(
      adType: AdType.rewarded,
      eventType: AdEventType.click,
      screen: screen,
    );
    await incrementDailyCounter('rewarded_clicks');
  }

  /// 보상 지급 기록 (feature_unlocks 연결용 ID 반환)
  static Future<String?> trackRewarded({
    required int rewardAmount,
    required String rewardType,
    String? screen,
    String? profileId,
  }) async {
    final adEventId = await insertAdEvent(
      adType: AdType.rewarded,
      eventType: AdEventType.rewarded,
      rewardAmount: rewardAmount,
      rewardType: rewardType,
      screen: screen,
      profileId: profileId,
    );
    await incrementDailyCounter('rewarded_tokens_earned', increment: rewardAmount);
    return adEventId;
  }

  /// 네이티브 광고 노출 기록
  static Future<void> trackNativeImpression({
    String? screen,
    String? sessionId,
  }) async {
    await insertAdEvent(
      adType: AdType.native,
      eventType: AdEventType.impression,
      screen: screen,
      sessionId: sessionId,
    );
    await incrementDailyCounter('native_impressions');
  }

  /// 네이티브 광고 클릭 기록
  static Future<void> trackNativeClick({
    String? screen,
    String? sessionId,
  }) async {
    await insertAdEvent(
      adType: AdType.native,
      eventType: AdEventType.click,
      screen: screen,
      sessionId: sessionId,
    );
    await incrementDailyCounter('native_clicks');
  }
}
