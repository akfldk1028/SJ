import 'package:hive_flutter/hive_flutter.dart';
import 'package:frontend/features/saju_chat/data/models/chat_message_model.dart';
import 'package:frontend/features/saju_chat/data/models/chat_session_model.dart';

class ChatLocalDataSource {
  static const String sessionBoxName = 'chat_sessions';
  static const String messageBoxName = 'chat_messages';

  Future<Box<ChatSessionModel>> get _sessionBox async {
    if (Hive.isBoxOpen(sessionBoxName)) {
      return Hive.box<ChatSessionModel>(sessionBoxName);
    }
    return await Hive.openBox<ChatSessionModel>(sessionBoxName);
  }

  Future<Box<ChatMessageModel>> get _messageBox async {
    if (Hive.isBoxOpen(messageBoxName)) {
      return Hive.box<ChatMessageModel>(messageBoxName);
    }
    return await Hive.openBox<ChatMessageModel>(messageBoxName);
  }

  Future<List<ChatSessionModel>> getSessions(String profileId) async {
    final box = await _sessionBox;
    return box.values
        .where((session) => session.profileId == profileId)
        .toList()
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
  }

  Future<void> saveSession(ChatSessionModel session) async {
    final box = await _sessionBox;
    await box.put(session.id, session);
  }

  Future<void> deleteSession(String sessionId) async {
    final sessionBox = await _sessionBox;
    await sessionBox.delete(sessionId);

    // 관련 메시지도 삭제
    final messageBox = await _messageBox;
    final messagesToDelete = messageBox.values
        .where((msg) => msg.sessionId == sessionId)
        .map((msg) => msg.id)
        .toList();
    
    for (var key in messagesToDelete) {
      await messageBox.delete(key); // Note: key might need to be checked if it matches id
    }
  }

  Future<List<ChatMessageModel>> getMessages(String sessionId) async {
    final box = await _messageBox;
    return box.values
        .where((msg) => msg.sessionId == sessionId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> saveMessage(ChatMessageModel message) async {
    final box = await _messageBox;
    await box.put(message.id, message);
  }
}
