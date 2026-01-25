/// Feature Unlock Service
/// 기능 해금 상태 관리 및 Supabase 동기화
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/supabase_service.dart';
import '../AI/fortune/common/korea_date_utils.dart';

/// 해금 기능 유형
enum FeatureType {
  categoryYearly,   // 연간 카테고리 운세 (2026 직업운, 연애운 등)
  categoryMonthly,  // 월간 카테고리 운세
  weekly,           // 주간 운세
  lifetime,         // 평생운
}

/// 해금 방법
enum UnlockMethod {
  adRewarded,       // 보상형 광고 시청
  subscription,     // 구독
  purchase,         // 일회성 구매
  freeTrial,        // 무료 체험
  adminGrant,       // 관리자 수동 부여
}

/// 해금 정보 모델
class FeatureUnlock {
  final String id;
  final String userId;
  final FeatureType featureType;
  final String featureKey;
  final int targetYear;
  final int targetMonth;
  final UnlockMethod unlockMethod;
  final String? adEventId;
  final int? rewardAmount;
  final String? rewardType;
  final DateTime unlockedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final Map<String, dynamic> metadata;

  FeatureUnlock({
    required this.id,
    required this.userId,
    required this.featureType,
    required this.featureKey,
    required this.targetYear,
    required this.targetMonth,
    required this.unlockMethod,
    this.adEventId,
    this.rewardAmount,
    this.rewardType,
    required this.unlockedAt,
    this.expiresAt,
    required this.isActive,
    required this.metadata,
  });

  factory FeatureUnlock.fromJson(Map<String, dynamic> json) {
    return FeatureUnlock(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      featureType: _parseFeatureType(json['feature_type'] as String),
      featureKey: json['feature_key'] as String,
      targetYear: json['target_year'] as int,
      targetMonth: json['target_month'] as int? ?? 0,
      unlockMethod: _parseUnlockMethod(json['unlock_method'] as String),
      adEventId: json['ad_event_id'] as String?,
      rewardAmount: json['reward_amount'] as int?,
      rewardType: json['reward_type'] as String?,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'feature_type': featureType.toDbString(),
      'feature_key': featureKey,
      'target_year': targetYear,
      'target_month': targetMonth,
      'unlock_method': unlockMethod.toDbString(),
      'ad_event_id': adEventId,
      'reward_amount': rewardAmount,
      'reward_type': rewardType,
      'unlocked_at': unlockedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
      'metadata': metadata,
    };
  }

  static FeatureType _parseFeatureType(String value) {
    switch (value) {
      case 'category_yearly': return FeatureType.categoryYearly;
      case 'category_monthly': return FeatureType.categoryMonthly;
      case 'weekly': return FeatureType.weekly;
      case 'lifetime': return FeatureType.lifetime;
      default: return FeatureType.categoryYearly;
    }
  }

  static UnlockMethod _parseUnlockMethod(String value) {
    switch (value) {
      case 'ad_rewarded': return UnlockMethod.adRewarded;
      case 'subscription': return UnlockMethod.subscription;
      case 'purchase': return UnlockMethod.purchase;
      case 'free_trial': return UnlockMethod.freeTrial;
      case 'admin_grant': return UnlockMethod.adminGrant;
      default: return UnlockMethod.adRewarded;
    }
  }

  /// 해금이 유효한지 확인
  bool get isValid {
    if (!isActive) return false;
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }
}

/// FeatureType 확장
extension FeatureTypeExtension on FeatureType {
  String toDbString() {
    switch (this) {
      case FeatureType.categoryYearly: return 'category_yearly';
      case FeatureType.categoryMonthly: return 'category_monthly';
      case FeatureType.weekly: return 'weekly';
      case FeatureType.lifetime: return 'lifetime';
    }
  }
}

/// UnlockMethod 확장
extension UnlockMethodExtension on UnlockMethod {
  String toDbString() {
    switch (this) {
      case UnlockMethod.adRewarded: return 'ad_rewarded';
      case UnlockMethod.subscription: return 'subscription';
      case UnlockMethod.purchase: return 'purchase';
      case UnlockMethod.freeTrial: return 'free_trial';
      case UnlockMethod.adminGrant: return 'admin_grant';
    }
  }
}

/// 기능 해금 서비스
///
/// 사용자의 기능 해금 상태를 관리하고 Supabase와 동기화
class FeatureUnlockService {
  FeatureUnlockService._();
  static final FeatureUnlockService instance = FeatureUnlockService._();

