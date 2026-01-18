/// # 2026 신년운세 뮤테이션
///
/// ## 개요
/// ai_summaries 테이블에 yearly_fortune_2026 결과 저장
/// target_year 필드 사용 (2026 고정)
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/yearly_2026/yearly_2026_mutations.dart`

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ai_constants.dart';
import '../common/korea_date_utils.dart';

/// 2026 신년운세 뮤테이션 클래스
class Yearly2026Mutations {
  final SupabaseClient _supabase;

  /// 2026년 고정
  static const int targetYear = 2026;

  Yearly2026Mutations(this._supabase);

  /// 2026 신년운세 결과 저장 (Upsert)
  ///
  /// [userId] 사용자 UUID
  /// [profileId] 프로필 UUID
  /// [content] 분석 결과 JSON
  /// [modelName] 사용된 모델명
  /// [promptTokens] 입력 토큰 수
  /// [completionTokens] 출력 토큰 수
  /// [totalCost] 총 비용 (USD)
  Future<Map<String, dynamic>> save({
    required String userId,
    required String profileId,
    required Map<String, dynamic> content,
    required String modelName,
    required int promptTokens,
    required int completionTokens,
    required double totalCost,
  }) async {
    // 만료 시간 계산 (한국 시간 기준)
    final expiresAt = CacheExpiry.yearlyFortune2026 != null
        ? KoreaDateUtils.calculateExpiry(CacheExpiry.yearlyFortune2026)
            .toIso8601String()
        : null;

    final data = {
      'user_id': userId,
      'profile_id': profileId,
      'summary_type': SummaryType.yearlyFortune2026,
      'target_year': targetYear,
      'target_month': null, // 년운은 월 없음
      'content': content,
      'model_name': modelName,
      'model_provider': ModelProvider.openai,
      'prompt_tokens': promptTokens,
      'completion_tokens': completionTokens,
      'total_cost_usd': totalCost,
      'expires_at': expiresAt,
      'updated_at': KoreaDateUtils.nowKoreaIso8601,
    };

    // Upsert: profile_id + summary_type + target_year 기준
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

  /// 2026 신년운세 삭제
  ///
  /// [profileId] 프로필 UUID
  Future<void> delete(String profileId) async {
    await _supabase
        .from('ai_summaries')
        .delete()
        .eq('profile_id', profileId)
        .eq('summary_type', SummaryType.yearlyFortune2026);
  }

  /// 캐시 무효화 (expires_at을 과거로 설정)
  ///
  /// [profileId] 프로필 UUID
  Future<void> invalidate(String profileId) async {
    await _supabase
        .from('ai_summaries')
        .update({
          'expires_at': DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String(),
        })
        .eq('profile_id', profileId)
        .eq('summary_type', SummaryType.yearlyFortune2026);
  }
}
