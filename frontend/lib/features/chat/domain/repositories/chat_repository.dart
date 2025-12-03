import '../entities/chat_message.dart';
import '../entities/chat_session.dart';

/// 채팅 Repository 인터페이스 (Domain Layer)
abstract class ChatRepository {
  /// 프로필별 채팅 세션 목록 조회
  Future<List<ChatSession>> getSessions(String profileId);

  /// 특정 세션 조회
  Future<ChatSession?> getSessionById(String sessionId);

  /// 세션의 메시지 목록 조회
  Future<List<ChatMessage>> getMessages(String sessionId);

  /// 새 세션 생성
  Future<ChatSession> createSession(String profileId);

  /// 세션 삭제
  Future<void> deleteSession(String sessionId);

  /// AI에게 메시지 전송 및 응답 받기
  /// [sessionId] null이면 새 세션 생성
  /// [profileId] 사주 프로필 ID
  /// [message] 사용자 메시지
  /// Returns: AI 응답 메시지
  Future<ChatMessage> sendMessage({
    String? sessionId,
    required String profileId,
    required String message,
  });
}
