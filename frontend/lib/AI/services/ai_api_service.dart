/// # AI API 서비스
///
/// ## 개요
/// OpenAI(GPT-5.2) 및 Google Gemini API 호출을 담당합니다.
/// **보안**: API 키는 클라이언트에 노출하지 않고, Supabase Edge Function을 통해 호출합니다.
///
/// ## 파일 위치
/// `frontend/lib/AI/services/ai_api_service.dart`
///
/// ## 아키텍처
/// ```
/// Flutter App
///     ↓
/// AiApiService.callOpenAI() / callGemini()
///     ↓
/// Supabase Edge Function (ai-openai, ai-gemini)
///     ↓
/// OpenAI API / Google Gemini API
///     ↓
/// 응답 (JSON)
/// ```
///
/// ## Edge Function 역할
/// - API 키 보안 (Supabase 환경변수로 관리)
/// - CORS 처리
/// - 응답 표준화 (성공/실패, 토큰 사용량)
///
/// ## 사용 예시
/// ```dart
/// final service = AiApiService();
///
/// // GPT-5.2 호출 (평생 사주)
/// final gptResponse = await service.callOpenAI(
///   messages: prompt.buildMessages(inputData),
///   model: 'gpt-5.2',
///   maxTokens: 4096,
///   temperature: 0.7,
/// );
///
/// // Gemini 호출 (일운)
/// final geminiResponse = await service.callGemini(
///   messages: prompt.buildMessages(inputData),
///   model: 'gemini-2.0-flash',
///   maxTokens: 2048,
///   temperature: 0.8,
/// );
/// ```
///
/// ## 응답 형식 (AiApiResponse)
/// ```dart
/// AiApiResponse(
///   success: true,
///   content: {'summary': '...', 'personality': {...}},
///   promptTokens: 1200,
///   completionTokens: 800,
///   cachedTokens: 0,
///   totalCostUsd: 0.032,
/// )
/// ```
///
/// ## 비용 계산
/// - OpenAI: `OpenAIPricing.calculateCost()` 사용
/// - Gemini: `GeminiPricing.calculateCost()` 사용
/// - 결과는 `ai_summaries.total_cost_usd`에 저장
///
/// ## 관련 파일
/// - `supabase/functions/ai-openai/index.ts`: OpenAI Edge Function
/// - `supabase/functions/ai-gemini/index.ts`: Gemini Edge Function
/// - `ai_constants.dart`: 모델명, 가격 정보

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/ai_constants.dart';
import '../core/ai_logger.dart';

/// API 응답 데이터 클래스
///
/// ## 필드 설명
/// | 필드 | 타입 | 설명 |
/// |------|------|------|
/// | success | bool | 호출 성공 여부 |
/// | content | Map? | AI 응답 (파싱된 JSON) |
/// | error | String? | 오류 메시지 (실패 시) |
/// | promptTokens | int? | 입력 토큰 수 |
/// | completionTokens | int? | 출력 토큰 수 |
/// | cachedTokens | int? | 캐시된 토큰 수 (OpenAI만) |
/// | totalCostUsd | double? | 계산된 비용 (USD) |
class AiApiResponse {
  /// 호출 성공 여부
  final bool success;

  /// AI 응답 (파싱된 JSON)
  /// 프롬프트에서 지정한 스키마에 맞는 구조
  final Map<String, dynamic>? content;

  /// 오류 메시지 (실패 시)
  final String? error;

  // ─────────────────────────────────────────────────────────────────────────
  // 토큰 사용량 및 비용
  // ─────────────────────────────────────────────────────────────────────────

  /// 입력 토큰 수 (프롬프트)
  final int? promptTokens;

  /// 출력 토큰 수 (응답)
  final int? completionTokens;

  /// 캐시된 토큰 수 (OpenAI Prompt Caching)
  /// 50% 할인된 가격으로 계산됨
  final int? cachedTokens;

  /// 총 비용 (USD)
  /// OpenAIPricing/GeminiPricing으로 계산
  final double? totalCostUsd;

  const AiApiResponse({
    required this.success,
    this.content,
    this.error,
    this.promptTokens,
    this.completionTokens,
    this.cachedTokens,
    this.totalCostUsd,
  });

  factory AiApiResponse.success({
    required Map<String, dynamic> content,
    int? promptTokens,
    int? completionTokens,
    int? cachedTokens,
    double? totalCostUsd,
  }) =>
      AiApiResponse(
        success: true,
        content: content,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        cachedTokens: cachedTokens,
        totalCostUsd: totalCostUsd,
      );

