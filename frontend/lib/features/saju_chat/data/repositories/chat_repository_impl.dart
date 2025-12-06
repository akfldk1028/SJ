import 'package:uuid/uuid.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/gemini_rest_datasource.dart';

/// ChatRepository 구현체
///
/// GeminiRestDatasource를 사용하여 Gemini 3.0 AI 통신
class ChatRepositoryImpl implements ChatRepository {
  final GeminiRestDatasource _datasource;
  final _uuid = const Uuid();
  bool _isSessionStarted = false;

  ChatRepositoryImpl({
    GeminiRestDatasource? datasource,
  }) : _datasource = datasource ?? GeminiRestDatasource();

  @override
  Future<ChatMessage> sendMessage({
    required String userMessage,
    required List<ChatMessage> conversationHistory,
    required String systemPrompt,
  }) async {
    // 세션이 시작되지 않았으면 초기화
    if (!_isSessionStarted) {
      _datasource.initialize();
      _datasource.startNewSession(systemPrompt);
      _isSessionStarted = true;
    }

    try {
      final response = await _datasource.sendMessage(userMessage);

      return ChatMessage(
        id: _uuid.v4(),
        sessionId: '', // AI 통신용 - 실제 sessionId는 provider에서 설정
        content: response,
        role: MessageRole.assistant,
        createdAt: DateTime.now(),
        status: MessageStatus.sent,
      );
    } catch (e) {
      return ChatMessage(
        id: _uuid.v4(),
        sessionId: '', // AI 통신용 - 실제 sessionId는 provider에서 설정
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
    // 세션이 시작되지 않았으면 초기화
    if (!_isSessionStarted) {
      _datasource.initialize();
      _datasource.startNewSession(systemPrompt);
      _isSessionStarted = true;
    }

    return _datasource.sendMessageStream(userMessage);
  }

  /// 세션 리셋 (새 대화 시작 시 호출)
  void resetSession() {
    _isSessionStarted = false;
    _datasource.dispose();
  }
}
