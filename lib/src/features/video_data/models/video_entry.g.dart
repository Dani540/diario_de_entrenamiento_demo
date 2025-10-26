// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoEntryAdapter extends TypeAdapter<VideoEntry> {
  @override
  final int typeId = 0;

  @override
  VideoEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoEntry(
      videoPath: fields[0] as String,
      tags: (fields[1] as List?)?.cast<String>(),
      thumbnailPath: fields[2] as String?,
      displayName: fields[3] as String?,
      isArchived: fields[4] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, VideoEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.videoPath)
      ..writeByte(1)
      ..write(obj.tags)
      ..writeByte(2)
      ..write(obj.thumbnailPath)
      ..writeByte(3)
      ..write(obj.displayName)
      ..writeByte(4)
      ..write(obj.isArchived);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
