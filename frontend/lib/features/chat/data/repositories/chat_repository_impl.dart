import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

/// ChatRepository 구현체 (Data Layer)
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ChatSession>> getSessions(String profileId) {
    return _remoteDataSource.getSessions(profileId);
  }

  @override
  Future<ChatSession?> getSessionById(String sessionId) {
    return _remoteDataSource.getSessionById(sessionId);
  }

  @override
  Future<List<ChatMessage>> getMessages(String sessionId) {
    return _remoteDataSource.getMessages(sessionId);
  }

  @override
  Future<ChatSession> createSession(String profileId) {
    return _remoteDataSource.createSession(profileId);
  }

  @override
  Future<void> deleteSession(String sessionId) {
    return _remoteDataSource.deleteSession(sessionId);
  }

  @override
  Future<ChatMessage> sendMessage({
    String? sessionId,
    required String profileId,
    required String message,
  }) {
    return _remoteDataSource.sendMessage(
      sessionId: sessionId,
      profileId: profileId,
      message: message,
    );
  }
}
