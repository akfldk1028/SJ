import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/chat_message.dart';

/// 채팅 Realtime 서비스
///
/// Supabase Realtime을 사용하여 새 메시지 수신
/// - INSERT: 다른 기기에서 보낸 메시지 수신
/// - DELETE: 다른 기기에서 삭제한 메시지 동기화
class ChatRealtimeService {
  static ChatRealtimeService? _instance;
  static ChatRealtimeService get instance => _instance ??= ChatRealtimeService._();

  ChatRealtimeService._();

  RealtimeChannel? _channel;
  String? _currentSessionId;

  /// 새 메시지 수신 스트림
  final _messageController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get onNewMessage => _messageController.stream;

  /// 메시지 삭제 이벤트 스트림
  final _deleteController = StreamController<String>.broadcast();
  Stream<String> get onMessageDeleted => _deleteController.stream;

  /// 세션의 메시지 구독 시작
  Future<void> subscribeToSession(String sessionId) async {
    final client = SupabaseService.client;
    if (client == null) {
      if (kDebugMode) {
        print('[ChatRealtime] Supabase 연결 안됨');
      }
      return;
    }

    // 기존 구독 해제
    if (_currentSessionId != null && _currentSessionId != sessionId) {
      await unsubscribe();
    }

    // 이미 같은 세션 구독 중이면 스킵
    if (_currentSessionId == sessionId) {
      return;
    }

    _currentSessionId = sessionId;

    // Realtime 채널 생성
    _channel = client.channel('chat_messages:$sessionId');

    // Postgres Changes 구독
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: _handleInsert,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: _handleDelete,
        )
        .subscribe((status, error) {
          if (kDebugMode) {
            print('[ChatRealtime] 구독 상태: $status, 에러: $error');
          }
        });

    if (kDebugMode) {
      print('[ChatRealtime] 세션 구독 시작: $sessionId');
    }
  }

  /// INSERT 이벤트 처리
  void _handleInsert(PostgresChangePayload payload) {
    try {
      final newRecord = payload.newRecord;
      if (newRecord.isEmpty) return;

      final message = _messageFromMap(newRecord);
      _messageController.add(message);

      if (kDebugMode) {
        print('[ChatRealtime] 새 메시지 수신: ${message.role.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ChatRealtime] INSERT 처리 오류: $e');
      }
    }
  }

  /// DELETE 이벤트 처리
  void _handleDelete(PostgresChangePayload payload) {
    try {
      final oldRecord = payload.oldRecord;
      final messageId = oldRecord['id'] as String?;
      if (messageId != null) {
        _deleteController.add(messageId);

        if (kDebugMode) {
          print('[ChatRealtime] 메시지 삭제 수신: $messageId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ChatRealtime] DELETE 처리 오류: $e');
      }
    }
  }

  /// Map → ChatMessage 변환
  ChatMessage _messageFromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      content: map['content'] as String,
      role: _roleFromString(map['role'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      tokensUsed: map['tokens_used'] as int?,
      suggestedQuestions: map['suggested_questions'] != null
          ? List<String>.from(map['suggested_questions'] as List)
          : null,
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

  /// 구독 해제
  Future<void> unsubscribe() async {
    if (_channel != null) {
      await _channel!.unsubscribe();
      _channel = null;
      _currentSessionId = null;

      if (kDebugMode) {
        print('[ChatRealtime] 구독 해제됨');
      }
    }
  }

  /// 리소스 해제
  void dispose() {
    unsubscribe();
    _messageController.close();
    _deleteController.close();
  }
}
