/// # 이번달 운세 서비스
///
/// ## 개요
/// 이번달 운세 분석 오케스트레이션
/// 캐시 확인 → API 호출 → 저장
/// 한국 시간(KST) 기준으로 월 전환 처리
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/monthly/monthly_service.dart`

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ai_constants.dart';
import '../../services/ai_api_service.dart';
import '../common/fortune_input_data.dart';
import '../common/korea_date_utils.dart';
import 'monthly_mutations.dart';
import 'monthly_prompt.dart';
import 'monthly_queries.dart';

/// 이번달 운세 분석 결과
class MonthlyResult {
  final bool success;
  final Map<String, dynamic>? content;
  final String? errorMessage;
  final bool fromCache;
  final int? promptTokens;
  final int? completionTokens;
  final double? totalCost;

  const MonthlyResult({
    required this.success,
    this.content,
    this.errorMessage,
    this.fromCache = false,
    this.promptTokens,
    this.completionTokens,
    this.totalCost,
  });

  factory MonthlyResult.fromCache(Map<String, dynamic> content) {
    return MonthlyResult(
      success: true,
      content: content,
      fromCache: true,
    );
  }

  factory MonthlyResult.error(String message) {
    return MonthlyResult(
      success: false,
      errorMessage: message,
    );
  }
}

/// 이번달 운세 서비스
class MonthlyService {
  final SupabaseClient _supabase;
  final AIApiService _aiApiService;

  late final MonthlyQueries _queries;
  late final MonthlyMutations _mutations;

  MonthlyService({
    required SupabaseClient supabase,
    required AIApiService aiApiService,
  })  : _supabase = supabase,
        _aiApiService = aiApiService {
    _queries = MonthlyQueries(_supabase);
    _mutations = MonthlyMutations(_supabase);
  }

  /// 이번달 운세 분석 실행
  ///
  /// [userId] 사용자 UUID
  /// [profileId] 프로필 UUID
  /// [inputData] 입력 데이터 (saju_base 포함)
  /// [year] 대상 연도 (기본: 한국 시간 기준 현재 연도)
  /// [month] 대상 월 (기본: 한국 시간 기준 현재 월)
  /// [forceRefresh] 캐시 무시하고 재분석
  Future<MonthlyResult> analyze({
    required String userId,
    required String profileId,
    required FortuneInputData inputData,
    int? year,
    int? month,
    bool forceRefresh = false,
  }) async {
    // 한국 시간 기준으로 기본값 설정
    final targetYear = year ?? KoreaDateUtils.currentYear;
    final targetMonth = month ?? KoreaDateUtils.currentMonth;

    print('[MonthlyService] 🚀 분석 시작: profileId=$profileId, year=$targetYear, month=$targetMonth');

    try {
      // 1. 캐시 확인
      if (!forceRefresh) {
        final cachedContent = await _queries.getContent(
          profileId,
          year: targetYear,
          month: targetMonth,
        );
        if (cachedContent != null) {
          print('[MonthlyService] 📦 캐시에서 반환');
          return MonthlyResult.fromCache(cachedContent);
        }
      }

      // 2. 프롬프트 생성
      print('[MonthlyService] 📝 프롬프트 생성');
      final prompt = MonthlyPrompt(
        inputData: inputData,
        targetYear: targetYear,
        targetMonth: targetMonth,
      );

      // 3. GPT-5-mini API 호출
      print('[MonthlyService] 🤖 API 호출 시작...');
      final apiResponse = await _aiApiService.chat(
        model: prompt.modelName,
        systemPrompt: prompt.systemPrompt,
        userPrompt: prompt.buildUserPrompt(),
        maxTokens: prompt.maxTokens,
        temperature: prompt.temperature,
        userId: userId,
      );
      print('[MonthlyService] 📡 API 응답: success=${apiResponse.success}');

      if (!apiResponse.success) {
        print('[MonthlyService] ❌ API 실패: ${apiResponse.errorMessage}');
        return MonthlyResult.error(
          apiResponse.errorMessage ?? 'API 호출 실패',
        );
      }

      // 4. 응답 파싱
      print('[MonthlyService] 🔍 응답 파싱 시작');
      final content = _parseResponse(apiResponse.content ?? '');
      if (content == null) {
        print('[MonthlyService] ❌ 파싱 실패');
        return MonthlyResult.error('응답 파싱 실패');
      }
      print('[MonthlyService] ✅ 파싱 성공');

      // 5. 비용 계산
      final totalCost = OpenAIPricing.calculateCost(
        model: prompt.modelName,
        promptTokens: apiResponse.promptTokens ?? 0,
        completionTokens: apiResponse.completionTokens ?? 0,
      );
      print('[MonthlyService] 💰 비용: \$$totalCost');

      // 6. 결과 저장 (전체 프롬프트 포함)
      print('[MonthlyService] 💾 DB 저장 시작...');
      await _mutations.save(
        userId: userId,
        profileId: profileId,
        targetYear: targetYear,
        targetMonth: targetMonth,
        content: content,
        modelName: prompt.modelName,
        promptTokens: apiResponse.promptTokens ?? 0,
        completionTokens: apiResponse.completionTokens ?? 0,
        totalCost: totalCost,
        inputData: inputData,
        systemPrompt: prompt.systemPrompt,
        userPrompt: prompt.buildUserPrompt(),
      );
      print('[MonthlyService] ✅ DB 저장 완료!');

      // 7. 결과 반환
      return MonthlyResult(
        success: true,
        content: content,
        fromCache: false,
        promptTokens: apiResponse.promptTokens,
        completionTokens: apiResponse.completionTokens,
        totalCost: totalCost,
      );
    } catch (e) {
      print('[MonthlyService] ❌ 에러: $e');
      return MonthlyResult.error(e.toString());
    }
  }

  /// 현재 월 운세 분석 (편의 메서드)
  Future<MonthlyResult> analyzeCurrentMonth({
    required String userId,
    required String profileId,
    required FortuneInputData inputData,
    bool forceRefresh = false,
  }) async {
    return analyze(
      userId: userId,
      profileId: profileId,
      inputData: inputData,
      forceRefresh: forceRefresh,
    );
  }

  /// 캐시 확인만 (한국 시간 기준)
  Future<Map<String, dynamic>?> getCached(
    String profileId, {
    int? year,
    int? month,
  }) {
    return _queries.getContent(
      profileId,
      year: year ?? KoreaDateUtils.currentYear,
      month: month ?? KoreaDateUtils.currentMonth,
    );
  }

  /// 캐시 존재 여부 (한국 시간 기준)
  Future<bool> hasCached(
    String profileId, {
    int? year,
    int? month,
  }) {
    return _queries.exists(
      profileId,
      year: year ?? KoreaDateUtils.currentYear,
      month: month ?? KoreaDateUtils.currentMonth,
    );
  }

  /// API 응답 파싱
  Map<String, dynamic>? _parseResponse(String response) {
    try {
      String jsonStr = response;

      final jsonMatch = RegExp(r'```json\s*([\s\S]*?)\s*```').firstMatch(response);
      if (jsonMatch != null) {
        jsonStr = jsonMatch.group(1) ?? response;
      } else {
        final braceMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
        if (braceMatch != null) {
          jsonStr = braceMatch.group(0) ?? response;
        }
      }

      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
