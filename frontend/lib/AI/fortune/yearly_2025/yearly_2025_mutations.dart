/// # 2025 회고 운세 뮤테이션
///
/// ## 개요
/// ai_summaries 테이블에 yearly_fortune_2025 결과 저장
/// target_year 필드 사용 (2025 고정)
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/yearly_2025/yearly_2025_mutations.dart`

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ai_constants.dart';
import '../common/korea_date_utils.dart';

/// 2025 회고 운세 뮤테이션 클래스
class Yearly2025Mutations {
  final SupabaseClient _supabase;

  /// 2025년 고정
  static const int targetYear = 2025;

  Yearly2025Mutations(this._supabase);

  /// 2025 회고 운세 결과 저장 (Upsert)
  ///
  /// [userId] 사용자 UUID
  /// [profileId] 프로필 UUID
  /// [content] 분석 결과 JSON
  /// [modelName] 사용된 모델명
  /// [promptTokens] 입력 토큰 수
  /// [completionTokens] 출력 토큰 수
  /// [totalCost] 총 비용 (USD)
  ///
  /// 참고: expires_at은 null (무기한 - 과거는 변하지 않음)
  Future<Map<String, dynamic>> save({
    required String userId,
    required String profileId,
    required Map<String, dynamic> content,
    required String modelName,
    required int promptTokens,
    required int completionTokens,
    required double totalCost,
  }) async {
    final data = {
      'user_id': userId,
      'profile_id': profileId,
      'summary_type': SummaryType.yearlyFortune2025,
      'target_year': targetYear,
      'target_month': null, // 년운은 월 없음
      'content': content,
      'model_name': modelName,
      'model_provider': ModelProvider.openai,
      'prompt_tokens': promptTokens,
      'completion_tokens': completionTokens,
      'total_cost_usd': totalCost,
      'expires_at': null, // 무기한 캐시
      'updated_at': KoreaDateUtils.nowKoreaIso8601,
    };

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

  /// 2025 회고 운세 삭제
  Future<void> delete(String profileId) async {
    await _supabase
        .from('ai_summaries')
        .delete()
        .eq('profile_id', profileId)
        .eq('summary_type', SummaryType.yearlyFortune2025);
  }
}
