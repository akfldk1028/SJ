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

  @HiveField(5)
  final String? targetProfileId;

  ChatSessionModel({
    required this.id,
    required this.profileId,
    this.targetProfileId,
    required this.title,
    required this.lastMessageAt,
    required this.createdAt,
  });

  factory ChatSessionModel.fromEntity(ChatSession entity) {
    return ChatSessionModel(
      id: entity.id,
      profileId: entity.profileId,
      targetProfileId: entity.targetProfileId,
      title: entity.title,
      lastMessageAt: entity.lastMessageAt,
      createdAt: entity.createdAt,
    );
  }

  ChatSession toEntity() {
    return ChatSession(
      id: id,
      profileId: profileId,
      targetProfileId: targetProfileId,
      title: title,
      lastMessageAt: lastMessageAt,
      createdAt: createdAt,
    );
  }

  /// Hive에 저장할 Map으로 변환
  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'profileId': profileId,
      'targetProfileId': targetProfileId,
      'title': title,
      'lastMessageAt': lastMessageAt.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Hive Map에서 생성
  static ChatSessionModel fromHiveMap(Map<dynamic, dynamic> map) {
    return ChatSessionModel(
      id: map['id'] as String,
      profileId: map['profileId'] as String,
      targetProfileId: map['targetProfileId'] as String?,
      title: map['title'] as String,
      lastMessageAt: DateTime.fromMillisecondsSinceEpoch(map['lastMessageAt'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }
}
