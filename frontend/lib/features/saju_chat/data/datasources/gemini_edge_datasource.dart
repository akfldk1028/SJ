import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/error_logging_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../AI/core/ai_logger.dart';
import '../../../../AI/core/ai_constants.dart';
import '../../../../AI/jina/context/chat_history_manager.dart';
import '../services/conversation_window_manager.dart';
import '../services/token_counter.dart';
import '../services/sse_stream_client.dart';

/// Gemini API 응답 (토큰 사용량 포함)
class GeminiResponse {
  final String content;
  final int? promptTokenCount;
  final int? candidatesTokenCount;
  final int? totalTokenCount;
  final int? thoughtsTokenCount;
  final String? finishReason;

  const GeminiResponse({
    required this.content,
    this.promptTokenCount,
    this.candidatesTokenCount,
    this.totalTokenCount,
    this.thoughtsTokenCount,
    this.finishReason,
  });

  /// 쿼타용 토큰 사용량 (candidatesTokenCount = output only, 공식 문서 확인)
  int? get tokensUsed => candidatesTokenCount;
}

/// Gemini Edge Function 데이터소스
///
/// Supabase Edge Function (ai-gemini)을 통해 Gemini API 호출
/// API 키가 서버에만 저장되어 보안 강화
class GeminiEdgeDatasource {
  final List<Map<String, dynamic>> _conversationHistory = [];
  String? _systemPrompt;
  bool _isInitialized = false;
  late final Dio _dio;
  late final SseStreamClient _sseClient;

  /// 대화 윈도우 관리자 (토큰 제한)
  final ConversationWindowManager _windowManager = ConversationWindowManager();

  /// 대화 요약 관리자 (맥락 유지)
  final ChatHistoryManager _historyManager = ChatHistoryManager();

  /// 마지막으로 요약을 생성한 시점의 제거 메시지 수 (중복 요약 방지)
  int _lastSummarizedRemovedCount = 0;

  /// 마지막 트리밍 정보
  WindowedConversation? _lastWindowResult;

  /// 새 세션 플래그 (첫 메시지에만 true)
  bool _isNewSession = false;

  /// v27: Context Caching용 세션 ID
  String? _sessionId;

  /// Edge Function URL
  String get _edgeFunctionUrl {
    final baseUrl = SupabaseService.supabaseUrl ?? '';
    return '$baseUrl/functions/v1/ai-gemini';
  }

  /// Supabase anon key (Authorization header용)
  String get _anonKey {
    return SupabaseService.anonKey ?? '';
  }

  /// 초기화 상태
  bool get isInitialized => _isInitialized;

  /// 현재 유효한 Authorization 토큰 (JWT 우선, 없으면 anon key)
  String get _authToken {
    // 사용자 JWT 토큰이 있으면 사용 (verify_jwt: true 대응)
    final userToken = SupabaseService.accessToken;
    if (userToken != null && userToken.isNotEmpty) {
      return userToken;
    }
    // fallback: anon key
    return _anonKey;
  }

