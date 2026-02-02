/// # 이번달 운세 쿼리
///
/// ## 개요
/// ai_summaries 테이블에서 monthly_fortune 캐시 조회
/// target_year, target_month 필드로 직접 필터링
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/monthly/monthly_queries.dart`

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ai_constants.dart';
import '../common/korea_date_utils.dart';

/// 현재 월운 프롬프트 버전
/// @deprecated PromptVersions.monthlyFortune 사용
/// 하위 호환성을 위해 유지
const String kMonthlyFortunePromptVersion = PromptVersions.monthlyFortune;

/// 이번달 운세 쿼리 클래스
class MonthlyQueries {
  final SupabaseClient _supabase;

  MonthlyQueries(this._supabase);

  /// 캐시된 월운 조회
  ///
  /// [profileId] 프로필 UUID
  /// [year] 대상 연도
  /// [month] 대상 월
  /// 반환: 캐시된 데이터 또는 null
  Future<Map<String, dynamic>?> getCached(
    String profileId, {
    required int year,
    required int month,
    bool includeStale = false,
  }) async {
    try {
      // target_year, target_month 필드로 직접 필터링
      final response = await _supabase
          .from('ai_summaries')
          .select('*')
          .eq('profile_id', profileId)
          .eq('summary_type', SummaryType.monthlyFortune)
          .eq('target_year', year)
          .eq('target_month', month)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      // 만료 체크
      final expiresAt = response['expires_at'];
      if (expiresAt != null) {
        final expiry = DateTime.parse(expiresAt);
        // 한국 시간 기준으로 만료 체크
        if (KoreaDateUtils.nowKorea().isAfter(expiry)) {
          return null;
        }
      }

      // 프롬프트 버전 체크
      final cachedVersion = response['prompt_version'];
      if (cachedVersion != kMonthlyFortunePromptVersion) {
        if (includeStale) {
          print('[MonthlyQueries] 프롬프트 버전 불일치: cached=$cachedVersion, current=$kMonthlyFortunePromptVersion → stale 데이터 반환');
          return {...response, '_isStale': true};
        }
        return null;
      }

      return response;
    } catch (e) {
      return null;
    }
  }

  /// 현재 월 운세 조회 (편의 메서드)
  /// 한국 시간 기준
  Future<Map<String, dynamic>?> getCurrentMonth(String profileId) async {
    return getCached(
      profileId,
      year: KoreaDateUtils.currentYear,
      month: KoreaDateUtils.currentMonth,
    );
  }

  /// 월운 존재 여부 확인
  Future<bool> exists(
    String profileId, {
    required int year,
    required int month,
  }) async {
    final cached = await getCached(profileId, year: year, month: month);
    return cached != null;
  }

  /// 월운 content만 조회
  Future<Map<String, dynamic>?> getContent(
    String profileId, {
    required int year,
    required int month,
  }) async {
    final cached = await getCached(profileId, year: year, month: month);
    if (cached == null) return null;

    final content = cached['content'];
    if (content is Map<String, dynamic>) {
      return content;
    }
    return null;
  }
}
