// ignore_for_file: non_constant_identifier_names, camel_case_types, file_namesimport, file_names, unnecessary_null_comparison, prefer_null_aware_operators
// Phase 48: 토큰 사용량 상세 추적 테이블
// Created: 2026-01-14 - Detailed token tracking system
import 'supadart_header.dart';

/// 일별 유저 토큰 사용량 추적
///
/// ## 추적 항목
/// - GPT 사주 분석 (gpt_saju_analysis_*)
/// - Gemini 운세 (gemini_fortune_*)
/// - Gemini 채팅 (gemini_chat_*)
/// - 궁합 분석 (compatibility_*)
///
/// ## 자동 업데이트
/// - ai_summaries INSERT 시 트리거로 자동 증가
/// - ai_api_logs INSERT 시 채팅 토큰 자동 증가
class UserDailyTokenUsage implements SupadartClass<UserDailyTokenUsage> {
  final String id;
  final String userId;
  final DateTime usageDate;

  // GPT 사주 분석 (saju_base)
  final int? gptSajuAnalysisTokens;
  final int? gptSajuAnalysisCount;

  // Gemini 운세 (daily/monthly/yearly_fortune)
  final int? geminiFortuneTokens;
  final int? geminiFortuneCount;

  // Gemini 채팅 (대화형)
  final int? geminiChatTokens;
  final int? geminiChatMessageCount;
  final int? geminiChatSessionCount;

  // 궁합 분석
  final int? compatibilityTokens;
  final int? compatibilityCount;

  // 총합 (GENERATED 컬럼)
  final int? totalTokens;
  final int? totalApiCalls;

  // 비용
  final double? gptCostUsd;
  final double? geminiCostUsd;
  final double? totalCostUsd;

  // 쿼터 관리
  final int? dailyQuota;
  final bool? isQuotaExceeded;

  // 광고 보너스
  final int? adsWatched;
  final int? bonusTokensEarned;

  // 레거시 필드 (deprecated)
  final int? chatTokens;
  final int? aiAnalysisTokens;
  final int? aiChatTokens;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserDailyTokenUsage({
    required this.id,
    required this.userId,
    required this.usageDate,
    this.gptSajuAnalysisTokens,
    this.gptSajuAnalysisCount,
    this.geminiFortuneTokens,
    this.geminiFortuneCount,
    this.geminiChatTokens,
    this.geminiChatMessageCount,
    this.geminiChatSessionCount,
    this.compatibilityTokens,
    this.compatibilityCount,
    this.totalTokens,
    this.totalApiCalls,
    this.gptCostUsd,
    this.geminiCostUsd,
    this.totalCostUsd,
    this.dailyQuota,
    this.isQuotaExceeded,
    this.adsWatched,
    this.bonusTokensEarned,
    this.chatTokens,
    this.aiAnalysisTokens,
    this.aiChatTokens,
    this.createdAt,
    this.updatedAt,
  });

  static String get table_name => 'user_daily_token_usage';

  // 컬럼명 상수
  static String get c_id => 'id';
  static String get c_userId => 'user_id';
  static String get c_usageDate => 'usage_date';
  static String get c_gptSajuAnalysisTokens => 'gpt_saju_analysis_tokens';
  static String get c_gptSajuAnalysisCount => 'gpt_saju_analysis_count';
  static String get c_geminiFortuneTokens => 'gemini_fortune_tokens';
  static String get c_geminiFortuneCount => 'gemini_fortune_count';
  static String get c_geminiChatTokens => 'gemini_chat_tokens';
  static String get c_geminiChatMessageCount => 'gemini_chat_message_count';
  static String get c_geminiChatSessionCount => 'gemini_chat_session_count';
  static String get c_compatibilityTokens => 'compatibility_tokens';
  static String get c_compatibilityCount => 'compatibility_count';
  static String get c_totalTokens => 'total_tokens';
  static String get c_totalApiCalls => 'total_api_calls';
  static String get c_gptCostUsd => 'gpt_cost_usd';
  static String get c_geminiCostUsd => 'gemini_cost_usd';
  static String get c_totalCostUsd => 'total_cost_usd';
  static String get c_dailyQuota => 'daily_quota';
  static String get c_isQuotaExceeded => 'is_quota_exceeded';
  static String get c_adsWatched => 'ads_watched';
  static String get c_bonusTokensEarned => 'bonus_tokens_earned';
  static String get c_chatTokens => 'chat_tokens';
  static String get c_aiAnalysisTokens => 'ai_analysis_tokens';
  static String get c_aiChatTokens => 'ai_chat_tokens';
  static String get c_createdAt => 'created_at';
  static String get c_updatedAt => 'updated_at';

  static List<UserDailyTokenUsage> converter(List<Map<String, dynamic>> data) {
    return data.map(UserDailyTokenUsage.fromJson).toList();
  }

  static UserDailyTokenUsage converterSingle(Map<String, dynamic> data) {
    return UserDailyTokenUsage.fromJson(data);
  }

