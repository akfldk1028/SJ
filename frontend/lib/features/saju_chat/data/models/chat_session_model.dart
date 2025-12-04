import 'package:frontend/features/saju_chat/domain/entities/chat_session.dart';
import 'package:frontend/features/saju_chat/domain/models/chat_type.dart';
import 'chat_message_model.dart';

/// 채팅 세션 데이터 모델 (Hive 저장용)
class ChatSessionModel {
  final String id;
  final String chatType; // ChatType enum as String
  final List<ChatMessageModel> messages;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ChatSessionModel({
    required this.id,
    required this.chatType,
    required this.messages,
    required this.createdAt,
    this.updatedAt,
  });

  factory ChatSessionModel.fromEntity(ChatSession entity) {
    return ChatSessionModel(
      id: entity.id,
      chatType: entity.chatType.name,
      messages: entity.messages
          .map((m) => ChatMessageModel.fromEntity(m))
          .toList(),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ChatSession toEntity() {
    return ChatSession(
      id: id,
      chatType: ChatType.values.byName(chatType),
      messages: messages.map((m) => m.toEntity()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Hive에 저장할 Map으로 변환
  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'chatType': chatType,
      'messages': messages.map((m) => m.toHiveMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Hive Map에서 생성
  static ChatSessionModel fromHiveMap(Map<dynamic, dynamic> map) {
    final messagesList = (map['messages'] as List?)
            ?.map((m) => ChatMessageModel.fromHiveMap(m as Map<dynamic, dynamic>))
            .toList() ??
        [];

    return ChatSessionModel(
      id: map['id'] as String,
      chatType: map['chatType'] as String,
      messages: messagesList,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
    );
  }
}
