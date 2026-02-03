import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/ai_config.dart';
import '../../../core/ai_simple_logger.dart';
import '../../../core/base_provider.dart';
import '../../../../core/services/error_logging_service.dart';

/// Gemini 3.0 추론 레벨 (thinking_level)
enum ThinkingLevel { none, low, medium, high }

/// Google Gemini Provider (Gemini 3.0 - 2025.12.17 출시)
class GeminiProvider extends BaseLLMProvider {
  static final GeminiProvider _instance = GeminiProvider._();
  factory GeminiProvider() => _instance;
  GeminiProvider._();

  late final Dio _dio;
  bool _isInitialized = false;
  String _model = AIConfig.geminiDefault;
  ThinkingLevel _thinkingLevel = ThinkingLevel.medium;

  @override
  String get name => 'Gemini 3.0';

  @override
  bool get isInitialized => _isInitialized;

  String get currentModel => _model;

  /// 모델 변경
  void setModel(String model) => _model = model;

  /// 추론 레벨 변경 (Gemini 3.0 신기능)
  void setThinkingLevel(ThinkingLevel level) => _thinkingLevel = level;

  @override
  void initialize() {
    final config = AIConfig.instance;
    if (!config.hasGemini) {
      AILogger.error(name, 'API key not configured');
      return;
    }

    _dio = Dio(BaseOptions(
      baseUrl: AIConfig.geminiBaseUrl,
      headers: {'Content-Type': 'application/json'},
      queryParameters: {'key': config.geminiApiKey},
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));

    _isInitialized = true;
    AILogger.log(name, 'Initialized with $_model (thinking: ${_thinkingLevel.name})');
  }

  @override
  Future<String> sendMessage(String message) async {
    if (!_isInitialized) return '[Gemini not initialized]';

    try {
      AILogger.request(name, '/models/$_model:generateContent');

      final response = await _dio.post(
        '/models/$_model:generateContent',
        data: {
          'contents': [
            {'parts': [{'text': message}]}
          ],
          // Gemini 3.0 thinking_level (추론 깊이 조절)
          if (_thinkingLevel != ThinkingLevel.none)
            'generationConfig': {
              'thinkingConfig': {
                'thinkingLevel': _thinkingLevel.name.toUpperCase(),
              },
            },
        },
      );

      final content = response.data['candidates'][0]['content']['parts'][0]['text'];
      AILogger.response(name);
      return content;
    } catch (e, stackTrace) {
      AILogger.error(name, e);
      ErrorLoggingService.logError(
        operation: 'gemini_send_message',
        errorMessage: e.toString(),
        sourceFile: 'gemini_provider.dart',
        stackTrace: stackTrace.toString(),
        extraData: {'model': _model},
      );
      return '[Gemini Error: $e]';
    }
  }

  @override
  Future<Map<String, dynamic>> sendStructured({
    required String systemPrompt,
    required String userMessage,
  }) async {
    if (!_isInitialized) {
      return {'error': 'Gemini not initialized'};
    }

    try {
      AILogger.request(name, '/models/$_model:generateContent (structured)');

      final response = await _dio.post(
        '/models/$_model:generateContent',
        data: {
          'contents': [
            {'parts': [{'text': '$systemPrompt\n\n$userMessage'}]}
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
            // Gemini 3.0 thinking_level
            if (_thinkingLevel != ThinkingLevel.none)
              'thinkingConfig': {
                'thinkingLevel': _thinkingLevel.name.toUpperCase(),
              },
          },
        },
      );

      final content = response.data['candidates'][0]['content']['parts'][0]['text'];
      AILogger.response(name);
      return jsonDecode(content);
    } catch (e, stackTrace) {
      AILogger.error(name, e);
      ErrorLoggingService.logError(
        operation: 'gemini_send_structured',
        errorMessage: e.toString(),
        sourceFile: 'gemini_provider.dart',
        stackTrace: stackTrace.toString(),
        extraData: {'model': _model},
      );
      return {'error': e.toString()};
    }
  }

  @override
  Stream<String> sendMessageStream(String message) async* {
    if (!_isInitialized) {
      yield '[Gemini not initialized]';
      return;
    }

    try {
      final response = await _dio.post<ResponseBody>(
        '/models/$_model:streamGenerateContent',
        data: {
          'contents': [
            {'parts': [{'text': message}]}
          ],
          // Gemini 3.0 thinking_level
          if (_thinkingLevel != ThinkingLevel.none)
            'generationConfig': {
              'thinkingConfig': {
                'thinkingLevel': _thinkingLevel.name.toUpperCase(),
              },
            },
        },
        queryParameters: {'alt': 'sse'},
        options: Options(responseType: ResponseType.stream),
      );

      String accumulated = '';
      await for (final chunk in response.data!.stream) {
        final lines = utf8.decode(chunk).split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            try {
              final data = jsonDecode(line.substring(6));
              final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
              if (text != null) {
                accumulated += text;
                yield accumulated;
              }
            } catch (_) {}
          }
        }
      }
    } catch (e, stackTrace) {
      ErrorLoggingService.logError(
        operation: 'gemini_send_message_stream',
        errorMessage: e.toString(),
        sourceFile: 'gemini_provider.dart',
        stackTrace: stackTrace.toString(),
        extraData: {'model': _model},
      );
      yield '[Gemini Stream Error: $e]';
    }
  }

  @override
  void dispose() {
    _isInitialized = false;
  }
}
