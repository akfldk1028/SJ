import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:frontend/features/saju_chat/data/datasources/chat_local_datasource.dart';
import 'package:frontend/features/saju_chat/data/repositories/chat_repository_impl.dart';
import 'package:frontend/features/saju_chat/domain/entities/chat_message.dart';
import 'package:frontend/features/saju_chat/domain/entities/chat_session.dart';
import 'package:frontend/features/saju_chat/domain/repositories/chat_repository.dart';

part 'chat_provider.g.dart';

@riverpod
ChatRepository chatRepository(ChatRepositoryRef ref) {
  return ChatRepositoryImpl(
    localDataSource: ChatLocalDataSource(),
  );
}

@riverpod
class ChatSessionController extends _$ChatSessionController {
  @override
  FutureOr<List<ChatSession>> build(String profileId) async {
    final repository = ref.watch(chatRepositoryProvider);
    return repository.getSessions(profileId);
  }

  Future<ChatSession> createSession({String? title, String? targetProfileId}) async {
    final repository = ref.read(chatRepositoryProvider);
    final session = await repository.createSession(
      profileId: profileId,
      targetProfileId: targetProfileId,
      title: title,
    );
    ref.invalidateSelf();
    return session;
  }
  
  Future<void> deleteSession(String sessionId) async {
    final repository = ref.read(chatRepositoryProvider);
    await repository.deleteSession(sessionId);
    ref.invalidateSelf();
  }
}

@riverpod
class ChatMessageController extends _$ChatMessageController {
  @override
  FutureOr<List<ChatMessage>> build(String sessionId) async {
    final repository = ref.watch(chatRepositoryProvider);
    return repository.getMessages(sessionId);
  }

  Future<void> sendMessage(String content) async {
    final repository = ref.read(chatRepositoryProvider);
    
    // Optimistic update or just reload for now
    // For better UX, we should append the user message immediately
    
    state = const AsyncValue.loading();
    
    try {
      await repository.sendMessage(
        sessionId: sessionId,
        content: content,
      );
      // Reload messages to get both user message and AI response
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
