/// # 일운 서비스
///
/// ## 개요
/// 오늘의 운세 분석 오케스트레이션
/// 캐시 확인 → Gemini API 호출 → 저장
/// 한국 시간(KST) 기준으로 일 전환 처리
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/daily/daily_service.dart`
///
/// ## 모델
/// Gemini 3.0 Flash (Google)

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ai_constants.dart';
import '../../services/ai_api_service.dart';
import '../common/fortune_input_data.dart';
import '../common/korea_date_utils.dart';
import 'daily_mutations.dart';
import 'daily_prompt.dart';
import 'daily_queries.dart';

/// 일운 분석 결과
class DailyResult {
  final bool success;
  final String? summaryId;
  final Map<String, dynamic>? content;
  final String? errorMessage;
  final bool fromCache;
  final int? promptTokens;
  final int? completionTokens;
  final double? totalCost;

  const DailyResult({
    required this.success,
    this.summaryId,
    this.content,
    this.errorMessage,
    this.fromCache = false,
    this.promptTokens,
    this.completionTokens,
    this.totalCost,
  });

  factory DailyResult.fromCache(Map<String, dynamic> cachedRow) {
    return DailyResult(
      success: true,
      summaryId: cachedRow['id']?.toString(),
      content: cachedRow['content'] as Map<String, dynamic>?,
      fromCache: true,
    );
  }

  factory DailyResult.error(String message) {
    return DailyResult(
      success: false,
      errorMessage: message,
    );
  }
}

/// 일운 서비스
class DailyService {
  final SupabaseClient _supabase;
  final AIApiService _aiApiService;

  late final DailyQueries _queries;
  late final DailyMutations _mutations;

  DailyService({
    required SupabaseClient supabase,
    required AIApiService aiApiService,
  })  : _supabase = supabase,
        _aiApiService = aiApiService {
    _queries = DailyQueries(_supabase);
    _mutations = DailyMutations(_supabase);
  }

  /// 일운 분석 실행
  ///
  /// [userId] 사용자 UUID
  /// [profileId] 프로필 UUID
  /// [inputData] 입력 데이터 (saju_base 포함)
  /// [targetDate] 대상 날짜 (기본: 한국 시간 기준 오늘)
  /// [forceRefresh] 캐시 무시하고 재분석
  /// [locale] 언어 코드 (ko, ja, en)
  Future<DailyResult> analyze({
    required String userId,
    required String profileId,
    required FortuneInputData inputData,
    DateTime? targetDate,
    bool forceRefresh = false,
    String locale = 'ko',
  }) async {
    // 한국 시간 기준으로 기본값 설정
    final date = targetDate ?? KoreaDateUtils.today;
    final targetYear = date.year;
    final targetMonth = date.month;
    final targetDay = date.day;

    print('[DailyService] 🚀 분석 시작: profileId=$profileId, date=$targetYear-$targetMonth-$targetDay');

    try {
      // 1. 캐시 확인 (전체 row 조회 - id 포함)
      if (!forceRefresh) {
        final cachedRow = await _queries.getCached(profileId, date, locale: locale);
        if (cachedRow != null) {
          print('[DailyService] 📦 캐시에서 반환');
          return DailyResult.fromCache(cachedRow);
        }
      }

      // 2. 프롬프트 생성
      print('[DailyService] 📝 프롬프트 생성');
      final prompt = DailyPrompt(
        inputData: inputData,
        targetDate: date,
        locale: locale,
      );

      // 3. Gemini API 호출 (Google)
      print('[DailyService] 🤖 Gemini API 호출 시작...');
      final apiResponse = await _aiApiService.chat(
        model: prompt.modelName,
        systemPrompt: prompt.systemPrompt,
        userPrompt: prompt.buildUserPrompt(),
        maxTokens: prompt.maxTokens,
        temperature: prompt.temperature,
        userId: userId,
        taskType: 'daily_fortune', // v29: 병렬 실행 시 task 분리
      );
      print('[DailyService] 📡 API 응답: success=${apiResponse.success}');

      if (!apiResponse.success) {
        print('[DailyService] ❌ API 실패: ${apiResponse.errorMessage}');
        return DailyResult.error(
          apiResponse.errorMessage ?? 'API 호출 실패',
        );
      }

      // 4. 응답 파싱
      print('[DailyService] 🔍 응답 파싱 시작');
      final content = _parseResponse(apiResponse.content ?? '');
      if (content == null) {
        print('[DailyService] ❌ 파싱 실패');
        return DailyResult.error('응답 파싱 실패');
      }
      print('[DailyService] ✅ 파싱 성공');

      // 5. 비용 계산 (Gemini 3.0 Flash)
      final totalCost = GeminiPricing.calculateCost(
        model: prompt.modelName,
        promptTokens: apiResponse.promptTokens ?? 0,
        completionTokens: apiResponse.completionTokens ?? 0,
      );
      print('[DailyService] 💰 비용: \$$totalCost');

      // 6. 결과 저장 (전체 프롬프트 포함)
      print('[DailyService] 💾 DB 저장 시작...');
      final savedRow = await _mutations.save(
        userId: userId,
        profileId: profileId,
        targetDate: date,
        content: content,
        modelName: prompt.modelName,
        promptTokens: apiResponse.promptTokens ?? 0,
        completionTokens: apiResponse.completionTokens ?? 0,
        totalCost: totalCost,
        inputData: inputData,
        systemPrompt: prompt.systemPrompt,
        userPrompt: prompt.buildUserPrompt(),
        locale: locale,
      );
      final summaryId = savedRow['id']?.toString();
      print('[DailyService] ✅ DB 저장 완료! summaryId=$summaryId');

      // 7. 결과 반환
      return DailyResult(
        success: true,
        summaryId: summaryId,
        content: content,
        fromCache: false,
        promptTokens: apiResponse.promptTokens,
        completionTokens: apiResponse.completionTokens,
        totalCost: totalCost,
      );
    } catch (e) {
      print('[DailyService] ❌ 에러: $e');
      return DailyResult.error(e.toString());
    }
  }

  /// 오늘 일운 분석 (편의 메서드)
  Future<DailyResult> analyzeToday({
    required String userId,
    required String profileId,
    required FortuneInputData inputData,
    bool forceRefresh = false,
    String locale = 'ko',
  }) async {
    return analyze(
      userId: userId,
      profileId: profileId,
      inputData: inputData,
      forceRefresh: forceRefresh,
      locale: locale,
    );
  }

  /// 캐시 확인만 (한국 시간 기준)
  Future<Map<String, dynamic>?> getCached(
    String profileId, {
    DateTime? targetDate,
    String locale = 'ko',
  }) {
    final date = targetDate ?? KoreaDateUtils.today;
    return _queries.getContent(profileId, date, locale: locale);
  }

  /// 오늘 캐시 확인
  Future<Map<String, dynamic>?> getTodayCached(String profileId, {String locale = 'ko'}) {
    return _queries.getTodayContent(profileId, locale: locale);
  }

  /// 캐시 존재 여부 (한국 시간 기준)
  Future<bool> hasCached(
    String profileId, {
    DateTime? targetDate,
    String locale = 'ko',
  }) {
    final date = targetDate ?? KoreaDateUtils.today;
    return _queries.exists(profileId, date, locale: locale);
  }

  /// 오늘 캐시 존재 여부
  Future<bool> hasTodayCached(String profileId, {String locale = 'ko'}) {
    return _queries.existsToday(profileId, locale: locale);
  }

  /// 최근 일운 목록 조회
  Future<List<Map<String, dynamic>>> getRecentDays(
    String profileId, {
    int days = 7,
    String locale = 'ko',
  }) {
    return _queries.getRecentDays(profileId, days: days, locale: locale);
  }

  /// API 응답 파싱
  Map<String, dynamic>? _parseResponse(String response) {
    try {
      String jsonStr = response;

      // ```json ... ``` 블록 추출
      final jsonMatch = RegExp(r'```json\s*([\s\S]*?)\s*```').firstMatch(response);
      if (jsonMatch != null) {
        jsonStr = jsonMatch.group(1) ?? response;
      } else {
        // JSON 객체 직접 추출
        final braceMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
        if (braceMatch != null) {
          jsonStr = braceMatch.group(0) ?? response;
        }
      }

      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      print('[DailyService] 파싱 에러: $e');
      return null;
    }
  }
}
