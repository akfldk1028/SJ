import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';

/// 채팅 세션 로컬 데이터소스
///
/// Hive를 사용한 채팅 세션/메시지 로컬 저장소
/// 주의: Box<dynamic>으로 열어서 타입 캐스팅 문제 방지
class ChatSessionLocalDatasource {
  static const String _sessionsBoxName = 'chat_sessions';
  static const String _messagesBoxName = 'chat_messages';

  Box<dynamic>? _sessionsBox;
  Box<dynamic>? _messagesBox;

  /// Hive Boxes 초기화 (dynamic 타입으로 열어서 호환성 보장)
  Future<void> init() async {
    // Sessions Box
    if (_sessionsBox == null || !_sessionsBox!.isOpen) {
      if (Hive.isBoxOpen(_sessionsBoxName)) {
        _sessionsBox = Hive.box(_sessionsBoxName);
      } else {
        _sessionsBox = await Hive.openBox(_sessionsBoxName);
      }
    }

    // Messages Box
    if (_messagesBox == null || !_messagesBox!.isOpen) {
      if (Hive.isBoxOpen(_messagesBoxName)) {
        _messagesBox = Hive.box(_messagesBoxName);
      } else {
        _messagesBox = await Hive.openBox(_messagesBoxName);
      }
    }
  }

  /// Sessions Box 가져오기 (null safety 보장)
  Box<dynamic> _getSessionsBox() {
    if (_sessionsBox == null || !_sessionsBox!.isOpen) {
      throw StateError('ChatSessionLocalDatasource not initialized. Call init() first.');
    }
    return _sessionsBox!;
  }

  /// Messages Box 가져오기 (null safety 보장)
  Box<dynamic> _getMessagesBox() {
    if (_messagesBox == null || !_messagesBox!.isOpen) {
      throw StateError('ChatSessionLocalDatasource not initialized. Call init() first.');
    }
    return _messagesBox!;
  }

  // ========== Session CRUD ==========

  /// 모든 세션 조회
  Future<List<ChatSessionModel>> getAllSessions() async {
    await init();
    final box = _getSessionsBox();

    final sessions = <ChatSessionModel>[];
    for (var i = 0; i < box.length; i++) {
      final raw = box.getAt(i);
      if (raw != null) {
        final map = Map<dynamic, dynamic>.from(raw as Map);
        sessions.add(ChatSessionModel.fromHiveMap(map));
      }
    }

    // 업데이트 시간 역순 정렬
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  /// ID로 세션 조회
  Future<ChatSessionModel?> getSessionById(String id) async {
    await init();
    final box = _getSessionsBox();

    for (var i = 0; i < box.length; i++) {
      final raw = box.getAt(i);
      if (raw != null) {
        final map = Map<dynamic, dynamic>.from(raw as Map);
        if (map['id'] == id) {
          return ChatSessionModel.fromHiveMap(map);
        }
      }
    }
    return null;
  }

  /// 세션 저장
  ///
  /// 같은 ID가 이미 있으면 업데이트, 없으면 추가
  Future<void> saveSession(ChatSessionModel session) async {
    await init();
    final box = _getSessionsBox();

    // 기존 세션 찾기
    int? existingIndex;
    for (var i = 0; i < box.length; i++) {
      final raw = box.getAt(i);
      if (raw != null) {
        final map = Map<dynamic, dynamic>.from(raw as Map);
        if (map['id'] == session.id) {
          existingIndex = i;
          break;
        }
      }
    }

    final data = session.toHiveMap();

    if (existingIndex != null) {
      // 업데이트
      await box.putAt(existingIndex, data);
    } else {
      // 새로 추가
      await box.add(data);
    }
  }

  /// 세션 업데이트
  Future<void> updateSession(ChatSessionModel session) async {
    await saveSession(session);
  }

  /// 세션 삭제
  Future<void> deleteSession(String id) async {
    await init();
    final box = _getSessionsBox();

    for (var i = 0; i < box.length; i++) {
      final raw = box.getAt(i);
      if (raw != null) {
        final map = Map<dynamic, dynamic>.from(raw as Map);
        if (map['id'] == id) {
          await box.deleteAt(i);
          return;
        }
      }
    }
  }

  /// 세션 개수 조회
  Future<int> getSessionCount() async {
    await init();
    return _getSessionsBox().length;
  }

  /// 모든 세션 삭제 (테스트용)
  Future<void> clearAllSessions() async {
    await init();
    await _getSessionsBox().clear();
  }

  // ========== Message CRUD ==========

  /// 특정 세션의 메시지 목록 조회
  Future<List<ChatMessageModel>> getSessionMessages(String sessionId) async {
    await init();
    final box = _getMessagesBox();

    final messages = <ChatMessageModel>[];
    for (var i = 0; i < box.length; i++) {
      final raw = box.getAt(i);
      if (raw != null) {
        final map = Map<dynamic, dynamic>.from(raw as Map);
        if (map['sessionId'] == sessionId) {
          messages.add(ChatMessageModel.fromHiveMap(map));
        }
      }
    }

    // 생성 시간 순서 정렬
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  /// 메시지 저장
  Future<void> saveMessage(ChatMessageModel message) async {
    await init();
    final box = _getMessagesBox();

    // 기존 메시지 찾기
    int? existingIndex;
    for (var i = 0; i < box.length; i++) {
      final raw = box.getAt(i);
      if (raw != null) {
        final map = Map<dynamic, dynamic>.from(raw as Map);
        if (map['id'] == message.id) {
          existingIndex = i;
          break;
        }
      }
    }

    final data = message.toHiveMap();

    if (existingIndex != null) {
      // 업데이트
      await box.putAt(existingIndex, data);
    } else {
      // 새로 추가
      await box.add(data);
    }
  }

  /// 특정 세션의 모든 메시지 삭제
  Future<void> deleteSessionMessages(String sessionId) async {
    await init();
    final box = _getMessagesBox();

    // 역순으로 삭제 (인덱스 변경 문제 방지)
    for (var i = box.length - 1; i >= 0; i--) {
      final raw = box.getAt(i);
      if (raw != null) {
        final map = Map<dynamic, dynamic>.from(raw as Map);
        if (map['sessionId'] == sessionId) {
          await box.deleteAt(i);
        }
      }
    }
  }

  /// 특정 메시지 삭제
  Future<void> deleteMessage(String id) async {
    await init();
    final box = _getMessagesBox();

    for (var i = 0; i < box.length; i++) {
      final raw = box.getAt(i);
      if (raw != null) {
        final map = Map<dynamic, dynamic>.from(raw as Map);
        if (map['id'] == id) {
          await box.deleteAt(i);
          return;
        }
      }
    }
  }

  /// 메시지 개수 조회
  Future<int> getMessageCount() async {
    await init();
    return _getMessagesBox().length;
  }

  /// 모든 메시지 삭제 (테스트용)
  Future<void> clearAllMessages() async {
    await init();
    await _getMessagesBox().clear();
  }

  // ========== Dispose ==========

  /// Box 닫기
  Future<void> dispose() async {
    if (_sessionsBox != null && _sessionsBox!.isOpen) {
      await _sessionsBox!.close();
      _sessionsBox = null;
    }
    if (_messagesBox != null && _messagesBox!.isOpen) {
      await _messagesBox!.close();
      _messagesBox = null;
    }
  }
}
