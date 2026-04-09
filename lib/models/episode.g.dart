// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EpisodeAdapter extends TypeAdapter<Episode> {
  @override
  final int typeId = 1;

  @override
  Episode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Episode(
      id: fields[0] as String,
      podcastId: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String,
      audioUrl: fields[4] as String,
      duration: fields[5] as int,
      publishDate: fields[6] as DateTime,
      isDownloaded: fields[7] as bool,
      localFilePath: fields[8] as String?,
      playbackPosition: fields[9] as int?,
      artworkUrl: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Episode obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.podcastId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.audioUrl)
      ..writeByte(5)
      ..write(obj.duration)
      ..writeByte(6)
      ..write(obj.publishDate)
      ..writeByte(7)
      ..write(obj.isDownloaded)
      ..writeByte(8)
      ..write(obj.localFilePath)
      ..writeByte(9)
      ..write(obj.playbackPosition)
      ..writeByte(10)
      ..write(obj.artworkUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpisodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
