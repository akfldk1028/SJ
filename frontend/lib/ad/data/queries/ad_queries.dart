/// Ad Queries
/// 광고 관련 Supabase 조회 쿼리
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../../AI/fortune/common/korea_date_utils.dart';

/// 광고 이벤트 조회 쿼리
class AdQueries {
  AdQueries._();

  static SupabaseClient? get _client => SupabaseService.client;
  static String? get _userId => SupabaseService.currentUserId;

  // ==================== 일일 통계 조회 ====================

  /// 오늘 일일 광고 통계 조회
  static Future<Map<String, dynamic>?> getDailyAdStats() async {
    if (_client == null || _userId == null) return null;

    try {
      final today = KoreaDateUtils.currentDateKey;
      final result = await _client!
          .from('user_daily_token_usage')
          .select('''
            banner_impressions,
            banner_clicks,
            interstitial_shows,
            interstitial_completes,
            interstitial_clicks,
            rewarded_shows,
            rewarded_completes,
            rewarded_clicks,
            rewarded_tokens_earned,
            native_impressions,
            native_clicks
          ''')
          .eq('user_id', _userId!)
          .eq('usage_date', today)
          .maybeSingle();

      debugPrint('[AdQueries] Daily stats: $result');
      return result;
    } catch (e) {
      debugPrint('[AdQueries] Failed to get daily stats: $e');
      return null;
    }
  }

  /// 특정 날짜 광고 통계 조회
  static Future<Map<String, dynamic>?> getAdStatsByDate(String dateKey) async {
    if (_client == null || _userId == null) return null;

    try {
      final result = await _client!
          .from('user_daily_token_usage')
          .select('''
            banner_impressions,
            banner_clicks,
            interstitial_shows,
            interstitial_completes,
            interstitial_clicks,
            rewarded_shows,
            rewarded_completes,
            rewarded_clicks,
            rewarded_tokens_earned,
            native_impressions,
            native_clicks,
            ads_watched,
            bonus_tokens_earned
          ''')
          .eq('user_id', _userId!)
          .eq('usage_date', dateKey)
          .maybeSingle();

      return result;
    } catch (e) {
      debugPrint('[AdQueries] Failed to get stats by date: $e');
      return null;
    }
  }

  // ==================== 광고 이벤트 조회 ====================

  /// 최근 광고 이벤트 목록 조회
  static Future<List<Map<String, dynamic>>> getRecentAdEvents({
    int limit = 50,
    String? adType,
  }) async {
    if (_client == null || _userId == null) return [];

    try {
      var query = _client!
          .from('ad_events')
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false)
          .limit(limit);

      if (adType != null) {
        query = query.eq('ad_type', adType);
      }

      final result = await query;
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('[AdQueries] Failed to get recent events: $e');
      return [];
    }
  }

  /// 오늘 전면광고 표시 횟수 조회
  static Future<int> getTodayInterstitialCount() async {
    final stats = await getDailyAdStats();
    return (stats?['interstitial_shows'] as int?) ?? 0;
  }

  /// 오늘 보상형광고 완료 횟수 조회
  static Future<int> getTodayRewardedCount() async {
    final stats = await getDailyAdStats();
    return (stats?['rewarded_completes'] as int?) ?? 0;
  }

  // ==================== Feature Unlock 조회 ====================

  /// 특정 기능 해금 여부 조회
  static Future<bool> isFeatureUnlocked({
    required String featureType,
    required String featureKey,
    required int targetYear,
    int? targetMonth,
  }) async {
    if (_client == null || _userId == null) return false;

    try {
      var query = _client!
          .from('feature_unlocks')
          .select('id, is_active, expires_at')
          .eq('user_id', _userId!)
          .eq('feature_type', featureType)
          .eq('feature_key', featureKey)
          .eq('target_year', targetYear)
          .eq('is_active', true);

      if (targetMonth != null) {
        query = query.eq('target_month', targetMonth);
      }

      final result = await query.maybeSingle();

      if (result == null) return false;

      // 만료 체크
      final expiresAt = result['expires_at'] as String?;
      if (expiresAt != null) {
        final expireDate = DateTime.parse(expiresAt);
        if (DateTime.now().isAfter(expireDate)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('[AdQueries] Failed to check feature unlock: $e');
      return false;
    }
  }

  /// 사용자의 모든 활성 해금 목록 조회
  static Future<List<Map<String, dynamic>>> getActiveUnlocks() async {
    if (_client == null || _userId == null) return [];

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final result = await _client!
          .from('feature_unlocks')
          .select()
          .eq('user_id', _userId!)
          .eq('is_active', true)
          .or('expires_at.is.null,expires_at.gt.$now')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('[AdQueries] Failed to get active unlocks: $e');
      return [];
    }
  }
}
