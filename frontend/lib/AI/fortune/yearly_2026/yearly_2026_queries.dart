/// # 2026 신년운세 쿼리
///
/// ## 개요
/// ai_summaries 테이블에서 yearly_fortune_2026 캐시 조회
/// target_year 필드로 필터링 (2026 고정)
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/yearly_2026/yearly_2026_queries.dart`

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ai_constants.dart';
import '../common/korea_date_utils.dart';

/// 2026 신년운세 쿼리 클래스
class Yearly2026Queries {
  final SupabaseClient _supabase;

  /// 2026년 고정
  static const int targetYear = 2026;

  Yearly2026Queries(this._supabase);

  /// 캐시된 2026 신년운세 조회
  ///
  /// [profileId] 프로필 UUID
  /// 반환: 캐시된 데이터 또는 null
  Future<Map<String, dynamic>?> getCached(String profileId) async {
    try {
      // target_year 필드로 직접 필터링
      final response = await _supabase
          .from('ai_summaries')
          .select('*')
          .eq('profile_id', profileId)
          .eq('summary_type', SummaryType.yearlyFortune2026)
          .eq('target_year', targetYear)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      // 만료 체크 (한국 시간 기준)
      final expiresAt = response['expires_at'];
      if (expiresAt != null) {
        final expiry = DateTime.parse(expiresAt);
        if (KoreaDateUtils.nowKorea().isAfter(expiry)) {
          // 만료됨 - null 반환
          return null;
        }
      }

      return response;
    } catch (e) {
      // 쿼리 실패 시 null 반환 (캐시 미스로 처리)
      return null;
    }
  }

  /// 2026 신년운세 존재 여부 확인
  ///
  /// [profileId] 프로필 UUID
  /// 반환: 유효한 캐시 존재 여부
  Future<bool> exists(String profileId) async {
    final cached = await getCached(profileId);
    return cached != null;
  }

  /// 2026 신년운세 content만 조회
  ///
  /// [profileId] 프로필 UUID
  /// 반환: content JSON 또는 null
  Future<Map<String, dynamic>?> getContent(String profileId) async {
    final cached = await getCached(profileId);
    if (cached == null) return null;

    final content = cached['content'];
    if (content is Map<String, dynamic>) {
      return content;
    } else if (content is String) {
      // JSON 문자열인 경우 파싱
      try {
        return Map<String, dynamic>.from(
          (content as dynamic),
        );
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// 캐시 만료 시간 조회
  ///
  /// [profileId] 프로필 UUID
  /// 반환: 만료 시간 또는 null (무기한)
  Future<DateTime?> getExpiryTime(String profileId) async {
    final cached = await getCached(profileId);
    if (cached == null) return null;

    final expiresAt = cached['expires_at'];
    if (expiresAt == null) return null;

    return DateTime.parse(expiresAt);
  }
}
