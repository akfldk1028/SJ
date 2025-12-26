import '../../../core/data/data.dart';
import 'models/chat_message_model.dart';
import 'models/chat_session_model.dart';
import 'schema.dart';

// ============================================================================
// Chat Session Queries
// ============================================================================

/// Chat Session 쿼리 클래스
class ChatSessionQueries extends BaseQueries {
  const ChatSessionQueries();

  /// 프로필 ID로 세션 목록 조회
  Future<QueryResult<List<ChatSessionModel>>> getAllByProfileId(
    String profileId, {
    int? limit,
  }) async {
    return safeListQuery(
      query: (client) async {
        var query = client
            .from(chatSessionsTable)
            .select(chatSessionSelectColumns)
            .eq(ChatSessionColumns.profileId, profileId)
            .order(ChatSessionColumns.updatedAt, ascending: false);

        if (limit != null) {
          query = query.limit(limit);
        }

        final response = await query;
        return List<Map<String, dynamic>>.from(response);
      },
      fromJson: ChatSessionModel.fromSupabaseMap,
      errorPrefix: '세션 목록 조회 실패',
    );
  }

  /// 세션 ID로 단일 조회
  Future<QueryResult<ChatSessionModel?>> getById(String sessionId) async {
    return safeSingleQuery(
      query: (client) async {
        final response = await client
            .from(chatSessionsTable)
            .select(chatSessionSelectColumns)
            .eq(ChatSessionColumns.id, sessionId)
            .maybeSingle();
        return response;
      },
      fromJson: ChatSessionModel.fromSupabaseMap,
      errorPrefix: '세션 조회 실패',
    );
  }

  /// 최근 세션 조회
  Future<QueryResult<ChatSessionModel?>> getLatestByProfileId(
    String profileId,
  ) async {
    return safeSingleQuery(
      query: (client) async {
        final response = await client
            .from(chatSessionsTable)
            .select(chatSessionSelectColumns)
            .eq(ChatSessionColumns.profileId, profileId)
            .order(ChatSessionColumns.updatedAt, ascending: false)
            .limit(1)
            .maybeSingle();
        return response;
      },
      fromJson: ChatSessionModel.fromSupabaseMap,
      errorPrefix: '최근 세션 조회 실패',
    );
  }

  /// 채팅 타입별 세션 목록
  Future<QueryResult<List<ChatSessionModel>>> getByChatType(
    String profileId,
    String chatType,
  ) async {
    return safeListQuery(
      query: (client) async {
        final response = await client
            .from(chatSessionsTable)
            .select(chatSessionSelectColumns)
            .eq(ChatSessionColumns.profileId, profileId)
            .eq(ChatSessionColumns.chatType, chatType)
            .order(ChatSessionColumns.updatedAt, ascending: false);
        return List<Map<String, dynamic>>.from(response);
      },
      fromJson: ChatSessionModel.fromSupabaseMap,
      errorPrefix: '타입별 세션 조회 실패',
    );
  }

  /// 세션 개수 조회
  Future<QueryResult<int>> countByProfileId(String profileId) async {
    return safeQuery(
      query: (client) async {
        final response = await client
            .from(chatSessionsTable)
            .select()
            .eq(ChatSessionColumns.profileId, profileId)
            .count();
        return response.count;
      },
      errorPrefix: '세션 개수 조회 실패',
    );
  }
}

// ============================================================================
// Chat Message Queries
// ============================================================================

/// Chat Message 쿼리 클래스
class ChatMessageQueries extends BaseQueries {
  const ChatMessageQueries();

  /// 세션 ID로 메시지 목록 조회
  Future<QueryResult<List<ChatMessageModel>>> getAllBySessionId(
    String sessionId, {
    int? limit,
    int? offset,
  }) async {
    return safeListQuery(
      query: (client) async {
        var query = client
            .from(chatMessagesTable)
            .select(chatMessageSelectColumns)
            .eq(ChatMessageColumns.sessionId, sessionId)
            .order(ChatMessageColumns.createdAt, ascending: true);

        if (offset != null) {
          query = query.range(offset, offset + (limit ?? 50) - 1);
        } else if (limit != null) {
          query = query.limit(limit);
        }

        final response = await query;
        return List<Map<String, dynamic>>.from(response);
      },
      fromJson: ChatMessageModel.fromSupabaseMap,
      errorPrefix: '메시지 목록 조회 실패',
    );
  }

