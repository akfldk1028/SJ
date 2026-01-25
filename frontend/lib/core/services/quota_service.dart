import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import '../../ad/ad_tracking_service.dart';

/// 토큰 Quota 서비스
///
/// 일일 토큰 사용량 관리 및 quota 초과 처리
/// - 사용량 조회: check_user_quota RPC
/// - 광고 보상: add_ad_bonus_tokens RPC
///
/// Edge Function에서 429 QUOTA_EXCEEDED 반환 시 이 서비스로 처리
class QuotaService {
  /// 일일 기본 quota (50,000 토큰)
  static const int dailyQuota = 50000;

  /// 광고 시청 시 보너스 토큰
  static const int adBonusTokens = 5000;

  /// 현재 사용자의 quota 상태 조회
  ///
  /// RPC: check_user_quota(p_user_id)
  /// 반환: {can_use, tokens_used, quota_limit, remaining}
  static Future<QuotaStatus> checkQuota() async {
    try {
      final client = SupabaseService.client;
      final userId = SupabaseService.currentUserId;

      if (client == null || userId == null) {
        // 오프라인 또는 미인증 → 제한 없이 사용 가능
        return QuotaStatus.unlimited();
      }

      final response = await client.rpc(
        'check_user_quota',
        params: {'p_user_id': userId},
      );

      if (response == null) {
        return QuotaStatus.unlimited();
      }

      final data = response as Map<String, dynamic>;

      return QuotaStatus(
        canUse: data['can_use'] as bool? ?? true,
        tokensUsed: data['tokens_used'] as int? ?? 0,
        quotaLimit: data['quota_limit'] as int? ?? dailyQuota,
        remaining: data['remaining'] as int? ?? dailyQuota,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[QuotaService] checkQuota error: $e');
      }
      // 에러 시 사용 가능으로 처리 (UX 우선)
      return QuotaStatus.unlimited();
    }
  }

  /// 광고 시청 후 보너스 토큰 추가
  ///
  /// RPC: add_ad_bonus_tokens(p_user_id, p_bonus_tokens)
  /// 반환: 성공 여부
  ///
  /// [bonusTokens] 추가할 보너스 토큰 수
  /// [trackAdEvent] ad_events 테이블에 기록 여부 (기본: true)
  static Future<AdBonusResult> addAdBonusTokens({
    int bonusTokens = adBonusTokens,
    bool trackAdEvent = true,
  }) async {
    try {
      final client = SupabaseService.client;
      final userId = SupabaseService.currentUserId;

      if (client == null || userId == null) {
        return AdBonusResult.failure('로그인이 필요합니다.');
      }

      // 1. 광고 이벤트 추적 (ad_events 테이블에 purpose: token_bonus로 기록)
      if (trackAdEvent) {
        await AdTrackingService.instance.trackRewarded(
          rewardAmount: bonusTokens,
          rewardType: 'token_bonus',
          screen: 'quota_exceeded_dialog',
          purpose: AdPurpose.tokenBonus,
        );
      }

      // 2. 보너스 토큰 추가 (RPC)
      final response = await client.rpc(
        'add_ad_bonus_tokens',
        params: {
          'p_user_id': userId,
          'p_bonus_tokens': bonusTokens,
        },
      );

      if (response == null) {
        return AdBonusResult.failure('보너스 토큰 추가에 실패했습니다.');
      }

      final data = response as Map<String, dynamic>;

      if (kDebugMode) {
        print('[QuotaService] Ad bonus added: $data');
      }

      return AdBonusResult.success(
        newQuota: data['new_quota'] as int? ?? dailyQuota + bonusTokens,
        adsWatched: data['ads_watched'] as int? ?? 1,
        bonusEarned: data['bonus_earned'] as int? ?? bonusTokens,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[QuotaService] addAdBonusTokens error: $e');
      }
      return AdBonusResult.failure(e.toString());
    }
  }

  /// QUOTA_EXCEEDED 에러인지 확인
  ///
  /// Edge Function 응답에서 quota 초과 여부 판단
  static bool isQuotaExceededError(dynamic error) {
    if (error == null) return false;

    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('quota_exceeded') ||
        errorStr.contains('quota exceeded') ||
        errorStr.contains('429');
  }

  /// Edge Function 응답에서 QuotaExceededInfo 파싱
  ///
  /// 429 응답의 body에서 상세 정보 추출
  static QuotaExceededInfo? parseQuotaExceededResponse(
    Map<String, dynamic>? data,
  ) {
    if (data == null) return null;

    final error = data['error']?.toString();
    if (error != 'QUOTA_EXCEEDED') return null;

    return QuotaExceededInfo(
      message: data['message']?.toString() ?? '오늘 토큰 사용량을 초과했습니다.',
      tokensUsed: data['tokens_used'] as int? ?? 0,
      quotaLimit: data['quota_limit'] as int? ?? dailyQuota,
      adsRequired: data['ads_required'] as bool? ?? true,
    );
  }
}

/// Quota 상태
class QuotaStatus {
  /// 사용 가능 여부
  final bool canUse;

  /// 오늘 사용한 토큰 수
  final int tokensUsed;

  /// 일일 quota 한도
  final int quotaLimit;

  /// 남은 토큰 수
  final int remaining;

  QuotaStatus({
    required this.canUse,
    required this.tokensUsed,
    required this.quotaLimit,
    required this.remaining,
  });

  /// 제한 없음 상태 (오프라인/미인증)
  factory QuotaStatus.unlimited() {
    return QuotaStatus(
      canUse: true,
      tokensUsed: 0,
      quotaLimit: QuotaService.dailyQuota,
      remaining: QuotaService.dailyQuota,
    );
  }

  /// 사용률 (0.0 ~ 1.0)
  double get usageRatio => quotaLimit > 0 ? tokensUsed / quotaLimit : 0.0;

  /// 사용률 퍼센트 (0 ~ 100)
  int get usagePercent => (usageRatio * 100).round();

  /// quota 초과 여부
  bool get isExceeded => !canUse;

  @override
  String toString() {
    return 'QuotaStatus(canUse: $canUse, used: $tokensUsed/$quotaLimit, remaining: $remaining)';
  }
}

/// 광고 보너스 결과
class AdBonusResult {
  final bool success;
  final int? newQuota;
  final int? adsWatched;
  final int? bonusEarned;
  final String? error;

  AdBonusResult._({
    required this.success,
    this.newQuota,
    this.adsWatched,
    this.bonusEarned,
    this.error,
  });

  factory AdBonusResult.success({
    required int newQuota,
    required int adsWatched,
    required int bonusEarned,
  }) {
    return AdBonusResult._(
      success: true,
      newQuota: newQuota,
      adsWatched: adsWatched,
      bonusEarned: bonusEarned,
    );
  }

  factory AdBonusResult.failure(String error) {
    return AdBonusResult._(
      success: false,
      error: error,
    );
  }
}

/// Quota 초과 정보
///
/// Edge Function 429 응답에서 추출된 정보
class QuotaExceededInfo {
  /// 사용자에게 표시할 메시지
  final String message;

  /// 오늘 사용한 토큰 수
  final int tokensUsed;

  /// 일일 quota 한도
  final int quotaLimit;

  /// 광고 시청 필요 여부
  final bool adsRequired;

  QuotaExceededInfo({
    required this.message,
    required this.tokensUsed,
    required this.quotaLimit,
    required this.adsRequired,
  });

  @override
  String toString() {
    return 'QuotaExceededInfo(used: $tokensUsed/$quotaLimit, adsRequired: $adsRequired)';
  }
}