  factory AiApiResponse.failure(String error) => AiApiResponse(
        success: false,
        error: error,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// AI API 서비스
// ═══════════════════════════════════════════════════════════════════════════

/// AI API 서비스 (Edge Function 호출)
///
/// ## 싱글톤 사용 예시
/// ```dart
/// final service = AiApiService();
/// // 또는 saju_analysis_service.dart에서 주입
/// ```
class AiApiService {
  /// Supabase 클라이언트 (싱글톤)
  SupabaseClient get _client => Supabase.instance.client;

  // ─────────────────────────────────────────────────────────────────────────
  // OpenAI API (GPT-5.2)
  // ─────────────────────────────────────────────────────────────────────────

  /// OpenAI API 호출 (GPT-5.2)
  ///
  /// ## Edge Function
  /// `supabase/functions/ai-openai/index.ts`
  ///
  /// ## 파라미터
  /// - `messages`: [{role: 'system', content: ...}, {role: 'user', content: ...}]
  /// - `model`: 모델 ID (기본: 'gpt-5.2')
  /// - `maxTokens`: 최대 응답 토큰 (기본: 2000)
  /// - `temperature`: 창의성 (0.0~2.0, 기본: 0.7)
  /// - `logType`: 로그 분류 (기본: 'unknown')
  ///
  /// ## 응답 처리
  /// 1. Edge Function 호출
  /// 2. JSON 응답 파싱 (```json``` 블록 처리)
  /// 3. 토큰 사용량 추출
  /// 4. 비용 계산
  /// 5. 로컬 로그 저장
  Future<AiApiResponse> callOpenAI({
    required List<Map<String, String>> messages,
    required String model,
    int maxTokens = 2000,
    double temperature = 0.7,
    String logType = 'unknown',
    String? userId,  // ai_tasks 중복 방지용
  }) async {
    try {
      print('[AiApiService] OpenAI 호출: $model (userId: ${userId ?? "null"})');

      final response = await _client.functions.invoke(
        'ai-openai',
        body: {
          'messages': messages,
          'model': model,
          'max_tokens': maxTokens,
          'temperature': temperature,
          'response_format': {'type': 'json_object'},
          if (userId != null) 'user_id': userId,  // Edge Function에서 ai_tasks.user_id로 저장
        },
      );

      if (response.status != 200) {
        final error = response.data?['error'] ?? 'OpenAI API 오류';
        print('[AiApiService] OpenAI 오류: $error');
        return AiApiResponse.failure(error.toString());
      }

      final data = response.data as Map<String, dynamic>;
      final content = _parseJsonContent(data['content'] as String?);

      // 토큰 사용량 추출
      final usage = data['usage'] as Map<String, dynamic>?;
      final promptTokens = usage?['prompt_tokens'] as int?;
      final completionTokens = usage?['completion_tokens'] as int?;
      final cachedTokens = usage?['cached_tokens'] as int? ?? 0;

      // 비용 계산
      final totalCostUsd = _calculateOpenAICost(
        model: model,
        promptTokens: promptTokens ?? 0,
        completionTokens: completionTokens ?? 0,
        cachedTokens: cachedTokens,
      );

      print('[AiApiService] OpenAI 완료: prompt=$promptTokens, completion=$completionTokens');

      // 로컬 로그 저장
      await AiLogger.log(
        provider: 'openai',
        model: model,
        type: logType,
        request: {
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': temperature,
        },
        response: content,
        tokens: {
          'prompt': promptTokens,
          'completion': completionTokens,
          'cached': cachedTokens,
        },
        costUsd: totalCostUsd,
        success: true,
      );

      return AiApiResponse.success(
        content: content,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        cachedTokens: cachedTokens,
        totalCostUsd: totalCostUsd,
      );
    } catch (e) {
      print('[AiApiService] OpenAI 예외: $e');

      // 실패 로그 저장
      await AiLogger.log(
        provider: 'openai',
        model: model,
        type: logType,
        request: {
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': temperature,
        },
        success: false,
        error: e.toString(),
      );

      return AiApiResponse.failure(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Google Gemini API
  // ─────────────────────────────────────────────────────────────────────────

  /// Gemini API 호출
  ///
  /// ## Edge Function
  /// `supabase/functions/ai-gemini/index.ts`
  ///
  /// ## 특징
  /// - GPT보다 훨씬 빠름 (1-2초)
  /// - 비용 약 25배 저렴
  /// - JSON 응답 강제 (`responseMimeType: 'application/json'`)
  ///
  /// ## 파라미터
  /// - `messages`: [{role: 'system', content: ...}, {role: 'user', content: ...}]
  /// - `model`: 모델 ID (기본: 'gemini-2.0-flash')
  /// - `maxTokens`: 최대 응답 토큰 (기본: 1000)
  /// - `temperature`: 창의성 (0.0~2.0, 기본: 0.8)
  /// - `logType`: 로그 분류 (기본: 'unknown')
  Future<AiApiResponse> callGemini({
    required List<Map<String, String>> messages,
    required String model,
    int maxTokens = 1000,
    double temperature = 0.8,
    String logType = 'unknown',
  }) async {
    try {
      print('[AiApiService] Gemini 호출: $model');

      final response = await _client.functions.invoke(
        'ai-gemini',
        body: {
          'messages': messages,
          'model': model,
          'max_tokens': maxTokens,
          'temperature': temperature,
        },
      );

      if (response.status != 200) {
        final error = response.data?['error'] ?? 'Gemini API 오류';
        print('[AiApiService] Gemini 오류: $error');
        return AiApiResponse.failure(error.toString());
      }

      final data = response.data as Map<String, dynamic>;
      final content = _parseJsonContent(data['content'] as String?);

      // 토큰 사용량 추출
      final usage = data['usage'] as Map<String, dynamic>?;
      final promptTokens = usage?['prompt_tokens'] as int?;
      final completionTokens = usage?['completion_tokens'] as int?;

      // 비용 계산
      final totalCostUsd = _calculateGeminiCost(
        model: model,
        promptTokens: promptTokens ?? 0,
        completionTokens: completionTokens ?? 0,
      );

      print('[AiApiService] Gemini 완료: prompt=$promptTokens, completion=$completionTokens');

      // 로컬 로그 저장
      await AiLogger.log(
        provider: 'gemini',
        model: model,
        type: logType,
        request: {
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': temperature,
        },
        response: content,
        tokens: {
          'prompt': promptTokens,
          'completion': completionTokens,
        },
        costUsd: totalCostUsd,
        success: true,
      );

      return AiApiResponse.success(
        content: content,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        totalCostUsd: totalCostUsd,
      );
    } catch (e) {
      print('[AiApiService] Gemini 예외: $e');

      // 실패 로그 저장
      await AiLogger.log(
        provider: 'gemini',
        model: model,
        type: logType,
        request: {
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': temperature,
        },
        success: false,
        error: e.toString(),
      );

      return AiApiResponse.failure(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 유틸리티 메서드
  // ─────────────────────────────────────────────────────────────────────────

  /// JSON 문자열 파싱
  ///
  /// ## 처리 케이스
  /// 1. `{"key": "value"}` → 그대로 파싱
  /// 2. ` ```json\n{...}\n``` ` → 마크다운 블록 제거 후 파싱
  /// 3. 파싱 실패 → `{'raw': content}` 반환
  Map<String, dynamic> _parseJsonContent(String? content) {
    if (content == null || content.isEmpty) {
      return {};
    }

    try {
      // ```json ... ``` 형식 처리
      String cleaned = content.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }

      return jsonDecode(cleaned.trim()) as Map<String, dynamic>;
    } catch (e) {
      print('[AiApiService] JSON 파싱 실패: $e');
      return {'raw': content};
    }
  }

  /// OpenAI 비용 계산
  ///
  /// ## 계산 공식
  /// ```
  /// 입력 비용 = (promptTokens - cachedTokens) × $2.50/1M
  /// 캐시 비용 = cachedTokens × $1.25/1M (50% 할인)
  /// 출력 비용 = completionTokens × $10.00/1M
  /// 총 비용 = 입력 + 캐시 + 출력
  /// ```
  double _calculateOpenAICost({
    required String model,
    required int promptTokens,
    required int completionTokens,
    int cachedTokens = 0,
  }) {
    final pricing = OpenAIPricing.getModelPricing(model);
    if (pricing == null) return 0.0;

    final inputCost =
        (promptTokens - cachedTokens) * pricing['input']! / 1000000;
    final cachedCost = cachedTokens * pricing['cached']! / 1000000;
    final outputCost = completionTokens * pricing['output']! / 1000000;

    return inputCost + cachedCost + outputCost;
  }

  /// Gemini 비용 계산
  ///
  /// ## 계산 공식
  /// ```
  /// 입력 비용 = promptTokens × $0.10/1M
  /// 출력 비용 = completionTokens × $0.40/1M
  /// 총 비용 = 입력 + 출력
  /// ```
  ///
  /// ## 참고
  /// Gemini는 현재 캐시 할인 미적용
  double _calculateGeminiCost({
    required String model,
    required int promptTokens,
    required int completionTokens,
  }) {
    final pricing = GeminiPricing.getModelPricing(model);
    if (pricing == null) return 0.0;

    final inputCost = promptTokens * pricing['input']! / 1000000;
    final outputCost = completionTokens * pricing['output']! / 1000000;

    return inputCost + outputCost;
  }
}
