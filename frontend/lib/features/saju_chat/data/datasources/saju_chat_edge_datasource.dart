import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/supabase_service.dart';

/// 사주 분석 데이터 모델
class SajuPillar {
  final String gan;
  final String ji;
  final String? ganHanja;
  final String? jiHanja;

  const SajuPillar({
    required this.gan,
    required this.ji,
    this.ganHanja,
    this.jiHanja,
  });

  Map<String, dynamic> toJson() => {
        'gan': gan,
        'ji': ji,
        if (ganHanja != null) 'ganHanja': ganHanja,
        if (jiHanja != null) 'jiHanja': jiHanja,
      };
}

/// 사주 데이터 모델
class SajuData {
  final SajuPillar year;
  final SajuPillar month;
  final SajuPillar day;
  final SajuPillar hour;

  const SajuData({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
  });

  Map<String, dynamic> toJson() => {
        'year': year.toJson(),
        'month': month.toJson(),
        'day': day.toJson(),
        'hour': hour.toJson(),
      };
}

/// 오행 카운트 모델
class OhengCount {
  final int wood;
  final int fire;
  final int earth;
  final int metal;
  final int water;

  const OhengCount({
    required this.wood,
    required this.fire,
    required this.earth,
    required this.metal,
    required this.water,
  });

  Map<String, dynamic> toJson() => {
        'wood': wood,
        'fire': fire,
        'earth': earth,
        'metal': metal,
        'water': water,
      };
}

