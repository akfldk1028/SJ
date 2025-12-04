import 'package:uuid/uuid.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/gemini_datasource.dart';

/// ChatRepository 구현체
///
/// GeminiDatasource를 사용하여 AI 통신
class ChatRepositoryImpl implements ChatRepository {
  final GeminiDatasource _datasource;
  final _uuid = const Uuid();

  ChatRepositoryImpl({
    GeminiDatasource? datasource,
  }) : _datasource = datasource ?? GeminiDatasource();

  @override
  Future<ChatMessage> sendMessage({
    required String userMessage,
    required List<ChatMessage> conversationHistory,
    required String systemPrompt,
  }) async {
    // 첫 메시지면 세션 시작
    if (conversationHistory.isEmpty) {
      _datasource.initialize();
      _datasource.startNewSession(systemPrompt);
    }

    try {
      final response = await _datasource.sendMessage(userMessage);

      return ChatMessage(
        id: _uuid.v4(),
        content: response,
        role: MessageRole.assistant,
        createdAt: DateTime.now(),
        status: MessageStatus.sent,
      );
    } catch (e) {
      return ChatMessage(
        id: _uuid.v4(),
        content: '죄송합니다. 응답을 받는 중 오류가 발생했습니다.',
        role: MessageRole.assistant,
        createdAt: DateTime.now(),
        status: MessageStatus.error,
      );
    }
  }

  @override
  Stream<String> sendMessageStream({
    required String userMessage,
    required List<ChatMessage> conversationHistory,
    required String systemPrompt,
  }) {
    // 첫 메시지면 세션 시작
    if (conversationHistory.isEmpty) {
      _datasource.initialize();
      _datasource.startNewSession(systemPrompt);
    }

    return _datasource.sendMessageStream(userMessage);
  }
}
