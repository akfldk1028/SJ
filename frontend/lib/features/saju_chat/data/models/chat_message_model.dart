import 'package:frontend/features/saju_chat/domain/entities/chat_message.dart';

/// 채팅 메시지 데이터 모델 (Hive 저장용)
class ChatMessageModel {
  final String id;
  final String content;
  final String role; // MessageRole enum as String
  final DateTime createdAt;
  final String status; // MessageStatus enum as String

  ChatMessageModel({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
    this.status = 'sent',
  });

  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      content: entity.content,
      role: entity.role.name,
      createdAt: entity.createdAt,
      status: entity.status.name,
    );
  }

  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      content: content,
      role: MessageRole.values.byName(role),
      createdAt: createdAt,
      status: MessageStatus.values.byName(status),
    );
  }

  /// Hive에 저장할 Map으로 변환
  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'content': content,
      'role': role,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'status': status,
    };
  }

  /// Hive Map에서 생성
  static ChatMessageModel fromHiveMap(Map<dynamic, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] as String,
      content: map['content'] as String,
      role: map['role'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      status: (map['status'] as String?) ?? 'sent',
    );
  }
}
