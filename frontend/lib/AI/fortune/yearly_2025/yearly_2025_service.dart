/// # 2025 회고 운세 서비스
///
/// ## 개요
/// 2025 회고 운세 분석 오케스트레이션
/// 캐시 확인 → API 호출 → 저장
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/yearly_2025/yearly_2025_service.dart`

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ai_constants.dart';
import '../../services/ai_api_service.dart';
import '../common/fortune_input_data.dart';
import 'yearly_2025_mutations.dart';
import 'yearly_2025_prompt.dart';
import 'yearly_2025_queries.dart';

/// 2025 회고 운세 분석 결과
class Yearly2025Result {
  final bool success;
  final Map<String, dynamic>? content;
  final String? errorMessage;
  final bool fromCache;
  final int? promptTokens;
  final int? completionTokens;
  final double? totalCost;

  const Yearly2025Result({
    required this.success,
    this.content,
    this.errorMessage,
    this.fromCache = false,
    this.promptTokens,
    this.completionTokens,
    this.totalCost,
  });

  factory Yearly2025Result.fromCache(Map<String, dynamic> content) {
    return Yearly2025Result(
      success: true,
      content: content,
      fromCache: true,
    );
  }

  factory Yearly2025Result.error(String message) {
    return Yearly2025Result(
      success: false,
      errorMessage: message,
    );
  }
}

/// 2025 회고 운세 서비스
class Yearly2025Service {
  final SupabaseClient _supabase;
  final AIApiService _aiApiService;

  late final Yearly2025Queries _queries;
  late final Yearly2025Mutations _mutations;

  Yearly2025Service({
    required SupabaseClient supabase,
    required AIApiService aiApiService,
  })  : _supabase = supabase,
        _aiApiService = aiApiService {
    _queries = Yearly2025Queries(_supabase);
    _mutations = Yearly2025Mutations(_supabase);
  }

  /// 2025 회고 운세 분석 실행
  ///
  /// ## 플로우
  /// 1. 캐시 확인 → 있으면 반환 (무기한 캐시)
  /// 2. 프롬프트 생성
  /// 3. GPT-5-mini API 호출
  /// 4. 결과 저장
  /// 5. 결과 반환
  ///
  /// [userId] 사용자 UUID
  /// [profileId] 프로필 UUID
  /// [inputData] 입력 데이터 (saju_base 포함)
  /// [forceRefresh] 캐시 무시하고 재분석 (일반적으로 사용 안함)
  Future<Yearly2025Result> analyze({
    required String userId,
    required String profileId,
    required FortuneInputData inputData,
    bool forceRefresh = false,
  }) async {
    try {
      // 1. 캐시 확인 (2025 회고는 무기한이므로 보통 캐시 사용)
      if (!forceRefresh) {
        final cachedContent = await _queries.getContent(profileId);
        if (cachedContent != null) {
          return Yearly2025Result.fromCache(cachedContent);
        }
      }

      // 2. 프롬프트 생성
      final prompt = Yearly2025Prompt(inputData: inputData);

      // 3. GPT-5-mini API 호출
      final apiResponse = await _aiApiService.chat(
        model: prompt.modelName,
        systemPrompt: prompt.systemPrompt,
        userPrompt: prompt.buildUserPrompt(),
        maxTokens: prompt.maxTokens,
        temperature: prompt.temperature,
      );

      if (!apiResponse.success) {
        return Yearly2025Result.error(
          apiResponse.errorMessage ?? 'API 호출 실패',
        );
      }

      // 4. 응답 파싱
      final content = _parseResponse(apiResponse.content ?? '');
      if (content == null) {
        return Yearly2025Result.error('응답 파싱 실패');
      }

      // 5. 비용 계산
      final totalCost = OpenAIPricing.calculateCost(
        model: prompt.modelName,
        promptTokens: apiResponse.promptTokens ?? 0,
        completionTokens: apiResponse.completionTokens ?? 0,
      );

      // 6. 결과 저장
      await _mutations.save(
        userId: userId,
        profileId: profileId,
        content: content,
        modelName: prompt.modelName,
        promptTokens: apiResponse.promptTokens ?? 0,
        completionTokens: apiResponse.completionTokens ?? 0,
        totalCost: totalCost,
      );

      // 7. 결과 반환
      return Yearly2025Result(
        success: true,
        content: content,
        fromCache: false,
        promptTokens: apiResponse.promptTokens,
        completionTokens: apiResponse.completionTokens,
        totalCost: totalCost,
      );
    } catch (e) {
      return Yearly2025Result.error(e.toString());
    }
  }

  /// 캐시 확인만
  Future<Map<String, dynamic>?> getCached(String profileId) {
    return _queries.getContent(profileId);
  }

  /// 캐시 존재 여부
  Future<bool> hasCached(String profileId) {
    return _queries.exists(profileId);
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
