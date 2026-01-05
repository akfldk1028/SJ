import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../../AI/core/ai_constants.dart';
import '../../../../AI/core/ai_logger.dart';
import '../services/conversation_window_manager.dart';
import '../services/token_counter.dart';

/// Gemini API 응답 (토큰 사용량 포함)
class GeminiResponse {
  final String content;
  final int? promptTokenCount;
  final int? candidatesTokenCount;
  final int? totalTokenCount;
  final int? thoughtsTokenCount;
  /// 응답이 MAX_TOKENS로 잘렸는지 여부
  final bool wasTruncated;
  /// finishReason (STOP, MAX_TOKENS, SAFETY 등)
  final String? finishReason;

  const GeminiResponse({
    required this.content,
    this.promptTokenCount,
    this.candidatesTokenCount,
    this.totalTokenCount,
    this.thoughtsTokenCount,
    this.wasTruncated = false,
    this.finishReason,
  });

  /// 총 토큰 사용량 (AI 응답 저장용)
  int? get tokensUsed => totalTokenCount;
}

/// Gemini 3.0 REST API 데이터소스
///
/// REST API를 직접 호출하여 Gemini 3.0 사용
/// 토큰 제한 관리 포함 (ConversationWindowManager)
class GeminiRestDatasource {
  late final Dio _dio;
  final List<Map<String, dynamic>> _conversationHistory = [];
  String? _systemPrompt;
  bool _isInitialized = false;

  /// 대화 윈도우 관리자 (토큰 제한)
  final ConversationWindowManager _windowManager = ConversationWindowManager();

  /// 마지막 트리밍 정보
  WindowedConversation? _lastWindowResult;

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String _model = 'gemini-3-flash-preview'; // Gemini 3.0 Flash (빠른 응답)

  /// 환경변수에서 API 키 가져오기
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// 초기화 상태
  bool get isInitialized => _isInitialized;

