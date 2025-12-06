import '../entities/chat_message.dart';
import '../entities/chat_session.dart';
import '../models/chat_type.dart';

/// 채팅 세션 Repository 인터페이스
///
/// 채팅 히스토리 기능을 위한 세션 및 메시지 관리
abstract class ChatSessionRepository {
  /// 모든 세션 조회
  Future<List<ChatSession>> getAllSessions();

  /// 특정 세션 조회
  Future<ChatSession?> getSession(String id);

  /// 새 세션 생성
  Future<ChatSession> createSession(ChatType chatType, String? profileId);

  /// 세션 업데이트
  Future<void> updateSession(ChatSession session);

  /// 세션 삭제
  Future<void> deleteSession(String id);

  /// 세션의 메시지 목록 조회
  Future<List<ChatMessage>> getSessionMessages(String sessionId);

  /// 메시지 저장
  Future<void> saveMessage(ChatMessage message);

  /// 세션의 모든 메시지 삭제
  Future<void> deleteSessionMessages(String sessionId);
}