  factory UserDailyTokenUsage.fromJson(Map<String, dynamic> json) {
    return UserDailyTokenUsage(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      usageDate: json['usage_date'] != null
          ? DateTime.parse(json['usage_date'].toString())
          : DateTime.now(),
      gptSajuAnalysisTokens: json['gpt_saju_analysis_tokens'] != null
          ? int.tryParse(json['gpt_saju_analysis_tokens'].toString())
          : null,
      gptSajuAnalysisCount: json['gpt_saju_analysis_count'] != null
          ? int.tryParse(json['gpt_saju_analysis_count'].toString())
          : null,
      geminiFortuneTokens: json['gemini_fortune_tokens'] != null
          ? int.tryParse(json['gemini_fortune_tokens'].toString())
          : null,
      geminiFortuneCount: json['gemini_fortune_count'] != null
          ? int.tryParse(json['gemini_fortune_count'].toString())
          : null,
      geminiChatTokens: json['gemini_chat_tokens'] != null
          ? int.tryParse(json['gemini_chat_tokens'].toString())
          : null,
      geminiChatMessageCount: json['gemini_chat_message_count'] != null
          ? int.tryParse(json['gemini_chat_message_count'].toString())
          : null,
      geminiChatSessionCount: json['gemini_chat_session_count'] != null
          ? int.tryParse(json['gemini_chat_session_count'].toString())
          : null,
      compatibilityTokens: json['compatibility_tokens'] != null
          ? int.tryParse(json['compatibility_tokens'].toString())
          : null,
      compatibilityCount: json['compatibility_count'] != null
          ? int.tryParse(json['compatibility_count'].toString())
          : null,
      totalTokens: json['total_tokens'] != null
          ? int.tryParse(json['total_tokens'].toString())
          : null,
      totalApiCalls: json['total_api_calls'] != null
          ? int.tryParse(json['total_api_calls'].toString())
          : null,
      gptCostUsd: json['gpt_cost_usd'] != null
          ? double.tryParse(json['gpt_cost_usd'].toString())
          : null,
      geminiCostUsd: json['gemini_cost_usd'] != null
          ? double.tryParse(json['gemini_cost_usd'].toString())
          : null,
      totalCostUsd: json['total_cost_usd'] != null
          ? double.tryParse(json['total_cost_usd'].toString())
          : null,
      dailyQuota: json['daily_quota'] != null
          ? int.tryParse(json['daily_quota'].toString())
          : null,
      isQuotaExceeded: json['is_quota_exceeded'] as bool?,
      adsWatched: json['ads_watched'] != null
          ? int.tryParse(json['ads_watched'].toString())
          : null,
      bonusTokensEarned: json['bonus_tokens_earned'] != null
          ? int.tryParse(json['bonus_tokens_earned'].toString())
          : null,
      chatTokens: json['chat_tokens'] != null
          ? int.tryParse(json['chat_tokens'].toString())
          : null,
      aiAnalysisTokens: json['ai_analysis_tokens'] != null
          ? int.tryParse(json['ai_analysis_tokens'].toString())
          : null,
      aiChatTokens: json['ai_chat_tokens'] != null
          ? int.tryParse(json['ai_chat_tokens'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'usage_date': usageDate.toIso8601String().split('T')[0],
      if (gptSajuAnalysisTokens != null) 'gpt_saju_analysis_tokens': gptSajuAnalysisTokens,
      if (gptSajuAnalysisCount != null) 'gpt_saju_analysis_count': gptSajuAnalysisCount,
      if (geminiFortuneTokens != null) 'gemini_fortune_tokens': geminiFortuneTokens,
      if (geminiFortuneCount != null) 'gemini_fortune_count': geminiFortuneCount,
      if (geminiChatTokens != null) 'gemini_chat_tokens': geminiChatTokens,
      if (geminiChatMessageCount != null) 'gemini_chat_message_count': geminiChatMessageCount,
      if (geminiChatSessionCount != null) 'gemini_chat_session_count': geminiChatSessionCount,
      if (compatibilityTokens != null) 'compatibility_tokens': compatibilityTokens,
      if (compatibilityCount != null) 'compatibility_count': compatibilityCount,
      if (totalApiCalls != null) 'total_api_calls': totalApiCalls,
      if (gptCostUsd != null) 'gpt_cost_usd': gptCostUsd,
      if (geminiCostUsd != null) 'gemini_cost_usd': geminiCostUsd,
      if (totalCostUsd != null) 'total_cost_usd': totalCostUsd,
      if (dailyQuota != null) 'daily_quota': dailyQuota,
      if (adsWatched != null) 'ads_watched': adsWatched,
      if (bonusTokensEarned != null) 'bonus_tokens_earned': bonusTokensEarned,
    };
  }

  static Map<String, dynamic> insert({
    required String userId,
    DateTime? usageDate,
  }) {
    return {
      'user_id': userId,
      'usage_date': (usageDate ?? DateTime.now()).toIso8601String().split('T')[0],
    };
  }

  /// 토큰 사용량 요약 문자열
  String get usageSummary {
    final parts = <String>[];
    if ((gptSajuAnalysisTokens ?? 0) > 0) {
      parts.add('GPT분석: ${gptSajuAnalysisTokens}t (${gptSajuAnalysisCount}회)');
    }
    if ((geminiFortuneTokens ?? 0) > 0) {
      parts.add('운세: ${geminiFortuneTokens}t (${geminiFortuneCount}회)');
    }
    if ((geminiChatTokens ?? 0) > 0) {
      parts.add('채팅: ${geminiChatTokens}t (${geminiChatMessageCount}msg)');
    }
    if ((compatibilityTokens ?? 0) > 0) {
      parts.add('궁합: ${compatibilityTokens}t (${compatibilityCount}회)');
    }
    return parts.isEmpty ? '사용량 없음' : parts.join(' | ');
  }

  /// 쿼터 사용률 (0.0 ~ 1.0)
  double get quotaUsageRatio {
    final quota = dailyQuota ?? 50000;
    final used = totalTokens ?? 0;
    return quota > 0 ? (used / quota).clamp(0.0, 1.0) : 0.0;
  }

  /// 남은 토큰
  int get remainingTokens {
    final quota = dailyQuota ?? 50000;
    final used = totalTokens ?? 0;
    return (quota - used).clamp(0, quota);
  }
}
