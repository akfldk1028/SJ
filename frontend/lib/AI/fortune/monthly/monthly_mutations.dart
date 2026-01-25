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
import '../common/fortune_input_data.dart';
import '../common/korea_date_utils.dart';
import 'monthly_queries.dart' show kMonthlyFortunePromptVersion;

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
  /// [inputData] 분석에 사용된 입력 데이터 (선택)
  /// [systemPrompt] AI에게 전달된 시스템 프롬프트 (선택)
  /// [userPrompt] AI에게 전달된 사용자 프롬프트 (선택)
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
    FortuneInputData? inputData,
    String? systemPrompt,
    String? userPrompt,
  }) async {
    print('[MonthlyMutations] 저장 시작: profileId=$profileId, year=$targetYear, month=$targetMonth');

    // 만료 시간: 해당 월 말일 23:59:59 KST
    // 월운은 해당 월 끝까지 유효
    final expiresAt = KoreaDateUtils.expiryEndOfMonth(targetYear, targetMonth);

    // input_data를 구조화된 JSON으로 저장
    final inputDataJson = _buildStructuredInputData(
      inputData: inputData,
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      targetYear: targetYear,
      targetMonth: targetMonth,
    );

    final data = {
      'user_id': userId,
      'profile_id': profileId,
      'summary_type': SummaryType.monthlyFortune,
      'target_year': targetYear,
      'target_month': targetMonth,
      'content': content,
      'input_data': inputDataJson.isNotEmpty ? inputDataJson : null,
      'model_name': modelName,
      'model_provider': ModelProvider.openai,
      'prompt_tokens': promptTokens,
      'completion_tokens': completionTokens,
      'total_cost_usd': totalCost,
      'expires_at': expiresAt,
      'updated_at': KoreaDateUtils.nowKoreaIso8601,
      'prompt_version': kMonthlyFortunePromptVersion, // 월운 프롬프트 버전
    };

    try {
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

      print('[MonthlyMutations] ✅ DB 저장 성공: ${response['id']}');
      return response;
    } catch (e) {
      print('[MonthlyMutations] ❌ DB 저장 실패: $e');
      rethrow;
    }
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

  /// 구조화된 input_data JSON 생성
  Map<String, dynamic> _buildStructuredInputData({
    FortuneInputData? inputData,
    String? systemPrompt,
    String? userPrompt,
    required int targetYear,
    required int targetMonth,
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

        // 대상 기간
        'target_period': {
          'year': targetYear,
          'month': targetMonth,
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
