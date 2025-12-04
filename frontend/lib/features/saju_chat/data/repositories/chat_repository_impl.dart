import 'package:frontend/features/saju_chat/data/datasources/chat_local_datasource.dart';
import 'package:frontend/features/saju_chat/data/models/chat_message_model.dart';
import 'package:frontend/features/saju_chat/data/models/chat_session_model.dart';
import 'package:frontend/features/saju_chat/domain/entities/chat_message.dart';
import 'package:frontend/features/saju_chat/domain/entities/chat_session.dart';
import 'package:frontend/features/saju_chat/domain/entities/message_role.dart';
import 'package:frontend/features/saju_chat/domain/repositories/chat_repository.dart';
import 'package:uuid/uuid.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatLocalDataSource _localDataSource;
  final Uuid _uuid;

  ChatRepositoryImpl({
    required ChatLocalDataSource localDataSource,
    Uuid uuid = const Uuid(),
  })  : _localDataSource = localDataSource,
        _uuid = uuid;

  @override
  Future<ChatSession> createSession({
    required String profileId,
    String? title,
  }) async {
    final now = DateTime.now();
    final session = ChatSession(
      id: _uuid.v4(),
      profileId: profileId,
      title: title ?? '새로운 상담',
      lastMessageAt: now,
      createdAt: now,
    );

    await _localDataSource.saveSession(ChatSessionModel.fromEntity(session));
    return session;
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await _localDataSource.deleteSession(sessionId);
  }

  @override
  Future<List<ChatMessage>> getMessages(String sessionId) async {
    final models = await _localDataSource.getMessages(sessionId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<ChatSession>> getSessions(String profileId) async {
    final models = await _localDataSource.getSessions(profileId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ChatMessage> sendMessage({
    required String sessionId,
    required String content,
  }) async {
    // 1. 사용자 메시지 저장
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      sessionId: sessionId,
      role: MessageRole.user,
      content: content,
      createdAt: DateTime.now(),
    );
    await _localDataSource.saveMessage(ChatMessageModel.fromEntity(userMessage));

    // 세션 업데이트 (마지막 메시지 시간)
    // TODO: 세션 타이틀 업데이트 로직 추가 가능 (첫 메시지 내용으로)
    // await _updateSessionTimestamp(sessionId);

    // 2. AI 응답 시뮬레이션 (Mock)
    // TODO: 실제 Supabase Edge Function 호출로 교체 필요
    await Future.delayed(const Duration(seconds: 1)); // 네트워크 지연 시뮬레이션

    final aiMessage = ChatMessage(
      id: _uuid.v4(),
      sessionId: sessionId,
      role: MessageRole.assistant,
      content: '안녕하세요! 사주에 대해 궁금한 점이 있으신가요? (Mock Response)',
      createdAt: DateTime.now(),
    );
    await _localDataSource.saveMessage(ChatMessageModel.fromEntity(aiMessage));

    return aiMessage;
  }
}
