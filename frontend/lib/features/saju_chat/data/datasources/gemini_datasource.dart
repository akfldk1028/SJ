import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/entities/chat_message.dart';

/// Gemini AI API 데이터소스
///
/// 실제 AI API 호출 담당
/// API 키는 환경 변수 또는 Supabase Edge Function에서 관리
class GeminiDatasource {
  GenerativeModel? _model;
  ChatSession? _chatSession;

  static const String _defaultApiKey = 'YOUR_API_KEY'; // TODO: 환경 변수로 이동

  /// 모델 초기화
  void initialize({String? apiKey}) {
    final key = apiKey ?? _defaultApiKey;
    if (key == 'YOUR_API_KEY') {
      // API 키가 설정되지 않은 경우 Mock 모드로 동작
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: key,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
  }

  /// 새 채팅 세션 시작
  void startNewSession(String systemPrompt) {
    if (_model == null) return;

    _chatSession = _model!.startChat(
      history: [
        Content.text(systemPrompt),
      ],
    );
  }

  /// 메시지 전송 및 응답 받기
  Future<String> sendMessage(String message) async {
    // Mock 모드
    if (_model == null || _chatSession == null) {
      return _getMockResponse(message);
    }

    try {
      final response = await _chatSession!.sendMessage(
        Content.text(message),
      );
      return response.text ?? '응답을 받지 못했습니다.';
    } catch (e) {
      throw Exception('AI 응답 오류: $e');
    }
  }

  /// 스트리밍 응답
  Stream<String> sendMessageStream(String message) async* {
    // Mock 모드
    if (_model == null || _chatSession == null) {
      final mockResponse = _getMockResponse(message);
      // 글자 하나씩 스트리밍하는 효과
      for (int i = 0; i < mockResponse.length; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
        yield mockResponse.substring(0, i + 1);
      }
      return;
    }

    try {
      final response = _chatSession!.sendMessageStream(
        Content.text(message),
      );

      String accumulated = '';
      await for (final chunk in response) {
        accumulated += chunk.text ?? '';
        yield accumulated;
      }
    } catch (e) {
      throw Exception('AI 스트리밍 오류: $e');
    }
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

  /// 대화 기록을 Gemini Content로 변환
  List<Content> convertToContents(List<ChatMessage> messages) {
    return messages.map((msg) {
      return Content(
        msg.isUser ? 'user' : 'model',
        [TextPart(msg.content)],
      );
    }).toList();
  }

  /// 리소스 정리
  void dispose() {
    _chatSession = null;
    _model = null;
  }
}
