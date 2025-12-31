import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/supabase_service.dart';

/// OpenAI GPT-5.2-Thinking Edge Function 데이터소스
///
/// Supabase Edge Function (ai-openai)을 통해 OpenAI API 호출
/// API 키가 서버에만 저장되어 보안 강화
/// 사주 분석 전용 - 추론 강화 모델 사용
///
/// 2024-12-31: GPT-5.2-Thinking 모델로 업그레이드 (추론 강화)
/// === 모델 변경 금지 === EdgeFunction_task.md 참조
class OpenAIEdgeDatasource {
  bool _isInitialized = false;
  late final Dio _dio;

  /// Edge Function URL
  String get _edgeFunctionUrl {
    final baseUrl = SupabaseService.supabaseUrl ?? '';
    return '$baseUrl/functions/v1/ai-openai';
  }

  /// Supabase anon key (Authorization header용)
  String get _anonKey {
    return SupabaseService.anonKey ?? '';
  }

  /// 현재 유효한 Authorization 토큰 (JWT 우선, 없으면 anon key)
  String get _authToken {
    final userToken = SupabaseService.accessToken;
    if (userToken != null && userToken.isNotEmpty) {
      return userToken;
    }
    return _anonKey;
  }

  /// 초기화 여부
  bool get isInitialized => _isInitialized;

  /// 초기화
  void initialize() {
    if (!SupabaseService.isConnected) {
      _isInitialized = false;
      if (kDebugMode) {
        print('[OpenAIEdge] Supabase not connected, using mock mode');
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
      receiveTimeout: const Duration(seconds: 180), // GPT 분석은 오래 걸릴 수 있음
    ));

    _isInitialized = true;
    if (kDebugMode) {
      print('[OpenAIEdge] Initialized with Edge Function');
    }
  }

  /// 사주 분석 요청 (GPT 5.2 Thinking 모드)
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

      // user_id 가져오기 (Admin 체크용)
      final userId = SupabaseService.currentUserId;

      final response = await _dio.post(
        '',
        data: {
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'model': 'gpt-5.2-thinking',  // 추론 강화 모델 - 변경 금지
          'max_tokens': 10000,           // 전체 응답 보장
          'temperature': 0.3,
          'response_format': {'type': 'json_object'},
          if (userId != null) 'user_id': userId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_authToken', // JWT 토큰 동적 설정
          },
        ),
      );

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] != true) {
        if (kDebugMode) {
          print('[OpenAIEdge] Error: ${responseData['error']}');
        }
        return _getMockAnalysis(question);
      }

      final content = responseData['content'] as String? ?? '';

      // JSON 파싱 시도
      try {
        return jsonDecode(content) as Map<String, dynamic>;
      } catch (_) {
        // JSON 파싱 실패 시 텍스트로 반환
        return {
          'analysis': {'raw_text': content},
          'parse_error': true,
        };
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[OpenAIEdge] DioError: ${e.message}');
        print('[OpenAIEdge] Response: ${e.response?.data}');
      }
      return _getMockAnalysis(question);
    } catch (e) {
      if (kDebugMode) {
        print('[OpenAIEdge] Error: $e');
      }
      return _getMockAnalysis(question);
    }
  }

  /// 스트리밍 분석 (실시간 추론 과정 표시)
  ///
  /// 참고: Edge Function은 현재 스트리밍 미지원
  /// 전체 응답을 받은 후 yield
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
      final result = await analyzeSaju(
        birthInfo: birthInfo,
        chartData: chartData,
        question: question,
      );
      yield jsonEncode(result);
    } catch (e) {
      if (kDebugMode) {
        print('[OpenAIEdge] Stream Error: $e');
      }
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
    // No resources to clean up
  }
}