/// 사주 채팅 메시지 모델
class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;

  const ChatMessage({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

/// 사주 채팅 응답
class SajuChatResponse {
  final String response;
  final int? promptTokens;
  final int? responseTokens;
  final int? totalTokens;
  final String? model;
  final bool blocked;
  final String? error;

  const SajuChatResponse({
    required this.response,
    this.promptTokens,
    this.responseTokens,
    this.totalTokens,
    this.model,
    this.blocked = false,
    this.error,
  });

  /// Quota 초과 여부
  bool get isQuotaExceeded => error == 'QUOTA_EXCEEDED';
}

/// saju-chat Edge Function 데이터소스
///
/// Supabase Edge Function (saju-chat)을 통해 사주 채팅 수행
/// 기능:
/// - 사주 컨텍스트 기반 대화
/// - Quota 체크 (일일 토큰 제한)
/// - 토큰 사용량 추적
class SajuChatEdgeDatasource {
  bool _isInitialized = false;
  late final Dio _dio;

  /// Edge Function URL
  String get _edgeFunctionUrl {
    final baseUrl = SupabaseService.client?.supabaseUrl ?? '';
    return '$baseUrl/functions/v1/saju-chat';
  }

  /// Supabase anon key
  String get _anonKey {
    return SupabaseService.client != null
        ? (SupabaseService.client!.headers['apikey'] ?? '')
        : '';
  }

  /// 현재 사용자 JWT
  String? get _accessToken {
    return SupabaseService.client?.auth.currentSession?.accessToken;
  }

  /// 초기화 여부
  bool get isInitialized => _isInitialized;

  /// 초기화
  void initialize() {
    if (!SupabaseService.isConnected) {
      _isInitialized = false;
      if (kDebugMode) {
        print('[SajuChatEdge] Supabase not connected, using mock mode');
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

    _isInitialized = true;
    if (kDebugMode) {
      print('[SajuChatEdge] Initialized with Edge Function');
    }
  }

  /// 사주 채팅 요청
  ///
  /// [messages] 대화 히스토리
  /// [sajuAnalysis] 사주 분석 데이터
  /// [profileName] 프로필 이름
  /// [birthDate] 생년월일
  /// [chatType] 채팅 유형 ('general' | 'compatibility' | 'yearly' | 'monthly')
  /// [contextSummary] 이전 대화 요약
  Future<SajuChatResponse> sendMessage({
    required List<ChatMessage> messages,
    Map<String, dynamic>? sajuAnalysis,
    String? profileName,
    String? birthDate,
    String chatType = 'general',
    String? contextSummary,
  }) async {
    if (!_isInitialized) {
      return SajuChatResponse(
        response: _getMockResponse(messages.last.content),
      );
    }

    try {
      // Authorization header 설정 (JWT)
      final headers = <String, dynamic>{};
      if (_accessToken != null) {
        headers['Authorization'] = 'Bearer $_accessToken';
      }

      final response = await _dio.post(
        '',
        data: {
          'messages': messages.map((m) => m.toJson()).toList(),
          if (sajuAnalysis != null) 'sajuAnalysis': sajuAnalysis,
          if (profileName != null) 'profileName': profileName,
          if (birthDate != null) 'birthDate': birthDate,
          'chatType': chatType,
          if (contextSummary != null) 'contextSummary': contextSummary,
        },
        options: Options(headers: headers),
      );

      final responseData = response.data as Map<String, dynamic>;

      // Quota 초과 체크
      if (response.statusCode == 429 || responseData['error'] == 'QUOTA_EXCEEDED') {
        return SajuChatResponse(
          response: responseData['message'] ?? '오늘 토큰 사용량을 초과했습니다.',
          error: 'QUOTA_EXCEEDED',
        );
      }

      // 에러 체크
      if (responseData['error'] != null) {
        return SajuChatResponse(
          response: '죄송합니다. 오류가 발생했습니다.',
          error: responseData['error'] as String,
        );
      }

      // 안전성 블록 체크
      if (responseData['blocked'] == true) {
        return SajuChatResponse(
          response: responseData['response'] ?? '죄송합니다. 해당 질문에 대해 답변드리기 어렵습니다.',
          blocked: true,
        );
      }

      final aiResponse = responseData['response'] as String? ?? '';
      final usage = responseData['usage'] as Map<String, dynamic>?;

      return SajuChatResponse(
        response: aiResponse,
        promptTokens: usage?['promptTokens'] as int?,
        responseTokens: usage?['responseTokens'] as int?,
        totalTokens: usage?['totalTokens'] as int?,
        model: responseData['model'] as String?,
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[SajuChatEdge] DioError: ${e.message}');
        print('[SajuChatEdge] Response: ${e.response?.data}');
      }

      // 429 Quota Exceeded
      if (e.response?.statusCode == 429) {
        final data = e.response?.data as Map<String, dynamic>?;
        return SajuChatResponse(
          response: data?['message'] ?? '오늘 토큰 사용량을 초과했습니다.',
          error: 'QUOTA_EXCEEDED',
        );
      }

      return SajuChatResponse(
        response: '네트워크 오류가 발생했습니다. 다시 시도해주세요.',
        error: e.message,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[SajuChatEdge] Error: $e');
      }
      return SajuChatResponse(
        response: '오류가 발생했습니다. 다시 시도해주세요.',
        error: e.toString(),
      );
    }
  }

  /// 스트리밍 응답 (현재 Edge Function은 스트리밍 미지원)
  Stream<String> sendMessageStream({
    required List<ChatMessage> messages,
    Map<String, dynamic>? sajuAnalysis,
    String? profileName,
    String? birthDate,
    String chatType = 'general',
    String? contextSummary,
  }) async* {
    final response = await sendMessage(
      messages: messages,
      sajuAnalysis: sajuAnalysis,
      profileName: profileName,
      birthDate: birthDate,
      chatType: chatType,
      contextSummary: contextSummary,
    );

    yield response.response;
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

    if (lowercaseMessage.contains('사주') || lowercaseMessage.contains('팔자')) {
      return '''사주를 분석해 드릴게요.

제공해주신 사주 정보를 바탕으로 분석하면, 당신은 창의적이고 진취적인 성향을 가지고 계십니다.

특히 올해는 새로운 시작에 좋은 기운이 있으니, 평소 생각해두셨던 계획을 실행에 옮기시면 좋겠습니다.

더 구체적인 질문이 있으시면 말씀해 주세요!''';
    }

    return '''네, 무엇이든 물어보세요!

저는 당신의 사주를 바탕으로 운세, 궁합, 진로 등 다양한 상담을 도와드릴 수 있어요.

- 오늘/이번 주/이번 달 운세
- 성격 및 적성 분석
- 대인관계 및 궁합
- 진로 및 직업 상담

어떤 것이 궁금하신가요?''';
  }

  /// 리소스 정리
  void dispose() {
    // No resources to clean up
  }
}
