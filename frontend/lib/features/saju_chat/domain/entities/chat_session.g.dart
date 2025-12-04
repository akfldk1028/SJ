// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatSessionImpl _$$ChatSessionImplFromJson(Map<String, dynamic> json) =>
    _$ChatSessionImpl(
      id: json['id'] as String,
      profileId: json['profileId'] as String,
      title: json['title'] as String,
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ChatSessionImplToJson(_$ChatSessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'profileId': instance.profileId,
      'title': instance.title,
      'lastMessageAt': instance.lastMessageAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };
