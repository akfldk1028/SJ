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

import '../../core/services/error_logging_service.dart';
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

  factory AiApiResponse.failure(
    String error, {
    int? promptTokens,
    int? completionTokens,
  }) =>
      AiApiResponse(
        success: false,
        error: error,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
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
  /// v29: taskType 파라미터 추가 - 병렬 실행 시 task 분리용
  /// - saju_base: 평생운세
  /// - monthly_fortune: 월별운세
  /// - yearly_2026: 2026 신년운세
  /// - yearly_2025: 2025 회고운세
  /// - daily_fortune: 오늘의 일운
  /// v43: reasoningEffort 파라미터 추가
  /// - "low": saju_base 분석 (속도 우선, 비용 절감)
  /// - "medium": 기본값 (기존 동작)
  /// - "high": 복잡한 분석 (품질 우선)
  Future<AiApiResponse> callOpenAI({
    required List<Map<String, String>> messages,
    required String model,
    int maxTokens = 2000,
    double temperature = 0.7,
    String logType = 'unknown',
    String? userId,
    bool runInBackground = true,  // v24: 기본값 true
    String taskType = 'saju_analysis',  // v29: task 구분용 (기본값 유지)
    String reasoningEffort = 'medium',  // v43: reasoning_effort (low/medium/high)
  }) async {
    try {
      print('[AiApiService v43] OpenAI 호출: $model (background=$runInBackground, taskType=$taskType, reasoning=$reasoningEffort, userId: ${userId ?? "null"})');

      final response = await _client.functions.invoke(
        'ai-openai',
        body: {
          'messages': messages,
          'model': model,
          'max_tokens': maxTokens,
          'temperature': temperature,
          'response_format': {'type': 'json_object'},
          'run_in_background': runInBackground,  // v24: Background 모드
          'task_type': taskType,  // v29: 병렬 실행 시 task 분리!
          'reasoning_effort': reasoningEffort,  // v43: reasoning_effort
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

        // Polling으로 결과 대기 (실패 시 sync fallback)
        return await _pollForOpenAIResult(
          taskId: taskId,
          model: model,
          logType: logType,
          messages: messages,
          maxTokens: maxTokens,
          temperature: temperature,
          userId: userId,
          taskType: taskType,
          reasoningEffort: reasoningEffort,
        );
      }

      // Sync 모드 (runInBackground=false) 또는 레거시 응답
      final content = _parseJsonContent(data['content'] as String?);

      // 토큰 사용량 추출
      final usage = data['usage'] as Map<String, dynamic>?;
      final promptTokens = usage?['prompt_tokens'] as int?;
      final completionTokens = usage?['completion_tokens'] as int?;
      final cachedTokens = usage?['cached_tokens'] as int? ?? 0;

      // v41: JSON 파싱 실패 감지 → failure 반환
      if (content.containsKey('_parse_failed')) {
        final syncParseError = 'JSON parse failed: ${content['_parse_error']}';
        print('[AiApiService v41] Sync 모드 JSON 파싱 실패 → failure 반환');
        ErrorLoggingService.logError(
          operation: 'ai_api_parse',
          errorMessage: syncParseError,
          errorType: 'json_parse',
          sourceFile: 'ai_api_service.dart',
          extraData: {'model': model, 'logType': logType, 'mode': 'sync'},
        );
        return AiApiResponse.failure(
          syncParseError,
          promptTokens: promptTokens,
          completionTokens: completionTokens,
        );
      }

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
  /// v52: 폴링 실패 시 sync API 직접 호출로 fallback
  Future<AiApiResponse> _pollForOpenAIResult({
    required String taskId,
    required String model,
    required String logType,
    required List<Map<String, String>> messages,
    required int maxTokens,
    required double temperature,
    String? userId,
    String taskType = 'saju_analysis',
    String reasoningEffort = 'medium',
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

            // v41: JSON 파싱 실패 감지 → failure 반환
            if (content.containsKey('_parse_failed')) {
              print('[AiApiService v41] JSON 파싱 실패 → failure 반환');
              final parseError = 'JSON parse failed: ${content['_parse_error']}';
              await AiLogger.log(
                provider: 'openai',
                model: model,
                type: logType,
                request: {'task_id': taskId},
                success: false,
                error: parseError,
              );
              ErrorLoggingService.logError(
                operation: 'ai_api_parse',
                errorMessage: parseError,
                errorType: 'json_parse',
                sourceFile: 'ai_api_service.dart',
                extraData: {'task_id': taskId, 'model': model, 'logType': logType},
              );
              return AiApiResponse.failure(
                parseError,
                promptTokens: promptTokens,
                completionTokens: completionTokens,
              );
            }

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
            // v41: incomplete = 응답 잘림 (max_tokens 초과) → 항상 failure
            final incUsage = data['usage'] as Map<String, dynamic>?;
            final incPromptTokens = incUsage?['prompt_tokens'] as int?;
            final incCompletionTokens = incUsage?['completion_tokens'] as int?;

            print('[AiApiService v41] 응답 잘림 (incomplete/max_tokens 초과) - 실패 처리');

            await AiLogger.log(
              provider: 'openai',
              model: model,
              type: logType,
              request: {'task_id': taskId, 'finish_reason': 'incomplete'},
              success: false,
              error: 'Response truncated (max_tokens reached)',
            );

            ErrorLoggingService.logError(
              operation: 'ai_api_incomplete',
              errorMessage: 'Response truncated (max_tokens reached)',
              errorType: 'truncation',
              sourceFile: 'ai_api_service.dart',
              extraData: {
                'task_id': taskId,
                'model': model,
                'logType': logType,
                'prompt_tokens': incPromptTokens,
                'completion_tokens': incCompletionTokens,
              },
            );

            return AiApiResponse.failure(
              'Response truncated (max_tokens reached)',
              promptTokens: incPromptTokens,
              completionTokens: incCompletionTokens,
            );

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

    // Timeout → sync API 직접 호출로 재시도
    print('[AiApiService v52] Polling timeout after ${_maxPollingAttempts * 2}s → sync 재시도');

    try {
      final syncResult = await callOpenAI(
        messages: messages,
        model: model,
        maxTokens: maxTokens,
        temperature: temperature,
        logType: logType,
        userId: userId,
        runInBackground: false,  // sync 직접 호출
        taskType: taskType,
        reasoningEffort: reasoningEffort,
      );
      if (syncResult.success) {
        print('[AiApiService v52] Sync 재시도 성공!');
        return syncResult;
      }
      print('[AiApiService v52] Sync 재시도도 실패: ${syncResult.error}');
    } catch (e) {
      print('[AiApiService v52] Sync 재시도 예외: $e');
    }

    final error = 'Polling timeout + sync retry failed';
    print('[AiApiService v52] $error');

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

      // v32: JSON 파싱 실패 감지 → failure 반환 (callOpenAI와 동일한 패턴)
      if (content.containsKey('_parse_failed')) {
        final parseError = 'JSON parse failed: ${content['_parse_error']}';
        print('[AiApiService] Gemini JSON 파싱 실패 → failure 반환');
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
          error: parseError,
        );
        return AiApiResponse.failure(parseError);
      }

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

  /// JSON 문자열 파싱 (v26: 강화된 파싱 로직)
  ///
  /// ## 처리 케이스
  /// 1. `{"key": "value"}` → 그대로 파싱
  /// 2. ` ```json\n{...}\n``` ` → 마크다운 블록 제거 후 파싱
  /// 3. 이중 이스케이프된 JSON → 2단계 파싱
  /// 4. 파싱 실패 → `{'raw': content}` 반환 (최후의 수단)
  ///
  /// ## v26 개선
  /// - 이중 이스케이프된 JSON 처리 (\\n, \\", etc.)
  /// - 마크다운 블록 내 이스케이프 처리
  /// - 여러 번 파싱 시도 후 실패 시에만 raw 반환
  Map<String, dynamic> _parseJsonContent(String? content) {
    if (content == null || content.isEmpty) {
      return {};
    }

    try {
      // 1차: 마크다운 블록 제거
      String cleaned = content.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      // 2차: 직접 파싱 시도
      try {
        return jsonDecode(cleaned) as Map<String, dynamic>;
      } catch (_) {
        // 3차: 이중 이스케이프된 경우 처리
        // AI가 JSON 문자열을 한 번 더 이스케이프한 경우
        // 예: "{\"summary\": \"...\"}" 대신 "{\\\"summary\\\": \\\"...\\\"}"
        if (cleaned.contains(r'\"') || cleaned.contains(r'\n')) {
          try {
            // 이스케이프 문자 언이스케이프
            final unescaped = cleaned
                .replaceAll(r'\"', '"')
                .replaceAll(r'\n', '\n')
                .replaceAll(r'\t', '\t')
                .replaceAll(r'\\', r'\');
            return jsonDecode(unescaped) as Map<String, dynamic>;
          } catch (_) {
            // 4차: JSON 문자열로 래핑된 경우
            // 예: "{\\"summary\\": \\"...\\"}"
            if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
              try {
                final inner = jsonDecode(cleaned) as String;
                return jsonDecode(inner) as Map<String, dynamic>;
              } catch (_) {}
            }
          }
        }
        rethrow;
      }
    } catch (e) {
      print('[AiApiService v26] JSON 파싱 실패: $e');
      print('[AiApiService v26] 원본 content (처음 200자): ${content.substring(0, content.length > 200 ? 200 : content.length)}');
      return {'raw': content, '_parse_failed': true, '_parse_error': e.toString()};
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
  /// [systemPrompt]와 [userPrompt]를 받아 messages 배열로 변환 후 API 호출
  /// v7.0: Gemini 모델 자동 감지 및 라우팅
  /// - gemini-* 모델 → callGemini() 사용
  /// - 그 외 → callOpenAI() 사용
  /// v29: taskType 파라미터 추가 - 병렬 실행 시 task 분리용
  /// v43: reasoningEffort 파라미터 추가
  Future<ChatResponse> chat({
    required String model,
    required String systemPrompt,
    required String userPrompt,
    int maxTokens = 2000,
    double temperature = 0.7,
    String logType = 'fortune',
    String? userId,
    String taskType = 'saju_analysis',  // v29: 병렬 실행 시 task 분리!
    String reasoningEffort = 'medium',  // v43: reasoning_effort
  }) async {
    final messages = [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt},
    ];

    // v7.0: Gemini 모델 자동 라우팅
    final isGemini = model.toLowerCase().contains('gemini');

    if (isGemini) {
      print('[AiApiService] 🔀 Gemini 모델 감지 → callGemini() 라우팅: $model');
      final response = await callGemini(
        messages: messages,
        model: model,
        maxTokens: maxTokens,
        temperature: temperature,
        logType: logType,
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

    // OpenAI 모델 - v29: taskType 전달, v43: reasoningEffort 전달
    final response = await callOpenAI(
      messages: messages,
      model: model,
      maxTokens: maxTokens,
      temperature: temperature,
      logType: logType,
      userId: userId,
      taskType: taskType,  // v29: 병렬 실행 시 task 분리!
      reasoningEffort: reasoningEffort,  // v43: reasoning_effort
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
