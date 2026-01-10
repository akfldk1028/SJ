import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/chat_session_local_datasource.dart';
import '../../data/repositories/chat_session_repository_impl.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/models/chat_type.dart';
import '../../domain/repositories/chat_session_repository.dart';

part 'chat_session_provider.g.dart';

/// 채팅 세션 상태
class ChatSessionState {
  final List<ChatSession> sessions;
  final String? currentSessionId;
  final bool isLoading;
  final String? error;

  /// 새 세션 생성 시 대기 중인 메시지 (세션 생성 후 자동 전송)
  final String? pendingMessage;

  const ChatSessionState({
    this.sessions = const [],
    this.currentSessionId,
    this.isLoading = false,
    this.error,
    this.pendingMessage,
  });

  ChatSessionState copyWith({
    List<ChatSession>? sessions,
    String? currentSessionId,
    bool? isLoading,
    String? error,
    String? pendingMessage,
    bool clearCurrentSessionId = false,
    bool clearPendingMessage = false,
  }) {
    return ChatSessionState(
      sessions: sessions ?? this.sessions,
      currentSessionId: clearCurrentSessionId ? null : (currentSessionId ?? this.currentSessionId),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pendingMessage: clearPendingMessage ? null : (pendingMessage ?? this.pendingMessage),
    );
  }
}

/// ChatSessionRepository Provider
@riverpod
ChatSessionRepository chatSessionRepository(ChatSessionRepositoryRef ref) {
  final datasource = ChatSessionLocalDatasource();
  return ChatSessionRepositoryImpl(datasource);
}

/// 채팅 세션 상태 관리 Provider
@riverpod
class ChatSessionNotifier extends _$ChatSessionNotifier {
  @override
  ChatSessionState build() {
    // 초기화 시 세션 로드 (build 완료 후 실행)
    Future.microtask(() => loadSessions());
    return const ChatSessionState();
  }

  /// 모든 세션 로드 (updatedAt 역순 정렬)
  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(chatSessionRepositoryProvider);
      final sessions = await repository.getAllSessions();

      // Repository에서 이미 정렬되어 오지만 명시적으로 한번 더 정렬
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      state = state.copyWith(
        sessions: sessions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '세션 로드 중 오류가 발생했습니다.',
      );
    }
  }

  /// 새 세션 생성 및 현재 세션으로 설정
  /// [initialMessage]: 세션 생성 후 바로 전송할 메시지 (선택)
  /// [targetProfileId]: 궁합 채팅 시 상대방 프로필 ID (선택)
  Future<ChatSession?> createSession(
    ChatType type,
    String? profileId, {
    String? initialMessage,
    String? targetProfileId,
  }) async {
    print('[ChatSessionNotifier] createSession 시작: type=$type, profileId=$profileId, targetProfileId=$targetProfileId, initialMessage=$initialMessage');
    try {
      final repository = ref.read(chatSessionRepositoryProvider);
      final newSession = await repository.createSession(type, profileId, targetProfileId: targetProfileId);
      print('[ChatSessionNotifier] 세션 생성 완료: id=${newSession.id}, targetProfileId=${newSession.targetProfileId}');

      // 세션 목록에 추가 (맨 앞에) + 대기 메시지 설정
      state = state.copyWith(
        sessions: [newSession, ...state.sessions],
        currentSessionId: newSession.id,
        pendingMessage: initialMessage,
      );
      print('[ChatSessionNotifier] state 업데이트 완료: currentSessionId=${state.currentSessionId}, pendingMessage=${state.pendingMessage}');

      return newSession;
    } catch (e) {
      print('[ChatSessionNotifier] 세션 생성 오류: $e');
      state = state.copyWith(
        error: '세션 생성 중 오류가 발생했습니다.',
      );
      return null;
    }
  }

  /// 대기 메시지 클리어
  void clearPendingMessage() {
    state = state.copyWith(clearPendingMessage: true);
  }

  /// 세션 선택
  void selectSession(String sessionId) {
    state = state.copyWith(currentSessionId: sessionId);
  }

  /// 세션 삭제 (세션 + 메시지)
  Future<void> deleteSession(String sessionId) async {
    try {
      final repository = ref.read(chatSessionRepositoryProvider);
      await repository.deleteSession(sessionId);

      // 세션 목록에서 제거
      final updatedSessions = state.sessions.where((s) => s.id != sessionId).toList();

      // 삭제된 세션이 현재 선택된 세션이면 초기화
      final shouldClearCurrentSessionId = state.currentSessionId == sessionId;

      state = state.copyWith(
        sessions: updatedSessions,
        clearCurrentSessionId: shouldClearCurrentSessionId,
      );
    } catch (e) {
      state = state.copyWith(
        error: '세션 삭제 중 오류가 발생했습니다.',
      );
    }
  }

  /// 세션 제목 변경
  Future<void> renameSession(String sessionId, String newTitle) async {
    try {
      // 현재 세션 찾기
      final session = state.sessions.firstWhere((s) => s.id == sessionId);

      // 제목 업데이트
      final updatedSession = session.copyWith(
        title: newTitle,
        updatedAt: DateTime.now(),
      );

      final repository = ref.read(chatSessionRepositoryProvider);
      await repository.updateSession(updatedSession);

      // 세션 목록 업데이트
      final updatedSessions = state.sessions.map((s) {
        return s.id == sessionId ? updatedSession : s;
      }).toList();

      // updatedAt 변경으로 재정렬
      updatedSessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      state = state.copyWith(sessions: updatedSessions);
    } catch (e) {
      state = state.copyWith(
        error: '세션 제목 변경 중 오류가 발생했습니다.',
      );
    }
  }

  /// 현재 선택된 세션 가져오기
  ChatSession? getCurrentSession() {
    if (state.currentSessionId == null) return null;

    try {
      return state.sessions.firstWhere((s) => s.id == state.currentSessionId);
    } catch (e) {
      return null;
    }
  }

  /// 날짜별로 그룹화된 세션 목록 반환
  Map<SessionGroup, List<ChatSession>> getGroupedSessions() {
    final grouped = <SessionGroup, List<ChatSession>>{};

    for (final session in state.sessions) {
      final group = session.group;
      grouped.putIfAbsent(group, () => []).add(session);
    }

    return grouped;
  }
}
