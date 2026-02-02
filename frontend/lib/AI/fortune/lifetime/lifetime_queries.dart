/// # 평생운세 쿼리
///
/// ## 개요
/// ai_summaries 테이블에서 saju_base 캐시 조회
/// 프로필 저장 시 1회 생성되는 평생 운세 데이터
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/lifetime/lifetime_queries.dart`

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ai_constants.dart';

/// 현재 평생운세(saju_base) 프롬프트 버전
/// @deprecated PromptVersions.sajuBase 사용
/// 하위 호환성을 위해 유지
const String kSajuBasePromptVersion = PromptVersions.sajuBase;

/// 평생운세 쿼리 클래스
class LifetimeQueries {
  final SupabaseClient _supabase;

  LifetimeQueries(this._supabase);

  /// 캐시된 평생운세 조회
  ///
  /// [profileId] 프로필 UUID
  /// 반환: 캐시된 데이터 또는 null
  ///
  /// 참고: saju_base는 무기한 캐시 (프로필 변경 시에만 재생성)
  /// v9.8: 버전 불일치 시에도 기존 데이터 반환 (graceful degradation)
  ///       → _isStale 플래그 추가하여 백그라운드 재생성 트리거 지원
  Future<Map<String, dynamic>?> getCached(
    String profileId, {
    bool includeStale = false,
  }) async {
    try {
      final response = await _supabase
          .from('ai_summaries')
          .select('*')
          .eq('profile_id', profileId)
          .eq('summary_type', SummaryType.sajuBase)
          .eq('status', 'completed')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      // 프롬프트 버전 체크
      final cachedVersion = response['prompt_version'];
      if (cachedVersion != kSajuBasePromptVersion) {
        if (includeStale) {
          print('[LifetimeQueries] 프롬프트 버전 불일치: cached=$cachedVersion, current=$kSajuBasePromptVersion → stale 데이터 반환');
          return {...response, '_isStale': true};
        }
        print('[LifetimeQueries] 프롬프트 버전 불일치: cached=$cachedVersion → null 반환');
        return null;
      }

      // saju_base는 만료 체크 안 함 (무기한)
      return response;
    } catch (e) {
      print('[LifetimeQueries] 캐시 조회 오류: $e');
      return null;
    }
  }

  /// 평생운세 존재 여부 확인
  Future<bool> exists(String profileId) async {
    final cached = await getCached(profileId);
    return cached != null;
  }

  /// 평생운세 content만 조회
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
