import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/ai_config.dart';
import '../../../core/ai_simple_logger.dart';
import '../../../core/base_provider.dart';

/// GPT-5.2 추론 레벨
enum ReasoningEffort { none, low, medium, high, xhigh }

/// OpenAI GPT Provider (GPT-5.2 Responses API)
class GPTProvider extends BaseLLMProvider {
  static final GPTProvider _instance = GPTProvider._();
  factory GPTProvider() => _instance;
  GPTProvider._();

  late final Dio _dio;
  bool _isInitialized = false;
  String _model = AIConfig.gptDefault;
  ReasoningEffort _reasoningEffort = ReasoningEffort.medium;

  @override
  String get name => 'GPT-5.2';

  @override
  bool get isInitialized => _isInitialized;

  String get currentModel => _model;

  /// 모델 변경
  void setModel(String model) => _model = model;

  /// 추론 레벨 변경
  void setReasoningEffort(ReasoningEffort effort) => _reasoningEffort = effort;

  @override
  void initialize() {
    final config = AIConfig.instance;
    if (!config.hasOpenAI) {
      AILogger.error(name, 'API key not configured');
      return;
    }

    _dio = Dio(BaseOptions(
      baseUrl: AIConfig.openaiBaseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.openaiApiKey}',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 180), // GPT-5.2는 추론에 시간 소요
    ));

    _isInitialized = true;
    AILogger.log(name, 'Initialized with $_model (reasoning: ${_reasoningEffort.name})');
  }

  @override
  Future<String> sendMessage(String message) async {
    if (!_isInitialized) return '[GPT not initialized]';

    try {
      AILogger.request(name, '/responses');

      // GPT-5.2 Responses API
      final response = await _dio.post('/responses', data: {
        'model': _model,
        'input': message,
        'reasoning': {'effort': _reasoningEffort.name},
      });

      final output = _parseResponseOutput(response.data);
      AILogger.response(name);
      return output;
    } catch (e) {
      AILogger.error(name, e);
      return '[GPT Error: $e]';
    }
  }

  @override
  Future<Map<String, dynamic>> sendStructured({
    required String systemPrompt,
    required String userMessage,
  }) async {
    if (!_isInitialized) {
      return {'error': 'GPT not initialized'};
    }

    try {
      AILogger.request(name, '/responses (structured)');

      // GPT-5.2 Responses API with JSON format
      final response = await _dio.post('/responses', data: {
        'model': _model,
        'input': '$systemPrompt\n\n$userMessage',
        'reasoning': {'effort': _reasoningEffort.name},
        'text': {
          'format': {'type': 'json_object'}
        },
      });

      final output = _parseResponseOutput(response.data);
      AILogger.response(name);
      return jsonDecode(output);
    } catch (e) {
      AILogger.error(name, e);
      return {'error': e.toString()};
    }
  }

  @override
  Stream<String> sendMessageStream(String message) async* {
    if (!_isInitialized) {
      yield '[GPT not initialized]';
      return;
    }

    try {
      // GPT-5.2 Responses API with streaming
      final response = await _dio.post<ResponseBody>(
        '/responses',
        data: {
          'model': _model,
          'input': message,
          'reasoning': {'effort': _reasoningEffort.name},
          'stream': true,
        },
        options: Options(responseType: ResponseType.stream),
      );

      String accumulated = '';
      await for (final chunk in response.data!.stream) {
        final lines = utf8.decode(chunk).split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ') && !line.contains('[DONE]')) {
            try {
              final data = jsonDecode(line.substring(6));
              // Responses API 스트리밍 구조
              final delta = data['delta'];
              if (delta != null && delta['type'] == 'content_block_delta') {
                final text = delta['delta']?['text'];
                if (text != null) {
                  accumulated += text;
                  yield accumulated;
                }
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      yield '[GPT Stream Error: $e]';
    }
  }

  /// Responses API 응답 파싱
  String _parseResponseOutput(dynamic data) {
    final output = data['output'] as List?;
    if (output == null || output.isEmpty) {
      return '[No output]';
    }

    for (final item in output) {
      if (item['type'] == 'message') {
        final content = item['content'] as List?;
        if (content != null) {
          for (final c in content) {
            if (c['type'] == 'output_text') {
              return c['text'] as String;
            }
          }
        }
      }
    }

    return '[Parse error]';
  }

  @override
  void dispose() {
    _isInitialized = false;
  }
}
