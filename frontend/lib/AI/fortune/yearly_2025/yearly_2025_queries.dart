/// # 2025 회고 운세 쿼리
///
/// ## 개요
/// ai_summaries 테이블에서 yearly_fortune_2025 캐시 조회
/// target_year 필드로 필터링 (2025 고정)
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/yearly_2025/yearly_2025_queries.dart`

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ai_constants.dart';

/// 현재 2025 회고 운세 프롬프트 버전
/// 프롬프트 변경 시 이 값을 업데이트하면 기존 캐시가 자동 무효화됨
const String kYearly2025FortunePromptVersion = 'V3.1';

/// 2025 회고 운세 쿼리 클래스
class Yearly2025Queries {
  final SupabaseClient _supabase;

  /// 2025년 고정
  static const int targetYear = 2025;

  Yearly2025Queries(this._supabase);

  /// 캐시된 2025 회고 운세 조회
  ///
  /// [profileId] 프로필 UUID
  /// 반환: 캐시된 데이터 또는 null
  ///
  /// 참고: 2025 회고는 무기한 캐시 (과거는 변하지 않음)
  Future<Map<String, dynamic>?> getCached(String profileId) async {
    try {
      // target_year 필드로 직접 필터링
      final response = await _supabase
          .from('ai_summaries')
          .select('*')
          .eq('profile_id', profileId)
          .eq('summary_type', SummaryType.yearlyFortune2025)
          .eq('target_year', targetYear)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // 2025 회고는 만료 체크 안 함 (무기한)
      if (response == null) return null;

      // 프롬프트 버전 체크 - 버전 불일치 시 캐시 무효화
      final cachedVersion = response['prompt_version'];
      if (cachedVersion != kYearly2025FortunePromptVersion) {
        print('[Yearly2025Queries] 프롬프트 버전 불일치: cached=$cachedVersion, current=$kYearly2025FortunePromptVersion');
        return null;
      }

      return response;
    } catch (e) {
      return null;
    }
  }

  /// 2025 회고 운세 존재 여부 확인
  Future<bool> exists(String profileId) async {
    final cached = await getCached(profileId);
    return cached != null;
  }

  /// 2025 회고 운세 content만 조회
  Future<Map<String, dynamic>?> getContent(String profileId) async {
    final cached = await getCached(profileId);
    if (cached == null) return null;

    final content = cached['content'];
    if (content is Map<String, dynamic>) {
      return content;
    }
    return null;
  }
}
