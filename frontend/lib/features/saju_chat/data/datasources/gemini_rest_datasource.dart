import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Gemini 3.0 REST API 데이터소스
///
/// REST API를 직접 호출하여 Gemini 3.0 사용
class GeminiRestDatasource {
  late final Dio _dio;
  final List<Map<String, dynamic>> _conversationHistory = [];
  String? _systemPrompt;
  bool _isInitialized = false;

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String _model = 'gemini-3-pro-preview'; // Gemini 3.0 Pro (Thinking 지원)

  /// 환경변수에서 API 키 가져오기
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

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
  }

  /// 메시지 전송 및 응답 받기
  Future<String> sendMessage(String message) async {
    if (!_isInitialized) {
      return _getMockResponse(message);
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
        return '응답을 받지 못했습니다.';
      }

      final content = candidates[0]['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List;
      final text = parts[0]['text'] as String;

      // 대화 기록에 AI 응답 추가
      _conversationHistory.add({
        'role': 'model',
        'parts': [
          {'text': text}
        ],
      });

      return text;
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

  /// 스트리밍 응답
  Stream<String> sendMessageStream(String message) async* {
    if (!_isInitialized) {
      final mockResponse = _getMockResponse(message);
      for (int i = 0; i < mockResponse.length; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
        yield mockResponse.substring(0, i + 1);
      }
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

      await for (final chunk in stream) {
        final chunkStr = utf8.decode(chunk);
        final lines = chunkStr.split('\n');

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6);
            if (jsonStr.trim().isEmpty) continue;

            try {
              final data = jsonDecode(jsonStr) as Map<String, dynamic>;
              final candidates = data['candidates'] as List?;
              if (candidates != null && candidates.isNotEmpty) {
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
            } catch (_) {
              // JSON 파싱 오류 무시
            }
          }
        }
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
    } on DioException catch (e) {
      throw Exception('스트리밍 오류: ${e.message}');
    } catch (e) {
      throw Exception('AI 스트리밍 오류: $e');
    }
  }

  /// 요청 본문 생성
  Map<String, dynamic> _buildRequestBody() {
    final contents = <Map<String, dynamic>>[];

    // 시스템 프롬프트가 있으면 첫 번째 사용자 메시지에 포함
    if (_systemPrompt != null && _conversationHistory.isNotEmpty) {
      final firstUserMsg = _conversationHistory.first;
      if (firstUserMsg['role'] == 'user') {
        contents.add({
          'role': 'user',
          'parts': [
            {'text': '$_systemPrompt\n\n${firstUserMsg['parts'][0]['text']}'}
          ],
        });
        contents.addAll(_conversationHistory.skip(1));
      } else {
        contents.addAll(_conversationHistory);
      }
    } else {
      contents.addAll(_conversationHistory);
    }

    return {
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 8192,
        // Thinking 모드 활성화 - 사주 분석 추론 강화
        'thinkingConfig': {
          'thinkingBudget': 2048, // 추론에 사용할 토큰 수
        },
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
}
