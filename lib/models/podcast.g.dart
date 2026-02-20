// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'podcast.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PodcastAdapter extends TypeAdapter<Podcast> {
  @override
  final int typeId = 0;

  @override
  Podcast read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Podcast(
      id: fields[0] as String,
      title: fields[1] as String,
      author: fields[2] as String,
      description: fields[3] as String,
      artworkUrl: fields[4] as String,
      feedUrl: fields[5] as String,
      isSubscribed: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Podcast obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.artworkUrl)
      ..writeByte(5)
      ..write(obj.feedUrl)
      ..writeByte(6)
      ..write(obj.isSubscribed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PodcastAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
