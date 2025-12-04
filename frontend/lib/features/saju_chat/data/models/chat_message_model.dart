import 'package:hive/hive.dart';
import 'package:frontend/features/saju_chat/domain/entities/chat_message.dart';
import 'package:frontend/features/saju_chat/domain/entities/message_role.dart';

part 'chat_message_model.g.dart';

@HiveType(typeId: 3)
class ChatMessageModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sessionId;

  @HiveField(2)
  final String role; // Store enum as String

  @HiveField(3)
  final String content;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final bool isError;

  ChatMessageModel({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isError = false,
  });

  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      sessionId: entity.sessionId,
      role: entity.role.name,
      content: entity.content,
      createdAt: entity.createdAt,
      isError: entity.isError,
    );
  }

  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      sessionId: sessionId,
      role: MessageRole.values.byName(role),
      content: content,
      createdAt: createdAt,
      isError: isError,
    );
  }

  /// Hive에 저장할 Map으로 변환
  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'role': role,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isError': isError,
    };
  }

  /// Hive Map에서 생성
  static ChatMessageModel fromHiveMap(Map<dynamic, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] as String,
      sessionId: map['sessionId'] as String,
      role: map['role'] as String,
      content: map['content'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      isError: (map['isError'] as bool?) ?? false,
    );
  }
}
