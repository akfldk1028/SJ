import '../../../core/data/data.dart';
import 'models/chat_message_model.dart';
import 'models/chat_session_model.dart';
import 'schema.dart';

// ============================================================================
// Chat Session Mutations
// ============================================================================

/// Chat Session 뮤테이션 클래스
class ChatSessionMutations extends BaseMutations {
  const ChatSessionMutations();

  /// 세션 생성
  Future<QueryResult<ChatSessionModel>> create(
    ChatSessionModel session,
  ) async {
    return safeMutation(
      mutation: (client) async {
        final data = session.toSupabaseInsert();
        final response = await client
            .from(chatSessionsTable)
            .insert(data)
            .select(chatSessionSelectColumns)
            .single();
        return ChatSessionModel.fromSupabaseMap(response);
      },
      errorPrefix: '세션 생성 실패',
    );
  }

  /// 세션 업데이트
  Future<QueryResult<ChatSessionModel>> update(
    ChatSessionModel session,
  ) async {
    return safeMutation(
      mutation: (client) async {
        final data = {
          ChatSessionColumns.title: session.title,
          ChatSessionColumns.messageCount: session.messageCount,
          ChatSessionColumns.lastMessagePreview: session.lastMessagePreview,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };

        final response = await client
            .from(chatSessionsTable)
            .update(data)
            .eq(ChatSessionColumns.id, session.id)
            .select(chatSessionSelectColumns)
            .single();
        return ChatSessionModel.fromSupabaseMap(response);
      },
      errorPrefix: '세션 업데이트 실패',
    );
  }

  /// 세션 삭제 (메시지도 함께 삭제 - CASCADE)
  Future<QueryResult<void>> delete(String sessionId) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from(chatSessionsTable)
            .delete()
            .eq(ChatSessionColumns.id, sessionId);
      },
      errorPrefix: '세션 삭제 실패',
    );
  }

  /// 세션 제목 업데이트
  Future<QueryResult<void>> updateTitle(
    String sessionId,
    String title,
  ) async {
    return safeMutation(
      mutation: (client) async {
        await client.from(chatSessionsTable).update({
          ChatSessionColumns.title: title,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq(ChatSessionColumns.id, sessionId);
      },
      errorPrefix: '세션 제목 업데이트 실패',
    );
  }

  /// 마지막 메시지 미리보기 업데이트
  Future<QueryResult<void>> updateLastMessage(
    String sessionId,
    String preview,
    int messageCount,
  ) async {
    return safeMutation(
      mutation: (client) async {
        await client.from(chatSessionsTable).update({
          ChatSessionColumns.lastMessagePreview: preview,
          ChatSessionColumns.messageCount: messageCount,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq(ChatSessionColumns.id, sessionId);
      },
      errorPrefix: '마지막 메시지 업데이트 실패',
    );
  }

  /// 프로필의 모든 세션 삭제
  Future<QueryResult<void>> deleteAllByProfileId(String profileId) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from(chatSessionsTable)
            .delete()
            .eq(ChatSessionColumns.profileId, profileId);
      },
      errorPrefix: '프로필 세션 삭제 실패',
    );
  }
}

// ============================================================================
// Chat Message Mutations
// ============================================================================

/// Chat Message 뮤테이션 클래스
class ChatMessageMutations extends BaseMutations {
  const ChatMessageMutations();

  /// 메시지 생성
  Future<QueryResult<ChatMessageModel>> create(
    ChatMessageModel message,
  ) async {
    return safeMutation(
      mutation: (client) async {
        final data = message.toSupabaseInsert();
        final response = await client
            .from(chatMessagesTable)
            .insert(data)
            .select(chatMessageSelectColumns)
            .single();
        return ChatMessageModel.fromSupabaseMap(response);
      },
      errorPrefix: '메시지 생성 실패',
    );
  }

  /// 사용자 메시지 + AI 응답 동시 생성
  Future<QueryResult<List<ChatMessageModel>>> createPair(
    ChatMessageModel userMessage,
    ChatMessageModel assistantMessage,
  ) async {
    return safeMutation(
      mutation: (client) async {
        final data = [
          userMessage.toSupabaseInsert(),
          assistantMessage.toSupabaseInsert(),
        ];
        final response = await client
            .from(chatMessagesTable)
            .insert(data)
            .select(chatMessageSelectColumns);
        return (response as List)
            .map((e) => ChatMessageModel.fromSupabaseMap(e))
            .toList();
      },
      errorPrefix: '메시지 쌍 생성 실패',
    );
  }

  /// 메시지 상태 업데이트
  Future<QueryResult<void>> updateStatus(
    String messageId,
    String status,
  ) async {
    return safeMutation(
      mutation: (client) async {
        await client.from(chatMessagesTable).update({
          ChatMessageColumns.status: status,
        }).eq(ChatMessageColumns.id, messageId);
      },
      errorPrefix: '메시지 상태 업데이트 실패',
    );
  }

  /// AI 응답 토큰 사용량 업데이트
  Future<QueryResult<void>> updateTokensUsed(
    String messageId,
    int tokensUsed,
  ) async {
    return safeMutation(
      mutation: (client) async {
        await client.from(chatMessagesTable).update({
          ChatMessageColumns.tokensUsed: tokensUsed,
        }).eq(ChatMessageColumns.id, messageId);
      },
      errorPrefix: '토큰 사용량 업데이트 실패',
    );
  }

  /// 메시지 삭제
  Future<QueryResult<void>> delete(String messageId) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from(chatMessagesTable)
            .delete()
            .eq(ChatMessageColumns.id, messageId);
      },
      errorPrefix: '메시지 삭제 실패',
    );
  }

  /// 세션의 모든 메시지 삭제
  Future<QueryResult<void>> deleteAllBySessionId(String sessionId) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from(chatMessagesTable)
            .delete()
            .eq(ChatMessageColumns.sessionId, sessionId);
      },
      errorPrefix: '세션 메시지 삭제 실패',
    );
  }

  /// 메시지 내용 업데이트 (스트리밍 완료 시)
  Future<QueryResult<void>> updateContent(
    String messageId,
    String content, {
    int? tokensUsed,
  }) async {
    return safeMutation(
      mutation: (client) async {
        final updates = <String, dynamic>{
          ChatMessageColumns.content: content,
          ChatMessageColumns.status: 'sent',
        };
        if (tokensUsed != null) {
          updates[ChatMessageColumns.tokensUsed] = tokensUsed;
        }
        await client
            .from(chatMessagesTable)
            .update(updates)
            .eq(ChatMessageColumns.id, messageId);
      },
      errorPrefix: '메시지 내용 업데이트 실패',
    );
  }

  /// 후속 질문 추가
  Future<QueryResult<void>> updateSuggestedQuestions(
    String messageId,
    List<String> questions,
  ) async {
    return safeMutation(
      mutation: (client) async {
        await client.from(chatMessagesTable).update({
          ChatMessageColumns.suggestedQuestions: questions,
        }).eq(ChatMessageColumns.id, messageId);
      },
      errorPrefix: '후속 질문 업데이트 실패',
    );
  }
}

/// 싱글톤 인스턴스
const chatSessionMutations = ChatSessionMutations();
const chatMessageMutations = ChatMessageMutations();
