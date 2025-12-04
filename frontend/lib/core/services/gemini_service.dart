import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gemini_service.g.dart';

/// Gemini API 키 (compile-time 환경변수 또는 기본값)
/// flutter run --dart-define=GEMINI_API_KEY=your_key 로 전달
const String _defaultGeminiApiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: '',
);

/// Gemini AI 서비스
class GeminiService {
  GeminiService(this._apiKey);

  final String _apiKey;
  GenerativeModel? _model;
  ChatSession? _chatSession;

  /// 사주 상담 시스템 프롬프트
  static const String _systemPrompt = '''
당신은 전문 사주팔자 상담사입니다. 사용자의 사주 정보를 바탕으로 친절하고 이해하기 쉽게 상담해주세요.

중요 지침:
1. 항상 긍정적이고 희망적인 메시지를 전달하세요.
2. 전문 용어는 쉬운 말로 풀어서 설명하세요.
3. 답변은 간결하면서도 핵심을 담아주세요.
4. 사용자의 질문에 공감하며 답변하세요.
5. 필요한 경우 후속 질문을 제안하세요.
6. 사주 해석은 참고용이며 절대적인 것이 아님을 명심하세요.

사주 정보 해석 시:
- 년주: 조상과 외부 환경
- 월주: 부모와 청년기
- 일주: 본인과 배우자
- 시주: 자녀와 노년기

오행의 의미:
- 목(木): 성장, 발전, 창의성
- 화(火): 열정, 명예, 에너지
- 토(土): 안정, 신뢰, 중재
- 금(金): 결단력, 정의, 수확
- 수(水): 지혜, 유연성, 소통
''';

  /// 모델 초기화
  /// Gemini 3 Pro - 2025년 11월 출시, 최강 멀티모달 모델
  GenerativeModel _getModel() {
    _model ??= GenerativeModel(
      model: 'gemini-3-pro',
      apiKey: _apiKey,
      systemInstruction: Content.text(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );
    return _model!;
  }

  /// 새 채팅 세션 시작
  ChatSession startNewChat({String? profileContext}) {
    final model = _getModel();

    // 프로필 정보가 있으면 히스토리에 추가
    final history = <Content>[];
    if (profileContext != null && profileContext.isNotEmpty) {
      history.add(Content.text('사용자 사주 정보: $profileContext'));
      history.add(Content.model([
        TextPart('네, 사주 정보를 확인했습니다. 무엇이든 물어보세요!'),
      ]));
    }

    _chatSession = model.startChat(history: history);
    return _chatSession!;
  }

  /// 스트리밍 메시지 전송
  Stream<String> sendMessageStream(String message) async* {
    _chatSession ??= startNewChat();

    final response = _chatSession!.sendMessageStream(Content.text(message));

    await for (final chunk in response) {
      final text = chunk.text;
      if (text != null && text.isNotEmpty) {
        yield text;
      }
    }
  }

  /// 일반 메시지 전송 (비스트리밍)
  Future<String> sendMessage(String message) async {
    _chatSession ??= startNewChat();

    final response = await _chatSession!.sendMessage(Content.text(message));
    return response.text ?? '';
  }

  /// 세션 초기화
  void resetChat() {
    _chatSession = null;
  }
}

/// Gemini API 키 Provider (compile-time 환경변수에서 로드)
@Riverpod(keepAlive: true)
String geminiApiKey(GeminiApiKeyRef ref) {
  return _defaultGeminiApiKey;
}

/// Gemini Service Provider
@Riverpod(keepAlive: true)
GeminiService geminiService(GeminiServiceRef ref) {
  final apiKey = ref.watch(geminiApiKeyProvider);
  return GeminiService(apiKey);
}
