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

import 'dart:async';
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
  // v24 Background 모드 Polling 설정
  // ─────────────────────────────────────────────────────────────────────────

  /// 최대 폴링 횟수 (GPT-5.2 reasoning: 60-120초, 최대 4분)
  static const int _maxPollingAttempts = 120;

  /// 폴링 간격 (2초 × 120회 = 최대 240초)
  static const Duration _pollingInterval = Duration(seconds: 2);

  // ─────────────────────────────────────────────────────────────────────────
  // OpenAI API (GPT-5.2)
  // ─────────────────────────────────────────────────────────────────────────

  /// OpenAI API 호출 (GPT-5.2 - v24 Background 모드 지원)
  ///
  /// ## Edge Function
  /// `supabase/functions/ai-openai/index.ts` (v24)
  ///
  /// ## v24 Background 모드 (기본값)
  /// - Supabase 150초 walltime 제한 완전 회피
  /// - OpenAI Responses API background=true 모드 사용
  /// - task_id 반환 → ai-openai-result로 polling
  ///
  /// ## 파라미터
  /// - `messages`: [{role: 'system', content: ...}, {role: 'user', content: ...}]
  /// - `model`: 모델 ID (기본: 'gpt-5.2')
  /// - `maxTokens`: 최대 응답 토큰 (기본: 2000)
  /// - `temperature`: 창의성 (0.0~2.0, 기본: 0.7)
  /// - `logType`: 로그 분류 (기본: 'unknown')
  /// - `runInBackground`: Background 모드 사용 여부 (기본: true)
  ///
  /// ## 응답 처리
  /// 1. Edge Function 호출 (run_in_background: true)
  /// 2. task_id 반환 받음
  /// 3. ai-openai-result Edge Function으로 polling
  /// 4. completed 상태일 때 결과 반환
  /// 5. 토큰 사용량/비용 계산
  /// 6. 로컬 로그 저장
  Future<AiApiResponse> callOpenAI({
    required List<Map<String, String>> messages,
    required String model,
    int maxTokens = 2000,
    double temperature = 0.7,
    String logType = 'unknown',
    String? userId,
    bool runInBackground = true,  // v24: 기본값 true
  }) async {
    try {
      print('[AiApiService v24] OpenAI 호출: $model (background=$runInBackground, userId: ${userId ?? "null"})');

      final response = await _client.functions.invoke(
        'ai-openai',
        body: {
          'messages': messages,
          'model': model,
          'max_tokens': maxTokens,
          'temperature': temperature,
          'response_format': {'type': 'json_object'},
          'run_in_background': runInBackground,  // v24: Background 모드
          if (userId != null) 'user_id': userId,
        },
      );

      if (response.status != 200) {
        final error = response.data?['error'] ?? 'OpenAI API 오류';
        print('[AiApiService v24] OpenAI 오류: $error');
        return AiApiResponse.failure(error.toString());
      }

      final data = response.data as Map<String, dynamic>;

      // v24: Background 모드인 경우 task_id로 polling
      if (runInBackground && data['task_id'] != null) {
        final taskId = data['task_id'] as String;
        final openaiResponseId = data['openai_response_id'] as String?;
        print('[AiApiService v24] Task created: $taskId');
        print('[AiApiService v24] OpenAI Response ID: $openaiResponseId');

        // Polling으로 결과 대기
        return await _pollForOpenAIResult(
          taskId: taskId,
          model: model,
          logType: logType,
          messages: messages,
          maxTokens: maxTokens,
          temperature: temperature,
        );
      }

      // Sync 모드 (runInBackground=false) 또는 레거시 응답
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

      print('[AiApiService v24] OpenAI 완료 (sync): prompt=$promptTokens, completion=$completionTokens');

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
      print('[AiApiService v24] OpenAI 예외: $e');

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

  /// v24: Task 결과 Polling (OpenAI Responses API)
  ///
  /// ai-openai-result Edge Function 호출
  /// → OpenAI /v1/responses/{id} 직접 polling
  /// → 상태: queued → in_progress → completed
  Future<AiApiResponse> _pollForOpenAIResult({
    required String taskId,
    required String model,
    required String logType,
    required List<Map<String, String>> messages,
    required int maxTokens,
    required double temperature,
  }) async {
    for (int attempt = 0; attempt < _maxPollingAttempts; attempt++) {
      try {
        final response = await _client.functions.invoke(
          'ai-openai-result',
          body: {'task_id': taskId},
        );

        if (response.status != 200) {
          print('[AiApiService v24] Polling error: status=${response.status}');
          await Future.delayed(_pollingInterval);
          continue;
        }

        final data = response.data as Map<String, dynamic>;
        final status = data['status'] as String?;

        if (attempt % 5 == 0) {
          print('[AiApiService v24] Polling attempt $attempt: status=$status');
        }

        switch (status) {
          case 'completed':
            print('[AiApiService v24] Task completed after $attempt attempts');

            // v24: content가 최상위 레벨에 있음
            final contentStr = data['content'] as String?;
            final content = _parseJsonContent(contentStr);

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

            print('[AiApiService v24] OpenAI 완료 (polling): prompt=$promptTokens, completion=$completionTokens');

            // 로컬 로그 저장
            await AiLogger.log(
              provider: 'openai',
              model: model,
              type: logType,
              request: {
                'messages': messages,
                'max_tokens': maxTokens,
                'temperature': temperature,
                'task_id': taskId,
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

          case 'incomplete':
            // v25: incomplete 상태에서 content가 있으면 성공으로 처리
            // max_tokens 도달로 응답이 잘렸지만 부분 콘텐츠 사용 가능
            final incompleteContent = data['content'] as String?;
            if (incompleteContent != null && incompleteContent.isNotEmpty) {
              print('[AiApiService v25] incomplete but has content (${incompleteContent.length} chars)');

              final parsedContent = _parseJsonContent(incompleteContent);
              final incUsage = data['usage'] as Map<String, dynamic>?;
              final incPromptTokens = incUsage?['prompt_tokens'] as int?;
              final incCompletionTokens = incUsage?['completion_tokens'] as int?;
              final incCachedTokens = incUsage?['cached_tokens'] as int? ?? 0;

              final incTotalCost = _calculateOpenAICost(
                model: model,
                promptTokens: incPromptTokens ?? 0,
                completionTokens: incCompletionTokens ?? 0,
                cachedTokens: incCachedTokens,
              );

              print('[AiApiService v25] incomplete 부분 완료: prompt=$incPromptTokens, completion=$incCompletionTokens');

              await AiLogger.log(
                provider: 'openai',
                model: model,
                type: logType,
                request: {'task_id': taskId, 'finish_reason': 'incomplete'},
                response: parsedContent,
                tokens: {
                  'prompt': incPromptTokens,
                  'completion': incCompletionTokens,
                  'cached': incCachedTokens,
                },
                costUsd: incTotalCost,
                success: true,
              );

              return AiApiResponse.success(
                content: parsedContent,
                promptTokens: incPromptTokens,
                completionTokens: incCompletionTokens,
                cachedTokens: incCachedTokens,
                totalCostUsd: incTotalCost,
              );
            }
            // content 없으면 아래 failed/cancelled와 같이 실패 처리
            final incError = data['error'] ?? 'Task incomplete: no content';
            print('[AiApiService v25] Task incomplete without content');

            await AiLogger.log(
              provider: 'openai',
              model: model,
              type: logType,
              request: {'task_id': taskId},
              success: false,
              error: incError.toString(),
            );

            return AiApiResponse.failure(incError.toString());

          case 'failed':
          case 'cancelled':
            // failed: API 오류
            // cancelled: 사용자 또는 시스템에 의해 취소됨
            final error = data['error'] ?? 'Task $status';
            print('[AiApiService v25] Task $status: $error');

            await AiLogger.log(
              provider: 'openai',
              model: model,
              type: logType,
              request: {'task_id': taskId},
              success: false,
              error: error.toString(),
            );

            return AiApiResponse.failure(error.toString());

          case 'queued':
          case 'in_progress':
            // v24: OpenAI 상태값 그대로 사용
            if (attempt % 10 == 0) {
              print('[AiApiService v24] OpenAI processing... ($status)');
            }
            await Future.delayed(_pollingInterval);
            break;

          case 'pending':
          case 'processing':
            // 레거시 상태값 호환
            await Future.delayed(_pollingInterval);
            break;

          default:
            print('[AiApiService v24] Unknown status: $status');
            await Future.delayed(_pollingInterval);
            break;
        }
      } catch (e) {
        print('[AiApiService v24] Polling error: $e');
        await Future.delayed(_pollingInterval);
      }
    }

    // Timeout
    final error = 'Polling timeout after ${_maxPollingAttempts * 2}s';
    print('[AiApiService v24] $error');

    await AiLogger.log(
      provider: 'openai',
      model: model,
      type: logType,
      request: {'task_id': taskId},
      success: false,
      error: error,
    );

    return AiApiResponse.failure(error);
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

  // ─────────────────────────────────────────────────────────────────────────
  // Chat 편의 메서드 (Fortune 서비스용)
  // ─────────────────────────────────────────────────────────────────────────

  /// Chat 편의 메서드 - Fortune 서비스에서 사용
  ///
  /// [systemPrompt]와 [userPrompt]를 받아 messages 배열로 변환 후 OpenAI 호출
  /// 내부적으로 [callOpenAI]를 사용
  Future<ChatResponse> chat({
    required String model,
    required String systemPrompt,
    required String userPrompt,
    int maxTokens = 2000,
    double temperature = 0.7,
    String logType = 'fortune',
    String? userId,
  }) async {
    final messages = [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt},
    ];

    final response = await callOpenAI(
      messages: messages,
      model: model,
      maxTokens: maxTokens,
      temperature: temperature,
      logType: logType,
      userId: userId,
    );

    return ChatResponse(
      success: response.success,
      content: response.content != null
          ? jsonEncode(response.content)
          : null,
      errorMessage: response.error,
      promptTokens: response.promptTokens,
      completionTokens: response.completionTokens,
    );
  }
}

/// Chat 응답 클래스 (Fortune 서비스 호환용)
class ChatResponse {
  final bool success;
  final String? content;
  final String? errorMessage;
  final int? promptTokens;
  final int? completionTokens;

  const ChatResponse({
    required this.success,
    this.content,
    this.errorMessage,
    this.promptTokens,
    this.completionTokens,
  });
}

/// Fortune 서비스와의 호환성을 위한 타입 별칭
/// (AIApiService 네이밍 사용 중인 코드와 호환)
typedef AIApiService = AiApiService;
