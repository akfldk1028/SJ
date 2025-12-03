import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';

/// 채팅 Remote DataSource (Supabase 연동)
class ChatRemoteDataSource {
  final SupabaseClient _client;

  ChatRemoteDataSource(this._client);

  /// 프로필별 세션 목록 조회 (최신순)
  Future<List<ChatSessionModel>> getSessions(String profileId) async {
    final response = await _client
        .from('chat_sessions')
        .select()
        .eq('profile_id', profileId)
        .order('last_message_at', ascending: false);

    return (response as List)
        .map((json) => ChatSessionModel.fromJson(json))
        .toList();
  }

  /// 특정 세션 조회
  Future<ChatSessionModel?> getSessionById(String sessionId) async {
    final response = await _client
        .from('chat_sessions')
        .select()
        .eq('id', sessionId)
        .maybeSingle();

    if (response == null) return null;
    return ChatSessionModel.fromJson(response);
  }

  /// 세션의 메시지 목록 조회 (시간순)
  Future<List<ChatMessageModel>> getMessages(String sessionId) async {
    final response = await _client
        .from('chat_messages')
        .select()
        .eq('chat_id', sessionId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => ChatMessageModel.fromJson(json))
        .toList();
  }

  /// 새 세션 생성
  Future<ChatSessionModel> createSession(String profileId) async {
    final now = DateTime.now();
    final response = await _client
        .from('chat_sessions')
        .insert({
          'profile_id': profileId,
          'created_at': now.toIso8601String(),
          'last_message_at': now.toIso8601String(),
          'message_count': 0,
        })
        .select()
        .single();

    return ChatSessionModel.fromJson(response);
  }

  /// 세션 삭제
  Future<void> deleteSession(String sessionId) async {
    await _client.from('chat_sessions').delete().eq('id', sessionId);
  }

  /// AI에게 메시지 전송 (Edge Function 호출)
  Future<ChatMessageModel> sendMessage({
    String? sessionId,
    required String profileId,
    required String message,
  }) async {
    final response = await _client.functions.invoke(
      'saju-chat',
      body: {
        'chatId': sessionId,
        'profileId': profileId,
        'message': message,
      },
    );

    if (response.status != 200) {
      throw Exception('채팅 API 오류: ${response.status}');
    }

    final data = response.data as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['error'] ?? '알 수 없는 오류');
    }

    final resultData = data['data'] as Map<String, dynamic>;
    final chatId = resultData['chatId'] as String;

    return ChatMessageModel.fromApiResponse(resultData, chatId);
  }
}