  /// 초기화
  void initialize() {
    if (!SupabaseService.isConnected) {
      _isInitialized = false;
      if (kDebugMode) {
        print('[GeminiEdge] Supabase not connected, using mock mode');
      }
      return;
    }

    _dio = Dio(BaseOptions(
      baseUrl: _edgeFunctionUrl,
      headers: {
        'Content-Type': 'application/json',
        'apikey': _anonKey,
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
    ));

    // SSE 스트리밍 클라이언트 초기화
    _sseClient = SseStreamClient(_dio);

    _isInitialized = true;
    if (kDebugMode) {
      print('[GeminiEdge] Initialized with Edge Function');
    }
  }

  /// 새 채팅 세션 시작
  /// [sessionId]: Context Caching용 세션 ID (v27)
  void startNewSession(String systemPrompt, {String? sessionId}) {
    _conversationHistory.clear();
    _systemPrompt = systemPrompt;
    _sessionId = sessionId;
    _windowManager.setSystemPrompt(systemPrompt);
    _historyManager.reset();
    _lastSummarizedRemovedCount = 0;
    _lastWindowResult = null;
    _isNewSession = true; // 새 세션 플래그 설정

    if (kDebugMode) {
      final promptTokens = TokenCounter.estimateSystemPromptTokens(systemPrompt);
      print('[GeminiEdge] 새 세션 시작, 시스템 프롬프트 토큰: $promptTokens');
    }
  }

  /// 기존 세션 복원 (앱 백그라운드 → 포그라운드 복귀 시)
  ///
  /// - 시스템 프롬프트 재설정
  /// - 대화 기록 복원 (Gemini 히스토리 동기화)
  /// - _isNewSession = true로 설정하여 첫 메시지에 사주 정보 포함
  void restoreSession(String systemPrompt, {List<Map<String, dynamic>>? messages, String? sessionId}) {
    _systemPrompt = systemPrompt;
    _sessionId = sessionId;
    _windowManager.setSystemPrompt(systemPrompt);
    _isNewSession = true; // 복원 후 첫 메시지에 사주 정보 포함!

    // 대화 히스토리 복원 (Gemini 포맷)
    if (messages != null && messages.isNotEmpty) {
      _conversationHistory.clear();
      _conversationHistory.addAll(messages);

      // 복원 메시지가 많으면 미리 요약 생성
      _historyManager.preGenerateSummaryIfNeeded(messages);

      if (kDebugMode) {
        print('[GeminiEdge] 대화 히스토리 복원: ${messages.length}개 메시지');
      }
    }

    if (kDebugMode) {
      final promptTokens = TokenCounter.estimateSystemPromptTokens(systemPrompt);
      print('[GeminiEdge] 세션 복원, 시스템 프롬프트 토큰: $promptTokens');
    }
  }

  /// 보너스 토큰 추가 (광고 시청 시)
  ///
  /// 광고를 보면 토큰 한도가 증가하여 이전 대화를 유지하면서 더 대화 가능
  /// [tokens]: 추가할 토큰 수
  void addBonusTokens(int tokens) {
    _windowManager.addBonusTokens(tokens);
    if (kDebugMode) {
      final newInfo = getTokenUsageInfo();
      print('[GeminiEdge] 보너스 토큰 추가: +$tokens');
      print('[GeminiEdge] 새 토큰 상태: ${newInfo.totalUsed}/${newInfo.maxTokens} (${newInfo.usagePercent}%)');
    }
  }

  /// 보너스 토큰 리셋 (새 세션 시작 시)
  void resetBonusTokens() {
    _windowManager.resetBonusTokens();
  }

  /// v6.0 (Phase 57): 시스템 프롬프트만 업데이트 (대화 기록 유지)
  ///
  /// 궁합 모드에서 참가자가 변경될 때 사용
  /// - 대화 기록은 유지
  /// - 시스템 프롬프트만 새 것으로 교체
  void updateSystemPrompt(String systemPrompt) {
    final oldPromptLength = _systemPrompt?.length ?? 0;
    _systemPrompt = systemPrompt;
    _windowManager.setSystemPrompt(systemPrompt);

    if (kDebugMode) {
      final newPromptTokens = TokenCounter.estimateSystemPromptTokens(systemPrompt);
      print('[GeminiEdge] 시스템 프롬프트 업데이트: $oldPromptLength → ${systemPrompt.length} chars ($newPromptTokens 토큰)');
    }
  }

  /// 메시지 전송 및 응답 받기 (토큰 사용량 포함)
  Future<GeminiResponse> sendMessageWithMetadata(String message) async {
    if (!_isInitialized) {
      return GeminiResponse(content: _getMockResponse(message));
    }

    try {
      // 대화 기록에 사용자 메시지 추가
      _conversationHistory.add({
        'role': 'user',
        'parts': [
          {'text': message}
        ],
      });

      // Edge Function 호출을 위한 메시지 포맷 변환
      final messages = _buildMessagesForEdge();

      // user_id 가져오기 (Admin 체크용)
      final userId = SupabaseService.currentUserId;

      if (kDebugMode) {
        final hasJwt = SupabaseService.accessToken != null;
        print('   🔑 [GeminiEdge] Auth: ${hasJwt ? 'JWT 토큰' : 'anon key (fallback)'}');
      }

      // 새 세션 여부 캡처 후 플래그 리셋
      final isNewSessionFlag = _isNewSession;
      _isNewSession = false;

      final response = await _dio.post(
        '',
        data: {
          'messages': messages,
          'model': 'gemini-3-flash-preview',
          'max_tokens': TokenLimits.questionAnswerMaxTokens, // v29: 4096 (끊김 방지)
          'temperature': 0.8,
          if (userId != null) 'user_id': userId,
          if (_sessionId != null) 'session_id': _sessionId,
          'is_new_session': isNewSessionFlag, // 새 세션 플래그
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_authToken', // JWT 토큰 동적 설정
          },
        ),
      );

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] != true) {
        throw Exception(responseData['error'] ?? 'Unknown error');
      }