  /// 메시지 ID로 단일 조회
  Future<QueryResult<ChatMessageModel?>> getById(String messageId) async {
    return safeSingleQuery(
      query: (client) async {
        final response = await client
            .from(chatMessagesTable)
            .select(chatMessageSelectColumns)
            .eq(ChatMessageColumns.id, messageId)
            .maybeSingle();
        return response;
      },
      fromJson: ChatMessageModel.fromSupabaseMap,
      errorPrefix: '메시지 조회 실패',
    );
  }

  /// 최근 메시지 N개 조회
  Future<QueryResult<List<ChatMessageModel>>> getRecentBySessionId(
    String sessionId, {
    int limit = 20,
  }) async {
    return safeListQuery(
      query: (client) async {
        final response = await client
            .from(chatMessagesTable)
            .select(chatMessageSelectColumns)
            .eq(ChatMessageColumns.sessionId, sessionId)
            .order(ChatMessageColumns.createdAt, ascending: false)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      },
      fromJson: ChatMessageModel.fromSupabaseMap,
      errorPrefix: '최근 메시지 조회 실패',
    );
  }

  /// 세션의 메시지 개수 조회
  Future<QueryResult<int>> countBySessionId(String sessionId) async {
    return safeQuery(
      query: (client) async {
        final response = await client
            .from(chatMessagesTable)
            .select()
            .eq(ChatMessageColumns.sessionId, sessionId)
            .count();
        return response.count;
      },
      errorPrefix: '메시지 개수 조회 실패',
    );
  }

  /// AI 응답 메시지만 조회 (토큰 통계용)
  Future<QueryResult<List<ChatMessageModel>>> getAssistantMessages(
    String sessionId,
  ) async {
    return safeListQuery(
      query: (client) async {
        final response = await client
            .from(chatMessagesTable)
            .select(chatMessageSelectColumns)
            .eq(ChatMessageColumns.sessionId, sessionId)
            .eq(ChatMessageColumns.role, 'assistant')
            .order(ChatMessageColumns.createdAt, ascending: true);
        return List<Map<String, dynamic>>.from(response);
      },
      fromJson: ChatMessageModel.fromSupabaseMap,
      errorPrefix: 'AI 메시지 조회 실패',
    );
  }

  /// 총 토큰 사용량 조회
  Future<QueryResult<int>> getTotalTokensUsed(String sessionId) async {
    return safeQuery(
      query: (client) async {
        final response = await client
            .from(chatMessagesTable)
            .select(ChatMessageColumns.tokensUsed)
            .eq(ChatMessageColumns.sessionId, sessionId)
            .not(ChatMessageColumns.tokensUsed, 'is', null);

        int total = 0;
        for (final row in response) {
          total += (row['tokens_used'] as int?) ?? 0;
        }
        return total;
      },
      errorPrefix: '토큰 사용량 조회 실패',
    );
  }

  /// AI 컨텍스트용 최근 대화 (요약용)
  Future<QueryResult<List<ChatMessageModel>>> getForAiContext(
    String sessionId, {
    int limit = 10,
  }) async {
    return safeListQuery(
      query: (client) async {
        final response = await client
            .from(chatMessagesTable)
            .select(chatMessageListColumns)
            .eq(ChatMessageColumns.sessionId, sessionId)
            .order(ChatMessageColumns.createdAt, ascending: false)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      },
      fromJson: ChatMessageModel.fromSupabaseMap,
      errorPrefix: 'AI 컨텍스트 메시지 조회 실패',
    );
  }
}

/// 싱글톤 인스턴스
const chatSessionQueries = ChatSessionQueries();
const chatMessageQueries = ChatMessageQueries();
