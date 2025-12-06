import 'package:uuid/uuid.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/models/chat_type.dart';
import '../../domain/repositories/chat_session_repository.dart';
import '../datasources/chat_session_local_datasource.dart';
import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';

/// 채팅 세션 Repository 구현체
///
/// LocalDataSource를 사용하여 채팅 세션 및 메시지 관리
class ChatSessionRepositoryImpl implements ChatSessionRepository {
  final ChatSessionLocalDatasource _localDatasource;
  final Uuid _uuid = const Uuid();

  ChatSessionRepositoryImpl(this._localDatasource);

  @override
  Future<List<ChatSession>> getAllSessions() async {
    final models = await _localDatasource.getAllSessions();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ChatSession?> getSession(String id) async {
    final model = await _localDatasource.getSessionById(id);
    return model?.toEntity();
  }

  @override
  Future<ChatSession> createSession(ChatType chatType, String? profileId) async {
    final now = DateTime.now();
    final newSession = ChatSessionModel(
      id: _uuid.v4(),
      title: '새 대화', // 초기 타이틀, 첫 메시지로 나중에 업데이트
      chatType: chatType.name,
      profileId: profileId,
      createdAt: now,
      updatedAt: now,
      messageCount: 0,
      lastMessagePreview: null,
    );

    await _localDatasource.saveSession(newSession);
    return newSession.toEntity();
  }

  @override
  Future<void> updateSession(ChatSession session) async {
    final model = ChatSessionModel.fromEntity(session);
    await _localDatasource.updateSession(model);
  }

  @override
  Future<void> deleteSession(String id) async {
    // 세션 삭제 전에 관련 메시지도 모두 삭제
    await _localDatasource.deleteSessionMessages(id);
    await _localDatasource.deleteSession(id);
  }

  @override
  Future<List<ChatMessage>> getSessionMessages(String sessionId) async {
    final models = await _localDatasource.getSessionMessages(sessionId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveMessage(ChatMessage message) async {
    final model = ChatMessageModel.fromEntity(message);
    await _localDatasource.saveMessage(model);

    // 메시지 저장 후 세션 메타데이터 업데이트
    await _updateSessionMetadata(message.sessionId);
  }

  @override
  Future<void> deleteSessionMessages(String sessionId) async {
    await _localDatasource.deleteSessionMessages(sessionId);

    // 메시지 삭제 후 세션 메타데이터 업데이트
    await _updateSessionMetadata(sessionId);
  }

  /// 세션 메타데이터 업데이트
  ///
  /// - messageCount: 메시지 개수
  /// - lastMessagePreview: 마지막 메시지 미리보기
  /// - title: 첫 사용자 메시지에서 생성 (아직 '새 대화'인 경우)
  /// - updatedAt: 현재 시간
  Future<void> _updateSessionMetadata(String sessionId) async {
    final session = await _localDatasource.getSessionById(sessionId);
    if (session == null) return;

    final messages = await _localDatasource.getSessionMessages(sessionId);

    // 메시지 개수
    final messageCount = messages.length;

    // 마지막 메시지 미리보기 (최대 50자)
    String? lastMessagePreview;
    if (messages.isNotEmpty) {
      final lastMessage = messages.last;
      final content = lastMessage.content;
      lastMessagePreview = content.length > 50
          ? '${content.substring(0, 50)}...'
          : content;
    }

    // 타이틀 생성 (첫 사용자 메시지에서)
    String title = session.title;
    if (title == '새 대화' && messages.isNotEmpty) {
      final firstUserMessage = messages.firstWhere(
        (m) => m.role == 'user',
        orElse: () => messages.first,
      );
      final content = firstUserMessage.content;
      title = content.length > 30
          ? '${content.substring(0, 30)}...'
          : content;
    }

    // 세션 업데이트
    final updatedSession = ChatSessionModel(
      id: session.id,
      title: title,
      chatType: session.chatType,
      profileId: session.profileId,
      createdAt: session.createdAt,
      updatedAt: DateTime.now(),
      messageCount: messageCount,
      lastMessagePreview: lastMessagePreview,
    );

    await _localDatasource.updateSession(updatedSession);
  }
}
