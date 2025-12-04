import '../entities/chat_message.dart';

/// 채팅 레포지토리 인터페이스
///
/// 의존성 역전: presentation -> domain <- data
/// AI 서비스 교체 시 이 인터페이스만 구현하면 됨
abstract class ChatRepository {
  /// AI에게 메시지 전송 및 응답 받기
  Future<ChatMessage> sendMessage({
    required String userMessage,
    required List<ChatMessage> conversationHistory,
    required String systemPrompt,
  });

  /// 스트리밍 응답 (실시간 타이핑 효과)
  Stream<String> sendMessageStream({
    required String userMessage,
    required List<ChatMessage> conversationHistory,
    required String systemPrompt,
  });
}