      final content = responseData['content'] as String? ?? '';
      final usage = responseData['usage'] as Map<String, dynamic>?;

      // 대화 기록에 AI 응답 추가
      _conversationHistory.add({
        'role': 'model',
        'parts': [
          {'text': content}
        ],
      });

      // 로컬 로그 저장
      await AiLogger.log(
        provider: 'gemini-edge',
        model: responseData['model'] ?? 'gemini-2.5-flash',
        type: 'chat',
        request: {
          'message': message,
          'system_prompt_length': _systemPrompt?.length ?? 0,
        },
        response: {'content': content},
        tokens: {
          'prompt': usage?['prompt_tokens'],
          'completion': usage?['completion_tokens'],
          'total': usage?['total_tokens'],
        },
        costUsd: _calculateCost(
          usage?['prompt_tokens'] ?? 0,
          usage?['completion_tokens'] ?? 0,
        ),
        success: true,
      );

      // v35.2: 클라이언트 방어 — thinking 토큰 누출 cap (비스트리밍 경로)
      int? rawCompletion = usage?['completion_tokens'];
      int? cappedCompletion = rawCompletion;
      if (cappedCompletion != null && content.isNotEmpty) {
        final maxReasonable = (content.length * 1.5).ceil();
        if (cappedCompletion > maxReasonable) {
          if (kDebugMode) {
            print('[GeminiEdge] ⚠️ 비스트리밍 토큰 cap: $cappedCompletion → $maxReasonable');
          }
          cappedCompletion = maxReasonable;
        }
      }

