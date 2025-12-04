// GENERATED CODE - DO NOT MODIFY BY HAND
// Manual stub for build compatibility

part of 'chat_session_model.dart';

// Note: hive_generator is disabled. This is a stub file.
// TypeAdapter not generated - use JSON serialization instead if Hive storage is needed.

class ChatSessionModelAdapter extends TypeAdapter<ChatSessionModel> {
  @override
  final int typeId = 2;

  @override
  ChatSessionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatSessionModel(
      id: fields[0] as String,
      profileId: fields[1] as String,
      title: fields[2] as String,
      lastMessageAt: fields[3] as DateTime,
      createdAt: fields[4] as DateTime,
      targetProfileId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ChatSessionModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.profileId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.lastMessageAt)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.targetProfileId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSessionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
