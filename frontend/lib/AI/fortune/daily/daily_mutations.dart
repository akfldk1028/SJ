/// # 일운 뮤테이션
///
/// ## 개요
/// ai_summaries 테이블에 daily_fortune 결과 저장
/// target_date 필드 사용 (기존 스키마 호환)
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/daily/daily_mutations.dart`
///
/// ## 모델
/// Gemini 3.0 Flash (Google)

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ai_constants.dart';
import '../common/fortune_input_data.dart';
import '../common/korea_date_utils.dart';

/// 일운 뮤테이션 클래스
class DailyMutations {
  final SupabaseClient _supabase;

  DailyMutations(this._supabase);

  /// 일운 결과 저장 (Upsert)
  ///
  /// [userId] 사용자 UUID
  /// [profileId] 프로필 UUID
  /// [targetDate] 대상 날짜 (한국 시간 기준)
  /// [content] 분석 결과 JSON
  /// [modelName] 사용된 모델명 (Gemini 3.0 Flash)
  /// [promptTokens] 입력 토큰 수
  /// [completionTokens] 출력 토큰 수
  /// [totalCost] 총 비용 (USD)
  /// [inputData] 분석에 사용된 입력 데이터 (선택)
  /// [systemPrompt] AI에게 전달된 시스템 프롬프트 (선택)
  /// [userPrompt] AI에게 전달된 사용자 프롬프트 (선택)
  Future<Map<String, dynamic>> save({
    required String userId,
    required String profileId,
    required DateTime targetDate,
    required Map<String, dynamic> content,
    required String modelName,
    required int promptTokens,
    required int completionTokens,
    required double totalCost,
    FortuneInputData? inputData,
    String? systemPrompt,
    String? userPrompt,
  }) async {
    final dateString = _formatDate(targetDate);
    print('[DailyMutations] 저장 시작: profileId=$profileId, date=$dateString');

    // 만료 시간: 해당 일 23:59:59 KST
    final expiresAt = KoreaDateUtils.expiryEndOfDay(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    // input_data를 구조화된 JSON으로 저장
    final inputDataJson = _buildStructuredInputData(
      inputData: inputData,
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      targetDate: targetDate,
    );

    final data = {
      'user_id': userId,
      'profile_id': profileId,
      'summary_type': SummaryType.dailyFortune,
      'target_date': dateString,
      'content': content,
      'input_data': inputDataJson.isNotEmpty ? inputDataJson : null,
      'model_name': modelName,
      'model_provider': ModelProvider.google, // Gemini
      'prompt_tokens': promptTokens,
      'completion_tokens': completionTokens,
      'total_cost_usd': totalCost,
      'expires_at': expiresAt,
      'updated_at': KoreaDateUtils.nowKoreaIso8601,
    };

    try {
      // Upsert: profile_id + summary_type + target_date 기준
      final response = await _supabase
          .from('ai_summaries')
          .upsert(
            data,
            onConflict: 'profile_id,summary_type,target_date',
          )
          .select()
          .single();

      print('[DailyMutations] ✅ DB 저장 성공: ${response['id']}');
      return response;
    } catch (e) {
      print('[DailyMutations] ❌ DB 저장 실패: $e');
      rethrow;
    }
  }

  /// 특정 날짜 일운 삭제
  Future<void> delete(String profileId, DateTime targetDate) async {
    await _supabase
        .from('ai_summaries')
        .delete()
        .eq('profile_id', profileId)
        .eq('summary_type', SummaryType.dailyFortune)
        .eq('target_date', _formatDate(targetDate));
  }

  /// 모든 일운 삭제
  Future<void> deleteAll(String profileId) async {
    await _supabase
        .from('ai_summaries')
        .delete()
        .eq('profile_id', profileId)
        .eq('summary_type', SummaryType.dailyFortune);
  }

  /// 특정 날짜 캐시 무효화
  Future<void> invalidate(String profileId, DateTime targetDate) async {
    await _supabase
        .from('ai_summaries')
        .update({
          'expires_at': KoreaDateUtils.nowKorea()
              .subtract(const Duration(days: 1))
              .toIso8601String(),
        })
        .eq('profile_id', profileId)
        .eq('summary_type', SummaryType.dailyFortune)
        .eq('target_date', _formatDate(targetDate));
  }

  /// 오래된 일운 정리 (N일 이전 데이터 삭제)
  ///
  /// [profileId] 프로필 UUID
  /// [daysToKeep] 보관할 일수 (기본 30일)
  Future<int> cleanupOld(
    String profileId, {
    int daysToKeep = 30,
  }) async {
    try {
      final cutoffDate = KoreaDateUtils.today.subtract(Duration(days: daysToKeep));

      await _supabase
          .from('ai_summaries')
          .delete()
          .eq('profile_id', profileId)
          .eq('summary_type', SummaryType.dailyFortune)
          .lt('target_date', _formatDate(cutoffDate));

      print('[DailyMutations] 오래된 일운 정리 완료 ($daysToKeep일 이전)');
      return 0;
    } catch (e) {
      print('[DailyMutations] 정리 실패: $e');
      return 0;
    }
  }

  /// 날짜 포맷 (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// 구조화된 input_data JSON 생성
  Map<String, dynamic> _buildStructuredInputData({
    FortuneInputData? inputData,
    String? systemPrompt,
    String? userPrompt,
    required DateTime targetDate,
  }) {
    final result = <String, dynamic>{};

    // 1. 프롬프트 텍스트 (원본 보존)
    if (systemPrompt != null || userPrompt != null) {
      result['prompt_text'] = {
        if (systemPrompt != null) 'system': systemPrompt,
        if (userPrompt != null) 'user': userPrompt,
      };
    }

    // 2. 구조화된 입력 데이터
    if (inputData != null) {
      result['structured_input'] = {
        // 기본 정보
        'basic_info': {
          'name': inputData.profileName,
          'birth_date': inputData.birthDate,
          if (inputData.birthTime != null) 'birth_time': inputData.birthTime,
          'gender': inputData.genderKorean,
        },

        // 대상 날짜
        'target_date': {
          'year': targetDate.year,
          'month': targetDate.month,
          'day': targetDate.day,
          'key': _formatDate(targetDate),
        },

        // 사주 팔자
        'saju_palja': {
          'year': {
            'gan': inputData.yearGan,
            'ji': inputData.yearJi,
          },
          'month': {
            'gan': inputData.monthGan,
            'ji': inputData.monthJi,
          },
          'day': {
            'gan': inputData.dayGan,
            'ji': inputData.dayJi,
          },
          'hour': {
            'gan': inputData.hourGan,
            'ji': inputData.hourJi,
          },
        },

        // 용신/기신
        if (inputData.yongsin != null)
          'yongsin': {
            'yongsin': inputData.yongsinElement,
            'huisin': inputData.huisinElement,
            'gisin': inputData.gisinElement,
            'gusin': inputData.gusinElement,
          },

        // 일간 강약
        if (inputData.dayStrength != null)
          'day_strength': inputData.dayStrength,

        // 합충형파해
        if (inputData.hapchung != null) 'hapchung': inputData.hapchung,

        // 신살
        if (inputData.sinsal != null) 'sinsal': inputData.sinsal,

        // 십신 정보
        if (inputData.sipsinInfo != null) 'sipsin_info': inputData.sipsinInfo,
      };
    }

    return result;
  }
}