  SupabaseClient? get _client => SupabaseService.client;
  String? get _userId => SupabaseService.currentUserId;

  // 로컬 캐시 (메모리)
  final Map<String, FeatureUnlock> _unlockCache = {};

  // ==================== 해금 상태 조회 ====================

  /// 특정 기능이 해금되었는지 확인
  ///
  /// [featureType] 기능 유형
  /// [featureKey] 기능 키 (career, love, wealth 등)
  /// [targetYear] 대상 연도
  /// [targetMonth] 대상 월 (연간 운세는 0)
  Future<bool> isUnlocked({
    required FeatureType featureType,
    required String featureKey,
    required int targetYear,
    int targetMonth = 0,
  }) async {
    final cacheKey = _buildCacheKey(featureType, featureKey, targetYear, targetMonth);

    // 1. 로컬 캐시 확인
    if (_unlockCache.containsKey(cacheKey)) {
      final unlock = _unlockCache[cacheKey]!;
      if (unlock.isValid) {
        debugPrint('[FeatureUnlock] Cache hit: $cacheKey = unlocked');
        return true;
      } else {
        // 만료된 캐시 제거
        _unlockCache.remove(cacheKey);
      }
    }

    // 2. DB 조회
    if (_client == null || _userId == null) {
      debugPrint('[FeatureUnlock] Not connected, returning false');
      return false;
    }

    try {
      final response = await _client!
          .from('feature_unlocks')
          .select()
          .eq('user_id', _userId!)
          .eq('feature_type', featureType.toDbString())
          .eq('feature_key', featureKey)
          .eq('target_year', targetYear)
          .eq('target_month', targetMonth)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        final unlock = FeatureUnlock.fromJson(response);
        if (unlock.isValid) {
          _unlockCache[cacheKey] = unlock;
          debugPrint('[FeatureUnlock] DB hit: $cacheKey = unlocked');
          return true;
        }
      }

      debugPrint('[FeatureUnlock] Not unlocked: $cacheKey');
      return false;
    } catch (e) {
      debugPrint('[FeatureUnlock] Error checking unlock: $e');
      return false;
    }
  }

  /// 연간 카테고리 해금 여부 확인 (편의 메서드)
  Future<bool> isCategoryYearlyUnlocked(String categoryKey, int year) async {
    return isUnlocked(
      featureType: FeatureType.categoryYearly,
      featureKey: categoryKey,
      targetYear: year,
    );
  }

  /// 월간 카테고리 해금 여부 확인 (편의 메서드)
  Future<bool> isCategoryMonthlyUnlocked(String categoryKey, int year, int month) async {
    return isUnlocked(
      featureType: FeatureType.categoryMonthly,
      featureKey: categoryKey,
      targetYear: year,
      targetMonth: month,
    );
  }

  /// 사용자의 모든 활성 해금 목록 조회
  Future<List<FeatureUnlock>> getActiveUnlocks() async {
    if (_client == null || _userId == null) {
      return [];
    }

    try {
      final response = await _client!
          .from('feature_unlocks')
          .select()
          .eq('user_id', _userId!)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final unlocks = (response as List)
          .map((json) => FeatureUnlock.fromJson(json))
          .where((u) => u.isValid)
          .toList();

      // 캐시 갱신
      for (final unlock in unlocks) {
        final cacheKey = _buildCacheKey(
          unlock.featureType,
          unlock.featureKey,
          unlock.targetYear,
          unlock.targetMonth,
        );
        _unlockCache[cacheKey] = unlock;
      }

      return unlocks;
    } catch (e) {
      debugPrint('[FeatureUnlock] Error fetching unlocks: $e');
      return [];
    }
  }

  // ==================== 해금 생성 ====================

  /// 광고 시청으로 기능 해금
  ///
  /// [featureType] 기능 유형
  /// [featureKey] 기능 키
  /// [targetYear] 대상 연도
  /// [targetMonth] 대상 월 (연간은 0)
  /// [rewardAmount] AdMob 보상 금액
  /// [rewardType] AdMob 보상 타입
  /// [adEventId] 연결할 ad_events ID (있으면)
  /// [profileId] 현재 활성 프로필 ID
  Future<FeatureUnlock?> unlockByRewardedAd({
    required FeatureType featureType,
    required String featureKey,
    required int targetYear,
    int targetMonth = 0,
    required int rewardAmount,
    required String rewardType,
    String? adEventId,
    String? profileId,
  }) async {
    if (_client == null || _userId == null) {
      debugPrint('[FeatureUnlock] Not connected, cannot unlock');
      return null;
    }

    // 만료 시간 계산
    final expiresAt = _calculateExpiresAt(featureType, targetYear, targetMonth);

    // 메타데이터
    final metadata = {
      'platform': Platform.isAndroid ? 'android' : 'ios',
      'unlocked_at_korea': KoreaDateUtils.nowKoreaIso8601,
      if (profileId != null) 'profile_id': profileId,
    };

    try {
      final response = await _client!.from('feature_unlocks').upsert({
        'user_id': _userId,
        'feature_type': featureType.toDbString(),
        'feature_key': featureKey,
        'target_year': targetYear,
        'target_month': targetMonth,
        'unlock_method': UnlockMethod.adRewarded.toDbString(),
        'ad_event_id': adEventId,
        'reward_amount': rewardAmount,
        'reward_type': rewardType,
        'expires_at': expiresAt?.toIso8601String(),
        'is_active': true,
        'metadata': metadata,
      }, onConflict: 'user_id,feature_type,feature_key,target_year,target_month')
      .select()
      .single();

      final unlock = FeatureUnlock.fromJson(response);

      // 캐시 업데이트
      final cacheKey = _buildCacheKey(featureType, featureKey, targetYear, targetMonth);
      _unlockCache[cacheKey] = unlock;

      debugPrint('[FeatureUnlock] Unlocked: $cacheKey (reward: $rewardAmount $rewardType)');
      return unlock;
    } catch (e) {
      debugPrint('[FeatureUnlock] Error unlocking: $e');
      return null;
    }
  }

  /// 연간 카테고리 광고 해금 (편의 메서드)
  Future<FeatureUnlock?> unlockCategoryYearlyByAd({
    required String categoryKey,
    required int year,
    required int rewardAmount,
    required String rewardType,
    String? adEventId,
    String? profileId,
  }) async {
    return unlockByRewardedAd(
      featureType: FeatureType.categoryYearly,
      featureKey: categoryKey,
      targetYear: year,
      rewardAmount: rewardAmount,
      rewardType: rewardType,
      adEventId: adEventId,
      profileId: profileId,
    );
  }

  /// 월간 카테고리 광고 해금 (편의 메서드)
  Future<FeatureUnlock?> unlockCategoryMonthlyByAd({
    required String categoryKey,
    required int year,
    required int month,
    required int rewardAmount,
    required String rewardType,
    String? adEventId,
    String? profileId,
  }) async {
    return unlockByRewardedAd(
      featureType: FeatureType.categoryMonthly,
      featureKey: categoryKey,
      targetYear: year,
      targetMonth: month,
      rewardAmount: rewardAmount,
      rewardType: rewardType,
      adEventId: adEventId,
      profileId: profileId,
    );
  }

  // ==================== 내부 메서드 ====================

  /// 캐시 키 생성
  String _buildCacheKey(
    FeatureType featureType,
    String featureKey,
    int targetYear,
    int targetMonth,
  ) {
    return '${featureType.toDbString()}_${featureKey}_${targetYear}_$targetMonth';
  }

  /// 만료 시간 계산
  DateTime? _calculateExpiresAt(
    FeatureType featureType,
    int targetYear,
    int targetMonth,
  ) {
    switch (featureType) {
      case FeatureType.categoryYearly:
      case FeatureType.lifetime:
        // 연말까지 유효
        return KoreaDateUtils.endOfYear(targetYear);
      case FeatureType.categoryMonthly:
      case FeatureType.weekly:
        // 해당 월말까지 유효
        return KoreaDateUtils.endOfMonth(targetYear, targetMonth);
    }
  }

  /// 캐시 초기화
  void clearCache() {
    _unlockCache.clear();
    debugPrint('[FeatureUnlock] Cache cleared');
  }

  /// 특정 기능의 캐시만 무효화
  void invalidateCache({
    required FeatureType featureType,
    required String featureKey,
    required int targetYear,
    int targetMonth = 0,
  }) {
    final cacheKey = _buildCacheKey(featureType, featureKey, targetYear, targetMonth);
    _unlockCache.remove(cacheKey);
    debugPrint('[FeatureUnlock] Cache invalidated: $cacheKey');
  }
}