      return GeminiResponse(
        content: content,
        promptTokenCount: usage?['prompt_tokens'],
        candidatesTokenCount: cappedCompletion,
        totalTokenCount: usage?['total_tokens'],
        finishReason: responseData['finish_reason'],
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[GeminiEdge] DioError: ${e.message}');
      }
      final errorMessage = e.response?.data?['error'] ?? e.message;
      throw Exception('AI 응답 오류: $errorMessage');
    } catch (e) {
      if (kDebugMode) {
        print('[GeminiEdge] Error: $e');
      }
      throw Exception('AI 응답 오류: $e');
    }
  }

  /// 메시지 전송 및 응답 받기 (기존 호환성 유지)
  Future<String> sendMessage(String message) async {
    final response = await sendMessageWithMetadata(message);
    return response.content;
  }

  /// 마지막 스트리밍 응답의 토큰 사용량 (스트리밍 완료 후 조회 가능)
  GeminiResponse? _lastStreamingResponse;

  /// 마지막 스트리밍 응답의 토큰 사용량 getter
  GeminiResponse? get lastStreamingResponse => _lastStreamingResponse;

  /// 스트리밍 응답 (SSE - Server-Sent Events)
  ///
  /// v17: 모듈화된 SseStreamClient 사용
  /// v18: MAX_TOKENS 자동 continuation 추가 (응답 끊김 방지)
  /// 응답이 실시간으로 yield되어 ChatGPT처럼 타이핑 효과 제공
  ///
  /// Web 플랫폼 참고:
  /// - Chrome/Firefox는 fetch API가 SSE를 버퍼링할 수 있음
  /// - 완전한 실시간 효과는 모바일에서 최적
  Stream<String> sendMessageStream(String message) async* {
    _lastStreamingResponse = null;
    bool hasYieldedContent = false;

    // Mock 모드
    if (!_isInitialized) {
      yield* _mockStreamingResponse(message);
      return;
    }

    try {
      // 대화 기록에 사용자 메시지 추가
      _addUserMessage(message);

      // Edge Function 호출 준비
      final messages = _buildMessagesForEdge();
      final userId = SupabaseService.currentUserId;

      // 새 세션 여부 캡처 후 플래그 리셋
      final isNewSessionFlag = _isNewSession;
      _isNewSession = false;

      if (kDebugMode) {
        print('[GeminiEdge] SSE 스트리밍 요청 시작... (newSession: $isNewSessionFlag)');
      }

      String accumulatedContent = '';
      String? lastFinishReason;
      int? totalPromptTokens;
      int? totalCompletionTokens;
      int? totalTokensUsed;

      // 모듈화된 SSE 클라이언트로 스트리밍
      // Web 플랫폼에서는 자동으로 시뮬레이션 스트리밍 적용
      await for (final chunk in _sseClient.streamRequestWithSimulation(
        url: '',
        data: {
          'messages': messages,
          'model': 'gemini-3-flash-preview',
          'max_tokens': TokenLimits.questionAnswerMaxTokens, // v29: 4096 (끊김 방지)
          'temperature': 0.8,
          'stream': true,
          if (userId != null) 'user_id': userId,
          if (_sessionId != null) 'session_id': _sessionId,
          'is_new_session': isNewSessionFlag, // 새 세션 플래그
        },
        headers: {
          'Authorization': 'Bearer $_authToken',
        },
      )) {
        // 텍스트 청크 yield
        if (chunk.accumulatedText.isNotEmpty) {
          hasYieldedContent = true;
          accumulatedContent = chunk.accumulatedText;
          yield chunk.accumulatedText;
        }

        // 완료 시 정보 저장
        if (chunk.isDone) {
          lastFinishReason = chunk.finishReason;
          totalPromptTokens = chunk.promptTokens;
          totalCompletionTokens = chunk.completionTokens;
          totalTokensUsed = chunk.totalTokens;
        }
      }

      // v29: 자동 continuation 제거
      // MAX_TOKENS 감지 시 chat_provider에서 "계속 이야기해줘" 버튼을 suggested questions에 추가
      // 사용자가 버튼을 클릭하면 그때 이어서 말하는 방식으로 변경
      if (_shouldContinue(lastFinishReason, accumulatedContent)) {
        if (kDebugMode) {
          print('[GeminiEdge] ⚠️ MAX_TOKENS 감지 - "계속 이야기해줘" 버튼으로 처리 (자동 continuation 비활성화)');
        }
        // 자동 continuation 하지 않음 - chat_provider에서 처리
      }

      // 최종 완료 처리
      await _handleStreamCompletion(
        message: message,
        content: accumulatedContent,
        promptTokens: totalPromptTokens,
        completionTokens: totalCompletionTokens,
        totalTokens: totalTokensUsed,
        finishReason: lastFinishReason,
      );

    } on SseException catch (e, stackTrace) {
      if (kDebugMode) {
        print('[GeminiEdge] SSE 에러: ${e.message}');
      }
      ErrorLoggingService.logError(
        operation: 'gemini_edge_send_message_stream',
        errorMessage: e.toString(),
        sourceFile: 'gemini_edge_datasource.dart',
        stackTrace: stackTrace.toString(),
        extraData: {'errorType': 'SseException'},
      );
      yield* _handleStreamError(
        originalError: e,
        message: message,
        hasYieldedContent: hasYieldedContent,
      );
    } on DioException catch (e, stackTrace) {
      if (kDebugMode) {
        print('[GeminiEdge] Dio 에러: ${e.message}');
      }
      ErrorLoggingService.logError(
        operation: 'gemini_edge_send_message_stream',
        errorMessage: e.toString(),
        sourceFile: 'gemini_edge_datasource.dart',
        stackTrace: stackTrace.toString(),
        extraData: {'errorType': 'DioException', 'statusCode': e.response?.statusCode},
      );
      yield* _handleStreamError(
        originalError: e,
        message: message,
        hasYieldedContent: hasYieldedContent,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[GeminiEdge] 알 수 없는 에러: $e');
      }
      ErrorLoggingService.logError(
        operation: 'gemini_edge_send_message_stream',
        errorMessage: e.toString(),
        sourceFile: 'gemini_edge_datasource.dart',
        stackTrace: stackTrace.toString(),
        extraData: {'errorType': 'unknown'},
      );
      _rollbackUserMessage();
      throw Exception('AI 스트리밍 오류: $e');
    }
  }

  /// v18: continuation이 필요한지 판단
  ///
  /// finishReason이 MAX_TOKENS이고:
  /// 1. 문장이 완성되지 않은 경우
  /// 2. [SUGGESTED_QUESTIONS] 태그가 없거나 불완전한 경우
  bool _shouldContinue(String? finishReason, String content) {
    // STOP이면 정상 완료
    if (finishReason == 'STOP' || finishReason == null) return false;

    // MAX_TOKENS 또는 LENGTH인 경우
    if (finishReason != 'MAX_TOKENS' && finishReason != 'LENGTH') return false;

    // 내용이 비어있으면 continuation 불필요
    if (content.isEmpty) return false;

    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;

    // v18.1: [SUGGESTED_QUESTIONS] 태그 체크 (Chip 연동을 위해 필수!)
    final hasStartTag = trimmed.contains('[SUGGESTED_QUESTIONS]');
    final hasEndTag = trimmed.contains('[/SUGGESTED_QUESTIONS]');

    // 태그가 완성되면 continuation 불필요
    if (hasStartTag && hasEndTag) {
      if (kDebugMode) {
        print('[GeminiEdge] SUGGESTED_QUESTIONS 태그 완성됨');
      }
      return false;
    }

    // 시작 태그는 있는데 끝 태그가 없으면 continuation 필요 (태그 중간에 끊김)
    if (hasStartTag && !hasEndTag) {
      if (kDebugMode) {
        print('[GeminiEdge] ⚠️ SUGGESTED_QUESTIONS 태그 불완전 - continuation 필요');
      }
      return true;
    }

    // 시작 태그도 없으면 문장 완성 여부로 판단
    // (AI가 아직 태그를 시작하지 않았거나 태그 없이 응답)

    // 마지막 문자 확인
    final lastChar = trimmed[trimmed.length - 1];
    final completionChars = ['.', '!', '?', '~', '요', '다', '죠', '네', '야', '해'];
    final emojiPattern = RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true);

    // 완성된 문장이면 continuation 불필요 (태그 없이 완성)
    if (completionChars.contains(lastChar) || emojiPattern.hasMatch(lastChar)) {
      if (kDebugMode) {
        print('[GeminiEdge] finishReason=$finishReason but sentence complete (no tag)');
      }
      return false;
    }

    // 문장이 불완전하면 continuation 필요
    if (kDebugMode) {
      print('[GeminiEdge] ⚠️ Incomplete sentence detected: "...${trimmed.substring(trimmed.length > 20 ? trimmed.length - 20 : 0)}"');
    }
    return true;
  }

  /// Mock 스트리밍 응답 (개발/테스트용)
  Stream<String> _mockStreamingResponse(String message) async* {
    final mockResponse = _getMockResponse(message);
    for (int i = 0; i < mockResponse.length; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
      yield mockResponse.substring(0, i + 1);
    }
    _lastStreamingResponse = GeminiResponse(content: mockResponse);
  }

  /// 사용자 메시지 추가
  void _addUserMessage(String message) {
    _conversationHistory.add({
      'role': 'user',
      'parts': [
        {'text': message}
      ],
    });
  }

  /// 마지막 사용자 메시지 롤백 (에러 시)
  void _rollbackUserMessage() {
    if (_conversationHistory.isNotEmpty &&
        _conversationHistory.last['role'] == 'user') {
      _conversationHistory.removeLast();
    }
  }

  /// 스트리밍 완료 처리
  Future<void> _handleStreamCompletion({
    required String message,
    required String content,
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
    String? finishReason,
  }) async {
    // 대화 기록에 AI 응답 추가
    _conversationHistory.add({
      'role': 'model',
      'parts': [
        {'text': content}
      ],
    });

    // 로컬 로그 저장
    await AiLogger.log(
      provider: 'gemini-edge-stream',
      model: 'gemini-3-flash-preview',
      type: 'chat-stream',
      request: {
        'message': message,
        'system_prompt_length': _systemPrompt?.length ?? 0,
      },
      response: {'content': content},
      tokens: {
        'prompt': promptTokens,
        'completion': completionTokens,
        'total': totalTokens,
      },
      costUsd: _calculateCost(promptTokens ?? 0, completionTokens ?? 0),
      success: true,
    );

    // v35.2: 클라이언트 방어 — thinking 토큰 누출 cap
    // 서버(Edge Function)에서 cap 했어야 하지만 실패 케이스 대비
    // 한글 최대 1.5 tokens/char 넘을 수 없음
    int? actualCompletion = completionTokens;
    if (actualCompletion != null && content.isNotEmpty) {
      final maxReasonable = (content.length * 1.5).ceil();
      if (actualCompletion > maxReasonable) {
        if (kDebugMode) {
          print('[GeminiEdge] ⚠️ 토큰 cap: $actualCompletion → $maxReasonable (textLen=${content.length}, ratio=${(actualCompletion / content.length).toStringAsFixed(2)})');
        }
        actualCompletion = maxReasonable;
      }
    }

    _lastStreamingResponse = GeminiResponse(
      content: content,
      promptTokenCount: promptTokens,
      candidatesTokenCount: actualCompletion,
      totalTokenCount: totalTokens,
      finishReason: finishReason,
    );

    if (kDebugMode) {
      print('[GeminiEdge] 스트리밍 완료: ${content.length}자, 토큰: $actualCompletion (raw: $completionTokens), finishReason: $finishReason');
    }
  }

  /// 스트리밍 에러 처리 및 폴백
  ///
  /// Web 플랫폼에서 SSE 연결 실패 시:
  /// - 비스트리밍 API로 전체 응답 수신
  /// - 클라이언트 측에서 타이핑 효과 시뮬레이션
  Stream<String> _handleStreamError({
    required dynamic originalError,
    required String message,
    required bool hasYieldedContent,
  }) async* {
    _rollbackUserMessage();

    // 429 Quota 초과 에러 감지
    if (originalError is DioException && originalError.response?.statusCode == 429) {
      final responseData = originalError.response?.data;
      String quotaMessage = '일일 토큰 한도를 초과했습니다. 광고를 시청하면 추가 토큰을 받을 수 있습니다.';
      if (responseData is Map && responseData['message'] != null) {
        quotaMessage = responseData['message'] as String;
      }
      print('[GeminiEdge] 429 Quota 초과: $quotaMessage');
      throw Exception('QUOTA_EXCEEDED: $quotaMessage');
    }

    // 401 인증 에러 감지
    if (originalError is DioException && originalError.response?.statusCode == 401) {
      print('[GeminiEdge] 401 인증 실패');
      throw Exception('AUTH_EXPIRED: 인증이 만료되었습니다. 앱을 재시작해주세요.');
    }

    // SseException에서 DioException 추출하여 상태 코드 확인
    if (originalError is SseException && originalError.original is DioException) {
      final dioError = originalError.original as DioException;
      if (dioError.response?.statusCode == 429) {
        print('[GeminiEdge] 429 Quota 초과 (SSE)');
        throw Exception('QUOTA_EXCEEDED: 일일 토큰 한도를 초과했습니다.');
      }
      if (dioError.response?.statusCode == 401) {
        print('[GeminiEdge] 401 인증 실패 (SSE)');
        throw Exception('AUTH_EXPIRED: 인증이 만료되었습니다. 앱을 재시작해주세요.');
      }
    }

    // 이미 콘텐츠가 전송된 경우 폴백 불가
    if (hasYieldedContent) {
      if (kDebugMode) {
        print('[GeminiEdge] 콘텐츠 전송 후 에러, 폴백 불가');
      }
      throw Exception('AI 스트리밍 중단: $originalError');
    }

    // 비스트리밍 API로 폴백 시도
    if (kDebugMode) {
      print('[GeminiEdge] 비스트리밍 API로 폴백...');
    }
    try {
      final response = await sendMessageWithMetadata(message);
      final content = response.content;
      _lastStreamingResponse = response;

      // Web 플랫폼: 클라이언트 측 타이핑 시뮬레이션
      // 단어 단위로 yield하여 스트리밍 효과 제공
      if (kIsWeb && content.isNotEmpty) {
        if (kDebugMode) {
          print('[GeminiEdge] Web 폴백 시뮬레이션: ${content.length}자 타이핑 효과');
        }

        final words = content.split(' ');
        final buffer = StringBuffer();

        for (int i = 0; i < words.length; i++) {
          if (i > 0) buffer.write(' ');
          buffer.write(words[i]);

          yield buffer.toString();

          // 단어당 24ms 지연 (글자당 8ms * 평균 3글자)
          await Future.delayed(const Duration(milliseconds: 24));
        }
      } else {
        // 모바일/데스크톱 또는 빈 응답: 바로 yield
        yield content;
      }
    } catch (fallbackError) {
      if (kDebugMode) {
        print('[GeminiEdge] 폴백도 실패: $fallbackError');
      }
      throw Exception('AI 응답 오류: $originalError');
    }
  }

  /// Edge Function용 메시지 포맷 구성
  List<Map<String, dynamic>> _buildMessagesForEdge() {
    // 토큰 제한에 맞게 대화 윈도우잉
    _lastWindowResult = _windowManager.windowMessages(_conversationHistory);

    if (kDebugMode && _lastWindowResult!.wasTrimmed) {
      print('[GeminiEdge] 토큰 제한으로 ${_lastWindowResult!.removedCount}개 메시지 트리밍');
      print('[GeminiEdge] 현재 토큰: ${_lastWindowResult!.estimatedTokens}');
    }

    // 트리밍된 메시지가 있고, 새로 제거된 메시지가 있을 때만 요약 생성 (중복 방지)
    final currentRemovedCount = _lastWindowResult!.removedCount;
    if (_lastWindowResult!.wasTrimmed &&
        currentRemovedCount > _lastSummarizedRemovedCount &&
        _lastWindowResult!.removedMessages.isNotEmpty) {
      // 이전에 요약한 이후 새로 제거된 메시지만 요약
      final newlyRemoved = _lastSummarizedRemovedCount > 0
          ? _lastWindowResult!.removedMessages.sublist(_lastSummarizedRemovedCount)
          : _lastWindowResult!.removedMessages;
      if (newlyRemoved.isNotEmpty) {
        _historyManager.generateSummary(newlyRemoved);
      }
      _lastSummarizedRemovedCount = currentRemovedCount;
    }

    final windowedMessages = _lastWindowResult!.messages;
    final messages = <Map<String, dynamic>>[];

    // 시스템 프롬프트 추가 (요약 주입 포함)
    if (_systemPrompt != null && _systemPrompt!.isNotEmpty) {
      final prompt = _injectSummaryIntoPrompt(_systemPrompt!);
      messages.add({
        'role': 'system',
        'content': prompt,
      });
    }

    // 대화 기록 변환 (Gemini 포맷 → OpenAI 포맷)
    for (final msg in windowedMessages) {
      final role = msg['role'] == 'model' ? 'assistant' : 'user';
      final text = (msg['parts'] as List?)?.first['text'] ?? '';
      messages.add({
        'role': role,
        'content': text,
      });
    }

    return messages;
  }

  /// 시스템 프롬프트에 대화 요약 주입
  String _injectSummaryIntoPrompt(String prompt) {
    if (!_historyManager.hasSummary) return prompt;

    final summary = _historyManager.currentSummary!;
    const summarySection = '\n\n---\n\n'
        '## 이전 대화 요약\n'
        '아래는 이전 대화의 핵심 내용입니다. 이 맥락을 참고하여 답변하세요:\n\n';
    const sectionEnd = '\n\n---';

    // "위 사용자 정보를 참고하여" 마커 앞에 삽입
    const marker = '위 사용자 정보를 참고하여';
    final markerIndex = prompt.indexOf(marker);

    if (markerIndex != -1) {
      final before = prompt.substring(0, markerIndex);
      final after = prompt.substring(markerIndex);
      final result = '$before$summarySection$summary$sectionEnd\n\n$after';

      if (kDebugMode) {
        print('[GeminiEdge] 대화 요약 주입됨 (${summary.length}자)');
      }
      return result;
    }

    // 마커를 못 찾으면 프롬프트 끝에 추가
    if (kDebugMode) {
      print('[GeminiEdge] 대화 요약 주입됨 - 프롬프트 끝 (${summary.length}자)');
    }
    return '$prompt$summarySection$summary$sectionEnd';
  }

  /// 현재 토큰 사용량 정보 조회
  TokenUsageInfo getTokenUsageInfo() {
    return _windowManager.getTokenUsageInfo(_conversationHistory);
  }

  /// 마지막 윈도우잉 결과 조회
  WindowedConversation? get lastWindowResult => _lastWindowResult;

  /// Mock 응답 생성
  String _getMockResponse(String userMessage) {
    final lowercaseMessage = userMessage.toLowerCase();

    if (lowercaseMessage.contains('오늘') || lowercaseMessage.contains('운세')) {
      return '''오늘의 운세를 봐드릴게요.

전반적으로 좋은 기운이 감도는 하루입니다. 특히 대인관계에서 긍정적인 일이 생길 수 있어요.

오전에는 조금 피곤할 수 있으니 무리하지 마시고, 오후부터 활력이 생기실 거예요.

재물운: ★★★★☆
애정운: ★★★★★
건강운: ★★★☆☆

오늘 하루도 좋은 일만 가득하시길 바랍니다!''';
    }

    if (lowercaseMessage.contains('사주') || lowercaseMessage.contains('생년월일')) {
      return '''사주 분석을 도와드릴게요.

정확한 분석을 위해 생년월일과 태어난 시간을 알려주세요.

예시: 1990년 1월 15일 오전 10시

시간까지 알려주시면 더 정확한 사주팔자를 분석해 드릴 수 있습니다.''';
    }

    if (lowercaseMessage.contains('궁합')) {
      return '''궁합을 봐드릴게요.

본인과 상대방의 생년월일을 알려주시면 두 분의 궁합을 분석해 드리겠습니다.

예시:
- 본인: 1990년 1월 15일
- 상대방: 1992년 3월 20일

날짜를 알려주시면 상세한 궁합 분석을 해드릴게요!''';
    }

    return '''네, 말씀해 주세요.

저는 사주, 운세, 궁합 등에 대해 상담해 드릴 수 있어요.

어떤 것이 궁금하신가요?
- 오늘의 운세
- 사주 분석
- 궁합 보기
- 기타 질문''';
  }

  /// 현재 대화 요약 (외부 노출용)
  String? get conversationSummary => _historyManager.currentSummary;

  /// 리소스 정리
  void dispose() {
    _conversationHistory.clear();
    _systemPrompt = null;
    _historyManager.reset();
    _lastSummarizedRemovedCount = 0;
  }

  /// Gemini 비용 계산 (USD)
  /// gemini-2.5-flash: 입력 $0.075/1M, 출력 $0.30/1M (thinking 없음)
  double _calculateCost(int promptTokens, int completionTokens) {
    const inputPrice = 0.075 / 1000000;
    const outputPrice = 0.30 / 1000000;
    return (promptTokens * inputPrice) + (completionTokens * outputPrice);
  }
}
