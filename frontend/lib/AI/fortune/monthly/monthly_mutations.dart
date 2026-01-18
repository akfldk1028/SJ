/// # 이번달 운세 뮤테이션
///
/// ## 개요
/// ai_summaries 테이블에 monthly_fortune 결과 저장
/// target_year, target_month 필드 사용
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/monthly/monthly_mutations.dart`

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ai_constants.dart';
import '../common/korea_date_utils.dart';

/// 이번달 운세 뮤테이션 클래스
class MonthlyMutations {
  final SupabaseClient _supabase;

  MonthlyMutations(this._supabase);

  /// 월운 결과 저장 (Upsert)
  ///
  /// [userId] 사용자 UUID
  /// [profileId] 프로필 UUID
  /// [targetYear] 대상 연도 (한국 시간 기준)
  /// [targetMonth] 대상 월 (한국 시간 기준)
  /// [content] 분석 결과 JSON
  /// [modelName] 사용된 모델명
  /// [promptTokens] 입력 토큰 수
  /// [completionTokens] 출력 토큰 수
  /// [totalCost] 총 비용 (USD)
  Future<Map<String, dynamic>> save({
    required String userId,
    required String profileId,
    required int targetYear,
    required int targetMonth,
    required Map<String, dynamic> content,
    required String modelName,
    required int promptTokens,
    required int completionTokens,
    required double totalCost,
  }) async {
    // 만료 시간 계산 (7일, 한국 시간 기준)
    final expiresAt = CacheExpiry.monthlyFortune != null
        ? KoreaDateUtils.calculateExpiry(CacheExpiry.monthlyFortune)
            .toIso8601String()
        : null;

    final data = {
      'user_id': userId,
      'profile_id': profileId,
      'summary_type': SummaryType.monthlyFortune,
      'target_year': targetYear,
      'target_month': targetMonth,
      'content': content,
      'model_name': modelName,
      'model_provider': ModelProvider.openai,
      'prompt_tokens': promptTokens,
      'completion_tokens': completionTokens,
      'total_cost_usd': totalCost,
      'expires_at': expiresAt,
      'updated_at': KoreaDateUtils.nowKoreaIso8601,
    };

    // Upsert: profile_id + summary_type + target_year + target_month 기준
    // 주의: DB에 해당 UNIQUE 제약 조건 필요
    final response = await _supabase
        .from('ai_summaries')
        .upsert(
          data,
          onConflict: 'profile_id,summary_type,target_year,target_month',
        )
        .select()
        .single();

    return response;
  }

  /// 특정 월 운세 삭제
  Future<void> delete(
    String profileId, {
    required int year,
    required int month,
  }) async {
    await _supabase
        .from('ai_summaries')
        .delete()
        .eq('profile_id', profileId)
        .eq('summary_type', SummaryType.monthlyFortune)
        .eq('target_year', year)
        .eq('target_month', month);
  }

  /// 모든 월운 삭제
  Future<void> deleteAll(String profileId) async {
    await _supabase
        .from('ai_summaries')
        .delete()
        .eq('profile_id', profileId)
        .eq('summary_type', SummaryType.monthlyFortune);
  }

  /// 특정 월 캐시 무효화
  Future<void> invalidate(
    String profileId, {
    required int year,
    required int month,
  }) async {
    await _supabase
        .from('ai_summaries')
        .update({
          'expires_at': KoreaDateUtils.nowKorea()
              .subtract(const Duration(days: 1))
              .toIso8601String(),
        })
        .eq('profile_id', profileId)
        .eq('summary_type', SummaryType.monthlyFortune)
        .eq('target_year', year)
        .eq('target_month', month);
  }
}
