/// # 일운 쿼리
///
/// ## 개요
/// ai_summaries 테이블에서 daily_fortune 캐시 조회
/// target_date 필드로 필터링 (기존 스키마 호환)
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/daily/daily_queries.dart`
///
/// ## 모델
/// Gemini 3.0 Flash (Google)

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ai_constants.dart';
import '../common/korea_date_utils.dart';

/// 현재 일운 프롬프트 버전
/// 프롬프트 변경 시 이 값을 업데이트하면 기존 캐시가 자동 무효화됨
const String kDailyFortunePromptVersion = 'V2.0';

/// 일운 쿼리 클래스
class DailyQueries {
  final SupabaseClient _supabase;

  DailyQueries(this._supabase);

  /// 캐시된 일운 조회
  ///
  /// [profileId] 프로필 UUID
  /// [targetDate] 대상 날짜
  /// 반환: 캐시된 데이터 또는 null
  Future<Map<String, dynamic>?> getCached(
    String profileId,
    DateTime targetDate,
  ) async {
    try {
      // target_date 문자열 변환 (YYYY-MM-DD)
      final dateString = _formatDate(targetDate);

      final response = await _supabase
          .from('ai_summaries')
          .select('*')
          .eq('profile_id', profileId)
          .eq('summary_type', SummaryType.dailyFortune)
          .eq('target_date', dateString)
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
          print('[DailyQueries] 캐시 만료됨: expires_at=$expiresAt');
          return null;
        }
      }

      // 프롬프트 버전 체크 - 버전 불일치 시 캐시 무효화
      final cachedVersion = response['prompt_version'];
      if (cachedVersion != kDailyFortunePromptVersion) {
        print('[DailyQueries] 프롬프트 버전 불일치: cached=$cachedVersion, current=$kDailyFortunePromptVersion');
        return null;
      }

      print('[DailyQueries] ✅ 캐시 히트: $dateString (version=$cachedVersion)');
      return response;
    } catch (e) {
      print('[DailyQueries] 캐시 조회 실패: $e');
      return null;
    }
  }

  /// 오늘 일운 조회 (편의 메서드)
  /// 한국 시간 기준
  Future<Map<String, dynamic>?> getToday(String profileId) async {
    return getCached(profileId, KoreaDateUtils.today);
  }

  /// 일운 존재 여부 확인
  Future<bool> exists(String profileId, DateTime targetDate) async {
    final cached = await getCached(profileId, targetDate);
    return cached != null;
  }

  /// 오늘 일운 존재 여부 확인
  Future<bool> existsToday(String profileId) async {
    return exists(profileId, KoreaDateUtils.today);
  }

  /// 일운 content만 조회
  Future<Map<String, dynamic>?> getContent(
    String profileId,
    DateTime targetDate,
  ) async {
    final cached = await getCached(profileId, targetDate);
    if (cached == null) return null;

    final content = cached['content'];
    if (content is Map<String, dynamic>) {
      return content;
    }
    return null;
  }

  /// 오늘 일운 content만 조회
  Future<Map<String, dynamic>?> getTodayContent(String profileId) async {
    return getContent(profileId, KoreaDateUtils.today);
  }

  /// 최근 N일 일운 목록 조회
  ///
  /// [profileId] 프로필 UUID
  /// [days] 조회할 일수 (기본 7일)
  Future<List<Map<String, dynamic>>> getRecentDays(
    String profileId, {
    int days = 7,
  }) async {
    try {
      final today = KoreaDateUtils.today;
      final startDate = today.subtract(Duration(days: days - 1));

      final response = await _supabase
          .from('ai_summaries')
          .select('*')
          .eq('profile_id', profileId)
          .eq('summary_type', SummaryType.dailyFortune)
          .gte('target_date', _formatDate(startDate))
          .lte('target_date', _formatDate(today))
          .order('target_date', ascending: false)
          .limit(days);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[DailyQueries] 최근 일운 조회 실패: $e');
      return [];
    }
  }

  /// 날짜 포맷 (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
