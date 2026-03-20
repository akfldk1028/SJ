import 'package:easy_localization/easy_localization.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/models/chat_type.dart';
import '../../domain/models/chat_persona.dart';
import '../../domain/models/ai_persona.dart';

part 'chat_session_model.freezed.dart';
part 'chat_session_model.g.dart';

/// 채팅 세션 데이터 모델
///
/// Entity를 확장하여 JSON/Hive 직렬화 기능 추가
/// Hive TypeAdapter를 사용하지 않고 Map으로 저장
///
/// 페르소나 필드:
/// - chatPersona: 세션 고정 페르소나 (대화 시작 후 변경 불가)
/// - mbtiQuadrant: BasePerson 선택 시 MBTI 4분면
@freezed
abstract class ChatSessionModel with _$ChatSessionModel {
  const factory ChatSessionModel({
    required String id,
    required String title,
    required String chatType, // ChatType enum을 문자열로 저장
    String? profileId,
    String? targetProfileId, // 궁합 채팅 시 상대방 프로필 ID
    String? chatPersona, // ChatPersona enum을 문자열로 저장
    String? mbtiQuadrant, // MbtiQuadrant enum을 문자열로 저장
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(0) int messageCount,
    String? lastMessagePreview,
  }) = _ChatSessionModel;

  const ChatSessionModel._();

  /// JSON 직렬화
  factory ChatSessionModel.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionModelFromJson(json);

  /// Entity로 변환
  ChatSession toEntity() {
    return ChatSession(
      id: id,
      title: title,
      chatType: ChatType.fromString(chatType),
      profileId: profileId,
      targetProfileId: targetProfileId,
      chatPersona: chatPersona != null ? ChatPersona.fromString(chatPersona) : null,
      mbtiQuadrant: mbtiQuadrant != null ? _mbtiQuadrantFromString(mbtiQuadrant!) : null,
      createdAt: createdAt,
      updatedAt: updatedAt,
      messageCount: messageCount,
      lastMessagePreview: lastMessagePreview,
    );
  }

  /// MbtiQuadrant 문자열 변환 헬퍼
  static MbtiQuadrant _mbtiQuadrantFromString(String value) {
    switch (value) {
      case 'NF':
        return MbtiQuadrant.NF;
      case 'NT':
        return MbtiQuadrant.NT;
      case 'SF':
        return MbtiQuadrant.SF;
      case 'ST':
        return MbtiQuadrant.ST;
      default:
        return MbtiQuadrant.NF;
    }
  }

  /// Entity에서 생성
  static ChatSessionModel fromEntity(ChatSession entity) {
    return ChatSessionModel(
      id: entity.id,
      title: entity.title,
      chatType: entity.chatType.name,
      profileId: entity.profileId,
      targetProfileId: entity.targetProfileId,
      chatPersona: entity.chatPersona?.name,
      mbtiQuadrant: entity.mbtiQuadrant?.name,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      messageCount: entity.messageCount,
      lastMessagePreview: entity.lastMessagePreview,
    );
  }

  /// Hive에 저장할 Map으로 변환
  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'title': title,
      'chatType': chatType,
      'profileId': profileId,
      'targetProfileId': targetProfileId,
      'chatPersona': chatPersona,
      'mbtiQuadrant': mbtiQuadrant,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'messageCount': messageCount,
      'lastMessagePreview': lastMessagePreview,
    };
  }

  /// Hive Map에서 생성
  static ChatSessionModel fromHiveMap(Map<dynamic, dynamic> map) {
    return ChatSessionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      chatType: map['chatType'] as String,
      profileId: map['profileId'] as String?,
      targetProfileId: map['targetProfileId'] as String?,
      chatPersona: map['chatPersona'] as String?,
      mbtiQuadrant: map['mbtiQuadrant'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      messageCount: (map['messageCount'] as int?) ?? 0,
      lastMessagePreview: map['lastMessagePreview'] as String?,
    );
  }

  /// Supabase에 저장할 Map으로 변환 (snake_case)
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'target_profile_id': targetProfileId,
      'chat_persona': chatPersona,
      'mbti_quadrant': mbtiQuadrant,
      'title': title,
      'chat_type': chatType,
      'message_count': messageCount,
      'last_message_preview': lastMessagePreview,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Supabase INSERT용 (id, created_at, updated_at, message_count 제외)
  Map<String, dynamic> toSupabaseInsert() {
    return {
      'profile_id': profileId,
      'target_profile_id': targetProfileId,
      'chat_persona': chatPersona,
      'mbti_quadrant': mbtiQuadrant,
      'title': title,
      'chat_type': chatType,
    };
  }

  /// Supabase Map에서 생성 (snake_case → camelCase)
  static ChatSessionModel fromSupabaseMap(Map<String, dynamic> map) {
    return ChatSessionModel(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? 'saju_chat.newConversation'.tr(),
      chatType: (map['chat_type'] as String?) ?? 'general',
      profileId: map['profile_id'] as String?,
      targetProfileId: map['target_profile_id'] as String?,
      chatPersona: map['chat_persona'] as String?,
      mbtiQuadrant: map['mbti_quadrant'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      messageCount: (map['message_count'] as int?) ?? 0,
      lastMessagePreview: map['last_message_preview'] as String?,
    );
  }
}
