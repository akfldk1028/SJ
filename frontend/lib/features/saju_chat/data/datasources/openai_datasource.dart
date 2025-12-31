import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// OpenAI GPT 5.2 Thinking 데이터소스
///
/// 사주 분석 전용 - 정확한 추론에 특화
/// Gemini보다 분석 정확도가 높음
class OpenAIDatasource {
  late final Dio _dio;
  bool _isInitialized = false;

  static const String _baseUrl = 'https://api.openai.com/v1';

  /// GPT 5.2 Thinking 모델 (복잡한 추론용, 100-150초)
  static const String _thinkingModel = 'gpt-5.2-thinking';

  /// GPT 5.2 Instant 모델 (빠른 응답용)
  static const String _instantModel = 'gpt-5.2-instant';

  /// 환경변수에서 API 키 가져오기
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  /// 초기화 여부
  bool get isInitialized => _isInitialized;

  /// 초기화
  void initialize({String? apiKey}) {
    final key = apiKey ?? _apiKey;
    if (key.isEmpty || key == 'YOUR_OPENAI_API_KEY') {
      _isInitialized = false;
      print('[OpenAI] API key not configured');
      return;
    }

    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
    ));

    _isInitialized = true;
    print('[OpenAI] Initialized with GPT 5.2');
  }

  /// 사주 분석 요청 (Thinking 모드)
  ///
  /// [birthInfo] 생년월일시 정보
  /// [chartData] 만세력 계산 결과 (JSON)
  /// [question] 사용자 질문
  ///
  /// Returns: 구조화된 분석 결과 (JSON)
  Future<Map<String, dynamic>> analyzeSaju({
    required Map<String, dynamic> birthInfo,
    required Map<String, dynamic> chartData,
    required String question,
  }) async {
    if (!_isInitialized) {
      return _getMockAnalysis(question);
    }

    try {
      final systemPrompt = _buildSajuAnalysisPrompt();
      final userPrompt = _buildUserPrompt(birthInfo, chartData, question);

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': _thinkingModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.3, // 낮은 온도로 일관된 분석
          'max_tokens': 4096,
          'response_format': {'type': 'json_object'},
        },
      );

      final data = response.data as Map<String, dynamic>;
      final content = data['choices'][0]['message']['content'] as String;

      return jsonDecode(content) as Map<String, dynamic>;
    } on DioException catch (e) {
      print('[OpenAI] API Error: ${e.message}');
      return _getMockAnalysis(question);
    } catch (e) {
      print('[OpenAI] Error: $e');
      return _getMockAnalysis(question);
    }
  }

  /// 스트리밍 분석 (실시간 추론 과정 표시)
  Stream<String> analyzeSajuStream({
    required Map<String, dynamic> birthInfo,
    required Map<String, dynamic> chartData,
    required String question,
  }) async* {
    if (!_isInitialized) {
      yield jsonEncode(_getMockAnalysis(question));
      return;
    }

    try {
      final systemPrompt = _buildSajuAnalysisPrompt();
      final userPrompt = _buildUserPrompt(birthInfo, chartData, question);

      final response = await _dio.post<ResponseBody>(
        '/chat/completions',
        data: {
          'model': _thinkingModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.3,
          'max_tokens': 4096,
          'stream': true,
        },
        options: Options(responseType: ResponseType.stream),
      );

      String accumulated = '';
      final stream = response.data!.stream;

      await for (final chunk in stream) {
        final chunkStr = utf8.decode(chunk);
        final lines = chunkStr.split('\n');

        for (final line in lines) {
          if (line.startsWith('data: ') && !line.contains('[DONE]')) {
            final jsonStr = line.substring(6);
            if (jsonStr.trim().isEmpty) continue;

            try {
              final data = jsonDecode(jsonStr) as Map<String, dynamic>;
              final delta = data['choices']?[0]?['delta'];
              final content = delta?['content'] as String?;

              if (content != null) {
                accumulated += content;
                yield accumulated;
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      print('[OpenAI] Stream Error: $e');
      yield jsonEncode(_getMockAnalysis(question));
    }
  }

  /// 사주 분석용 시스템 프롬프트
  String _buildSajuAnalysisPrompt() {
    return '''당신은 전문 사주명리학자입니다.
만세력 데이터를 기반으로 정확하고 체계적인 사주 분석을 제공합니다.

분석 규칙:
1. 오행(五行) 균형 분석
2. 일간 강약 판단
3. 용신(用神) 도출
4. 격국(格局) 판단
5. 대운/세운 흐름 분석

응답 형식 (JSON):
{
  "analysis": {
    "summary": "핵심 분석 요약 (2-3문장)",
    "oheng_balance": {
      "strong": ["목", "화"],
      "weak": ["금", "수"],
      "missing": []
    },
    "day_strength": {
      "level": "신강/신약/중화",
      "score": 65,
      "reason": "판단 근거"
    },
    "yongsin": {
      "primary": "금",
      "secondary": "수",
      "reason": "용신 선정 이유"
    },
    "fortune": {
      "overall": "긍정적/보통/주의필요",
      "career": "직장운 분석",
      "wealth": "재물운 분석",
      "relationship": "대인관계 분석",
      "health": "건강 주의사항"
    },
    "advice": ["조언1", "조언2", "조언3"]
  },
  "confidence": 0.85
}''';
  }

  /// 사용자 프롬프트 생성
  String _buildUserPrompt(
    Map<String, dynamic> birthInfo,
    Map<String, dynamic> chartData,
    String question,
  ) {
    return '''## 생년월일시 정보
${jsonEncode(birthInfo)}

## 만세력 데이터
${jsonEncode(chartData)}

## 사용자 질문
$question

위 정보를 바탕으로 사주 분석을 JSON 형식으로 제공해주세요.''';
  }

  /// Mock 분석 결과
  Map<String, dynamic> _getMockAnalysis(String question) {
    return {
      'analysis': {
        'summary': '사주팔자를 분석한 결과, 전반적으로 균형 잡힌 명식입니다. '
            '목(木)과 화(火)가 강하고 금(金)이 부족하여 용신으로 금을 사용합니다.',
        'oheng_balance': {
          'strong': ['목', '화'],
          'weak': ['금'],
          'missing': [],
        },
        'day_strength': {
          'level': '신강',
          'score': 65,
          'reason': '월지에서 생조를 받고 비겁이 많아 신강합니다.',
        },
        'yongsin': {
          'primary': '금',
          'secondary': '수',
          'reason': '신강하므로 억부법에 따라 금으로 설기하고 수로 조절합니다.',
        },
        'fortune': {
          'overall': '긍정적',
          'career': '올해는 새로운 기회가 열리는 시기입니다.',
          'wealth': '재물운이 상승하는 기간입니다.',
          'relationship': '대인관계에서 귀인의 도움을 받을 수 있습니다.',
          'health': '과로에 주의하고 충분한 휴식이 필요합니다.',
        },
        'advice': [
          '금(金) 기운을 보충하면 좋습니다 (흰색, 서쪽)',
          '급한 결정보다는 신중한 판단이 필요한 시기입니다',
          '대인관계를 넓히면 좋은 기회가 올 수 있습니다',
        ],
      },
      'confidence': 0.75,
      'is_mock': true,
    };
  }

  /// 리소스 정리
  void dispose() {
    // Dio는 별도 정리 불필요
  }
}
