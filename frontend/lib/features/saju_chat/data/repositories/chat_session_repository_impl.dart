import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/models/chat_type.dart';
import '../../domain/repositories/chat_session_repository.dart';
import '../datasources/chat_session_local_datasource.dart';
import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';
import '../../../../core/repositories/chat_repository.dart';
import '../../../../core/services/auth_service.dart';

/// 채팅 세션 Repository 구현체
///
/// Local-First + Cloud Sync 패턴:
/// - Hive(로컬): 빠른 응답, 오프라인 지원
/// - Supabase(클라우드): 데이터 백업, 기기 간 동기화
class ChatSessionRepositoryImpl implements ChatSessionRepository {
  final ChatSessionLocalDatasource _localDatasource;
  final ChatRepository _supabaseRepository;
  final AuthService _authService;
  final Uuid _uuid = const Uuid();

  ChatSessionRepositoryImpl(this._localDatasource)
      : _supabaseRepository = ChatRepository(),
        _authService = AuthService();

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
    if (kDebugMode) {
      print('[ChatRepo] createSession 호출: chatType=$chatType, profileId=$profileId');
    }
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

    // 1. 로컬 저장 (Hive) - 즉시 응답
    await _localDatasource.saveSession(newSession);

    // 2. 클라우드 저장 (Supabase) - 비동기 백업
    _syncSessionToSupabase(newSession.toEntity());

    return newSession.toEntity();
  }

  /// 세션을 Supabase에 저장 (비동기, 에러 발생해도 앱 계속 동작)
  Future<void> _syncSessionToSupabase(ChatSession session) async {
    try {
      if (!_authService.isLoggedIn) {
        if (kDebugMode) {
          print('[ChatRepo] Supabase 동기화 스킵: 로그인되지 않음');
        }
        return;
      }

      if (session.profileId == null) {
        if (kDebugMode) {
          print('[ChatRepo] Supabase 동기화 스킵: profileId 없음');
        }
        return;
      }

      await _supabaseRepository.createSession(
        id: session.id, // 로컬 ID와 동일하게 유지
        profileId: session.profileId!,
        chatType: ChatType.fromString(session.chatType.name),
        title: session.title,
      );

      if (kDebugMode) {
        print('[ChatRepo] Supabase 세션 저장 완료: ${session.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ChatRepo] Supabase 세션 저장 실패 (로컬은 저장됨): $e');
      }
    }
  }

  @override
  Future<void> updateSession(ChatSession session) async {
    final model = ChatSessionModel.fromEntity(session);
    await _localDatasource.updateSession(model);
  }

  @override
  Future<void> deleteSession(String id) async {
    // 1. 로컬 삭제 (세션 + 메시지)
    await _localDatasource.deleteSessionMessages(id);
    await _localDatasource.deleteSession(id);

    // 2. 클라우드 삭제 (Supabase) - CASCADE로 메시지도 삭제됨
    _deleteSessionFromSupabase(id);
  }

  /// Supabase에서 세션 삭제
  Future<void> _deleteSessionFromSupabase(String sessionId) async {
    try {
      if (!_authService.isLoggedIn) return;

      await _supabaseRepository.deleteSession(sessionId);
      if (kDebugMode) {
        print('[ChatRepo] Supabase 세션 삭제 완료: $sessionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ChatRepo] Supabase 세션 삭제 실패: $e');
      }
    }
  }

  @override
  Future<List<ChatMessage>> getSessionMessages(String sessionId) async {
    final models = await _localDatasource.getSessionMessages(sessionId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveMessage(ChatMessage message) async {
    // 1. 로컬 저장 (Hive) - 즉시 응답
    final model = ChatMessageModel.fromEntity(message);
    await _localDatasource.saveMessage(model);

    // 메시지 저장 후 세션 메타데이터 업데이트
    await _updateSessionMetadata(message.sessionId);

    // 2. 클라우드 저장 (Supabase) - 비동기 백업
    _syncMessageToSupabase(message);
  }

  /// 메시지를 Supabase에 저장
  Future<void> _syncMessageToSupabase(ChatMessage message) async {
    try {
      if (!_authService.isLoggedIn) {
        if (kDebugMode) {
          print('[ChatRepo] 메시지 동기화 스킵: 로그인되지 않음');
        }
        return;
      }

      await _supabaseRepository.addMessage(
        sessionId: message.sessionId,
        content: message.content,
        role: message.role,
      );

      if (kDebugMode) {
        print('[ChatRepo] Supabase 메시지 저장 완료: ${message.role.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ChatRepo] Supabase 메시지 저장 실패 (로컬은 저장됨): $e');
      }
    }
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
