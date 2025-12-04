import 'package:frontend/features/saju_chat/domain/entities/chat_message.dart';
import 'package:frontend/features/saju_chat/domain/entities/chat_session.dart';

abstract class ChatRepository {
  /// 모든 채팅 세션 목록을 가져옵니다.
  Future<List<ChatSession>> getSessions(String profileId);

  /// 특정 세션의 메시지 목록을 가져옵니다.
  Future<List<ChatMessage>> getMessages(String sessionId);

  /// 새로운 채팅 세션을 생성합니다.
  Future<ChatSession> createSession({
    required String profileId,
    String? targetProfileId,
    String? title,
  });

  /// 메시지를 전송합니다. (사용자 메시지 저장 -> AI 응답 요청 -> AI 응답 저장)
  /// Stream을 통해 실시간으로 응답(또는 상태)을 받을 수 있도록 설계할 수도 있지만,
  /// 현재는 Future로 단발성 응답을 처리합니다.
  Future<ChatMessage> sendMessage({
    required String sessionId,
    required String content,
  });

  /// 세션을 삭제합니다.
  Future<void> deleteSession(String sessionId);
}