  /// 초기화
  void initialize({String? apiKey}) {
    final key = apiKey ?? _apiKey;
    if (key.isEmpty || key == 'YOUR_API_KEY_HERE') {
      _isInitialized = false;
      return;
    }

    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: {
        'Content-Type': 'application/json',
      },
      queryParameters: {
        'key': key,
      },
    ));

    _isInitialized = true;
  }

  /// 새 채팅 세션 시작
  void startNewSession(String systemPrompt) {
    _conversationHistory.clear();
    _systemPrompt = systemPrompt;
    _windowManager.setSystemPrompt(systemPrompt);
    _lastWindowResult = null;

    if (kDebugMode) {
      final promptTokens = TokenCounter.estimateSystemPromptTokens(systemPrompt);
      print('[GeminiDatasource] 새 세션 시작, 시스템 프롬프트 토큰: $promptTokens');
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

      final response = await _dio.post(
        '/models/$_model:generateContent',
        data: _buildRequestBody(),
      );

      final responseData = response.data as Map<String, dynamic>;
      final candidates = responseData['candidates'] as List?;

      if (candidates == null || candidates.isEmpty) {
        return const GeminiResponse(content: '응답을 받지 못했습니다.');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List;
      final text = parts[0]['text'] as String;

      // usageMetadata 파싱
      final usageMetadata = responseData['usageMetadata'] as Map<String, dynamic>?;
      final promptTokenCount = usageMetadata?['promptTokenCount'] as int?;
      final candidatesTokenCount = usageMetadata?['candidatesTokenCount'] as int?;
      final totalTokenCount = usageMetadata?['totalTokenCount'] as int?;
      final thoughtsTokenCount = usageMetadata?['thoughtsTokenCount'] as int?;

      // 대화 기록에 AI 응답 추가
      _conversationHistory.add({
        'role': 'model',
        'parts': [
          {'text': text}
        ],
      });

      // 로컬 로그 저장
      await AiLogger.log(
        provider: 'gemini',
        model: _model,
        type: 'chat',
        request: {
          'message': message,
          'system_prompt_length': _systemPrompt?.length ?? 0,
        },
        response: {'content': text},
        tokens: {
          'prompt': promptTokenCount,
          'completion': candidatesTokenCount,
          'total': totalTokenCount,
          'thoughts': thoughtsTokenCount,
        },
        costUsd: _calculateCost(promptTokenCount ?? 0, candidatesTokenCount ?? 0),
        success: true,
      );

      return GeminiResponse(
        content: text,
        promptTokenCount: promptTokenCount,
        candidatesTokenCount: candidatesTokenCount,
        totalTokenCount: totalTokenCount,
        thoughtsTokenCount: thoughtsTokenCount,
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        throw Exception('API 오류: ${errorData?['error']?['message'] ?? e.message}');
      }
      throw Exception('네트워크 오류: ${e.message}');
    } catch (e) {
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

  /// 스트리밍 응답 (토큰 사용량은 lastStreamingResponse에서 조회)
  Stream<String> sendMessageStream(String message) async* {
    _lastStreamingResponse = null;

    if (!_isInitialized) {
      final mockResponse = _getMockResponse(message);
      for (int i = 0; i < mockResponse.length; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
        yield mockResponse.substring(0, i + 1);
      }
      _lastStreamingResponse = GeminiResponse(content: mockResponse);
      return;
    }

    try {
      // 대화 기록에 사용자 메시지 추가
      _conversationHistory.add({
        'role': 'user',
        'parts': [
          {'text': message}
        ],
      });

      final response = await _dio.post<ResponseBody>(
        '/models/$_model:streamGenerateContent',
        data: _buildRequestBody(),
        queryParameters: {'alt': 'sse'},
        options: Options(responseType: ResponseType.stream),
      );

      String accumulated = '';
      final stream = response.data!.stream;

      // 토큰 사용량 수집 (마지막 청크에서)
      int? promptTokenCount;
      int? candidatesTokenCount;
      int? totalTokenCount;
      int? thoughtsTokenCount;

      // 🔧 finishReason 추적 (MAX_TOKENS 감지용)
      String? lastFinishReason;
      bool wasTruncated = false;

      await for (final chunk in stream) {
        final chunkStr = utf8.decode(chunk);
        final lines = chunkStr.split('\n');

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6);
            if (jsonStr.trim().isEmpty) continue;

            try {
              final data = jsonDecode(jsonStr) as Map<String, dynamic>;

              // usageMetadata 파싱 (마지막 청크에 포함됨)
              final usageMetadata = data['usageMetadata'] as Map<String, dynamic>?;
              if (usageMetadata != null) {
                promptTokenCount = usageMetadata['promptTokenCount'] as int?;
                candidatesTokenCount = usageMetadata['candidatesTokenCount'] as int?;
                totalTokenCount = usageMetadata['totalTokenCount'] as int?;
                thoughtsTokenCount = usageMetadata['thoughtsTokenCount'] as int?;
              }

              final candidates = data['candidates'] as List?;
              if (candidates != null && candidates.isNotEmpty) {
                // 🔧 finishReason 확인 (MAX_TOKENS면 응답이 잘린 것)
                final finishReason = candidates[0]['finishReason'] as String?;
                if (finishReason != null) {
                  lastFinishReason = finishReason;
                  if (finishReason == 'MAX_TOKENS') {
                    wasTruncated = true;
                    if (kDebugMode) {
                      print('[GeminiDatasource] ⚠️ 응답이 MAX_TOKENS로 잘림! candidatesTokenCount: $candidatesTokenCount');
                    }
                  }
                }

                final content = candidates[0]['content'] as Map<String, dynamic>?;
                if (content != null) {
                  final parts = content['parts'] as List?;
                  if (parts != null && parts.isNotEmpty) {
                    final text = parts[0]['text'] as String?;
                    if (text != null) {
                      accumulated += text;
                      yield accumulated;
                    }
                  }
                }
              }
            } catch (e) {
              // 🔧 파싱 오류 로깅 (디버그 모드)
              if (kDebugMode) {
                print('[GeminiDatasource] JSON 파싱 오류: $e');
              }
            }
          }
        }
      }

      // 🔧 응답 잘림 감지 시 로그
      if (kDebugMode && lastFinishReason != null) {
        print('[GeminiDatasource] 스트리밍 완료 - finishReason: $lastFinishReason, wasTruncated: $wasTruncated');
      }

      // 대화 기록에 AI 응답 추가
      if (accumulated.isNotEmpty) {
        _conversationHistory.add({
          'role': 'model',
          'parts': [
            {'text': accumulated}
          ],
        });
      }

      // 마지막 스트리밍 응답 저장 (토큰 사용량 + 잘림 여부 포함)
      _lastStreamingResponse = GeminiResponse(
        content: accumulated,
        promptTokenCount: promptTokenCount,
        candidatesTokenCount: candidatesTokenCount,
        totalTokenCount: totalTokenCount,
        thoughtsTokenCount: thoughtsTokenCount,
        wasTruncated: wasTruncated,
        finishReason: lastFinishReason,
      );

      // 로컬 로그 저장
      await AiLogger.log(
        provider: 'gemini',
        model: _model,
        type: 'chat_stream',
        request: {
          'message': message,
          'system_prompt_length': _systemPrompt?.length ?? 0,
        },
        response: {'content': accumulated},
        tokens: {
          'prompt': promptTokenCount,
          'completion': candidatesTokenCount,
          'total': totalTokenCount,
          'thoughts': thoughtsTokenCount,
        },
        costUsd: _calculateCost(promptTokenCount ?? 0, candidatesTokenCount ?? 0),
        success: true,
      );
    } on DioException catch (e) {
      throw Exception('스트리밍 오류: ${e.message}');
    } catch (e) {
      throw Exception('AI 스트리밍 오류: $e');
    }
  }

  /// 요청 본문 생성 (토큰 제한 적용)
  Map<String, dynamic> _buildRequestBody() {
    // 토큰 제한에 맞게 대화 윈도우잉
    _lastWindowResult = _windowManager.windowMessages(_conversationHistory);

    if (kDebugMode && _lastWindowResult!.wasTrimmed) {
      print('[GeminiDatasource] 토큰 제한으로 ${_lastWindowResult!.removedCount}개 메시지 트리밍');
      print('[GeminiDatasource] 현재 토큰: ${_lastWindowResult!.estimatedTokens}');
    }

    final windowedMessages = _lastWindowResult!.messages;
    final contents = <Map<String, dynamic>>[];

    // 시스템 프롬프트가 있으면 첫 번째 사용자 메시지에 포함
    if (_systemPrompt != null && windowedMessages.isNotEmpty) {
      final firstUserMsg = windowedMessages.first;
      if (firstUserMsg['role'] == 'user') {
        contents.add({
          'role': 'user',
          'parts': [
            {'text': '$_systemPrompt\n\n${firstUserMsg['parts'][0]['text']}'}
          ],
        });
        contents.addAll(windowedMessages.skip(1));
      } else {
        contents.addAll(windowedMessages);
      }
    } else {
      contents.addAll(windowedMessages);
    }

    // [디버깅 로그 추가]
    final maxTokens = TokenLimits.questionAnswerMaxTokens;
    if (kDebugMode) {
      print('[gemini_rest_datasource.dart] _buildRequestBody: maxOutputTokens = $maxTokens');
    }

    return {
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': maxTokens,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
      ],
    };
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

  /// 리소스 정리
  void dispose() {
    _conversationHistory.clear();
    _systemPrompt = null;
  }

  /// Gemini 비용 계산 (USD)
  /// gemini-3-flash: 입력 $0.50/1M, 출력 $3.00/1M
  double _calculateCost(int promptTokens, int completionTokens) {
    const inputPrice = 0.50 / 1000000;
    const outputPrice = 3.00 / 1000000;
    return (promptTokens * inputPrice) + (completionTokens * outputPrice);
  }
}
