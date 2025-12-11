import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../../features/saju_chat/domain/entities/chat_session.dart';
import '../../features/saju_chat/domain/entities/chat_message.dart';
import '../../features/saju_chat/domain/models/chat_type.dart';

/// Supabase chat_sessions + chat_messages 테이블 Repository
class ChatRepository {
  final SupabaseClient _client;

  ChatRepository() : _client = SupabaseService.client;

  // ============================================================
  // SESSIONS - CREATE
  // ============================================================

  /// 새 채팅 세션 생성
  /// [id]: 로컬에서 생성한 UUID를 사용 (동기화를 위해)
  Future<ChatSession> createSession({
    String? id,
    required String profileId,
    required ChatType chatType,
    String? title,
  }) async {
    final data = {
      if (id != null) 'id': id,
      'profile_id': profileId,
      'chat_type': chatType.name,
      'title': title,
    };

    final response = await _client
        .from('chat_sessions')
        .insert(data)
        .select()
        .single();

    return _sessionFromMap(response);
  }

  // ============================================================
  // SESSIONS - READ
  // ============================================================

  /// 프로필의 모든 세션 조회 (최신순)
  Future<List<ChatSession>> getSessionsByProfile(String profileId) async {
    final response = await _client
        .from('chat_sessions')
        .select()
        .eq('profile_id', profileId)
        .order('updated_at', ascending: false);

    return (response as List)
        .map((e) => _sessionFromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// 세션 ID로 조회
  Future<ChatSession?> getSessionById(String sessionId) async {
    final response = await _client
        .from('chat_sessions')
        .select()
        .eq('id', sessionId)
        .maybeSingle();

    if (response == null) return null;
    return _sessionFromMap(response);
  }

  /// 최근 세션 조회 (limit 개수만큼)
  Future<List<ChatSession>> getRecentSessions(String profileId, {int limit = 10}) async {
    final response = await _client
        .from('chat_sessions')
        .select()
        .eq('profile_id', profileId)
        .order('updated_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => _sessionFromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SESSIONS - UPDATE
  // ============================================================

  /// 세션 제목 업데이트
  Future<void> updateSessionTitle(String sessionId, String title) async {
    await _client
        .from('chat_sessions')
        .update({'title': title})
        .eq('id', sessionId);
  }

  /// 세션 컨텍스트 요약 업데이트 (토큰 절약용)
  Future<void> updateContextSummary(String sessionId, String summary) async {
    await _client
        .from('chat_sessions')
        .update({'context_summary': summary})
        .eq('id', sessionId);
  }

  // ============================================================
  // SESSIONS - DELETE
  // ============================================================

  /// 세션 삭제 (CASCADE로 메시지도 삭제됨)
  Future<void> deleteSession(String sessionId) async {
    await _client.from('chat_sessions').delete().eq('id', sessionId);
  }

  // ============================================================
  // MESSAGES - CREATE
  // ============================================================

  /// 메시지 추가
  Future<ChatMessage> addMessage({
    required String sessionId,
    required String content,
    required MessageRole role,
    List<String>? suggestedQuestions,
    int? tokensUsed,
  }) async {
    final data = {
      'session_id': sessionId,
      'content': content,
      'role': role.name,
      'status': 'sent',
      'suggested_questions': suggestedQuestions,
      'tokens_used': tokensUsed,
    };

    final response = await _client
        .from('chat_messages')
        .insert(data)
        .select()
        .single();

    return _messageFromMap(response);
    // 트리거가 자동으로 session의 message_count, last_message_preview 업데이트
  }

  /// 사용자 메시지 추가 (편의 메서드)
  Future<ChatMessage> addUserMessage(String sessionId, String content) async {
    return addMessage(
      sessionId: sessionId,
      content: content,
      role: MessageRole.user,
    );
  }

  /// AI 응답 메시지 추가 (편의 메서드)
  Future<ChatMessage> addAssistantMessage(
    String sessionId,
    String content, {
    List<String>? suggestedQuestions,
    int? tokensUsed,
  }) async {
    return addMessage(
      sessionId: sessionId,
      content: content,
      role: MessageRole.assistant,
      suggestedQuestions: suggestedQuestions,
      tokensUsed: tokensUsed,
    );
  }

  // ============================================================
  // MESSAGES - READ
  // ============================================================

  /// 세션의 모든 메시지 조회 (시간순)
  Future<List<ChatMessage>> getMessagesBySession(String sessionId) async {
    final response = await _client
        .from('chat_messages')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((e) => _messageFromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// 최근 N개 메시지 조회 (AI 컨텍스트용)
  Future<List<ChatMessage>> getRecentMessages(String sessionId, {int limit = 20}) async {
    final response = await _client
        .from('chat_messages')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: false)
        .limit(limit);

    // 시간순으로 정렬해서 반환
    final messages = (response as List)
        .map((e) => _messageFromMap(e as Map<String, dynamic>))
        .toList();
    return messages.reversed.toList();
  }

  // ============================================================
  // MESSAGES - UPDATE
  // ============================================================

  /// 메시지 상태 업데이트
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    await _client
        .from('chat_messages')
        .update({'status': status.name})
        .eq('id', messageId);
  }

  // ============================================================
  // 변환 함수
  // ============================================================

  ChatSession _sessionFromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      chatType: ChatType.fromString(map['chat_type'] as String?),
      profileId: map['profile_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      messageCount: map['message_count'] as int? ?? 0,
      lastMessagePreview: map['last_message_preview'] as String?,
    );
  }

  ChatMessage _messageFromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      content: map['content'] as String,
      role: _roleFromString(map['role'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      status: _statusFromString(map['status'] as String?),
    );
  }

  MessageRole _roleFromString(String role) {
    switch (role) {
      case 'user':
        return MessageRole.user;
      case 'assistant':
        return MessageRole.assistant;
      case 'system':
        return MessageRole.system;
      default:
        return MessageRole.user;
    }
  }

  MessageStatus _statusFromString(String? status) {
    switch (status) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'error':
        return MessageStatus.error;
      default:
        return MessageStatus.sent;
    }
  }

  // ============================================================
  // 컨텍스트 관련 (AI 대화용)
  // ============================================================

  /// 세션 컨텍스트 요약 조회
  Future<String?> getContextSummary(String sessionId) async {
    final response = await _client
        .from('chat_sessions')
        .select('context_summary')
        .eq('id', sessionId)
        .maybeSingle();

    if (response == null) return null;
    return response['context_summary'] as String?;
  }
}
