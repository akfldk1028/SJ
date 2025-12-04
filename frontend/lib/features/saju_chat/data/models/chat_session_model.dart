import 'package:hive/hive.dart';
import 'package:frontend/features/saju_chat/domain/entities/chat_session.dart';

part 'chat_session_model.g.dart';

@HiveType(typeId: 2) // TypeId 0: SajuProfile, 1: SajuProfileModel (check to avoid conflict)
class ChatSessionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String profileId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final DateTime lastMessageAt;

  @HiveField(4)
  final DateTime createdAt;

  ChatSessionModel({
    required this.id,
    required this.profileId,
    required this.title,
    required this.lastMessageAt,
    required this.createdAt,
  });

  factory ChatSessionModel.fromEntity(ChatSession entity) {
    return ChatSessionModel(
      id: entity.id,
      profileId: entity.profileId,
      title: entity.title,
      lastMessageAt: entity.lastMessageAt,
      createdAt: entity.createdAt,
    );
  }

  ChatSession toEntity() {
    return ChatSession(
      id: id,
      profileId: profileId,
      title: title,
      lastMessageAt: lastMessageAt,
      createdAt: createdAt,
    );
  }
}
