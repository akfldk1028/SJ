import 'package:hive_flutter/hive_flutter.dart';
import 'package:frontend/features/saju_chat/data/models/chat_message_model.dart';
import 'package:frontend/features/saju_chat/data/models/chat_session_model.dart';

class ChatLocalDataSource {
  static const String sessionBoxName = 'chat_sessions';
  static const String messageBoxName = 'chat_messages';

  /// Map 기반 Hive Box (TypeAdapter 불필요)
  Future<Box<Map<dynamic, dynamic>>> get _sessionBox async {
    if (Hive.isBoxOpen(sessionBoxName)) {
      return Hive.box<Map<dynamic, dynamic>>(sessionBoxName);
    }
    return await Hive.openBox<Map<dynamic, dynamic>>(sessionBoxName);
  }

  Future<Box<Map<dynamic, dynamic>>> get _messageBox async {
    if (Hive.isBoxOpen(messageBoxName)) {
      return Hive.box<Map<dynamic, dynamic>>(messageBoxName);
    }
    return await Hive.openBox<Map<dynamic, dynamic>>(messageBoxName);
  }

  Future<List<ChatSessionModel>> getSessions(String profileId) async {
    final box = await _sessionBox;
    final sessions = <ChatSessionModel>[];

    for (var i = 0; i < box.length; i++) {
      final map = box.getAt(i);
      if (map != null && map['profileId'] == profileId) {
        sessions.add(ChatSessionModel.fromHiveMap(map));
      }
    }

    // 최근 메시지 순으로 정렬
    sessions.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return sessions;
  }

  Future<void> saveSession(ChatSessionModel session) async {
    final box = await _sessionBox;

    // 기존 세션 찾기
    int? existingIndex;
    for (var i = 0; i < box.length; i++) {
      final map = box.getAt(i);
      if (map != null && map['id'] == session.id) {
        existingIndex = i;
        break;
      }
    }

    final data = session.toHiveMap();
    if (existingIndex != null) {
      await box.putAt(existingIndex, data);
    } else {
      await box.add(data);
    }
  }

  Future<void> deleteSession(String sessionId) async {
    final sessionBox = await _sessionBox;

    // 세션 삭제
    for (var i = 0; i < sessionBox.length; i++) {
      final map = sessionBox.getAt(i);
      if (map != null && map['id'] == sessionId) {
        await sessionBox.deleteAt(i);
        break;
      }
    }

    // 관련 메시지도 삭제
    final messageBox = await _messageBox;
    final toDeleteIndices = <int>[];

    for (var i = 0; i < messageBox.length; i++) {
      final map = messageBox.getAt(i);
      if (map != null && map['sessionId'] == sessionId) {
        toDeleteIndices.add(i);
      }
    }

    // 역순으로 삭제 (인덱스 변경 방지)
    for (var i = toDeleteIndices.length - 1; i >= 0; i--) {
      await messageBox.deleteAt(toDeleteIndices[i]);
    }
  }

  Future<List<ChatMessageModel>> getMessages(String sessionId) async {
    final box = await _messageBox;
    final messages = <ChatMessageModel>[];

    for (var i = 0; i < box.length; i++) {
      final map = box.getAt(i);
      if (map != null && map['sessionId'] == sessionId) {
        messages.add(ChatMessageModel.fromHiveMap(map));
      }
    }

    // 생성 시간순 정렬
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  Future<void> saveMessage(ChatMessageModel message) async {
    final box = await _messageBox;

    // 기존 메시지 찾기
    int? existingIndex;
    for (var i = 0; i < box.length; i++) {
      final map = box.getAt(i);
      if (map != null && map['id'] == message.id) {
        existingIndex = i;
        break;
      }
    }

    final data = message.toHiveMap();
    if (existingIndex != null) {
      await box.putAt(existingIndex, data);
    } else {
      await box.add(data);
    }
  }
}
